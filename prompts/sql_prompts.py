TEXT2SQL_PROMPT = """You are an expert SQL assistant. Generate precise SQL queries based on the database schema and user question.

RELEVANT TABLES (from vector search):
{context}

FEW-SHOT EXAMPLES:
Example 1:
Question: "Show me total sales by product category last month"
SQL: SELECT category, SUM(amount) as total_sales FROM sales s JOIN products p ON s.product_id = p.id WHERE s.sale_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') GROUP BY category;

Example 2:
Question: "Which customers spent more than $1000 in 2024?"
SQL: SELECT customer_id, SUM(amount) as total_spent FROM orders WHERE order_date >= '2024-01-01' GROUP BY customer_id HAVING SUM(amount) > 1000;

Example 3:
Question: "Top 5 products by revenue this quarter"
SQL: SELECT p.name, SUM(oi.quantity * oi.unit_price) as revenue FROM order_items oi JOIN products p ON oi.product_id = p.id JOIN orders o ON oi.order_id = o.id WHERE o.order_date >= DATE_TRUNC('quarter', CURRENT_DATE) GROUP BY p.id, p.name ORDER BY revenue DESC LIMIT 5;


USER QUESTION: {question}

Generate ONLY the SQL query. Use proper table aliases. Consider date formats and constraints from schema."""

ERROR_CORRECTION_PROMPT = """The following SQL query failed:

```sql
{failed_query}
Error: {error}

Fix the query and return ONLY the corrected SQL."""