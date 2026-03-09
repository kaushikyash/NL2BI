#!/usr/bin/env python3
"""
Fixed Bar/Pie Grafana Dashboard Generator
"""
import json
import requests
import base64

def generate_bar_pie_dashboard(title: str = "Sales Analytics") -> dict:
    """Generate Bar + Pie dashboard - FIXED booleans"""
    return {
        "dashboard": {
            "id": None,
            "uid": "sales-analytics",
            "title": title,
            "tags": ["bar", "pie", "analytics"],
            "timezone": "browser",
            "schemaVersion": 38,
            "version": 0,
            "refresh": "30s",
            "panels": [
                # BAR CHART
                {
                    "id": 1,
                    "gridPos": {"h": 12, "w": 12, "x": 0, "y": 0},
                    "title": "Revenue by Category",
                    "type": "barchart",
                    "targets": [{"expr": "100", "legendFormat": "Revenue", "refId": "A"}],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "currencyUSD",
                            "color": {"mode": "palette-desaturate"},
                            "custom": {
                                "axisLabel": "",
                                "barAlignment": 0,
                                "drawTooltip": True,
                                "fillOpacity": 80,
                                "gradientMode": "none",
                                "justifyMode": "auto",
                                "orientation": "horizontal",
                                "showUnfilled": True
                            }
                        }
                    },
                    "options": {
                        "orientation": "horizontal",
                        "xTickLabelRotation": 0
                    }
                },
                
                # PIE CHART
                {
                    "id": 2,
                    "gridPos": {"h": 12, "w": 12, "x": 12, "y": 0},
                    "title": "Market Share",
                    "type": "piechart",
                    "targets": [
                        {"expr": "40", "legendFormat": "Electronics", "refId": "A"},
                        {"expr": "35", "legendFormat": "Clothing", "refId": "B"},
                        {"expr": "25", "legendFormat": "Books", "refId": "C"}
                    ],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "percent",
                            "color": {"mode": "palette-classic"},
                            "min": 0
                        }
                    },
                    "options": {
                        "pieType": "pie",
                        "tooltip": {"mode": "single", "sort": "none"},
                        "reduceOptions": {
                            "calcs": ["lastNotNull"],
                            "fields": "",
                            "values": False
                        }
                    }
                },
                
                # PostgreSQL Bar (SQL ready)
                {
                    "id": 3,
                    "gridPos": {"h": 12, "w": 24, "x": 0, "y": 12},
                    "title": "Orders by Category (SQL)",
                    "type": "barchart",
                    "targets": [{
                        "rawSql": "SELECT category, COUNT(*) as orders FROM orders GROUP BY category",
                        "datasource": {"type": "postgres", "uid": "-- Mixed --"},
                        "format": "table",
                        "refId": "A"
                    }],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "short",
                            "color": {"mode": "palette-desaturate"}
                        }
                    }
                }
            ],
            "time": {"from": "now-24h", "to": "now"},
            "timepicker": {}
        },
        "folder": 0,
        "overwrite": True
    }

def deploy_dashboard(grafana_url: str = "http://localhost:3000"):
    """Deploy to Grafana"""
    dashboard = generate_bar_pie_dashboard()
    
    headers = {
        "Authorization": "Basic YWRtaW46YWRtaW4=",
        "Content-Type": "application/json"
    }
    
    response = requests.post(
        f"{grafana_url}/api/dashboards/db",
        headers=headers,
        json=dashboard
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ LIVE: {grafana_url}{result['url']}")
        return result['url']
    else:
        print(f"❌ {response.status_code}: {response.text}")
        return None

def main():
    dashboard = generate_bar_pie_dashboard()
    
    # Save JSON
    with open("bar-pie-dashboard.json", "w") as f:
        json.dump(dashboard, f, indent=2)
    print("✅ Saved: bar-pie-dashboard.json")
    
    # Deploy
    url = deploy_dashboard()
    if url:
        print(f"\n📊 Open: http://localhost:3000{dashboard['dashboard']['uid']}/{dashboard['dashboard']['uid']}")

if __name__ == "__main__":
    main()