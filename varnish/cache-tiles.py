#!/usr/bin/python
from multiprocessing import cpu_count
import mercantile
import subprocess
import ujson

# SETUP USER

# Zoom to cache
minzoom = 0
maxzoom = 14

# Delimited zone to cache
west = -11.1133787
south = 51.122
east = -5.5582362
north = 55.736

# Varnish connection
host = '127.0.0.1'
port = 6081

# Style 
style_dir = '/srv/projects/vectortiles/project/osm-ireland/django/composite/map/templates/map/style.json'

# END SETUP USER


def load_style():
    """
    Load the style file
    """
    style_file = open(style_dir).read()
    style_json = ujson.loads(style_file)

    return style_json


def get_layers_names(style_json):
    """
    Get all the names of layers present in the style file
    """
    list_names = []

    for layer in style_json['layers']:
        try:
            layer_already_exist = False
            for context_layer in list_names:
                if context_layer == layer['source-layer']:
                    layer_already_exist = True
            if layer_already_exist is False:
                list_names.append(layer['source-layer'])
        except KeyError:
            pass

    return list_names


def get_names():
    """
    Create a string with all the names of layers
    """
    style_json = load_style()
    list_names = get_layers_names(style_json)

    names = ""

    for name in list_names:
        if name == list_names[len(list_names) - 1]:
            names += name
        else:
            names += name + "+"

    return names



def cache_tiles():
    """
    Cache all tiles in the delimited zone
    """
    names = get_names()

    # Variable to prevent stack overflow
    procs = []

    for zoom in range(minzoom, maxzoom + 1):
        west_south_tile = mercantile.tile(west, south, zoom)
        east_north_tile = mercantile.tile(east, north, zoom)
        for x in range(west_south_tile.x, east_north_tile.x + 1):
            for y in range(east_north_tile.y, west_south_tile.y + 1):
                print(zoom, x, y)
                url = "http://{0}:{1}/{2}/{3}/{4}/{5}.pbf".format(host, port, names, zoom, x, y)
                procs.append(subprocess.Popen(['wget', '-q', url, '-O', '/dev/null']))
                # To prevent stack overflow
                if len(procs) > (cpu_count() * 4):
                    procs[0].wait()
                    procs.remove(procs[0])

cache_tiles()
