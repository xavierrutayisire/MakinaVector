from django.template import loader, TemplateDoesNotExist
from django.contrib.gis.geos import GEOSGeometry
from django.core.urlresolvers import resolve
from django.http import HttpResponse
from shutil import move, copyfile
from jsonmerge import Merger
import psycopg2
import ujson
import yaml
import io
import os

## Variables ##

# Django
django_host = '127.0.0.1'
django_port = 8080
title_of_index = 'Map'

# Mapbox
mapboxAccessToken = 'pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'
startingZoom = 14
startingPosition = '[-6.3316, 53.3478]'

# Database
database_name = 'imposm3_db_ir'
database_host = '127.0.0.1'
database_user = 'imposm3_user_ir'
database_password = 'makina'

# Utilery
utilery_host = '127.0.0.1' 
utilery_port = 3579

# Tiles
tiles_host = '127.0.0.1'
tiles_port = 8001

# Directory
queries_dir = '/srv/projects/vectortiles/project/osm-ireland/utilery/queries.yml'
new_querie_dir = '/srv/projects/vectortiles/project/osm-ireland/utilery/new-querie.yml'
style_dir = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/style.json'
multiple_style_dir = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/multiple-style.json'
new_style_dir = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/new-style.json'
upload_dir = 'upload/'

# Render the index page
def index(request):
    context = locals()
    context['django_host'] = django_host
    context['django_port'] = django_port
    context['title'] = title_of_index
    context['database'] = database_name
    context['mapboxAccessToken'] = mapboxAccessToken
    context['startingZoom'] = startingZoom
    context['startingPosition'] = startingPosition

    # Get all the layer name
    style_file = open(style_dir).read()
    style_json = ujson.loads(style_file)
    context['list_item'] = []

    for layer in style_json['layers']:
        try:
            layer_already_exist = 0
            for context_layer in context['list_item']:
                if context_layer == layer['source-layer']:
                    layer_already_exist = 1
            if layer_already_exist == 0:
                context['list_item'].append(layer['source-layer'])
        except:
            pass

    multiple_style_file = open(multiple_style_dir).read()
    multiple_style_json = ujson.loads(multiple_style_file)

    for layer in multiple_style_json['layers']:
        try:
            layer_already_exist = 0
            for context_layer in context['list_item']:
                if context_layer == layer['source-layer']:
                    layer_already_exist = 1
            if layer_already_exist == 0:
                context['list_item'].append(layer['source-layer'])
        except:
            pass

    # Load the template
    try:
        template = loader.get_template('map/index.html')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))

