# NL2BI
AI-driven analytics tool that turns natural language questions into precise data insights and interactive dashboards. It connects directly to your data warehouse, generates optimized SQL queries automatically, and presents results through clear visualizations—making advanced business intelligence effortless and conversational.

# 1. Install dependencies
pip install -r requirements.txt

# 2. Create embeddings (run once)
python -c "
from utils.schema_embeddings import extract_schema_embeddings
extract_schema_embeddings('your_database.db', 'data/faiss_index')
"

# 3. Run API
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

# Command to hit the endpoint
curl -X POST "http://localhost:8000/generate-sql" \
  -H "Content-Type: application/json" \
  -d '{"question": "Show top 5 customers by total spend in 2025"}'