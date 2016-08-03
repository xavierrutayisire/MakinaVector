#!/usr/bin/python
import psycopg2
import sys

conn = psycopg2.connect(host=sys.argv[3], database=sys.argv[2], user=sys.argv[0], password=sys.argv[1])
cursor = conn.cursor()
cursor.execute("DELETE FROM diff WHERE processed = true")
conn.commit()
