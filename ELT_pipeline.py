"""
Database Setup and CSV Loader

Automates creation of the Fecom Inc. e-commerce database, loads CSV datasets,
applies normalization, and logs progress. Connects to PostgreSQL and handles
missing files gracefully.

Usage:
1. Update DB_CONFIG with your PostgreSQL connection parameters;
2. Adjust paths to CSV and SQL files before running;
3. Run the script with Python 3.
"""
import psycopg2
from pathlib import Path

# ----------------------------
# Database connection settings
# ----------------------------
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'dbname': 'your_database_name',              
    'user': 'your_username',
    'password': 'your_password'
}

# ----------------------------
# Paths to CSV and SQL files
# ----------------------------
DATA_DIR = Path("path_to_your_dataset")
SQL_FILE = Path("path_to_your_sql/create_DB.sql")
NORMALIZATION_SQL = Path("path_to_your_sql/database_normalization.sql")

CSV_FILES = {
    'geolocations': DATA_DIR / 'Fecom Inc Geolocations.csv',
    'customer_list': DATA_DIR / 'Fecom Inc Customer List.csv',
    'products': DATA_DIR / 'Fecom Inc Products.csv',
    'sellers_list': DATA_DIR / 'Fecom Inc Sellers List.csv',
    'orders': DATA_DIR / 'Fecom Inc Orders.csv',
    'order_items': DATA_DIR / 'Fecom Inc Order Items.csv',
    'order_payments': DATA_DIR / 'Fecom Inc Order Payments.csv',
    'order_reviews': DATA_DIR / 'Fecom_Inc_Order_Reviews_No_Emojis.csv'
}

# ----------------------------
# Functions
# ----------------------------
def execute_sql_file(cursor, file_path):
    sql_text = file_path.read_text(encoding='utf-8')
    cursor.execute(sql_text)

def load_csv(cursor, table_name, file_path, delimiter=';'):
    sql = f"COPY {table_name} FROM STDIN WITH CSV HEADER DELIMITER '{delimiter}' NULL '';"
    with open(file_path, 'r', encoding='utf-8') as f:
        cursor.copy_expert(sql, f)

# ----------------------------
# Main process
# ----------------------------
def main():
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        conn.autocommit = True

        print("Creating tables...")
        execute_sql_file(cursor, SQL_FILE)

        print("Loading CSV files...")
        for table, file in CSV_FILES.items():
            if file.exists():
                print(f"Loading {table} from {file}")
                load_csv(cursor, table, file)
            else:
                print(f"File not found: {file}")

        # ----------------------------
        # Database normalization
        # ----------------------------
        if NORMALIZATION_SQL.exists():
            print("Running database normalization...")
            execute_sql_file(cursor, NORMALIZATION_SQL)
            print("Normalization done.")
        else:
            print(f"Normalization SQL file not found: {NORMALIZATION_SQL}")

        print("All done!")

    except Exception as e:
        print("Error:", e)

    finally:
        if conn:
            conn.close()

# ----------------------------
# Run
# ----------------------------
if __name__ == "__main__":
    main()
