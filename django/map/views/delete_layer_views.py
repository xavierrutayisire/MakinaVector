from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse
from http.client import HTTPConnection
import psycopg2, ujson, yaml, os


def database_connection():
    """
    Database connection
    """
    conn = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, password=settings.DATABASE_PASSWORD)
    cursor = conn.cursor()

    return conn, cursor


def check_table_exist(table_name, cursor):
    """
    Check if the table exist
    """
    cursor.execute("SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = \'{0}\')".format(table_name))
    table_exist = cursor.fetchall()
    table_exist = table_exist[0][0]

    return table_exist


def drop_table(table_name, cursor, conn):
    """
    Drop the table
    """
    cursor.execute("DROP TABLE {0}".format(table_name))
    conn.commit()


def load_queries():
    """
    Load the queries file
    """
    queries_yml_file = open(settings.QUERIES_DIR).read()
    queries_yml = yaml.load(queries_yml_file)

    return queries_yml


def check_query_exist(layer_name, queries_yml):
    """
    Check if the query exist
    """
    query_exist = 0

    for layer in queries_yml['layers']:
        if layer['name'] == layer_name:
            query_exist = 1

    return query_exist


def remove_query(queries_yml, layer_name):
    """
    Remove query
    """
    new_layers = [layer for layer in queries_yml['layers'] if layer['name'] != layer_name]
    queries_yml['layers'] = new_layers

    # Create the new queries file without the layer querie
    with open(settings.QUERIES_DIR, "w") as new_queries_file:
        new_queries_file.write(yaml.dump((queries_yml)))


def load_multiple_style():
    """
    Load the multiple style file
    """
    multiple_style_file = open(settings.MULTIPLE_STYLE_DIR).read()
    multiple_style_json = ujson.loads(multiple_style_file)

    return multiple_style_json
 
def check_layer_exist_multiple_style(layer_name, multiple_style_json):
    """
    Check if the layer style exist in the multiple style file
    """
    style_exist = 0

    for layer in multiple_style_json['layers']:
        try:
          if layer['source-layer'] == layer_name:
              style_exist = 1
        except:
          pass

    return style_exist


def create_new_multiple_style(layer_name, multiple_style_json):
    """
    Remove the layers of the multiple style file
    """
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


def ban_varnish_tiles(layer_name):
    """
    Ban all the tiles of this layer
    """
    connHTTP = HTTPConnection(settings.UTILERY_HOST + ':' + str(settings.UTILERY_PORT))
    connHTTP.request("BAN", "/" + layer_name + "/")
    resp = connHTTP.getresponse()

    return resp


def delete_layer(request):
    """
    Delete a layer from the database, his style and querie
    """
    # Get the layer name
    layer_name = request.POST['layerNameDel']

    # Set the table name
    table_name = 'extra_' + layer_name

    # Database
    conn, cursor = database_connection()
    table_exist = check_table_exist(table_name,cursor)

    # Remove layer from database and delete his style and querie if table exist
    if table_exist == True:
        drop_table(table_name, cursor, conn)

        # Queries
        queries_yml = load_queries()
        query_exist = check_query_exist(layer_name, queries_yml)

        if query_exist == 1:
            remove_query(queries_yml, layer_name)

        # Style
        multiple_style_json = load_multiple_style()
        style_exist = check_layer_exist_multiple_style(layer_name, multiple_style_json)

        if style_exist == 1:
            create_new_multiple_style(layer_name, multiple_style_json)

        # Varnish
        resp = ban_varnish_tiles(layer_name)

        # Utilery
        os.system('/bin/systemctl restart utilery.service')

        # Response if delete was done
        return HttpResponse(status=200)
    else:
        # Response if the table doesn't exist
        return HttpResponse(status=202)
