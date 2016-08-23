#!/usr/bin/python
import psycopg2
import sys


def database_connection():
    """
    Database connection
    """
    conn = psycopg2.connect(host=sys.argv[4],
                            database=sys.argv[3],
                            user=sys.argv[1],
                            password=sys.argv[2])
    cursor = conn.cursor()

    return conn, cursor


def request(cursor):
    """
    Execute the request to clean diff table
    """
    cursor.execute("DELETE FROM diff WHERE processed = true")


def commit(conn):
    """
    Save changes
    """
    conn.commit()


def clean_diff():
    """
    Clean the diff table
    """
    conn, cursor = database_connection()
    request(cursor)
    commit(conn)

clean_diff()
