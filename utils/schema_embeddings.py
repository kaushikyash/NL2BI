import sqlite3
import chromadb
from chromadb.utils import embedding_functions
import json
import os

def extract_schema_metadata(db_path: str = ":memory:") -> list:
    """Extract table/column metadata for vectorization"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    metadata = []
    
    # Get all tables
    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    tables = cursor.fetchall()
    
    for table_name in tables:
        table_name = table_name[0]
        
        # Get columns
        cursor.execute(f"""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = '{table_name}'
        """)
        columns = cursor.fetchall()
        
        table_info = {
            "table_name": table_name,
            "columns": [{"name": col[0], "type": col[1], "nullable": col[2], "default": col[3]} for col in columns],
            "description": f"Table {table_name} with columns: {', '.join(c[0] for c in columns)}"
        }
        
        metadata.append(table_info)
    
    conn.close()
    return metadata

def create_schema_embeddings(metadata: list, index_path: str):
    """Create FAISS/Chroma embeddings for schema metadata"""
    os.makedirs(os.path.dirname(index_path), exist_ok=True)
    
    chroma_client = chromadb.PersistentClient(path=index_path)
    embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="all-MiniLM-L6-v2"
    )
    
    collection = chroma_client.get_or_create_collection(
        name="schema_metadata",
        embedding_function=embedding_fn
    )
    
    documents = []
    ids = []
    metadatas = []
    
    for i, table_info in enumerate(metadata):
        doc = json.dumps(table_info, indent=2)
        documents.append(doc)
        ids.append(f"table_{i}")
        metadatas.append({"table_name": table_info["table_name"]})
    
    collection.add(
        documents=documents,
        ids=ids,
        metadatas=metadatas
    )
