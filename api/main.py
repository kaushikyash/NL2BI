from fastapi import FastAPI
from pydantic import BaseModel
from core.rag_pipeline import NL2SQLPipeline

app = FastAPI(title="NL2SQL ClickHouse Agent")
pipeline = NL2SQLPipeline()

class QueryRequest(BaseModel):
    question: str

@app.post("/query")
async def ask_sql(request: QueryRequest):
    result = pipeline.process_query(request.question)
    return result

@app.get("/health")
async def health():
    return {"status": "ready"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
