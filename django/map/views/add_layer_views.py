from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.contrib.gis.geos import GEOSGeometry
from django.http import HttpResponse
from http.client import HTTPConnection
from jsonmerge import Merger
import psycopg2, ujson, yaml, os

# Save geoJSON file
def save_geoJSON(file_geojson, layer_name):
    path_geojson = settings.UPLOAD_DIR + 'geojson-' + layer_name + '-0.json'
    nb_file = 0

    # Set the path of the file depending of the number of same file in the upload folder
    for root, dirs, files in os.walk(settings.UPLOAD_DIR):
        for file in files:
            if os.path.isfile(settings.UPLOAD_DIR + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'):
                nb_file += 1
                path_geojson = settings.UPLOAD_DIR + 'geojson-' + layer_name + '-' + str(nb_file) + '.json'

    # Save the geojson file
    destination_geojson = open(path_geojson, 'wb+')

    for chunk in file_geojson.chunks():
        destination_geojson.write(chunk)
    destination_geojson.close()

    return path_geojson

# Load the original style file
def load_style():
    style_file = open(settings.STYLE_DIR).read()
    style_data = ujson.loads(style_file)

    return style_data

# Chek if layer exist in initial style
def layer_exist_style(layer_name, style_data):
    layer_exist = 0

    for layer in style_data['layers']:
        try:
            if layer_name == layer['source-layer']:
                layer_exist = 1
        except:
            pass

    return layer_exist

# Decode geojson file
def decode_geoJSON(path_geojson):
    with open(path_geojson) as file_stream:
        geometry_data = ujson.load(file_stream)

    return geometry_data

# Database connection
def database_connection():
    conn = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, password=settings.DATABASE_PASSWORD)
    cursor = conn.cursor()

    return conn, cursor

# Add the geometry into the database
def add_geometry_database(layer_name, geometry_data, cursor, conn):
    table_name = 'custom_' + layer_name

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

    # Save changes
    conn.commit()

# Load the original multiple style file
def load_multiple_style():
    multiple_style_json_data = open(settings.MULTIPLE_STYLE_DIR).read()
    multiple_style_data = ujson.loads(multiple_style_json_data)

    return multiple_style_data

# Check if the style of this layer already exist in the multiple style file
def layer_exist_multiple_style(layer_name, multiple_style_data):
    style_already_exist = 0

    # Check if style already exist for this layer
    for source_layer in range(len(multiple_style_data['layers'])):
        try:
            if multiple_style_data['layers'][source_layer]['source-layer'] == layer_name:
                style_already_exist = 1
                break
        except:
            pass

    return style_already_exist

# Load the new style file
def load_new_style(layer_name):
    new_style = open(settings.NEW_STYLE_DIR).read()
    new_style = new_style.replace("{ layer_name }", layer_name)
    new_style_data = ujson.loads(new_style)

    return new_style_data

# Create the new style with the new layer
def create_new_style(multiple_style_data, new_style_data):
    # Merge the sources of the original style with the new style into the
    schema_sources = {
               "properties": {
                   "sources": {
                      "mergeStrategy": "append"
                  }
              }
           }
    merger = Merger(schema_sources)
    sources = merger.merge(new_style_data['sources'], multiple_style_data['sources'])
    multiple_style_data['sources'] = sources

    # Add the layers of the new style into the original style
    for i in range(len(new_style_data['layers'])):
        multiple_style_data['layers'].append(new_style_data['layers'][i])

    # Clean the json file
    multiple_style_data = repr(multiple_style_data).replace("True", "true")
    remove_char = "'"

    for char in remove_char:
        multiple_style_data = repr(multiple_style_data).replace(char,'"')

    # Create the new multiple style file
    with open(settings.MULTIPLE_STYLE_DIR, "w") as new_style_file:
        new_style_file.write(multiple_style_data[1:-1])

# Load the queries file
def load_queries():
    queries_yml_file = open(settings.QUERIES_DIR).read()
    queries_yml = yaml.load(queries_yml_file)

    return queries_yml

# Check if the query of this layer exist in original queries files
def query_exist(layer_name, queries_yml):
    query_exist = 0

    # Check if the querie exist
    for layer in queries_yml['layers']:
        if layer['name'] == layer_name:
            query_exist = 1

    return query_exist

# Load the new querie
def load_new_query(layer_name):
    # Load the new query
    new_query = open(settings.NEW_QUERY_DIR).read()
    new_query = new_queries.replace("{ layer_name }", layer_name)
    new_query = new_queries.replace("{ table_name }", table_name)

    return new_query

# Create the new queries with the new layer
def create_new_queries(queries_yml, new_query):
    # Change the orginal queries file
    old_queries_yml = del queries_yml['srid']

    # Create the queries file without the sird
    with open(settings.QUERIES_DIR, "w") as queries_file:
        queries_file.write(yaml.dump(old_queries_yml))

    # Add the query into the queries.yml file
    with open(settings.QUERIES_DIR, "a+") as queries_file:
        queries_file.write(new_query)

    # Load the file with the new query in it
    new_queries_file = open(settings.QUERIES_DIR).read()
    new_queries_yml = yaml.load(new_queries_file)

    # Add the queries of the new queries file into the old one
    old_queries_file_yml = queries_yml
    old_queries_file_yml['layers'] = new_queries_yml['layers']

    # Create the new queries file with the old and the new query
    with open(settings.QUERIES_DIR, "w") as queries_file:
        queries_file.write(yaml.dump(old_queries_file_yml))

# Ban all the tiles of this layer
def ban_varnish_tiles(layer_name):
    conn = HTTPConnection(settings.UTILERY_HOST + ':' + str(settings.UTILERY_PORT))
    conn.request("BAN", "/" + layer_name + "/")
    resp = conn.getresponse()

    return resp

# Add a layer into the database, create a new style and querie
def add_layer(request):
    # Get the layer_name from the form
    layer_name = request.POST['layerNameAdd']

    # Get the geojson file
    file_geojson = request.FILES['fileGeoJSON']

    # Save geoJSON file
    path_geojson = save_geoJSON(file_geojson, layer_name)

    # Load the original style file
    style_data = load_style()

    # Chek if layer exist in initial style
    layer_exist = layer_exist_style(layer_name, style_data)

    # Only if layer is not in initial map
    if layer_exist == 0:
        # Decode geojson file
        geometry_data = decode_geoJSON(path_geojson)

        # Database connection
        conn, cursor = database_connection()

        # Add the geometry into the database
        add_geometry_database(layer_name, geometry_data, cursor, conn)

        # Load the original multiple style file
        multiple_style_data = load_multiple_style()

        # Check if the style of this layer already exist in the multiple style file
        style_already_exist = layer_exist_multiple_style(layer_name, multiple_style_data)

        # if style not exist
        if style_already_exist == 0:
            # Load the new style file
            new_style_data = load_new_style(layer_name)

            # Create the new style file with the new layer
            create_new_style(multiple_style_data, new_style_data)

        # Load the queries file
        queries_yml = load_queries()

        # Check if the querie of this layer exist in  original queries files
        query_exist = query_exist(layer_name, queries_yml)

        # if query not exist
        if querie_exist == 0:
            # Load the new query
            new_query = load_new_query(layer_name)

            # Create the new queries file with the new layer
            create_new_queries(queries_yml, new_query)

        # Ban all the tiles of this layer
        resp = ban_varnish_tiles(layer_name)

        # Restart utilery to load the change of the queries file
        os.system('/bin/systemctl restart utilery.service')

        # Response if add was done
        return HttpResponse(status=200)
    else:
        # Response if you try to add a layer from initial map
        return HttpResponse(status=202)
