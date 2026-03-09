import re
from typing import Dict

from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI

from config.settings import settings
from prompts.sql_prompts import TEXT2SQL_PROMPT


class SQLGeneratorAgent:
    def __init__(self):
        api_key = settings.GOOGLE_API_KEY

        self.llm = ChatGoogleGenerativeAI(
            model=settings.LLM_MODEL,
            google_api_key=api_key,
            temperature=0.1,
        )
        self.prompt = ChatPromptTemplate.from_template(TEXT2SQL_PROMPT)
        self.chain = self.prompt | self.llm

    def generate_sql(self, question: str, context: Dict) -> Dict:
        """Generate SQL from NL + schema context."""
        prompt_context = context.get("table_context") or context.get("raw_context") or str(context)
        response = self.chain.invoke({
            "question": question,
            "context": prompt_context,
        })
        raw_text = response.content if hasattr(response, "content") else str(response)
        print("[sql_generator] raw model output:")
        print(raw_text)

        sql = self._extract_sql(raw_text)
        return {
            "sql": sql,
            "title": self._derive_title(question),
        }

    def _extract_sql(self, text: str) -> str:
        fenced_sql = re.search(r"```sql\s*(.*?)```", text, flags=re.IGNORECASE | re.DOTALL)
        if fenced_sql:
            return fenced_sql.group(1).strip()

        generic_fence = re.search(r"```\s*(.*?)```", text, flags=re.DOTALL)
        if generic_fence:
            return generic_fence.group(1).strip()

        return text.strip()

    def _derive_title(self, question: str) -> str:
        cleaned = question.strip().rstrip("?.!")
        return cleaned[:80] or "Query Result"
