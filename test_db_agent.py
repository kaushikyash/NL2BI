import os
from dotenv import load_dotenv
from openai import OpenAI
from clickhouse_connect import get_client
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import google.generativeai as genai



load_dotenv()

# -----------------------------
# CONFIG
# -----------------------------

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CLICKHOUSE_HOST = os.getenv("CLICKHOUSE_HOST")
CLICKHOUSE_PORT = str(os.getenv("CLICKHOUSE_PORT"))
CLICKHOUSE_DB = os.getenv("CLICKHOUSE_DB")

EMBED_MODEL = "text-embedding-3-small"
LLM_MODEL = "gpt-4.1"

# -----------------------------
# CLIENTS
# -----------------------------

# Configures from env var GEMINI_API_KEY
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

model = genai.GenerativeModel("gemini-2.5-flash")
response = model.generate_content("Explain RAG in AI.")
#print(response.text)


#openai = OpenAI(api_key=OPENAI_API_KEY)

clickhouse = get_client(
    host=CLICKHOUSE_HOST,
    port=CLICKHOUSE_PORT,
    database=CLICKHOUSE_DB
)

qdrant = QdrantClient(":memory:")

COLLECTION = "schema_vectors"
'''
# -----------------------------
# CREATE VECTOR COLLECTION
# -----------------------------

def init_vector_db():

    if COLLECTION not in [c.name for c in qdrant.get_collections().collections]:

        qdrant.create_collection(
            collection_name=COLLECTION,
            vectors_config=VectorParams(
                size=1536,
                distance=Distance.COSINE
            )
        )

# -----------------------------
# EXTRACT CLICKHOUSE SCHEMA
# -----------------------------

def get_schema():

    query = """
    SELECT
        table,
        name,
        type
    FROM system.columns
    WHERE database = %(db)s
    """

    rows = clickhouse.query(query, {"db": CLICKHOUSE_DB}).result_rows

    docs = []

    for table, column, dtype in rows:

        docs.append(
            f"Table {table} column {column} type {dtype}"
        )

    return docs

# -----------------------------
# CREATE EMBEDDINGS
# -----------------------------

def embed_text(texts):

    resp = openai.embeddings.create(
        model=EMBED_MODEL,
        input=texts
    )

    return [e.embedding for e in resp.data]

# -----------------------------
# INDEX SCHEMA
# -----------------------------

def index_schema():

    docs = get_schema()

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

    hits = qdrant.search(
        collection_name=COLLECTION,
        query_vector=vec,
        limit=5
    )

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

Schema:
{schema_context}

Question:
{question}

Return only SQL.
"""

    resp = openai.chat.completions.create(
        model=LLM_MODEL,
        messages=[{"role": "user", "content": prompt}]
    )

    sql = resp.choices[0].message.content.strip()

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
'''
