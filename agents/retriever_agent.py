from typing import Any, Dict, List

import chromadb
from chromadb.config import Settings
from chromadb.utils.embedding_functions import SentenceTransformerEmbeddingFunction

from config.settings import settings


class SchemaRetriever:
    def __init__(self):
        self.index_path = settings.CHROMA_PATH
        self.top_k = getattr(settings, "TOP_K", 10)
        self.similarity_threshold = getattr(settings, "SIMILARITY_THRESHOLD", 0.6)

        self.client = chromadb.PersistentClient(
            path=self.index_path,
            settings=Settings(anonymized_telemetry=False),
        )
        self.embedding_fn = SentenceTransformerEmbeddingFunction(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.collection = self.client.get_collection(
            name="clickhouse_schema",
            embedding_function=self.embedding_fn,
        )

    def retrieve_context(self, question: str, k: int = 10, threshold: float = 0.6) -> Dict[str, Any]:
        results = self.collection.query(
            query_texts=[question],
            n_results=k,
            include=["metadatas", "distances"],
        )

        relevant_tables: List[Dict[str, Any]] = []
        context_lines: List[str] = []

        for i, (metadata, distance) in enumerate(zip(results["metadatas"][0], results["distances"][0])):
            similarity = 1.0 - distance
            if similarity < threshold:
                continue

            table_info = {
                "database": metadata.get("database", "unknown"),
                "table": metadata.get("table", "unknown"),
                "column": metadata.get("column_name", "unknown"),
                "type": metadata.get("type", "unknown"),
                "comment": metadata.get("column_comment", "N/A"),
                "similarity": round(similarity, 3),
                "rank": i + 1,
            }
            relevant_tables.append(table_info)
            context_lines.append(
                f"#{i + 1} Table: {table_info['database']}.{table_info['table']} | "
                f"Column: {table_info['column']} ({table_info['type']}) | "
                f"Sim: {table_info['similarity']:.2f}"
            )

        table_context = self._group_by_table(relevant_tables)
        unique_tables = len({f"{t['database']}.{t['table']}" for t in relevant_tables})

        return {
            "relevant_tables": relevant_tables,
            "table_context": table_context,
            "raw_context": "\n".join(context_lines),
            "unique_tables": unique_tables,
            "hits": len(relevant_tables),
        }

    def _group_by_table(self, tables: List[Dict[str, Any]]) -> str:
        table_groups: Dict[str, List[str]] = {}
        for table_info in tables:
            table_key = f"{table_info['database']}.{table_info['table']}"
            table_groups.setdefault(table_key, []).append(
                f"{table_info['column']} ({table_info['type']})"
            )

        grouped = []
        for table, cols in table_groups.items():
            grouped.append(f"Table {table}: {', '.join(cols[:5])}...")

        return "\n".join(grouped)
