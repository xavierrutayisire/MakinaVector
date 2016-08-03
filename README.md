## serveVectorTilesFromAtoZ

### Info:

This repository allows you to easily create a postgis database and import osm data with imposm3.

The database will be automatically updated every 5 minutes with a cron job so the database will always be up to date.

With Utilery you can generate vector tiles.

You also have the possibility to update the tiles with the new modifications every 5 minutes.

With Django you can create an application to render a map.

The Django application is made so you can add or remove different layers directly from your browser.

---

! Dont remove any file from the repository !

! Execute install-database.sh and install-utilery.sh as root user !

! Don't forget to edit the « setup user » when mentioned !

---

### Installation

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
- Edit views.py in your map application and change all the variables with your setup !important!

---

##### 8 - Lauch Django server:

- Go to the folder of django where manage.py is
- Run « `%%%/utilery-virtualenv/bin/python manage.py runserver %%%` » and change %%% with the right folder and the port you use in views.py

---

##### 9 - Ready to go !

- Open you browser and open « `%%%:%%%` » and change %%% with the host and the port you used for the django server

![alt tag](http://image.noelshack.com/fichiers/2016/31/1470150787-screenshot-from-2016-08-02-17-12-28.png)

---

#### Usage:

When you generate you tiles Utilery create all the layers with a file name « `queries.yml` ». <br />
You need to choose the name of all the queries with the source-layer you will want in your style Mapbox. <br />
With mapbox you can style the layers you just generate into pbf tiles. For that you will have to use the « `style.json` » file. <br />
The actual style file and so the tiles is based on Mapbox Streets V7. <br />
To allow you to add more layers from the same or different sources, you have the  « `multiple-style.json` » file. <br />
You can find a working example of the « `multiple-style.json` » file in the templates folder of your application. <br />
If you don't want to use external layers style just change this line:
- `"multiple_style": true,` with this `"multiple_style": false,`

---

#### Webography:

- https://github.com/omniscale/imposm3
- https://github.com/tilery/utilery/tree/master/utilery
- https://github.com/openstreetmap/osmosis
- https://www.djangoproject.com
- https://www.mapbox.com
