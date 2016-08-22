from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse
import ujson


def load_style():
    """
    Load the style file
    """
    style_file = open(settings.STYLE_DIR).read()
    style_json = ujson.loads(style_file)
    
    return style_json


def add_layer_style(style_json, list_item):
    """
    Add all the layers present in the style file
    """
    for layer in style_json['layers']:
    try:
        layer_already_exist = False
        for context_layer in list_item:
            if context_layer == layer['source-layer']:
                layer_already_exist = True
        if layer_already_exist is False:
            list_item.append(layer['source-layer'])
    except:
        pass


def load_multiple_style():
    """
    Load the multiple style file
    """
    multiple_style_file = open(settings.MULTIPLE_STYLE_DIR).read()
    multiple_style_json = ujson.loads(multiple_style_file)
    
    return multiple_style_json
    
    
def add_layer_multiple_style(multiple_style_json, list_item):
    """
    Add all the layers present in the multiple style file
    """
    for layer in multiple_style_json['layers']:
        try:
            layer_already_exist = False
            for context_layer in list_item:
                if context_layer == layer['source-layer']:
                    layer_already_exist = True
            if layer_already_exist is False:
                list_item.append(layer['source-layer'])
        except:
            pass
    
    return list_item


def get_layers_Names():
    """
    Get all the layers names
    """
    list_item = []
    
    # Style
    style_json = load_style()
    list_item = add_layer_style(style_json, list_item)
    
    # Multiple style
    multiple_style_json = load_multiple_style()
    list_item = add_layer_multiple_style(multiple_style_json, list_item)
    
    return list_item

def index(request):
    """
    Render the index page
    """
    context = locals()
    context['django_host'] = settings.DJANGO_HOST
    context['django_port'] = settings.DJANGO_PORT
    context['title'] = settings.TITLE_OF_INDEX
    context['database'] = settings.DATABASE_NAME
    context['mapboxAccessToken'] = settings.MAPBOX_ACCESS_TOKEN
    context['startingZoom'] = settings.STARTING_ZOOM
    context['startingPosition'] = settings.STARTING_POSITION
    context['list_item'] = get_layers_Names()

    # Load the template
    try:
        template = loader.get_template('map/index.html')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))
