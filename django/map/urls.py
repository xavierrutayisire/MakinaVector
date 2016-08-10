from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^$', views.index, name='index'),
    url(r'^index$', views.index, name='index'),
    url(r'^style$', views.style, name='style'),
    url(r'^multiple-style$', views.multiple_style, name='multiple_style'),
    url(r'^upload', views.upload, name='upload'),
]
