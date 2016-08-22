from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse
from http.client import HTTPConnection
import psycopg2, ujson, yaml, os

# Database connection
def database_connection():
    conn = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, password=settings.DATABASE_PASSWORD)
    cursor = conn.cursor()

    return conn, cursor

# Check if the table exist
def check_table_exist(table_name, cursor):
    cursor.execute("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = \'%s\')" % (table_name))
    table_exist = cursor.fetchall()
    table_exist = table_exist[0][0]

    return table_exist

# Drop the table
def drop_table(table_name, cursor, conn):
    cursor.execute("DROP TABLE %s" % (table_name))
    conn.commit()

# Load the queries file
def load_queries():
    queries_yml_file = open(settings.QUERIES_DIR).read()
    queries_yml = yaml.load(queries_yml_file)

    return queries_yml

# Check if the query exist
def check_query_exist(layer_name, queries_yml):
    query_exist = 0

    for layer in queries_yml['layers']:
        if layer['name'] == layer_name:
            query_exist = 1

    return query_exist

# Remove query
def remove_query(queries_yml, layer_name):
    new_layers = [layer for layer in queries_yml['layers'] if layer['name'] != layer_name]
    queries_yml['layers'] = new_layers

    # Create the new queries file without the layer querie
    with open(settings.QUERIES_DIR, "w") as new_queries_file:
        new_queries_file.write(yaml.dump((queries_yml)))

# Load the multiple style file
def load_multiple_style():
    multiple_style_file = open(settings.MULTIPLE_STYLE_DIR).read()
    multiple_style_json = ujson.loads(multiple_style_file)

    return multiple_style_json

# Check if the layer style exist in the multiple style file
def check_layer_exist_multiple_style(layer_name, multiple_style_json):
    style_exist = 0

    for layer in multiple_style_json['layers']:
        try:
          if layer['source-layer'] == layer_name:
              style_exist = 1
        except:
          pass

    return style_exist

# Remove the layers of the multiple style file
def create_new_multiple_style(layer_name, multiple_style_json):
    new_multiple_style_layers = []

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
    with open(settings.MULTIPLE_STYLE_DIR, "w") as new_multiple_style_file:
        new_multiple_style_file.write(multiple_style_json[1:-1])

# Ban all the tiles of this layer
def ban_varnish_tiles(layer_name):
    connHTTP = HTTPConnection(settings.UTILERY_HOST + ':' + str(settings.UTILERY_PORT))
    connHTTP.request("BAN", "/" + layer_name + "/")
    resp = connHTTP.getresponse()

    return resp

# Delete a layer from the database, his style and querie
def delete_layer(request):
    # Get the layer name
    layer_name = request.POST['layerNameDel']

    # Set the table name
    table_name = 'extra_' + layer_name

    # Database connection
    conn, cursor = database_connection()

    # Check if the table exist
    table_exist = check_table_exist(table_name,cursor)

    # Remove layer from database and delete his style and querie if table exist
    if table_exist == True:
        # Drop the table
        drop_table(table_name, cursor, conn)

        # Load the queries file
        queries_yml = load_queries()

        # Check if the query exist
        query_exist = check_query_exist(layer_name, queries_yml)

        # If query exist
        if query_exist == 1:
            # Remove query
            remove_query(queries_yml, layer_name)

        # Load the multiple style file
        multiple_style_json = load_multiple_style()

        # Check if the layer style exist
        style_exist = check_layer_exist_multiple_style(layer_name, multiple_style_json)

        # If style exist
        if style_exist == 1:
            # Remove the layers of the multiple style file
            create_new_multiple_style(layer_name, multiple_style_json)

        # Ban all the tiles of this layer
        resp = ban_varnish_tiles(layer_name)

        # Restart utilery to load the change of the queries file
        os.system('/bin/systemctl restart utilery.service')

        # Response if delete was done
        return HttpResponse(status=200)
    else:
        # Response if the table doesn't exist
        return HttpResponse(status=202)
