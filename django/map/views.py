from django.http import HttpResponse
from django.template import loader, TemplateDoesNotExist

def index(request):
    context = locals()
    context['django_host'] = '127.0.0.1'
    context['django_port'] = 8080
    context['title'] = 'Map'
    context['database'] = 'imposm3_db_ir'
    context['mapboxAccessToken'] = 'pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'
    context['startingZoom'] = '14'
    context['startingPosition'] = '[-6.3316, 53.3478]'
    template = loader.get_template('map/index.html')
    return HttpResponse(template.render(context, request))

def style(request):
    context = locals()
    context['tiles_host'] = '127.0.0.1'
    context['tiles_port']  = 8001
    context['dbname'] = 'imposm3_db_ir'
    template = loader.get_template('map/style.json')
    return HttpResponse(template.render(context, request))

def multiple_style(request):
    context = locals()
    context['tiles_host'] = '127.0.0.1'
    context['tiles_port']  = 8001
    context['dbname'] = 'imposm3_db_ir'

    try:
        template = loader.get_template('map/multiple-style.json')
    except TemplateDoesNotExist:
        return HttpResponse(status=404)

    return HttpResponse(template.render(context, request))
