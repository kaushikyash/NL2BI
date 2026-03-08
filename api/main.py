from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from core.rag_pipeline import Text2SQLPipeline
from config.settings import settings
import uvicorn
from typing import Dict

app = FastAPI(title="Text2SQL RAG API", version="1.0.0")

class SQLRequest(BaseModel):
    question: str
    db_path: str = ":memory:"

class SQLResponse(BaseModel):
    success: bool
    sql: str = None
    retrieval: Dict = None
    question: str = None
    error: str = None

pipeline = Text2SQLPipeline()

@app.post("/generate-sql", response_model=SQLResponse)
async def generate_sql(request: SQLRequest) -> SQLResponse:
    """Generate SQL from natural language using RAG"""
    try:
        result = await pipeline.generate_sql(request.question)
        return SQLResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy", "pipeline": "ready"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=True
    )
