#!/usr/bin/env python3
"""
Export a ClickHouse database to a single SQL file containing:
- CREATE DATABASE
- CREATE TABLE / CREATE VIEW
- INSERT statements for table data

Designed for simple database cloning when you want one .sql file that can be
run later on another machine after ClickHouse is installed.

Example:
  python clickhouse_sql_dump.py \
      --host localhost \
      --port 8123 \
      --username default \
      --password "" \
      --database manufacturing_dw \
      --output manufacturing_dw_dump.sql
"""

from __future__ import annotations

import argparse
import datetime as dt
import decimal
from pathlib import Path
from typing import Any, Iterable, List

import clickhouse_connect


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Dump a ClickHouse database to SQL.")
    p.add_argument("--host", default="localhost")
    p.add_argument("--port", type=int, default=8123)
    p.add_argument("--username", default="default")
    p.add_argument("--password", default="")
    p.add_argument("--database", required=True)
    p.add_argument("--output", required=True, help="Output .sql file path")
    p.add_argument("--chunk-size", type=int, default=1000, help="Rows per INSERT statement")
    p.add_argument("--include-views", action="store_true", default=True)
    return p.parse_args()


def qident(name: str) -> str:
    return "`" + name.replace("`", "``") + "`"


def escape_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"

    if isinstance(value, bool):
        return "1" if value else "0"

    if isinstance(value, int):
        return str(value)

    if isinstance(value, float):
        if value != value:  # NaN
            return "nan"
        if value == float("inf"):
            return "inf"
        if value == float("-inf"):
            return "-inf"
        return repr(value)

    if isinstance(value, decimal.Decimal):
        return format(value, "f")

    if isinstance(value, dt.datetime):
        return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"

    if isinstance(value, dt.date):
        return f"'{value.isoformat()}'"

    if isinstance(value, str):
        return f"'{escape_string(value)}'"

    if isinstance(value, bytes):
        return f"'{escape_string(value.decode('utf-8', errors='replace'))}'"

    if isinstance(value, list):
        return "[" + ", ".join(sql_literal(v) for v in value) + "]"

    if isinstance(value, tuple):
        return "(" + ", ".join(sql_literal(v) for v in value) + ")"

    # Fallback
    return f"'{escape_string(str(value))}'"


def batched(rows: List[tuple], size: int) -> Iterable[List[tuple]]:
    for i in range(0, len(rows), size):
        yield rows[i : i + size]


def main() -> None:
    args = parse_args()

    client = clickhouse_connect.get_client(
        host=args.host,
        port=args.port,
        username=args.username,
        password=args.password,
        database=args.database,
    )

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    db = args.database

    objects = client.query(f"""
        SELECT
            name,
            engine
        FROM system.tables
        WHERE database = '{db}'
        ORDER BY
            case
                when engine = 'View' then 2
                else 1
            end,
            name
    """).result_rows

    with out_path.open("w", encoding="utf-8") as f:
        f.write("-- ClickHouse SQL dump\n")
        f.write(f"-- Database: {db}\n")
        f.write(f"-- Generated at: {dt.datetime.now().isoformat(sep=' ', timespec='seconds')}\n\n")

        create_db = client.command(f"SHOW CREATE DATABASE {qident(db)}")
        f.write(f"{create_db};\n\n")

        # DDL first
        for obj_name, engine in objects:
            if engine == "View" and not args.include_views:
                continue
            ddl = client.command(f"SHOW CREATE TABLE {qident(db)}.{qident(obj_name)}")
            f.write(f"{ddl};\n\n")

        # Data only for base tables
        for obj_name, engine in objects:
            if engine == "View":
                continue

            result = client.query(f"SELECT * FROM {qident(db)}.{qident(obj_name)}")
            columns = result.column_names
            rows = result.result_rows

            if not rows:
                continue

            col_list = ", ".join(qident(c) for c in columns)
            table_ref = f"{qident(db)}.{qident(obj_name)}"

            for block in batched(rows, args.chunk_size):
                values_sql = []
                for row in block:
                    row_sql = "(" + ", ".join(sql_literal(v) for v in row) + ")"
                    values_sql.append(row_sql)

                f.write(f"INSERT INTO {table_ref} ({col_list}) VALUES\n")
                f.write(",\n".join(values_sql))
                f.write(";\n\n")

    print(f"SQL dump written to: {out_path}")


if __name__ == "__main__":
    main()
