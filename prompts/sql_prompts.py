TEXT2SQL_PROMPT = """You are an expert SQL assistant. Generate precise SQL queries based on the database schema and user question.

DATABASE SCHEMA:
{schema}

RELEVANT TABLES (from vector search):
{context}

FEW-SHOT EXAMPLES:
