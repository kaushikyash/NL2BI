from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel

from core.rag_pipeline import NL2SQLPipeline
from utils.generate_py_dash import save_dashboard_payload


app = FastAPI(title="NL2SQL ClickHouse Agent")
pipeline = NL2SQLPipeline()


class QueryRequest(BaseModel):
    question: str
    create_dashboard: bool = False
    dashboard_title: Optional[str] = None
    dashboard_uid: Optional[str] = None


@app.post("/query")
async def ask_sql(request: QueryRequest):
    print(
        "[api] /query",
        {
            "question": request.question,
            "create_dashboard": request.create_dashboard,
            "dashboard_title": request.dashboard_title,
            "dashboard_uid": request.dashboard_uid,
        },
    )
    response = pipeline.process_query(
        question=request.question,
        create_dashboard=request.create_dashboard,
        dashboard_title=request.dashboard_title,
        dashboard_uid=request.dashboard_uid,
    )
    dashboard = response.get("dashboard")
    if dashboard and dashboard.get("json"):
        saved_path = save_dashboard_payload(dashboard)
        response["dashboard"]["saved_path"] = str(saved_path)
    return response


@app.get("/health")
async def health():
    return {"status": "ready"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
