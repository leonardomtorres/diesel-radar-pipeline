import os
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
import requests
import snowflake.connector
from dotenv import load_dotenv
from snowflake.connector.pandas_tools import write_pandas

# ANP muda esse link toda semana. Por enquanto atualizamos manualmente aqui;
# calcular isso sozinho fica pra quando o Airflow assumir a execução (Task 7).
ANP_FILE_URL = (
    "https://www.gov.br/anp/pt-br/assuntos/precos-e-defesa-da-concorrencia/"
    "precos/arquivos-lpc/2026/revendas_lpc_2026-07-26_2026-08-01.xlsx"
)

RAW_DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"


def normalize_column_name(name: str) -> str:
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode("ascii")
    return name.strip().lower().replace(" ", "_").replace("-", "_")


def download_anp_file(url: str) -> Path:
    RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
    destination = RAW_DATA_DIR / url.split("/")[-1]

    response = requests.get(url, timeout=60)
    response.raise_for_status()
    destination.write_bytes(response.content)

    return destination


def already_loaded(connection, file_name: str) -> bool:
    cursor = connection.cursor()
    try:
        cursor.execute(
            "SELECT COUNT(*) FROM BRONZE.PRECOS_COMBUSTIVEIS_RAW WHERE _SOURCE_FILE = %s",
            (file_name,),
        )
        (count,) = cursor.fetchone()
        return count > 0
    except snowflake.connector.errors.ProgrammingError:
        # A tabela ainda não existe -> nada foi carregado ainda.
        return False
    finally:
        cursor.close()


def load_to_bronze(file_path: Path) -> None:
    # O arquivo da ANP traz 9 linhas de título/metadado do relatório antes
    # da tabela de dados começar; a linha 10 (índice 9) é o cabeçalho real.
    df = pd.read_excel(file_path, header=9)
    df.columns = [normalize_column_name(c) for c in df.columns]

    # Algumas colunas de texto vêm com tipos misturados (ex: um nome fantasia
    # preenchido só com números) — isso quebra a conversão pro formato que o
    # Snowflake espera. Forçamos tudo que não é claramente numérico a virar
    # texto, mantendo valores vazios como nulos de verdade.
    text_columns = df.select_dtypes(include="object").columns
    df[text_columns] = df[text_columns].apply(
        lambda col: col.where(col.isna(), col.astype(str))
    )

    df["_source_file"] = file_path.name
    df["_loaded_at"] = datetime.now(timezone.utc)

    connection = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema="BRONZE",
    )
    try:
        if already_loaded(connection, file_path.name):
            print(f"{file_path.name} já foi carregado antes — pulando para evitar duplicidade.")
            return

        write_pandas(
            conn=connection,
            df=df,
            table_name="PRECOS_COMBUSTIVEIS_RAW",
            auto_create_table=True,
            use_logical_type=True,
        )
    finally:
        connection.close()


def main() -> None:
    load_dotenv()

    print(f"Baixando arquivo da ANP: {ANP_FILE_URL}")
    file_path = download_anp_file(ANP_FILE_URL)
    print(f"Arquivo salvo em: {file_path}")

    print("Carregando dados no Snowflake (BRONZE.PRECOS_COMBUSTIVEIS_RAW)...")
    load_to_bronze(file_path)
    print("Concluído.")


if __name__ == "__main__":
    main()
