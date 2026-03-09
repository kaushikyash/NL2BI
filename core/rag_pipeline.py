from pprint import pformat
from typing import Dict

from agents.retriever_agent import SchemaRetriever
from agents.sql_generator_agent import SQLGeneratorAgent
from core.executor import SQLExecutor


class NL2SQLPipeline:
    def __init__(self):
        self.retriever = SchemaRetriever()
        self.sql_gen = SQLGeneratorAgent()
        self.executor = SQLExecutor()

    def process_query(self, question: str) -> Dict:
        """Full pipeline: NL -> SQL -> Execute -> JSON."""
        print(f"[pipeline] question: {question}")

        context = self.retriever.retrieve_context(question)
        print(
            f"[pipeline] retrieved hits={context.get('hits', 0)} "
            f"unique_tables={context.get('unique_tables', 0)}"
        )
        if context.get("table_context"):
            print("[pipeline] table context:")
            print(context["table_context"])

        sql_result = self.sql_gen.generate_sql(question, context)
        print("[pipeline] generated SQL:")
        print(sql_result["sql"])

        result = self.executor.execute(sql_result["sql"])
        print(f"[pipeline] execution rows={result.rows} columns={result.columns}")
        if result.data:
            print("[pipeline] first row:")
            print(pformat(result.data[0]))

        if result.is_single_row and not result.data[0].get("error"):
            return {
                "type": "text",
                "message": str(result.data[0]),
                "sql": sql_result["sql"],
                "rows": result.rows,
            }

        return {
            "type": "table",
            "columns": result.columns,
            "data": result.data,
            "sql": sql_result["sql"],
            "rows": result.rows,
        }
