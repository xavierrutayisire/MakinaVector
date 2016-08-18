# SETUP USER

minzoom = 0
maxzoom = 14
west = -11.1133787
south = 51.122
east = -5.5582362
north = 55.736
host = '127.0.0.1'
port = 6081

# END SETUP USER

import mercantile
import subprocess
from multiprocessing import cpu_count
from subprocess import Popen 
import os

procs = []
directory_generation = '/dev/null'

if not os.path.exists("%s" % (directory_generation)):
		os.makedirs("%s" % (directory_generation))

for zoom in range(minzoom, maxzoom + 1):
	if not os.path.exists("%s/%s" % (directory_generation, zoom)):
		os.makedirs("%s/%s" % (directory_generation, zoom))
	west_south_tile = mercantile.tile(west, south, zoom)
	east_north_tile = mercantile.tile(east, north, zoom)
	for x in range(west_south_tile.x, east_north_tile.x + 1):
		if not os.path.exists("%s/%s/%s" % (directory_generation, zoom, x)):
			os.makedirs("%s/%s/%s" % (directory_generation, zoom, x))
		for y in range(east_north_tile.y, west_south_tile.y + 1):
			print(zoom, x, y)
			filename = "%s/%s/%s" % (directory_generation, zoom, x)
			if not os.path.isfile(filename):
				url = "http://%s:%s/default/all/%s/%s/%s.pbf" % (host, port, zoom, x, y)
				procs.append(subprocess.Popen(['wget', url, '-P', filename, '-q']))
				if len(procs) > (cpu_count() * 4):
					procs[0].wait()
					procs.remove(procs[0]) 
