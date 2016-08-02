## serveVectorTilesFromAtoZ

! Dont remove any file from the repository !

! Execute install-database.sh and install-utilery.sh as root user !

! Don't forget to edit the « setup user » when mentioned !

---

##### 1 - Deployment of database:

- Edit install-database.sh and change the « setup user »
- Run « `sudo sh install-database.sh` » from Deploy-Imposm3-Utilery folder

---

##### 2 - Deployment of Utilery:

- Edit install-utilery.sh and change the « setup user »
- Run « `sudo sh install-utilery.sh` » from Deploy-Imposm3-Utilery folder

---

##### 3 - Usage of Utilery:

- Add the config for Utilery:
    - Run « `export UTILERY_SETTINGS=%%%/utilery/utilery/config/default.py` » and change %%% with the right directory
- Run « `%%%/utilery-virtualenv/bin/python %%%/utilery/utilery/serve.py` » and change %%% with the right directory

---

##### 4 - Generate tiles:

- Edit generate-tiles.py and change the « setup user »
- Run « `sudo %%%/utilery-virtualenv/bin/python generate-tiles.py` » and change %%% with the right directory

---

##### 5 - Update tiles: (Utilery server need to be running)

- Edit update-tiles.sh and change the « setup user »
- Run « `sudo sh update-tiles.sh` » from Deploy-Imposm3-Utilery folder

---

##### 6 - Serve tiles:

- Run « `cd %%%/utilery/tiles` » and change %%% with the right directory
- Run « `http-server -p %%%` » and change %%% with the port you wanna use

---

##### 7 - Create a Django application:

- Edit install-django.sh and change the « setup user »
- Run « `sudo sh install-django.sh` » from Deploy-Imposm3-Utilery folder
- Edit composite/settings.py in your django project folder and add « `'map'` » in « `INSTALLED_APPS = []` »
- Edit views.py in your map application and change all the variables with your setup

---

##### 8 - Lauch Django server:

- Go to the folder of django where manage.py is
- Run « `python manage.py runserver %%%` » and change %%% with the port you wanna use

---

##### 9 - Ready to go !

- Open you browser and open « `%%%:%%%` » and change %%% with the host and the port you used for the django server

![alt tag](http://img4.hostingpics.net/pics/220631Screenshotfrom20160802170649.png)

---

##### Info:

This repository allows you to easily create a postgis database and import osm data with imposm3.

The database will be automatically updated 5 minute with a cron job so the database will always be up to date.

Utilery is a tool who allows you to generate vector tiles.

With Django you can create an application to render a map.

---

##### Webography:

- https://github.com/omniscale/imposm3
- https://github.com/tilery/utilery/tree/master/utilery
- https://github.com/openstreetmap/osmosis
- https://www.djangoproject.com
- https://www.mapbox.com
