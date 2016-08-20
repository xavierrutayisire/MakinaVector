#!/usr/bin/python
import psycopg2
import sys

# Database connection
conn = psycopg2.connect(host=sys.argv[4], database=sys.argv[3], user=sys.argv[1], password=sys.argv[2])
cursor = conn.cursor()

# Request
cursor.execute("DELETE FROM diff WHERE processed = true")
conn.commit()
