import os
from dotenv import load_dotenv
from clickhouse_connect import get_client
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from google import genai
from google.genai import types
import pandas as pd
import json

load_dotenv()

# -----------------------------
# CONFIG
# -----------------------------

CLICKHOUSE_HOST = os.getenv("CLICKHOUSE_HOST")
CLICKHOUSE_PORT = str(os.getenv("CLICKHOUSE_PORT"))
CLICKHOUSE_DB = os.getenv("CLICKHOUSE_DB")
CLICKHOUSE_USER = os.getenv("USERNAME")
CLICKHOUSE_PASSWORD = os.getenv("PASSWORD")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

EMBED_MODEL = "gemini-embedding-001"
LLM_MODEL = "gemini-2.5-flash"
EMBED_DIM = 768
COLLECTION = "schema_vectors"

# -----------------------------
# CLIENTS
# -----------------------------

genai_client = genai.Client(api_key=GEMINI_API_KEY)

clickhouse = get_client(
    host=CLICKHOUSE_HOST,
    port=CLICKHOUSE_PORT,
    database=CLICKHOUSE_DB,
    username=CLICKHOUSE_USER,
    password=CLICKHOUSE_PASSWORD
)

qdrant = QdrantClient(":memory:")

# -----------------------------
# CREATE VECTOR COLLECTION
# -----------------------------

def init_vector_db():
    existing = [c.name for c in qdrant.get_collections().collections]

    if COLLECTION not in existing:
        qdrant.create_collection(
            collection_name=COLLECTION,
            vectors_config=VectorParams(
                size=EMBED_DIM,
                distance=Distance.COSINE
            )
        )

    print(qdrant.get_collections().collections)

# -----------------------------
# EXTRACT CLICKHOUSE SCHEMA
# -----------------------------


def get_schema():

    query = f"""
    SELECT
        c.database,
        c.table,
        t.comment AS table_comment,
        c.name AS column_name,
        c.type,
        c.comment AS column_comment
    FROM system.columns c
    LEFT JOIN system.tables t
        ON c.database = t.database
    AND c.table = t.name
    WHERE c.database = '{CLICKHOUSE_DB}'
    """

    result = clickhouse.query(query)
    df = pd.DataFrame(result.result_rows, columns=result.column_names)

    # Convert to structured JSON (useful for AI context)
    schema_dict = {}

    for _, row in df.iterrows():
        table = row["table"]
        
        if table not in schema_dict:
            schema_dict[table] = {
                "table_comment": row["table_comment"],
                "columns": []
            }

        schema_dict[table]["columns"].append({
            "column_name": row["column_name"],
            "type": row["type"],
            "column_comment": row["column_comment"]
        })

    # Save JSON
    with open("clickhouse_schema_comments.json", "w") as f:
        json.dump(schema_dict, f, indent=4)

# -----------------------------
# CREATE EMBEDDINGS
# -----------------------------

def embed_text(texts, batch_size=100):
    all_vectors = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]

        result = genai_client.models.embed_content(
            model=EMBED_MODEL,
            contents=batch,
            config=types.EmbedContentConfig(
                output_dimensionality=EMBED_DIM,
                task_type="SEMANTIC_SIMILARITY"
            )
        )

        all_vectors.extend([emb.values for emb in result.embeddings])

    return all_vectors

# -----------------------------
# INDEX SCHEMA
# -----------------------------

def index_schema():
    docs = get_schema()

    if not docs:
        print("No schema docs found.")
        return

    print(f"Embedding {len(docs)} schema rows...")

    vectors = embed_text(docs)

    points = []
    for i, (doc, vec) in enumerate(zip(docs, vectors)):
        points.append(
            PointStruct(
                id=i,
                vector=vec,
                payload={"text": doc}
            )
        )

    qdrant.upsert(
        collection_name=COLLECTION,
        points=points
    )

    print(f"Indexed {len(points)} schema rows")

# -----------------------------
# RETRIEVE RELEVANT SCHEMA
# -----------------------------

def retrieve_schema(question):

    vec = embed_text([question])[0]

    result = qdrant.query_points(
        collection_name=COLLECTION,
        query=vec,
        limit=5
    )

    hits = result.points

    context = "\n".join(
        hit.payload["text"] for hit in hits
    )

    return context

# -----------------------------
# GENERATE SQL
# -----------------------------

def generate_sql(question, schema_context):
    prompt = f"""
You are a ClickHouse SQL expert.

Use only the schema context below to answer.

Schema:
{schema_context}

Question:
{question}

Rules:
- Return only valid ClickHouse SQL.
- Do not add markdown.
- Do not add explanations.
- Prefer explicit table and column names from the schema.
"""

    response = genai_client.models.generate_content(
        model=LLM_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=0
        )
    )

    sql = response.text.strip()
    sql = sql.replace("```sql", "").replace("```", "").strip()
    return sql

# -----------------------------
# EXECUTE SQL
# -----------------------------

def run_sql(sql):
    try:
        result = clickhouse.query(sql)
        return result.result_rows
    except Exception as e:
        return str(e)

# -----------------------------
# AGENT LOOP
# -----------------------------

def ask(question):
    print("\nQuestion:", question)

    schema_context = retrieve_schema(question)
    print("\nRetrieved schema context:\n", schema_context)

    sql = generate_sql(question, schema_context)
    print("\nGenerated SQL:\n", sql)

    result = run_sql(sql)
    print("\nResult:\n", result)

# -----------------------------
# MAIN
# -----------------------------

def main():
    init_vector_db()
    index_schema()

    print("\nAI ClickHouse Agent Ready")

    while True:
        q = input("\nAsk question (or quit): ")

        if q.lower() in ["quit", "exit"]:
            break

        ask(q)

if __name__ == "__main__":
    main()