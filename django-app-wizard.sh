#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

helpFunction()
{
   echo ""
   echo "Usage: $0 -a parameterA -b parameterB -c parameterC"
   echo -e "\t-a The name of the app or project eg. 'ToDoList'"
   echo -e "\t-b The name of the first model eg 'Item'"
#    echo -e "\t-c Description of what is parameterC"
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
    title = models.CharField(max_length=200)
    description = models.CharField(max_length=4000)
    def __str__(self):
         return self.title
"
views_py="
from django.http import HttpResponse
from django.shortcuts import render
from django.template import loader
from $modelName.models import $modelName
from $modelName.forms import modelNameForm

def list_view(request):
    all_objects = $modelName.objects.all()
    context = {
        'all_objects': all_objects
    }
    return render(request, '$modelName/index.html', context)

def main_form(request):
    form = mainForm()
    if request.method == 'POST':
        form = mainForm(request.POST)
        if form.is_valid():
            form.save()
            form = mainForm()
    context = {
        'form': form
    }
    return render(request, '$modelName/add.html', context)
"
forms_py="
from django.forms import ModelForm
from $modelName.models import $modelName

class modelNameForm(ModelForm):
    class Meta:
        model = $modelName
        fields = '__all__'
"

admin_text="
from django.contrib import admin
from .models import testModel

admin.site.register(testModel)
"

# set up venv
echo -e "\n${bold}setting up a virtual environment${normal}"
cp -R ~/dev/tyto/python3-venv/ ~/dev/personal-python3-venv    #replace with maske venv
source personal-python3-venv/bin/activate

# check django version
echo -e "\n${bold}You are running django version:{normal}"
python3 -m pip install -U Django
python3 -m django --version

# create app and remove previous version
echo -e "\n${bold}creating an app called $appName${normal}"
rm -rf $appName
django-admin startproject $appName

# startapp and create model
echo -e "\n${bold}creating a model called $modelName${normal}"
cd $appName
python3 manage.py startapp $modelName
echo -e "$models_py" > ~/dev/$appName/$modelName/models.py

# add app to installed apps
echo -e "\n${bold}installing the model${normal}"
installed_apps="INSTALLED_APPS = [\n    '${appName}',"
sed -i "s/^INSTALLED_APPS.*/${installed_apps}/" ~/dev/$appName/$appName/settings.py

# make migrations
python3 manage.py makemigrations $appName
python3 manage.py migrate

# Add a default view
echo -e "$view_text" > ~/dev/$appName/$modelName/views.py

# Add a form
echo -e "$forms_py" > ~/dev/$appName/$modelName/forms.py

# allow hosting locally and on pythonanywhere
allowed_hosts="ALLOWED_HOSTS = ['andrewmcloughlin.pythonanywhere.com','127.0.0.1']"
sed -i "s/^ALLOWED_HOSTS.*/${allowed_hosts}/" ~/dev/$appName/$appName/settings.py

# add model to admin interface   (not working)
echo -e "$admin_text" > ~/dev/$appName/$modelName/admin.py

# Create superuser; TODO Give superuser more permissions
echo -e "\n${bold}create superuser${normal}"
python3 manage.py createsuperuser

# make migrations
python3 manage.py makemigrations $appName
python3 manage.py migrate

#runserver
cd ~/dev/$appName
python3 manage.py runserver
