import os
from pydantic import BaseSettings

class Settings(BaseSettings):
    # API
    API_HOST = "0.0.0.0"
    API_PORT = 8000
    
    # LLM
    LLM_MODEL = "gemini-2.5-flash"  # or "llama3.1" for local
    LLM_API_KEY = os.getenv("GOOGLE_API_KEY")
    LLM_BASE_URL = os.getenv("LLM_BASE_URL", "")
    
    # Vector DB
    FAISS_INDEX_PATH = "data/faiss_index"
    EMBEDDING_MODEL = "text-embedding-3-small"
    
    # Database
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", 5432)
    DB_NAME = os.getenv("DB_NAME", "your_db")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
    
    # RAG
    TOP_K = 5
    SIMILARITY_THRESHOLD = 0.7
    
    class Config:
        env_file = ".env"

settings = Settings()
