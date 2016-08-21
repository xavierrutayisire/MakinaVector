from django.conf import settings
from django.template import loader, TemplateDoesNotExist
from django.http import HttpResponse

# Return the multiple style file
def multiple_style(request):
    context = locals()
    context['dbname'] = settings.DATABASE_NAME
    context['utilery_host'] = settings.UTILERY_HOST
    context['utilery_port'] = settings.UTILERY_PORT

    # Load the template
    try:
        template = loader.get_template('map/multiple-style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    # Response
    return HttpResponse(template.render(context, request))
