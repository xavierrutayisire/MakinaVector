from django.http import HttpResponse
from django.template import loader, TemplateDoesNotExist
from django.contrib.gis.geos import LineString, Point, Polygon, GEOSGeometry
import json
import os
import psycopg2
import mercantile
import subprocess
from multiprocessing import cpu_count
from subprocess import Popen
import io
from tempfile import mkstemp
from shutil import move
from os import remove, close
from shutil import copyfile
from django.core.urlresolvers import resolve
from jsonmerge import Merger
import yaml

def index(request):
    context = locals()
    context['django_host'] = '127.0.0.1'
    context['django_port'] = 8080
    context['title'] = 'Map'
    context['database'] = 'imposm3_db_ir'
    context['mapboxAccessToken'] = 'pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'
    context['startingZoom'] = '14'
    context['startingPosition'] = '[-6.3316, 53.3478]'

    with open('/srv/projects/vectortiles/project/osm-ireland/utilery/queries.yml', 'r') as queries_yml_file:
        queries_yml = yaml.load(queries_yml_file)

    context['list_item'] = []
    for layer in queries_yml['layers']:
        if layer['name'] != 'mountain_peak_label':
            context['list_item'].append(layer['name'])

    try:
        template = loader.get_template('map/index.html')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    return HttpResponse(template.render(context, request))

def style(request):
    context = locals()
    context['tiles_host'] = '127.0.0.1'
    context['tiles_port']  = 8001
    context['dbname'] = 'imposm3_db_ir'

    try:
        template = loader.get_template('map/style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    return HttpResponse(template.render(context, request))

def multiple_style(request):
    context = locals()
    context['tiles_host'] = '127.0.0.1'
    context['tiles_port']  = 8001
    context['dbname'] = 'imposm3_db_ir'
    context['utilery_host'] = '127.0.0.1'
    context['utilery_port'] = 3579

    try:
        template = loader.get_template('map/multiple-style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    return HttpResponse(template.render(context, request))

def upload(request):
    dir_upload = 'upload/'
    layer_name = request.POST['layerName']

    """
    Geometry (geojson file)
    """
    file_geojson = request.FILES['fileGeoJSON']
    path_geojson = dir_upload + 'geojson-' + layer_name + '-0.json'

    nb_file = 0
    for root, dirs, files in os.walk(dir_upload):
        for file in files:
            if os.path.isfile(dir_upload + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'):
                nb_file += 1
                path_geojson = dir_upload + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'


    destination_geojson = open(path_geojson, 'wb+')

    for chunk in file_geojson.chunks():
        destination_geojson.write(chunk)
        destination_geojson.close()

    """
    Add the geometry into the database
    """
    # psycopg2 variables
    host = '127.0.0.1'
    database = 'imposm3_db_ir'
    user = 'imposm3_user_ir'
    password = 'makina'

    # Read geojson file
    geojson_data = open(path_geojson).read()
    geometry_data = json.loads(geojson_data)

    # Database connexion
    conn = psycopg2.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    # Table for the layer
    cursor.execute("CREATE TABLE IF NOT EXISTS %s (id serial PRIMARY KEY, geometry geometry(Geometry,3857) NOT NULL, geometry_type varchar(40) NOT NULL)" % (layer_name))

    # For all geometry in my geojson
    for feature in range(len(geometry_data['features'])):
        geometry = geometry_data['features'][feature]['geometry']
        geometry_type = geometry['type']

        # Convert geojson into geometry
        geojson = GEOSGeometry(str(geometry), srid=4326)
        geojson.transform(3857)
        geom = geojson.hex.decode()

        # Add the geometry into the table
        cursor.execute(
        'INSERT INTO %s(geometry, geometry_type)'
        'SELECT ST_SetSRID(\'%s\'::geometry, 3857) as geometry, \'%s\' as geometry_type '
        'WHERE NOT EXISTS (SELECT geometry FROM %s WHERE geometry = ST_SetSRID(\'%s\'::geometry, 3857))' % (layer_name, geom, geometry_type, layer_name, geom))

    conn.commit()

    """
    Create a simple style for the new layer
    """
    original_style_dir = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/multiple-style.json'

    original_style_json_data = open(original_style_dir).read()
    original_style_data = json.loads(original_style_json_data)

    style_already_exist = 0
    for source_layer in range(len(original_style_data['layers'])):
        try:
            if original_style_data['layers'][source_layer]['source-layer'] == layer_name:
                style_already_exist = 1
                break
        except:
            pass

    if style_already_exist == 0:
        new_style = """{
            "sources": {
                "{{ dbname }}_{ layer_name }": {
                    "type": "vector",
                    "tiles": [
                        "http://{{ utilery_host }}:{{ utilery_port }}/{ layer_name }/{z}/{x}/{y}.pbf"
                    ],
                    "maxzoom": 14,
                    "minzoom": 0
                }
            },
            "layers": [{
        		"id": "{ layer_name }-line",
        		"type": "line",
        		"source": "{{ dbname }}_{ layer_name }",
        		"source-layer": "{ layer_name }",
                "layout": {
                    "line-join": "round",
                    "line-cap": "round"
                },
                "filter": ["==", "geometry_type", "LineString"],
                "paint": {
                    "line-color": "#877b59",
                    "line-width": 1
                },
                "before": "housenum-label"
        	}, {
        		"id": "{ layer_name }-polygon",
        		"type": "fill",
        		"source": "{{ dbname }}_{ layer_name }",
        		"source-layer": "{ layer_name }",
                "layout": {},
                "filter": ["==", "geometry_type", "Polygon"],
                "paint": {
                    "fill-color": "#877b59"
                },
                "before": "housenum-label"
    	    }, {
        		"id": "{ layer_name }-point",
        		"type": "circle",
        		"source": "{{ dbname }}_{ layer_name }",
        		"source-layer": "{ layer_name }",
                "layout": {},
                "filter": ["==", "geometry_type", "Point"],
                "paint": {
                    "circle-radius": 8,
                    "circle-color": "rgba(55,148,179,1)"
                },
                "before": "housenum-label"
    	    }]
        }
        """

        new_style = new_style.replace("{ layer_name }", layer_name)
        style_data = json.loads(new_style)

        schema_sources = {
                   "properties": {
                       "sources": {
                          "mergeStrategy": "append"
                      }
                  }
               }

        merger = Merger(schema_sources)
        sources = merger.merge(style_data['sources'], original_style_data['sources'])

        for i in range(len(style_data['layers'])):
            original_style_data['layers'].append(style_data['layers'][i])

        original_style_data['sources'] = sources

        remove_char = "'"
        for char in remove_char:
            original_style_data = repr(original_style_data).replace(char,'"')

        original_style_data = repr(original_style_data).replace("True", "true")

        os.remove(original_style_dir)
        with open(original_style_dir, "a+") as new_style_file:
            new_style_file.write(original_style_data[1:-1])

    """
    Add the querie into the queries.yml file
    """
    queries_dir = '/srv/projects/vectortiles/project/osm-ireland/utilery/queries.yml'

    if layer_name not in open(queries_dir).read():
        new_queries = """- name: { layer_name }
  buffer: 4
  queries:
    - minzoom: 0
      maxzoom: 14
      sql: |-
        SELECT
            id AS osm_id, geometry AS way, geometry_type
        FROM
            { layer_name }
        WHERE
            geometry && !bbox!
        """

        new_queries = new_queries.replace("{ layer_name }", layer_name)

        with open(queries_dir, "a") as queries_file:
            queries_file.write(new_queries)

    return HttpResponse(status=200)
