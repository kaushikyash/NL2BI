import copy
import json
import re
from pathlib import Path
from typing import Any, Dict, List


DASHBOARD_OUTPUT_DIR = Path(r"C:\Projects\NL2BI\dash_json")


TEMPLATE_JSON = {
    "annotations": {
        "list": [
            {
                "builtIn": 1,
                "datasource": {
                    "type": "grafana",
                    "uid": "-- Grafana --"
                },
                "enable": True,
                "hide": True,
                "iconColor": "rgba(0, 211, 255, 1)",
                "name": "Annotations & Alerts",
                "type": "dashboard"
            }
        ]
    },
    "editable": True,
    "fiscalYearStartMonth": 0,
    "graphTooltip": 0,
    "links": [],
    "panels": [
        {
            "datasource": {
                "type": "grafana-clickhouse-datasource",
                "uid": "bffhe9vw4r0n4f"
            },
            "fieldConfig": {
                "defaults": {
                    "color": {
                        "mode": "palette-classic"
                    },
                    "custom": {
                        "hideFrom": {
                            "legend": False,
                            "tooltip": False,
                            "viz": False
                        }
                    },
                    "mappings": [],
                    "min": 0,
                    "unit": "percent"
                },
                "overrides": []
            },
            "gridPos": {
                "h": 12,
                "w": 12,
                "x": 12,
                "y": 0
            },
            "id": 2,
            "options": {
                "legend": {
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": True
                },
                "pieType": "pie",
                "reduceOptions": {
                    "calcs": [
                        "lastNotNull"
                    ],
                    "fields": "",
                    "values": False
                },
                "sort": "desc",
                "tooltip": {
                    "hideZeros": False,
                    "mode": "single",
                    "sort": "none"
                }
            },
            "pluginVersion": "12.4.0",
            "targets": [
                {
                    "editorType": "sql",
                    "expr": "40",
                    "format": 1,
                    "legendFormat": "Electronics",
                    "meta": {
                        "builderOptions": {
                            "columns": [],
                            "database": "",
                            "limit": 1000,
                            "mode": "list",
                            "queryType": "table",
                            "table": ""
                        }
                    },
                    "pluginVersion": "4.14.0",
                    "queryType": "table",
                    "rawSql": "sELECT 1, sum(shipped_quantity) AS total_units FROM fact_shipment",
                    "refId": "A"
                },
                {
                    "expr": "35",
                    "legendFormat": "Clothing",
                    "refId": "B"
                },
                {
                    "expr": "25",
                    "legendFormat": "Books",
                    "refId": "C"
                }
            ],
            "title": "Market Share",
            "type": "piechart"
        },
        {
            "datasource": {
                "type": "grafana-clickhouse-datasource",
                "uid": "bffhe9vw4r0n4f"
            },
            "fieldConfig": {
                "defaults": {
                    "color": {
                        "mode": "palette-desaturate"
                    },
                    "custom": {
                        "axisBorderShow": False,
                        "axisCenteredZero": False,
                        "axisColorMode": "text",
                        "axisLabel": "",
                        "axisPlacement": "auto",
                        "fillOpacity": 80,
                        "gradientMode": "none",
                        "hideFrom": {
                            "legend": False,
                            "tooltip": False,
                            "viz": False
                        },
                        "lineWidth": 1,
                        "scaleDistribution": {
                            "type": "linear"
                        },
                        "thresholdsStyle": {
                            "mode": "off"
                        }
                    },
                    "mappings": [],
                    "thresholds": {
                        "mode": "absolute",
                        "steps": [
                            {
                                "color": "green",
                                "value": 0
                            },
                            {
                                "color": "red",
                                "value": 80
                            }
                        ]
                    },
                    "unit": "short"
                },
                "overrides": []
            },
            "gridPos": {
                "h": 12,
                "w": 24,
                "x": 0,
                "y": 12
            },
            "id": 3,
            "options": {
                "barRadius": 0,
                "barWidth": 0.97,
                "fullHighlight": False,
                "groupWidth": 0.7,
                "legend": {
                    "calcs": [],
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": True
                },
                "orientation": "auto",
                "showValue": "auto",
                "stacking": "none",
                "tooltip": {
                    "hideZeros": False,
                    "mode": "single",
                    "sort": "none"
                },
                "xTickLabelRotation": 0,
                "xTickLabelSpacing": 0
            },
            "pluginVersion": "12.4.0",
            "targets": [
                {
                    "datasource": {
                        "type": "grafana-clickhouse-datasource",
                        "uid": "bffhe9vw4r0n4f"
                    },
                    "editorType": "sql",
                    "format": 1,
                    "meta": {
                        "builderOptions": {
                            "columns": [],
                            "database": "",
                            "limit": 1000,
                            "mode": "list",
                            "queryType": "table",
                            "table": ""
                        }
                    },
                    "pluginVersion": "4.14.0",
                    "queryType": "table",
                    "rawSql": "sELECT '2026-03-09',SUM(shipped_quantity) AS total_units FROM fact_shipment",
                    "refId": "A"
                }
            ],
            "title": "Orders by Category (SQL)",
            "type": "barchart"
        }
    ],
    "preload": False,
    "refresh": "5s",
    "schemaVersion": 42,
    "tags": [
        "bar",
        "pie",
        "analytics"
    ],
    "templating": {
        "list": []
    },
    "time": {
        "from": "now-24h",
        "to": "now"
    },
    "timepicker": {},
    "timezone": "browser",
    "title": "Sales Analytics",
    "uid": "sales-analytics",
    "version": 4,
    "weekStart": ""
}


