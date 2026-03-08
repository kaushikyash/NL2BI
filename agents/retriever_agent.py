from core.vector_store import SchemaVectorStore
from typing import List, Dict, Any
from config.settings import settings

class RetrieverAgent:
    def __init__(self):
        self.vector_store = SchemaVectorStore(settings.FAISS_INDEX_PATH)
    
    def retrieve(self, question: str) -> Dict[str, Any]:
        """Retrieve relevant schema context for RAG"""
        relevant_tables = self.vector_store.retrieve_relevant_schema(
            query=question,
            top_k=settings.TOP_K,
            threshold=settings.SIMILARITY_THRESHOLD
        )
        
        context = "\n".join([
            f"Table: {item['table_name']}\nSchema: {item['schema']}"
            for item in relevant_tables
        ])
        
        return {
            "relevant_tables": relevant_tables,
            "context": context,
            "table_count": len(relevant_tables)
        }
