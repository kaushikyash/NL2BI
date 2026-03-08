from prompts.sql_prompts import TEXT2SQL_PROMPT, ERROR_CORRECTION_PROMPT
from typing import Dict, Any
import openai
from config.settings import settings
import json
import re

class SQLGeneratorAgent:
    def __init__(self):
        openai.api_key = settings.LLM_API_KEY
        if settings.LLM_BASE_URL:
            openai.api_base = settings.LLM_BASE_URL
    
    async def generate_sql(self, question: str, context: str) -> Dict[str, Any]:
        """Generate SQL using RAG + few-shot prompting"""
        
        prompt = TEXT2SQL_PROMPT.format(
            context=context,
            question=question
        )
        
        try:
            response = await openai.ChatCompletion.acreate(
                model=settings.LLM_MODEL,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1,
                max_tokens=1000
            )
            
            sql_query = response.choices[0].message.content.strip()
            sql_query = re.sub(r'^```sql\s*|\s*```$', '', sql_query).strip()
            
            return {
                "success": True,
                "sql": sql_query,
                "question": question,
                "context_used": context[:500] + "..." if len(context) > 500 else context
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "sql": None
            }
