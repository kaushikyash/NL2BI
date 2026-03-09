import re
from datetime import datetime
from pprint import pformat
from typing import Any, Dict, List, Optional

from agents.retriever_agent import SchemaRetriever
from agents.sql_generator_agent import SQLGeneratorAgent
from core.executor import SQLExecutor
from utils.generate_py_dash import build_dashboard_for_query


class NL2SQLPipeline:
    def __init__(self):
        self.retriever = SchemaRetriever()
        self.sql_gen = SQLGeneratorAgent()
        self.executor = SQLExecutor()

    def process_query(
        self,
        question: str,
        create_dashboard: bool = False,
        dashboard_title: Optional[str] = None,
        dashboard_uid: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Full pipeline: NL -> SQL -> Execute -> response."""
        print(
            "[pipeline] request",
            {
                "question": question,
                "create_dashboard": create_dashboard,
                "dashboard_title": dashboard_title,
                "dashboard_uid": dashboard_uid,
            },
        )

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

        visualization = self._infer_visualization(question, sql_result["sql"], result)
        print("[pipeline] visualization:")
        print(pformat(visualization))

        response = self._format_response(result, sql_result["sql"])
        response["visualization"] = visualization

        if create_dashboard and not self._has_error(result):
            print("[pipeline] dashboard generation enabled, building payload")
            dashboard_payload = self._build_dashboard_payload(
                sql=sql_result["sql"],
                question=question,
                visualization=visualization,
                dashboard_title=dashboard_title,
                dashboard_uid=dashboard_uid,
            )
            response["dashboard"] = dashboard_payload
        else:
            print(
                "[pipeline] dashboard generation skipped",
                {
                    "create_dashboard": create_dashboard,
                    "has_error": self._has_error(result),
                },
            )

        return response

    def _format_response(self, result: Any, sql: str) -> Dict[str, Any]:
        if result.is_single_row and result.data and not result.data[0].get("error"):
            return {
                "type": "text",
                "message": str(result.data[0]),
                "sql": sql,
                "rows": result.rows,
            }

        return {
            "type": "table",
            "columns": result.columns,
            "data": result.data,
            "sql": sql,
            "rows": result.rows,
        }

    def _build_dashboard_payload(
        self,
        sql: str,
        question: str,
        visualization: Dict[str, Any],
        dashboard_title: Optional[str],
        dashboard_uid: Optional[str],
    ) -> Dict[str, Any]:
        title = dashboard_title or f"Dashboard for {visualization['title']}"
        if not dashboard_title or not dashboard_uid:
            generated_title, generated_uid = self._default_dashboard_metadata()
            title = dashboard_title or generated_title
            uid = dashboard_uid or generated_uid
        else:
            uid = dashboard_uid
        query_payload = {
            "title": visualization["title"],
            "sql": sql,
            "panel_type": visualization["panel_type"],
            "unit": visualization["unit"],
        }
        print(
            "[pipeline] dashboard payload input",
            {
                "title": title,
                "uid": uid,
                "query_payload": query_payload,
            },
        )
        dashboard_json = build_dashboard_for_query(
            sql=sql,
            title=visualization["title"],
            panel_type=visualization["panel_type"],
            unit=visualization["unit"],
            dashboard_title=title,
            dashboard_uid=uid,
        )
        return {
            "enabled": True,
            "title": title,
            "uid": uid,
            "queries": [query_payload],
            "json": dashboard_json,
        }

    def _infer_visualization(self, question: str, sql: str, result: Any) -> Dict[str, Any]:
        if self._has_error(result):
            return {
                "panel_type": "table",
                "unit": "short",
                "title": self._derive_title(question),
                "reason": "Execution returned an error, so raw table output is safest.",
            }

        columns = result.columns or []
        rows = result.data or []
        title = self._derive_title(question)
        unit = self._infer_unit(columns)

        if result.rows == 1:
            numeric_cols = self._numeric_columns(rows, columns)
            if len(numeric_cols) == 1:
                return {
                    "panel_type": "stat",
                    "unit": unit,
                    "title": title,
                    "reason": "Single-row single-metric result fits a stat panel.",
                }

        if self._looks_timeseries(columns, rows):
            return {
                "panel_type": "timeseries",
                "unit": unit,
                "title": title,
                "reason": "First column looks temporal and pairs with numeric values.",
            }

        if self._looks_categorical_metric(columns, rows):
            category_count = len(rows)
            panel_type = "piechart" if 2 <= category_count <= 8 else "barchart"
            reason = (
                "Low-cardinality categorical breakdown fits a pie chart."
                if panel_type == "piechart"
                else "Categorical comparison fits a bar chart."
            )
            return {
                "panel_type": panel_type,
                "unit": unit,
                "title": title,
                "reason": reason,
            }

        return {
            "panel_type": "table",
            "unit": unit,
            "title": title,
            "reason": "Multi-column result is best preserved as a table.",
        }

    def _has_error(self, result: Any) -> bool:
        return bool(result.data and isinstance(result.data[0], dict) and result.data[0].get("error"))

    def _derive_title(self, question: str) -> str:
        cleaned = question.strip().rstrip("?.!")
        return cleaned[:80] or "Query Result"

    def _slugify(self, value: str) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
        return slug or "generated-dashboard"

    def _default_dashboard_metadata(self) -> tuple[str, str]:
        suffix = datetime.now().strftime("%Y%m%d-%H%M%S")
        return (f"Generated Dashboard {suffix}", f"generated-dashboard-{suffix}")

    def _infer_unit(self, columns: List[str]) -> str:
        currency_terms = ("revenue", "sales", "amount", "price", "cost", "profit")
        percent_terms = ("percent", "percentage", "ratio", "rate", "share")
        column_text = " ".join(columns).lower()
        if any(term in column_text for term in currency_terms):
            return "currencyUSD"
        if any(term in column_text for term in percent_terms):
            return "percent"
        return "short"

    def _numeric_columns(self, rows: List[Dict[str, Any]], columns: List[str]) -> List[str]:
        numeric_cols: List[str] = []
        if not rows:
            return numeric_cols

        sample = rows[0]
        for column in columns:
            value = sample.get(column)
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                numeric_cols.append(column)
        return numeric_cols

    def _looks_timeseries(self, columns: List[str], rows: List[Dict[str, Any]]) -> bool:
        if len(columns) < 2 or not rows:
            return False
        first_col = columns[0].lower()
        if any(token in first_col for token in ("date", "time", "month", "year", "day")):
            return len(self._numeric_columns(rows, columns[1:])) >= 1
        return False

    def _looks_categorical_metric(self, columns: List[str], rows: List[Dict[str, Any]]) -> bool:
        if len(columns) != 2 or not rows:
            return False
        sample = rows[0]
        first_value = sample.get(columns[0])
        second_value = sample.get(columns[1])
        return isinstance(first_value, (str, int)) and isinstance(second_value, (int, float))
