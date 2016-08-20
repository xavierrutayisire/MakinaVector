# SETUP USER

# Zoom to cache
minzoom = 0
maxzoom = 14

# Delimited zone to cache
west = -11.1133787
south = 51.122
east = -5.5582362
north = 55.736

# Utilery connection (by Varnish)
host = '127.0.0.1'
port = 6081

# END SETUP USER

import mercantile
import subprocess
from multiprocessing import cpu_count
from subprocess import Popen 
import os

# Variable to prevent stack overflow
procs = []

# Cache all tiles in the delimited zone
for zoom in range(minzoom, maxzoom + 1):
	west_south_tile = mercantile.tile(west, south, zoom)
	east_north_tile = mercantile.tile(east, north, zoom)
	for x in range(west_south_tile.x, east_north_tile.x + 1):
		for y in range(east_north_tile.y, west_south_tile.y + 1):
			print(zoom, x, y)
			url = "http://%s:%s/all/%s/%s/%s.pbf" % (host, port, zoom, x, y)
			procs.append(subprocess.Popen(['curl', url, '>', '/dev/null', '2>&1']))
			# To prevent stack overflow
			if len(procs) > (cpu_count() * 4): 
				procs[0].wait()
				procs.remove(procs[0]) 
