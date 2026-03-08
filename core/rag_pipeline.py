from agents.retriever_agent import RetrieverAgent
from agents.sql_generator_agent import SQLGeneratorAgent
from utils.schema_embeddings import extract_schema_metadata
from typing import Dict, Any

class Text2SQLPipeline:
    def __init__(self, db_path: str = ":memory:"):
        self.retriever = RetrieverAgent()
        self.sql_generator = SQLGeneratorAgent()
        self.db_path = db_path
        self.full_schema = self._load_full_schema()
    
    def _load_full_schema(self) -> str:
        """Load complete database schema"""
        metadata = extract_schema_metadata(self.db_path)
        return "\n".join([json.dumps(m, indent=2) for m in metadata])
    
    async def generate_sql(self, question: str) -> Dict[str, Any]:
        """Complete RAG pipeline: retrieve -> generate SQL"""
        
        # Step 1: Retrieve relevant schema
        retrieval_result = self.retriever.retrieve_relevant_tables(question)
    
        print(f"Retrieved {retrieval_result['table_count']}/{retrieval_result['top_k_searched']} tables")
        print("Context preview:", retrieval_result['context'][:200])
        
        # Step 2: Generate SQL
        generation_result = await self.sql_generator.generate_sql(
            question=question,
            context=retrieval_result["context"]
        )
        
        return generation_result
