#!/usr/bin/python
import mercantile
import psycopg2
import sys
import pprint
import json
import subprocess
from multiprocessing import cpu_count
from subprocess import Popen
import os
from http.client import HTTPConnection

conn = psycopg2.connect(host=sys.argv[5], database=sys.argv[4], user=sys.argv[2], password=sys.argv[3])
cursor = conn.cursor()
cursor.execute("SELECT * FROM diff where processed = false")
records = cursor.fetchall()
tiles_generate = []

for record in records:
    to_generate = conn.cursor()
    to_generate.execute("SELECT ST_AsGeoJSON(ST_Transform(geometry, 4326), 15, 1) as geojson FROM diff where id = %s" % (record[0]))
    point = to_generate.fetchall()
    bbox = json.loads(point[0][0])

    minzoom = int(sys.argv[6])
    maxzoom = int(sys.argv[7])
    west = bbox["bbox"][0]
    south = bbox["bbox"][1]
    east = bbox["bbox"][2]
    north = bbox["bbox"][3]
    host = sys.argv[8]
    directory_generation = sys.argv[1]
    procs = []
    conn = HTTPConnection('127.0.0.1:6081') 

    for zoom in range(minzoom, maxzoom + 1):
        if not os.path.exists("%s/%s" % (directory_generation, zoom)):
            os.makedirs("%s/%s" % (directory_generation, zoom))
        west_south_tile = mercantile.tile(west, south, zoom)
        east_north_tile = mercantile.tile(east, north, zoom)
        for x in range(west_south_tile.x, east_north_tile.x + 1):
            if not os.path.exists("%s/%s/%s" % (directory_generation, zoom, x)):
                os.makedirs("%s/%s/%s" % (directory_generation, zoom, x))
            for y in range(east_north_tile.y, west_south_tile.y + 1):
                filename = "%s/%s/%s" % (directory_generation, zoom, x)
                tile_already_generate = 0
                if not os.path.isfile(filename):
                    url = "http://%s:3579/default/all/%s/%s/%s.pbf" % (host, zoom, x, y)
                    for tile in tiles_generate:
                        if(tile == '%s/%s/%s' % (zoom, x, y)):
                            tile_already_generate = 1
                            break
                    if(tile_already_generate == 0):
                        print(zoom, x, y)                 
                        tiles_generate.append('%s/%s/%s' % (zoom, x, y))
                        procs.append(conn.request("PURGE", "/all/" + zoom + "/" + x + "/" + y + ".pbf"))
                        if len(procs) > (cpu_count() * 4):
                            procs[0].wait()
                            procs.remove(procs[0])
    update_diff = conn.cursor()
    update_diff.execute("UPDATE diff SET processed = true WHERE id = %s" % (record[0]))

conn.commit()