def clean_target_for_sql(target: Dict[str, Any], sql: str, ref_id: str = "A") -> Dict[str, Any]:
    cleaned = copy.deepcopy(target)
    cleaned["editorType"] = "sql"
    cleaned["format"] = 1
    cleaned["queryType"] = "table"
    cleaned["rawSql"] = sql
    cleaned["query"] = sql
    cleaned["refId"] = ref_id
    cleaned.pop("expr", None)
    cleaned.pop("legendFormat", None)

    if "meta" not in cleaned:
        cleaned["meta"] = {
            "builderOptions": {
                "columns": [],
                "database": "",
                "limit": 1000,
                "mode": "list",
                "queryType": "table",
                "table": ""
            }
        }

    return cleaned


def create_panel_from_template(
    base_panel: Dict[str, Any],
    sql: str,
    title: str,
    panel_id: int,
    panel_type: str,
    unit: str,
    x: int,
    y: int,
    w: int = 12,
    h: int = 10
) -> Dict[str, Any]:
    panel = copy.deepcopy(base_panel)
    panel["id"] = panel_id
    panel["title"] = title
    panel["type"] = panel_type
    panel["gridPos"] = {"h": h, "w": w, "x": x, "y": y}

    if "fieldConfig" in panel and "defaults" in panel["fieldConfig"]:
        panel["fieldConfig"]["defaults"]["unit"] = unit

    first_target = panel["targets"][0]
    panel["targets"] = [clean_target_for_sql(first_target, sql, ref_id="A")]

    if "datasource" in panel and "datasource" not in panel["targets"][0]:
        panel["targets"][0]["datasource"] = copy.deepcopy(panel["datasource"])

    if panel_type != "piechart" and "options" in panel and "pieType" in panel["options"]:
        panel["options"].pop("pieType", None)

    return panel


def build_dashboard_from_queries(
    template_dashboard: Dict[str, Any],
    queries: List[Dict[str, Any]],
    dashboard_title: str = "Generated Dashboard",
    dashboard_uid: str = "generated-dashboard"
) -> Dict[str, Any]:
    dashboard = copy.deepcopy(template_dashboard)
    base_panel = dashboard["panels"][1] if len(dashboard["panels"]) > 1 else dashboard["panels"][0]

    new_panels = []
    col_width = 12
    panel_height = 10

    for i, q in enumerate(queries):
        row = i // 2
        col = i % 2
        x = col * col_width
        y = row * panel_height

        panel = create_panel_from_template(
            base_panel=base_panel,
            sql=q["sql"],
            title=q["title"],
            panel_id=i + 1,
            panel_type=q.get("panel_type", "barchart"),
            unit=q.get("unit", "short"),
            x=x,
            y=y,
            w=col_width,
            h=panel_height
        )
        new_panels.append(panel)

    dashboard["title"] = dashboard_title
    dashboard["uid"] = dashboard_uid
    dashboard["panels"] = new_panels
    dashboard["version"] = 1
    return dashboard


def build_dashboard_for_query(
    sql: str,
    title: str,
    panel_type: str = "barchart",
    unit: str = "short",
    dashboard_title: str = "Generated Dashboard",
    dashboard_uid: str = "generated-dashboard",
    template_dashboard: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    print(
        "[generate_py_dash] build_dashboard_for_query",
        {
            "title": title,
            "panel_type": panel_type,
            "unit": unit,
            "dashboard_title": dashboard_title,
            "dashboard_uid": dashboard_uid,
        },
    )
    template = template_dashboard or TEMPLATE_JSON
    dashboard_json = build_dashboard_from_queries(
        template_dashboard=template,
        queries=[
            {
                "sql": sql,
                "title": title,
                "panel_type": panel_type,
                "unit": unit,
            }
        ],
        dashboard_title=dashboard_title,
        dashboard_uid=dashboard_uid,
    )
    print(
        "[generate_py_dash] dashboard json created",
        {
            "title": dashboard_json.get("title"),
            "uid": dashboard_json.get("uid"),
            "panel_count": len(dashboard_json.get("panels", [])),
        },
    )
    return dashboard_json


def save_dashboard_payload(dashboard_payload: Dict[str, Any], output_dir: Path = DASHBOARD_OUTPUT_DIR) -> Path:
    title = dashboard_payload.get("title") or dashboard_payload.get("uid") or "generated-dashboard"
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", title).strip("-").lower() or "generated-dashboard"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{slug}.json"
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(dashboard_payload["json"], f, indent=2)
    print("[generate_py_dash] dashboard json saved", {"path": str(output_path)})
    return output_path


if __name__ == "__main__":
    queries = [
        {
            "title": "Total Units Sold",
            "sql": "SELECT SUM(shipped_quantity) AS total_units FROM fact_shipment",
            "panel_type": "stat",
            "unit": "short"
        }
    ]
    dashboard_json = build_dashboard_from_queries(
        template_dashboard=TEMPLATE_JSON,
        queries=queries,
        dashboard_title="Auto Generated Sales Dashboard",
        dashboard_uid="auto-generated-sales-dashboard"
    )
    with open("generated_dashboard.json", "w", encoding="utf-8") as f:
        json.dump(dashboard_json, f, indent=2)
    print("generated_dashboard.json created successfully")
