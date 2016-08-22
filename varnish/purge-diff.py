#!/usr/bin/python
import mercantile
import psycopg2
import sys
import ujson
import os

# Database connection
conn = psycopg2.connect(host=sys.argv[4], database=sys.argv[3], user=sys.argv[1], password=sys.argv[2])
cursor = conn.cursor()

# Request to get all the diff not processed
cursor.execute("SELECT * FROM diff where processed = false")
records = cursor.fetchall()

tiles_generate = []

for record in records:
    # Request to the geometry
    to_generate = conn.cursor()
    to_generate.execute("SELECT ST_AsGeoJSON(ST_Transform(geometry, 4326), 15, 1) as geojson FROM diff where id = {0}".format(record[0]))
    point = to_generate.fetchall()
    bbox = ujson.loads(point[0][0])

    # Zoom
    minzoom = int(sys.argv[5])
    maxzoom = int(sys.argv[6])

    # Zone
    west = bbox["bbox"][0]
    south = bbox["bbox"][1]
    east = bbox["bbox"][2]
    north = bbox["bbox"][3]

    # Utilery host (by varnish)
    host = sys.argv[7]
    port = sys.argv[8]

    for zoom in range(minzoom, maxzoom + 1):
        west_south_tile = mercantile.tile(west, south, zoom)
        east_north_tile = mercantile.tile(east, north, zoom)
        for x in range(west_south_tile.x, east_north_tile.x + 1):
            for y in range(east_north_tile.y, west_south_tile.y + 1):
                tile_already_generate = 0
                url = "http://{0}:{1}/all/{2}/{3}/{4}.pbf".format(host, port, zoom, x, y)
                for tile in tiles_generate:
                    if(tile == url):
                        tile_already_generate = 1
                        break
                if(tile_already_generate == 0):
                    print(zoom, x, y)
                    tiles_generate.append(url)
                    os.system('curl -s -X PURGE {0} > /dev/null 2>&1'.format(url))

    # Set the diff as processed
    update_diff = conn.cursor()
    update_diff.execute("UPDATE diff SET processed = true WHERE id = {0}".format(record[0]))

# Save the change
conn.commit()
