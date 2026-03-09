#!/usr/bin/env python3
"""
Generate minimal working Grafana dashboard JSON
"""
import json
import requests
from typing import Optional

def generate_basic_dashboard(title: str = "Basic Dashboard") -> dict:
    """
    Generate minimal VALID Grafana dashboard JSON
    """
    return {
        "dashboard": {
            "id": None,
            "uid": title.lower().replace(" ", "-"),
            "title": title,
            "tags": ["generated", "basic"],
            "timezone": "browser",
            "schemaVersion": 38,
            "version": 0,
            "refresh": "30s",
            "panels": [
                {
                    "id": 1,
                    "gridPos": {"h": 9, "w": 12, "x": 0, "y": 0},
                    "title": "Static Metric",
                    "type": "stat",
                    "targets": [{"expr": "100", "refId": "A"}],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "short",
                            "color": {"mode": "fixed", "fixedColor": "green"},
                            "thresholds": {
                                "steps": [{"color": "green", "value": None}]
                            },
                            "min": 0
                        }
                    }
                },
                {
                    "id": 2,
                    "gridPos": {"h": 9, "w": 12, "x": 12, "y": 0},
                    "title": "Uptime",
                    "type": "stat",
                    "targets": [{"expr": "up", "refId": "A"}],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "percent",
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "steps": [
                                    {"color": "red", "value": 0},
                                    {"color": "yellow", "value": 0.5},
                                    {"color": "green", "value": 1}
                                ]
                            }
                        }
                    }
                },
                {
                    "id": 3,
                    "gridPos": {"h": 9, "w": 24, "x": 0, "y": 9},
                    "title": "Time Range",
                    "type": "bargauge",
                    "targets": [{"expr": "time()", "refId": "A"}],
                    "fieldConfig": {
                        "defaults": {
                            "unit": "dateTimeAsIso",
                            "color": {"mode": "palette-classic"}
                        }
                    }
                }
            ],
            "time": {
                "from": "now-6h",
                "to": "now"
            },
            "timepicker": {
                "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h"]
            },
            "templating": {
                "list": []
            },
            "annotations": {
                "list": []
            }
        },
        "folder": 0,
        "overwrite": True,
        "provisioning": "python-generated"
    }

def save_dashboard(filename: str, dashboard: dict):
    """Save to JSON file"""
    with open(filename, 'w') as f:
        json.dump(dashboard, f, indent=2)
    print(f"✅ Saved: {filename}")

def deploy_dashboard(grafana_url: str = "http://localhost:3000", 
                    username: str = "admin", 
                    password: str = "admin") -> Optional[dict]:
    """
    Deploy directly to Grafana API
    """
    dashboard = generate_basic_dashboard()
    
    auth = f"{username}:{password}"
    import base64
    b64auth = base64.b64encode(auth.encode()).decode()
    
    headers = {
        "Authorization": f"Basic {b64auth}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            f"{grafana_url}/api/dashboards/db",
            headers=headers,
            json=dashboard
        )
        response.raise_for_status()
        result = response.json()
        print(f"✅ Deployed: {result['url']}")
        print(f"  Title: {result['title']}")
        print(f"  UID: {result['uid']}")
        return result
    except Exception as e:
        print(f"❌ Deploy failed: {e}")
        return None

def main():
    """Generate + deploy"""
    dashboard = generate_basic_dashboard("Python Generated Dashboard")
    
    # Option 1: Save file
    save_dashboard("basic-dashboard.json", dashboard)
    
    # Option 2: Deploy to Grafana
    print("\nDeploying to localhost:3000...")
    deploy_dashboard()
    
    print("\n✅ Done! Check:")
    print("  File: basic-dashboard.json")
    print("  URL: http://localhost:3000/d/python-generated-dashboard/python-generated-dashboard")

if __name__ == "__main__":
    main()
