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

# Begin script in case all parameters are correct
echo -e "\n${bold}creating an app called $appName${normal}"

echo -e "\n${bold}setting up a virtual environment${normal}"
rm -rf testApp
django-admin startproject $appName
cp -R ~/dev/tyto/python3-venv/ $appName/python3-venv
source $appName/python3-venv/bin/activate
cd $appName


#startapp
echo -e "\n${bold}creating a model called $modelName${normal}"
python3 manage.py startapp $modelName
echo -e "class $modelName(models.Model): \n    title = models.CharField(max_length=200) \n    description = models.CharField(max_length=4000)\n    def __str__(self):\n        return self.title" >> ~/dev/$appName/$modelName/models.py

#modify view
echo -e "\n${bold}creating default view${normal}"
echo -e "from django.http import HttpResponse\n\ndef index(request):\n    return HttpResponse('Hello, world.')" >> ~/dev/$appName/$modelName/views.py

#create a file called urls.py in the project directory
echo -e "from django.urls import path\nfrom . import views\n\nurlpatterns = [\n    path('', views.index, name='index'),\n]" >> ~/dev/$appName/$modelName/urls.py

#add url to 
echo -e "\n${bold}modify urls.py${normal}"
import_list="from django.urls import include, path"
sed -i "s/^from django\.urls import path.*/${import_list}/" ~/dev/$appName/$appName/urls.py
url_patterns="urlpatterns = [\n    path('', include('testModel.urls')),\n    path('testModel\/', include('testModel.urls')),"
sed -i "s/^urlpatterns.*/${url_patterns}/" ~/dev/$appName/$appName/urls.py


echo -e "\n${bold}modifying allowed hosts${normal}"
allowed_hosts="ALLOWED_HOSTS = ['andrewmcloughlin.pythonanywhere.com','127.0.0.1']"
sed -i "s/^ALLOWED_HOSTS.*/${allowed_hosts}/" ~/dev/$appName/$appName/settings.py

echo -e "\n${bold}installing the model${normal}"
installed_apps="INSTALLED_APPS = [ \n    '${appName}',"
sed -i "s/^INSTALLED_APPS.*/${installed_apps}/" ~/dev/$appName/$appName/settings.py

#change db type -not sure if this is necessary
# db_name="        'NAME': BASE_DIR \/ 'db.sqlite3',"
# sed -i "s/^        'NAME': os.path.join.*/${db_name}/" ~/dev/$appName/$appName/settings.py


echo -e "\n${bold}activating the model${normal}"
python3 manage.py makemigrations $appName

echo -e "\n${bold}add model to admin interface${normal}"
echo -e "from .models import $modelName \n \nadmin.site.register($modelName)" >> ~/dev/$appName/$modelName/admin.py

echo -e "\n${bold}making migrations${normal}"
python3 manage.py makemigrations $appName
python3 manage.py migrate

echo -e "\n${bold}create superuser${normal}"
python3 manage.py createsuperuser


python3 manage.py runserver


