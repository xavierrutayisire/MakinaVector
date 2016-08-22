from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse


def style(request):
    """
    Return the style file
    """
    context = locals()
    context['utilery_host'] = settings.UTILERY_HOST
    context['utilery_port'] = settings.UTILERY_PORT
    context['dbname'] = settings.DATABASE_NAME

    # Load the template
    try:
        template = loader.get_template('map/style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))
