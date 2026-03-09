import clickhouse_connect
import json
from typing import Dict, Any
from config.settings import settings
from pydantic import BaseModel

class QueryResult(BaseModel):
    rows: int
    columns: list
    data: list
    is_single_row: bool

class SQLExecutor:
    def __init__(self):
        self.client = None
        self.client = clickhouse_connect.get_client(
            host=settings.CLICKHOUSE_HOST,
            port=settings.CLICKHOUSE_PORT,
            database=settings.CLICKHOUSE_DB,
            username=settings.CLICKHOUSE_USER,
            password=settings.CLICKHOUSE_PASSWORD
        )
    
    def execute(self, sql: str) -> QueryResult:
        """Execute SQL and format as JSON"""
        try:
            df = self.client.query_df(sql)
            
            result = QueryResult(
                rows=len(df),
                columns=df.columns.tolist(),
                data=df.to_dict('records'),
                is_single_row=len(df) <= 1
            )
            
            return result
        except Exception as e:
            return QueryResult(
                rows=0,
                columns=[],
                data=[{"error": str(e)}],
                is_single_row=True
            )
    
    def __del__(self):
        if self.client is not None:
            self.client.close()
