import chromadb
from chromadb.utils import embedding_functions
from typing import List, Dict, Any

class SchemaVectorStore:
    def __init__(self, index_path: str):
        self.index_path = index_path
        self.client = chromadb.PersistentClient(path=index_path)
        self.embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        self.collection = self.client.get_or_create_collection(
            name="schema_metadata",
            embedding_function=self.embedding_fn
        )
    
    def retrieve_relevant_schema(self, query: str, top_k: int = 5, threshold: float = 0.7) -> List[Dict]:
        """Retrieve most relevant table schemas for the query"""
        results = self.collection.query(
            query_texts=[query],
            n_results=top_k,
            include=["documents", "metadatas", "distances"]
        )
        
        relevant_schema = []
        for doc, metadata, distance in zip(
            results["documents"][0], 
            results["metadatas"][0], 
            results["distances"][0]
        ):
            if distance < (1.0 - threshold):  # Convert similarity threshold
                relevant_schema.append({
                    "table_name": metadata["table_name"],
                    "schema": doc,
                    "similarity": 1.0 - distance
                })
        
        return relevant_schema
