
import os
from pathlib import Path

import psycopg
from flask import Flask, jsonify

from api import register_api

app = Flask(__name__)


def load_environment():
    """Load optional local environment file.

    Existing environment variables take precedence.
    AWS deployments can supply configuration securely
    without requiring a .env file.
    """
    env_file = Path(__file__).parent / ".env"

    if not env_file.exists():
        return

    for line in env_file.read_text().splitlines():
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        key, separator, value = line.partition("=")

        if separator:
            value = value.strip()

            if (
                len(value) >= 2
                and value[0] == value[-1]
                and value[0] in ("'", '"')
            ):
                value = value[1:-1]

            os.environ.setdefault(key.strip(), value)


load_environment()


def get_db_connection():
    connection_options = {
        "host": os.environ["DB_HOST"],
        "port": int(os.getenv("DB_PORT", "5432")),
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "connect_timeout": 5,
        "sslmode": os.getenv("DB_SSLMODE", "verify-full"),
        "options": "-c default_transaction_read_only=on",
    }

    if os.getenv("DB_SSLROOTCERT"):
        connection_options["sslrootcert"] = os.environ["DB_SSLROOTCERT"]

    return psycopg.connect(**connection_options)


app.register_blueprint(register_api(get_db_connection))


@app.get("/")
def home():
    return jsonify({
        "application": "Project 3 Hybrid Migration",
        "environment": os.getenv("APP_ENV", "on-premises"),
        "status": "running",
    })


@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": "migration-app",
    })


@app.get("/db-health")
def db_health():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT current_database(), 1")
                database, result = cursor.fetchone()

        return jsonify({
            "status": "healthy",
            "database": database,
            "connection": "successful",
            "query_result": result,
        })

    except psycopg.Error:
        app.logger.exception("Database health check failed")

        return jsonify({
            "status": "unhealthy",
            "database": "unavailable",
        }), 503


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
