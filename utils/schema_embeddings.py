import clickhouse_connect
from typing import List, Dict
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import chromadb
from chromadb.utils import embedding_functions
from config.settings import settings


def get_clickhouse_schema() -> List[Dict]:
    """Extract schema from ClickHouse"""
    client = clickhouse_connect.get_client(
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        database=settings.DB_NAME,
        username=settings.DB_USER,
        password=settings.DB_PASSWORD
    )
    
    query = f"""
    SELECT 
        c.database,
        c.table,
        t.comment AS table_comment,
        c.name AS column_name,
        c.type,
        c.comment AS column_comment
    FROM system.columns c
    LEFT JOIN system.tables t ON c.database = t.database AND c.table = t.name
    WHERE c.database = '{settings.DB_NAME}'
    """
    
    rows = client.query_df(query).to_dict('records')
    client.close()
    
    # Create embedding texts
    schema_docs = []
    for row in rows:
        doc = f"""
        Table: {row['table']} ({row.get('table_comment', 'No comment')})
        Columns: {row['column_name']} ({row['type']}) - {row.get('column_comment', 'No comment')}
        Database: {row['database']}
        """.strip()
        
        schema_docs.append({
            "id": f"{row['table']}_{row['column_name']}",
            "embedding_text": doc,
            "metadata": row
        })
    
    return schema_docs

def build_schema_index():
    """Build ChromaDB index"""
    docs = get_clickhouse_schema()
    
    client = chromadb.PersistentClient(path=settings.CHROMA_PATH)
    embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="all-MiniLM-L6-v2"
    )
    
    collection = client.get_or_create_collection(
        name="clickhouse_schema",
        embedding_function=embedding_fn
    )
    
    # Add documents
    collection.add(
        documents=[doc["embedding_text"] for doc in docs],
        ids=[doc["id"] for doc in docs],
        metadatas=[doc["metadata"] for doc in docs]
    )
    
    print(f"✅ Schema index built: {len(docs)} columns")

build_schema_index()