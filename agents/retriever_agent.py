from typing import Dict, Any
import chromadb
from chromadb.utils import embedding_functions
from chromadb.config import Settings
from config.settings import settings

class RetrieverAgent:
    def __init__(self):
        self.index_path = settings.FAISS_INDEX_PATH
        self.top_k = getattr(settings, 'TOP_K', 5)
        self.similarity_threshold = getattr(settings, 'SIMILARITY_THRESHOLD', 0.7)
        
        self.client = chromadb.PersistentClient(path=self.index_path)
        self.embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        self.collection = self.client.get_or_create_collection(
            name="db_schema",
            embedding_function=self.embedding_fn,
            metadata={"hnsw:space": "cosine"}
        )
    
    def retrieve_relevant_tables(self, question: str) -> Dict[str, Any]:
        """
        Retrieve relevant schema tables via ChromaDB vector search
        Returns formatted context for LLM prompting
        """
        # Vector similarity search
        results = self.collection.query(
            query_texts=[question],
            n_results=self.top_k,
            include=["documents", "metadatas", "distances"]
        )
        
        # Filter + format context
        relevant_tables = []
        context_lines = []
        
        for doc, metadata, distance in zip(
            results['documents'][0],
            results['metadatas'][0],
            results['distances'][0]
        ):
            similarity = 1.0 - distance
            
            if similarity >= self.similarity_threshold:
                table_name = metadata['table_name']
                
                context_lines.append(
                    f"Table: {table_name} (sim={similarity:.2f})\n{doc}"
                )
                
                relevant_tables.append({
                    "table_name": table_name,
                    "similarity": similarity
                })
        
        context = "\n\n---\n\n".join(context_lines)
        
        return {
            "relevant_tables": relevant_tables,
            "context": context,
            "table_count": len(relevant_tables)
        }
