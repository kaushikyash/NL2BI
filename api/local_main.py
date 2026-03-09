import os
import sys
from pprint import pformat

from pydantic import BaseModel

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.rag_pipeline import NL2SQLPipeline


class QueryRequest(BaseModel):
    question: str


async def ask_sql(request: QueryRequest):
    pipeline = NL2SQLPipeline()
    return pipeline.process_query(request.question)


def main():
    pipeline = NL2SQLPipeline()
    question = (
        "For each manufacturing plant, show the product name and the "
        "current quantity on hand in inventory."
    )
    response = pipeline.process_query(question)
    print("[local_main] final response:")
    print(pformat(response))


if __name__ == "__main__":
    main()
