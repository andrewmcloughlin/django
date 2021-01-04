#!/bin/bash
helpFunction()
{
   echo ""
   echo "Usage: $0 -a parameterA -b parameterB -c parameterC"
   echo -e "\t-a The name of the app or project eg. 'ToDoList'"
   echo -e "\t-b The name of the first model eg 'Item'"
   exit 1 # Exit script after printing help
}

while getopts "a:b:" opt
do
   case "$opt" in
      a ) appName="$OPTARG" ;;
      b ) modelName="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$appName" ] || [ -z "$modelName" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script if all parameters are correct

models_py="
from django.db import models

class $modelName(models.Model):
    id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=200)
    description = models.CharField(max_length=4000)
    image = models.ImageField(
        null=True, 
        blank=True, 
        upload_to='assets', 
        default='logo.png'
        )
    def __str__(self):
         return self.title
"
views_py="
from django.http import HttpResponse
from django.shortcuts import render, redirect
from django.template import loader
from .models import $modelName
from .forms import mainForm

def list_view(request):
    all_objects = $modelName.objects.all()
    context = {
        'all_objects': all_objects
    }
    return render(request, '$appName/index.html', context)

def add(request):
    form = mainForm()
    if request.method == 'POST':
        form = mainForm(request.POST)
        if form.is_valid():
            form.save()
            form = mainForm()
            return redirect('home')
    context = {
        'form': form
    }
    return render(request, '$appName/add.html', context)

def update(request, pk):
    form = mainForm()
    context = {
        'form': form
    }
    return render(request, '$appName/add.html', context)
"
forms_py="
from django.forms import ModelForm
from .models import $modelName

class mainForm(ModelForm):
    class Meta:
        model = $modelName
        fields = '__all__'
"

admin_py="
from django.contrib import admin
from .models import $modelName

admin.site.register($modelName)
"

urls_py="
from django.contrib import admin
from django.urls import path
from $appName.views import *
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [
    path('', list_view, name ='home'),
    path('home/', list_view, name ='home'),
    path('add/', add, name = 'add'),
    path('admin/', admin.site.urls),
    path('u<int:id>/', update, name = 'update'),
]+ static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

urlpatterns += staticfiles_urlpatterns()
"

base_html="
{% load static %}
<html>
    <head>
        <link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Material+Icons'>
        <link rel='stylesheet' href='https://unpkg.com/bootstrap-material-design@4.1.1/dist/css/bootstrap-material-design.min.css' integrity='sha384-wXznGJNEXNG1NFsbm0ugrLFMQPWswR3lds2VeinahP8N0zJw9VWSopbjv2x7WCvX' crossorigin='anonymous'>
        <title>
            $appName
        </title>
    </head>
    <body>
        <ul class='nav nav-tabs navbar-dark box-shadow'>
            <li class='nav-item'>
                <a class='nav-link' href='/'>
                     <img src='{% static 'logo.png' %}' height='20'>
                </a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='/'>Home</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='/add'>add</a>
            </li>
            <li class='nav-item'>
                <a class='nav-link' href='/admin'>admin</a>
            </li>
        </ul>
        <div class='container'>
            <div class='my-3 p-3 rounded box-shadow'>
                {% block content %}
                {% endblock %}
            </div>
        </div>
    </body>
</html>
"

index_html="
{% extends '$appName/base.html' %}
{% load static %}
{% block content %}
{% for object in all_objects %}
<div class='col s1 m1'>
    <div class='card mb-4 box-shadow'>
        <div class='card-body'>
            <img src='{{object.image.url}}' class='card-img-top' height=50>
            <h2 class='card-text'>{{object}}</h2>
            <p class='card-text'>Title: {{object.title}}</p>
            <p class='card-text'>Description: {{object.description}}</p>
            <div class='d-flex justify-content-between align-items-center'>
                <div class='btn-group'>
                    <button type='button' class='btn btn-sm btn-outline-primary' href=\"{% url 'update' object.id %}\">
                        Edit
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
{% endfor %}
<a href='/add'>
    <button type='button' class='btn btn-lg btn-primary' >
        <i class='material-icons'>add
        </i> Add
    </button>
</a>
{% endblock %}
"

add_html="
{% extends '$appName/base.html' %}
{% block content %}
<form action='' method='POST' enctype='multipart/form-data'>
    <div class='form-group'>
        {% csrf_token %}
        {{form.as_p}}
    </div>
    <input type='submit' value='Submit' class='btn btn-lg btn-secondary'>
</form>
{% endblock content %}
"

settings_py="

import os
STATICFILES_DIRS = (
    os.path.join(BASE_DIR, 'assets'),
)

MEDIA_ROOT = (
    os.path.join(BASE_DIR, 'assets')
)

"

# set up venv and requirements
python3 -m venv django-venv
source django-venv/bin/activate
python3 -m pip install --upgrade pip
pip install -r requirements.txt

# create app and remove previous version
cd ~/dev
rm -rf $appName
django-admin startproject $appName

# startapp and create model
cd $appName
echo -e "$models_py" > ~/dev/$appName/$appName/models.py

# add app to installed apps
installed_apps="INSTALLED_APPS = [\n    '${appName}',"
sed -i "s/^INSTALLED_APPS.*/${installed_apps}/" ~/dev/$appName/$appName/settings.py

# make migrations
python3 manage.py makemigrations $appName
python3 manage.py migrate

# Add views.py, urls.py and forms.py
echo -e "$views_py" > ~/dev/$appName/$appName/views.py
echo -e "$urls_py" > ~/dev/$appName/$appName/urls.py
echo -e "$forms_py" > ~/dev/$appName/$appName/forms.py

# append to settings.py
echo -e "$settings_py" >> ~/dev/$appName/$appName/settings.py

# allow hosting locally and on pythonanywhere
allowed_hosts="ALLOWED_HOSTS = ['andrewmcloughlin.pythonanywhere.com','127.0.0.1']"
sed -i "s/^ALLOWED_HOSTS.*/${allowed_hosts}/" ~/dev/$appName/$appName/settings.py

# make an assets dir for static files
cd ~/dev/$appName
git clone https://github.com/andrewmcloughlin/assets
cd ~/dev/$appName

# add model to admin interface
echo -e "$admin_py" > ~/dev/$appName/$appName/admin.py

tree -L 2

# Create superuser
DJANGO_SUPERUSER_PASSWORD=maclin1527 \
DJANGO_SUPERUSER_USER=andrew \
DJANGO_SUPERUSER_EMAIL=my_user@domain.com \
./manage.py createsuperuser \
--no-input --username andrew

# make migrations
python3 manage.py makemigrations $appName
python3 manage.py migrate

# html templates
cd ~/dev/$appName/$appName
mkdir templates
cd templates
mkdir $appName
cd $appName
echo -e "$base_html" > ~/dev/$appName/$appName/templates/$appName/base.html
echo -e "$index_html" > ~/dev/$appName/$appName/templates/$appName/index.html
echo -e "$add_html" > ~/dev/$appName/$appName/templates/$appName/add.html

#runserver
cd ~/dev/$appName
python3 manage.py runserver
