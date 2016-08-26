from django.conf import settings
from django.contrib.gis.geos import GEOSGeometry
from django.http import HttpResponse
from http.client import HTTPConnection
from jsonmerge import Merger
import psycopg2
import ujson
import yaml
import os


def save_geoJSON(file_geojson, layer_name):
    """
    Save geoJSON file
    """
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


def load_style():
    """
    Load the original style file
    """
    style_file = open(settings.STYLE_DIR).read()
    style_data = ujson.loads(style_file)

    return style_data


def check_layer_exist_style(layer_name, style_data):
    """
    Chek if layer exist in initial style
    """
    layer_exist = False

    for layer in style_data['layers']:
        try:
            if layer_name == layer['source-layer']:
                layer_exist = True
                break
        except KeyError:
            pass

    return layer_exist


def decode_geoJSON(path_geojson):
    """
    Decode geojson file
    """
    with open(path_geojson) as file_stream:
        geometry_data = ujson.load(file_stream)

    return geometry_data


def database_connection():
    """
    Database connection
    """
    conn = psycopg2.connect(host=settings.DATABASE_HOST,
                            database=settings.DATABASE_NAME,
                            user=settings.DATABASE_USER,
                            password=settings.DATABASE_PASSWORD)
    cursor = conn.cursor()

    return conn, cursor


def add_geometry_database(table_name, geometry_data, cursor, conn):
    """
    Add the geometry into the database
    """
    # Create table if not exist for the layer
    cursor.execute("""CREATE TABLE IF NOT EXISTS {0} (id serial PRIMARY KEY,
                      geometry geometry(Geometry,3857) NOT NULL,
                      geometry_type varchar(40) NOT NULL)""".format(table_name))

    # Add geometry and geometry type of the geojson into the database
    for feature in range(len(geometry_data['features'])):
        geometry = geometry_data['features'][feature]['geometry']
        geometry_type = geometry['type']

        # Convert geojson into geometry
        geojson = GEOSGeometry(str(geometry), srid=4326)
        geojson.transform(3857)
        geom = geojson.hex.decode()

        # Add the geometry into the table if the geometry doesn't already exist
        cursor.execute("""INSERT INTO {0}(geometry, geometry_type)
                          SELECT ST_SetSRID(\'{1}\'::geometry, 3857) AS geometry,
                                 \'{2}\' AS geometry_typ
                          WHERE NOT EXISTS
                              (SELECT geometry
                               FROM {0}
                               WHERE geometry = ST_SetSRID(\'{1}\'::geometry, 3857))
                       """.format(table_name, geom, geometry_type))

    # Save changes
    conn.commit()


def load_multiple_style():
    """
    Load the original multiple style file
    """
    multiple_style_json_data = open(settings.MULTIPLE_STYLE_DIR).read()
    multiple_style_data = ujson.loads(multiple_style_json_data)

    return multiple_style_data


def check_layer_exist_multiple_style(layer_name, multiple_style_data):
    """
    Check if the style of this layer already exist in the multiple style file
    """
    style_already_exist = False

    # Check if style already exist for this layer
    for source_layer in range(len(multiple_style_data['layers'])):
        try:
            if multiple_style_data['layers'][source_layer]['source-layer'] == layer_name:
                style_already_exist = True
                break
        except KeyError:
            pass

    return style_already_exist


def load_new_style(layer_name):
    """
    Load the new style file
    """
    new_style = open(settings.NEW_STYLE_DIR).read()
    new_style = new_style.replace("{ layer_name }", layer_name)
    new_style_data = ujson.loads(new_style)

    return new_style_data


def create_new_style(multiple_style_data, new_style_data, multiple_style_state):
    """
    Create the new style with the new layer
    """
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
    if multiple_style_state:
        multiple_style_data = repr(multiple_style_data).replace("True", "true")
    else:
        multiple_style_data = repr(multiple_style_data).replace("False", "true")

    remove_char = "'"

    for char in remove_char:
        multiple_style_data = repr(multiple_style_data).replace(char, '"')

    multiple_style_json = ujson.loads(multiple_style_data[1:-1])

    # Create the new multiple style file
    with open(settings.MULTIPLE_STYLE_DIR, "w") as new_style_file:
        new_style_file.write(ujson.dumps(multiple_style_json, indent=4))


def load_queries():
    """
    Load the queries file
    """
    queries_yml_file = open(settings.QUERIES_DIR).read()
    queries_yml = yaml.load(queries_yml_file)

    return queries_yml, queries_yml_file


def check_query_exist(layer_name, queries_yml):
    """
    Check if the query of this layer exist in original queries files
    """
    query_exist = False

    # Check if the querie exist
    for layer in queries_yml['layers']:
        if layer['name'] == layer_name:
            query_exist = True
            break

    return query_exist


def load_new_query(layer_name, table_name):
    """
    Load the new query
    """
    new_query = open(settings.NEW_QUERY_DIR).read()
    new_query = new_query.replace("{ layer_name }", layer_name)
    new_query = new_query.replace("{ table_name }", table_name)

    return new_query


def create_new_queries(queries_yml, new_query, queries_yml_file):
    """
    Create the new queries with the new layer
    """
    # Change the orginal queries file
    old_queries_yml = queries_yml
    del old_queries_yml['srid']

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
    queries_yml_old = yaml.load(queries_yml_file)
    old_queries_file_yml = queries_yml_old
    old_queries_file_yml['layers'] = new_queries_yml['layers']

    # Create the new queries file with the old and the new query
    with open(settings.QUERIES_DIR, "w") as queries_file:
        queries_file.write(yaml.dump(old_queries_file_yml, default_flow_style=False))


def ban_varnish_tiles(layer_name):
    """
    Ban all the tiles of this layer
    """
    connHTTP = HTTPConnection(settings.VARNISH_HOST + ':' + str(settings.VARNISH_PORT))
    connHTTP.request("BAN", "/" + layer_name + "/")


def add_layer(request):
    """
    Add a layer into the database, create a new style and querie
    """
    # Get the layer_name from the form
    layer_name = request.POST['layerNameAdd']

    # Set the table name of the layer
    table_name = 'extra_' + layer_name

    # geoJSON
    file_geojson = request.FILES['fileGeoJSON']
    path_geojson = save_geoJSON(file_geojson, layer_name)

    # Style
    style_data = load_style()
    layer_exist = check_layer_exist_style(layer_name, style_data)

    if layer_exist is False:
        geometry_data = decode_geoJSON(path_geojson)

        # Database
        conn, cursor = database_connection()
        add_geometry_database(table_name, geometry_data, cursor, conn)

        # Multiple style
        multiple_style_data = load_multiple_style()
        style_already_exist = check_layer_exist_multiple_style(layer_name, multiple_style_data)

        if style_already_exist is False:
            # New style
            new_style_data = load_new_style(layer_name)
            multiple_style_state = multiple_style_data['multiple_style']
            create_new_style(multiple_style_data, new_style_data, multiple_style_state)

        # Queries
        queries_yml, queries_yml_file = load_queries()
        query_exist = check_query_exist(layer_name, queries_yml)

        if query_exist is False:
            # New query
            new_query = load_new_query(layer_name, table_name)
            create_new_queries(queries_yml, new_query, queries_yml_file)

        # Varnish
        ban_varnish_tiles(layer_name)

        # Utilery
        os.system('/bin/systemctl restart utilery.service')

        # Response if add was done
        return HttpResponse(status=200)
    else:
        # Response if you try to add a layer from initial map
        return HttpResponse(status=202)
