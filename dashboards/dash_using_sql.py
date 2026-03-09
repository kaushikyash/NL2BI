#!/usr/bin/env python3
"""
Dynamic Grafana Dashboard Creator
- Creates datasource from connection
- Generates panels from SQL queries  
- Deploys via API
"""
import requests
import json
import base64
from typing import Dict, List, Optional

class GrafanaDashboardCreator:
    def __init__(self, grafana_url: str = "http://localhost:3000", 
                 username: str = "admin", password: str = "admin"):
        self.grafana_url = grafana_url.rstrip('/')
        self.auth = base64.b64encode(f"{username}:{password}".encode()).decode()
        self.headers = {
            "Authorization": f"Basic {self.auth}",
            "Content-Type": "application/json"
        }
    
    def create_postgres_datasource(self, name: str, host: str, port: int, 
                                 database: str, username: str, password: str) -> Optional[str]:
        """Create PostgreSQL datasource"""
        datasource = {
            "name": name,
            "type": "postgres",
            "url": f"{host}:{port}",
            "database": database,
            "user": username,
            "secureJsonData": {"password": password},
            "jsonData": {
                "sslmode": "disable",
                "maxOpenConns": 100,
                "maxIdleConns": 100,
                "maxConnLifetime": 14400,
                "postgresVersion": 1500,
                "timescaledb": False
            },
            "isDefault": True
        }
        
        response = requests.post(
            f"{self.grafana_url}/api/datasources",
            headers=self.headers,
            json=datasource
        )
        
        if response.status_code == 200:
            uid = response.json()["datasource"]["uid"]
            print(f"✅ Datasource '{name}' created: {uid}")
            return uid
        else:
            print(f"❌ Datasource failed: {response.status_code}")
            print(response.text)
            return None
    
    def create_clickhouse_datasource(self, name: str, host: str, port: int = 8123,
                                database: str = "default", username: str = "default", 
                                password: str = "") -> Optional[str]:
        datasource = {
            "name": name,
            "type": "clickhouse",  # ← CHANGED: "postgres" → "clickhouse"
            "url": f"{host}:{port}",  # Default HTTP: 8123
            "database": database,
            "user": username,
            "secureJsonData": {"password": password},
            "jsonData": {
                "serverTimezone": "utc",
                "tlsSkipVerify": True,  # For self-signed certs
                "port": port,
                "protocol": "http"      # or "native" (9000)
            },
            "isDefault": True
        }
        
        response = requests.post(
            f"{self.grafana_url}/api/datasources",
            headers=self.headers,
            json=datasource
        )
        
        if response.status_code == 200:
            uid = response.json()["datasource"]["uid"]
            print(f"✅ ClickHouse '{name}' created: {uid}")
            return uid
        else:
            print(f"❌ ClickHouse failed: {response.text}")
            return None


    def generate_panel(self, title: str, sql: str, panel_type: str = "stat", 
                      datasource_uid: str = "postgres-mixed") -> dict:
        """Generate panel from SQL query"""
        return {
            "id": None,
            "title": title,
            "gridPos": {"h": 9, "w": 12, "x": 0, "y": 0},
            "type": panel_type,
            "targets": [{
                "datasource": {"type": "postgres", "uid": datasource_uid},
                "rawSql": sql,
                "format": "time_series",
                "refId": "A"
            }],
            "fieldConfig": {
                "defaults": {
                    "unit": "short",
                    "color": {"mode": "palette-classic"},
                    "thresholds": {
                        "steps": [
                            {"color": "green", "value": None},
                            {"color": "yellow", "value": 80},
                            {"color": "red", "value": 200}
                        ]
                    }
                }
            }
        }
    
    def create_dashboard(self, title: str, panels: List[dict], 
                        datasource_uid: str, folder: int = 0) -> Optional[str]:
        """Create dashboard with panels"""
        dashboard = {
            "dashboard": {
                "id": None,
                "uid": title.lower().replace(" ", "-"),
                "title": title,
                "panels": panels,
                "time": {"from": "now-24h", "to": "now"},
                "refresh": "30s",
                "schemaVersion": 38,
                "tags": ["python", "dynamic"]
            },
            "folder": folder,
            "overwrite": True
        }
        
        response = requests.post(
            f"{self.grafana_url}/api/dashboards/db",
            headers=self.headers,
            json=dashboard
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Dashboard '{title}': {self.grafana_url}{result['url']}")
            return result['uid']
        else:
            print(f"❌ Dashboard failed: {response.status_code}")
            print(response.text)
            return None

def main():
    """Example usage"""
    creator = GrafanaDashboardCreator()
    
    # 1. Create datasource
    ds_uid = creator.create_clickhouse_datasource(
        name="sales_db",
        host="localhost",
        port=8123,
        database="sales",
        username="default",
        password="password"
    )
    
    if not ds_uid:
        print("❌ Cannot continue without datasource")
        return
    
    # 2. SQL queries
    queries = [
        ("Total Revenue", "SELECT sum(revenue) as value, now() as time FROM sales"),
        ("Orders Today", "SELECT count(*) as orders, now() as time FROM orders WHERE date_trunc('day', order_date) = current_date"),
        ("Top Category", "SELECT category, sum(revenue) as revenue FROM sales GROUP BY category ORDER BY revenue DESC LIMIT 1"),
        ("Customer Count", "SELECT count(distinct customer_id) as customers FROM orders")
    ]
    
    # 3. Generate panels
    panels = []
    for i, (title, sql) in enumerate(queries):
        panel = creator.generate_panel(
            title=title,
            sql=sql,
            panel_type="stat" if i < 3 else "table",
            datasource_uid=ds_uid
        )
        panel["gridPos"]["x"] = (i % 2) * 12
        panel["gridPos"]["y"] = (i // 2) * 9
        panels.append(panel)
    
    # 4. Create dashboard
    creator.create_dashboard(
        title="Sales Analytics Dashboard",
        panels=panels,
        datasource_uid=ds_uid
    )

if __name__ == "__main__":
    main()
