
from flask import Blueprint, jsonify
from psycopg.rows import dict_row

api = Blueprint("api", __name__)


def register_api(get_db_connection):

    @api.get("/customers")
    def customers():
        with get_db_connection() as conn:
            with conn.cursor(row_factory=dict_row) as cursor:
                cursor.execute("SELECT * FROM customers LIMIT 10")
                rows = cursor.fetchall()
        return jsonify(rows)

    @api.get("/products")
    def products():
        with get_db_connection() as conn:
            with conn.cursor(row_factory=dict_row) as cursor:
                cursor.execute("SELECT * FROM products LIMIT 10")
                rows = cursor.fetchall()
        return jsonify(rows)

    @api.get("/orders")
    def orders():
        with get_db_connection() as conn:
            with conn.cursor(row_factory=dict_row) as cursor:
                cursor.execute("SELECT * FROM orders LIMIT 10")
                rows = cursor.fetchall()
        return jsonify(rows)

    return api
