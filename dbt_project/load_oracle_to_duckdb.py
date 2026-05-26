#!/usr/bin/env python3
"""
Load data from Oracle database to DuckDB for dbt transformation.
This script extracts tables from Oracle TESTUSER schema and loads them into DuckDB.

Run from dbt-mcp container:
  docker exec -it dbt-mcp python3 /dbt_project/load_oracle_to_duckdb.py
"""

import os
import duckdb
import oracledb

# Oracle connection
ORACLE_USER = os.getenv("ORACLE_USER", "testuser")
ORACLE_PASSWORD = os.getenv("ORACLE_PASSWORD", "TestPassword123")
ORACLE_DSN = "oracle-db:1521/FREE"
ORACLE_SCHEMA = os.getenv("ORACLE_SCHEMA", "TESTUSER").lower()

# DuckDB connection
DUCKDB_PATH = os.getenv("DUCKDB_PATH", "/data/oracle_lineage.duckdb")

# Tables to extract
TABLES = ["customers", "products", "orders", "order_items"]

def main():
    print("=" * 60)
    print("Oracle → DuckDB Data Loader")
    print("=" * 60)

    print(f"\nOracle DSN: {ORACLE_DSN}")
    print(f"DuckDB Path: {DUCKDB_PATH}")
    print(f"Tables: {', '.join(TABLES)}")

    print("\n[1/3] Connecting to Oracle...")
    try:
        oracle_conn = oracledb.connect(
            user=ORACLE_USER,
            password=ORACLE_PASSWORD,
            dsn=ORACLE_DSN
        )
        print("✓ Oracle connection successful")
    except Exception as e:
        print(f"✗ Oracle connection failed: {e}")
        return

    print("\n[2/3] Connecting to DuckDB...")
    try:
        duck_conn = duckdb.connect(DUCKDB_PATH)
        print("✓ DuckDB connection successful")
    except Exception as e:
        print(f"✗ DuckDB connection failed: {e}")
        oracle_conn.close()
        return

    # Create schema in DuckDB
    print("\n[3/3] Loading tables...")
    duck_conn.execute(f"CREATE SCHEMA IF NOT EXISTS {ORACLE_SCHEMA}")

    for table in TABLES:
        print(f"\n  → {table.upper()}")

        try:
            # Read from Oracle
            oracle_cursor = oracle_conn.cursor()
            oracle_cursor.execute(f"SELECT * FROM {table.upper()}")

            # Get column names (convert to lowercase for DuckDB)
            columns = [desc[0].lower() for desc in oracle_cursor.description]
            rows = oracle_cursor.fetchall()

            print(f"    • Extracted {len(rows)} rows from Oracle")

            # Drop existing table in DuckDB
            duck_conn.execute(f"DROP TABLE IF EXISTS {ORACLE_SCHEMA}.{table}")

            if rows:
                # Register as DataFrame for easier insertion
                import pandas as pd
                df = pd.DataFrame(rows, columns=columns)

                # Create table in DuckDB
                duck_conn.execute(f"CREATE TABLE {ORACLE_SCHEMA}.{table} AS SELECT * FROM df")

                print(f"    • Loaded into DuckDB {ORACLE_SCHEMA}.{table}")
            else:
                print(f"    • No data found, skipping")

        except Exception as e:
            print(f"    ✗ Error loading {table}: {e}")

    oracle_conn.close()
    duck_conn.close()

    print("\n" + "=" * 60)
    print("✓ Data load complete!")
    print("=" * 60)
    print(f"\nDuckDB database: {DUCKDB_PATH}")
    print("\nNext steps:")
    print("  1. Run: docker exec -it dbt-mcp dbt run")
    print("  2. Query: docker exec -it duckdb duckdb {DUCKDB_PATH}")
    print()

if __name__ == "__main__":
    main()