# Return the style file
def style(request):
    context = locals()
    context['tiles_host'] = tiles_host
    context['tiles_port'] = tiles_port
    context['dbname'] = database_name

    # Load the template
    try:
        template = loader.get_template('map/style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))

# Return the multiple style file
def multiple_style(request):
    context = locals()
    context['tiles_host'] = tiles_host
    context['tiles_port']  = tiles_port
    context['dbname'] = database_name
    context['utilery_host'] = utilery_host
    context['utilery_port'] = utilery_port

    # Load the template
    try:
        template = loader.get_template('map/multiple-style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))

# Add a layer into the database, create a new style and querie
def add_layer(request):
    # Get the layer_name from the form
    layer_name = request.POST['layerNameAdd']

    ## GEOJSON FILE ##

    # Get the geojson file
    file_geojson = request.FILES['fileGeoJSON']
    path_geojson = upload_dir + 'geojson-' + layer_name + '-0.json'
    nb_file = 0

    # Set the path of the file depending of the number of same file in the upload folder
    for root, dirs, files in os.walk(upload_dir):
        for file in files:
            if os.path.isfile(upload_dir + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'):
                nb_file += 1
                path_geojson = upload_dir + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'

    # Save the geojson file
    destination_geojson = open(path_geojson, 'wb+')

    for chunk in file_geojson.chunks():
        destination_geojson.write(chunk)
    destination_geojson.close()

    ## DATABASE ##

    # Add the geometry into the database
    table_name = 'custom_' + layer_name

    # Decode geojson file
    with open(path_geojson) as file_stream: 
        geometry_data = ujson.load(file_stream)

    # Database connexion
    conn = psycopg2.connect(host=database_host, database=database_name, user=database_user, password=database_password)
    cursor = conn.cursor()

    # Create table if not exist for the layer
    cursor.execute("CREATE TABLE IF NOT EXISTS %s (id serial PRIMARY KEY, geometry geometry(Geometry,3857) NOT NULL, geometry_type varchar(40) NOT NULL)" % (table_name))

    # Add geometry and geometry type of the geojson into the database
    for feature in range(len(geometry_data['features'])):
        geometry = geometry_data['features'][feature]['geometry']
        geometry_type = geometry['type']

        # Convert geojson into geometry
        geojson = GEOSGeometry(str(geometry), srid=4326)
        geojson.transform(3857)
        geom = geojson.hex.decode()

        # Add the geometry into the table if the geometry doesn't already exist
        cursor.execute(
        'INSERT INTO %s(geometry, geometry_type)'
        'SELECT ST_SetSRID(\'%s\'::geometry, 3857) as geometry, \'%s\' as geometry_type '
        'WHERE NOT EXISTS (SELECT geometry FROM %s WHERE geometry = ST_SetSRID(\'%s\'::geometry, 3857))' % (table_name, geom, geometry_type, table_name, geom))

    conn.commit()

    ## STYLE ##

    # Load the original multiple style file
    original_style_json_data = open(multiple_style_dir).read()
    original_style_data = ujson.loads(original_style_json_data)
    style_already_exist = 0

    # Check if style already exist for this layer
    for source_layer in range(len(original_style_data['layers'])):
        try:
            if original_style_data['layers'][source_layer]['source-layer'] == layer_name:
                style_already_exist = 1
                break
        except:
            pass

    # Create the new style for the new layer
    if style_already_exist == 0:
        # Load the new style
        new_style = open(new_style_dir).read()
        new_style = new_style.replace("{ layer_name }", layer_name)
        style_data = ujson.loads(new_style)

        # Merge the sources of the original style with the new style into the 
        schema_sources = {
                   "properties": {
                       "sources": {
                          "mergeStrategy": "append"
                      }
                  }
               }
        merger = Merger(schema_sources)
        sources = merger.merge(style_data['sources'], original_style_data['sources'])
        original_style_data['sources'] = sources

        # Add the layers of the new style into the original style
        for i in range(len(style_data['layers'])):
            original_style_data['layers'].append(style_data['layers'][i])

        # Clean the json file
        original_style_data = repr(original_style_data).replace("True", "true")
        remove_char = "'"

        for char in remove_char:
            original_style_data = repr(original_style_data).replace(char,'"')

        # Create the new multiple style file
        with open(multiple_style_dir, "w") as new_style_file:
            new_style_file.write(original_style_data[1:-1])

    ## QUERIE ##

    # Create a new querie for the layer
    if layer_name not in open(queries_dir).read():
        # Load the new querie
        new_queries = open(new_querie_dir).read()
        new_queries = new_queries.replace("{ layer_name }", layer_name)
        new_queries = new_queries.replace("{ table_name }", table_name)

        # Load the old queries file
        old_queries_file = open(queries_dir).read()
        old_queries_yml = yaml.load(old_queries_file)
        del old_queries_yml['srid']

        # Create the queries file without the sird
        with open(queries_dir, "w") as queries_file:
            queries_file.write(yaml.dump(old_queries_yml))

        # Add the querie into the queries.yml file
        with open(queries_dir, "a+") as queries_file:
            queries_file.write(new_queries)

        # Load the file with the new querie in it
        new_queries_file = open(queries_dir).read()
        new_queries_yml = yaml.load(new_queries_file)

        # Add the queries of the new queries file into the old one
        old_queries_file_yml = yaml.load(old_queries_file)
        old_queries_file_yml['layers'] = new_queries_yml['layers']

        # Create the new queries file with the old and the new queries
        with open(queries_dir, "w") as queries_file:
            queries_file.write(yaml.dump(old_queries_file_yml))
    
    # Response
    return HttpResponse(status=200)

# Delete a layer from the database, his style and querie
def delete_layer(request):
    # Get the layer name
    layer_name = request.POST['layerNameDel']

    ## DATABASE ##

    # Database connexion
    conn = psycopg2.connect(host=database_host, database=database_name, user=database_user, password=database_password)
    cursor = conn.cursor()

    # Check the table exist
    table_name = 'custom_' + layer_name
    cursor.execute("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = \'%s\')" % (table_name))
    table_exist = cursor.fetchall()
    table_exist = table_exist[0][0]

    # Remove layer from database and delete his style and querie if table exist
    if table_exist == True:
        # Drop the table if exist
        cursor.execute("DROP TABLE %s" % (table_name))
        conn.commit()

        ## QUERIE ##

        # Load the queries file
        queries_yml_file = open(queries_dir).read()
        queries_yml = yaml.load(queries_yml_file)
        querie_exist = 0

        # Check if the querie exist
        for layer in queries_yml['layers']:
            if layer['name'] == layer_name:
                querie_exist = 1

        # Remove querie if exist and table exist
        if querie_exist == 1:
            new_layers = [layer for layer in queries_yml['layers'] if layer['name'] != layer_name]
            queries_yml['layers'] = new_layers

            # Create the new queries file without the layer querie
            with open(queries_dir, "w") as new_queries_file:
                new_queries_file.write(yaml.dump((queries_yml)))

        ## STYLE ##

        # Load the multiple style file
        multiple_style_file = open(multiple_style_dir).read()
        multiple_style_json = ujson.loads(multiple_style_file)
        style_exist = 0

        # Check if the layer style exist
        for layer in multiple_style_json['layers']:
            try:
              if layer['source-layer'] == layer_name:
                  style_exist = 1
            except:
              pass

        # Remove the style if exist
        if style_exist == 1:
            new_multiple_style_layers = []

            # Remove the layers of the style 
            for layer in multiple_style_json['layers']:
                try:
                  if layer['source-layer'] != layer_name:
                      new_multiple_style_layers.append(layer)
                except:
                  new_multiple_style_layers.append(layer)
                  pass

            multiple_style_json['layers'] = new_multiple_style_layers

            # Remove the source of the style 
            new_multiple_style_sources = {name: source for name, source in multiple_style_json['sources'].items() if name != '{{ dbname }}_' + layer_name}
            multiple_style_json['sources'] = new_multiple_style_sources

            # Clean the new style
            multiple_style_json = repr(multiple_style_json).replace("'", '"')
            multiple_style_json = repr(multiple_style_json).replace("True", "true")

            # Create a new multiple style file without the old styles
            with open(multiple_style_dir, "w") as new_multiple_style_file:
                new_multiple_style_file.write(multiple_style_json[1:-1])

        # Response if delete was done
        return HttpResponse(status=200)
    else:
        # Response if the table doesn't exist
        return HttpResponse(status=202)
