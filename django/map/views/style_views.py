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
        except:
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


def style(request):
    """
    Return the style file
    """
    context = locals()
    context['dbname'] = settings.DATABASE_NAME
    context['varnish_host'] = settings.VARNISH_HOST
    context['varnish_port'] = settings.VARNISH_PORT
    context['names'] = get_names()
    # Load the template
    try:
        template = loader.get_template('map/style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))
