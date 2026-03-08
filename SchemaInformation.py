import clickhouse_connect
import pandas as pd
import json

# Connection configuration
CLICKHOUSE_HOST = "localhost"
CLICKHOUSE_PORT = 8123
CLICKHOUSE_USER = "default"
CLICKHOUSE_PASSWORD = "default"
DATABASE = "manufacturing_dw"

# Connect to ClickHouse
client = clickhouse_connect.get_client(
    host=CLICKHOUSE_HOST,
    port=CLICKHOUSE_PORT,
    username=CLICKHOUSE_USER,
    password=CLICKHOUSE_PASSWORD
)

query = f"""
SELECT
    c.database,
    c.table,
    t.comment AS table_comment,
    c.name AS column_name,
    c.type,
    c.comment AS column_comment,
    c.position
FROM system.columns c
LEFT JOIN system.tables t
    ON c.database = t.database
   AND c.table = t.name
WHERE c.database = '{DATABASE}'
ORDER BY c.table, c.position
"""

# Execute query
result = client.query(query)

# Convert to dataframe
df = pd.DataFrame(result.result_rows, columns=result.column_names)

# Save CSV
#df.to_csv("clickhouse_schema_comments.csv", index=False)

# Convert to structured JSON (useful for AI context)
schema_dict = {}

for _, row in df.iterrows():
    table = row["table"]
    
    if table not in schema_dict:
        schema_dict[table] = {
            "table_comment": row["table_comment"],
            "columns": []
        }

    schema_dict[table]["columns"].append({
        "column_name": row["column_name"],
        "type": row["type"],
        "column_comment": row["column_comment"]
    })

# Save JSON
with open("clickhouse_schema_comments.json", "w") as f:
    json.dump(schema_dict, f, indent=4)

print(schema_dict)
print(" - clickhouse_schema_comments.json")