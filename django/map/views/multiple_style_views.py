from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse


def multiple_style(request):
    """
    Return the multiple style file
    """
    context = locals()
    context['dbname'] = settings.DATABASE_NAME
    context['varnish_host'] = settings.VARNISH_HOST
    context['varnish_port'] = settings.VARNISH_PORT

    # Load the template
    try:
        template = loader.get_template('map/multiple-style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))
