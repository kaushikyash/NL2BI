import os
import sys
from datetime import datetime
from pprint import pformat

from pydantic import BaseModel

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.rag_pipeline import NL2SQLPipeline
from utils.generate_py_dash import save_dashboard_payload


class QueryRequest(BaseModel):
    question: str
    create_dashboard: bool = False
    dashboard_title: str | None = None
    dashboard_uid: str | None = None


async def ask_sql(request: QueryRequest):
    pipeline = NL2SQLPipeline()
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


def _random_dashboard_metadata() -> tuple[str, str]:
    suffix = datetime.now().strftime("%Y%m%d-%H%M%S")
    return (f"Generated Dashboard {suffix}", f"generated-dashboard-{suffix.lower()}")


def main():
    pipeline = NL2SQLPipeline()
    question = (
        "For each manufacturing plant, show the product name and the "
        "current quantity on hand in inventory."
    )
    dashboard_title, dashboard_uid = _random_dashboard_metadata()
    response = pipeline.process_query(
        question=question,
        create_dashboard=True,
        dashboard_title=dashboard_title,
        dashboard_uid=dashboard_uid,
    )
    dashboard = response.get("dashboard")
    if dashboard and dashboard.get("json"):
        saved_path = save_dashboard_payload(dashboard)
        response["dashboard"]["saved_path"] = str(saved_path)
    print("[local_main] final response:")
    print(pformat(response))


if __name__ == "__main__":
    main()
