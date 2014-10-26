#!/usr/bin/env bash
echo 'starting provisioning'
apt-get update
packagelist=(
    build-essential
    apache2
    gcc                    
    gdal-bin               
    gettext                
    git-core               
    libapache2-mod-wsgi    
    libgeos-dev            
    libjpeg-dev            
    libpng-dev             
    libpq-dev              
    libproj-dev            
    libxml2-dev            
    libxslt1-dev            
    openjdk-6-jre          
    patch                  
    postgresql-9.3         
    postgresql-9.3-postgis-2.1 
    postgresql-contrib     
    postgresql-contrib-9.3
    python                 
    python-dev             
    python-gdal            
    python-imaging         
    python-lxml            
    python-pip             
    python-pyproj          
    python-pastescript     
    python-software-properties 
    python-shapely         
    python-support         
    python-httplib2        
    python-urlgrabber      
    python-virtualenv      
    tomcat7                
    tmux                   
    unzip                  
    zip
    zlib1g-dev
)

apt-get install -y ${packagelist[@]}
apt-get build-dep -y python-lxml
pip install virtualenvwrapper
apt-get install -y --force-yes openjdk-6-jdk ant maven2 --no-install-recommends

echo 'Statics devs tools'
apt-get install -y git gettext
add-apt-repository -y ppa:chris-lea/node.js
apt-get update
apt-get install -y nodejs
npm install -y -g bower
npm install -y -g grunt-cli

echo ' > Fix bug, install gdal for development'
add-apt-repository ppa:ubuntugis/ubuntugis-unstable
apt-get update
apt-get -y install libgdal1h libgdal-dev python-gdal
python -c "from osgeo import gdal; print gdal.__version__"
echo ' > end fix gdal dev (nexts step will be done onto virtualenv)'

echo ' Setting up virtualenv for geonode'
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=/home/.venvs
source /usr/local/bin/virtualenvwrapper.sh
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
mkvirtualenv geonode --system-site-package
workon geonode
echo ' Debug : installing psycopg2 for python 2.7'
pip install psycopg2
cd /home/

echo 'configuring postgresql users and passwords :'
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'password';"
sudo -u postgres psql -U postgres -d postgres -c "create user geonode with password 'geonode';"

echo 'allowing remote access to db server and enable password auth for all :'
cp /etc/postgresql/9.3/main/postgresql.conf /etc/postgresql/9.3/main/postgresql.conf.bck
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.3/main/postgresql.conf
cp /etc/postgresql/9.3/main/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf.bck
sed -i "s/local   all             all                                     peer/local   all             all                                     md5/g" /etc/postgresql/9.3/main/pg_hba.conf
sed -i "s/host    all             all             ::1\/128                 md5/host    all             all             ::1\/32                 md5/g" /etc/postgresql/9.3/main/pg_hba.conf
service postgresql restart

echo 'setup geonode database, postgis extension'
sudo -u postgres psql -U postgres -d postgres -c 'CREATE DATABASE geonode;'
sudo -u postgres psql -U postgres -d postgres -c 'GRANT ALL PRIVILEGES ON DATABASE geonode TO geonode;'
sudo -u postgres psql -U postgres -d postgres -c 'CREATE DATABASE "geonode-imports";'
sudo -u postgres psql -U postgres -d postgres -c 'GRANT ALL PRIVILEGES ON DATABASE "geonode-imports" TO geonode;'
sudo -u postgres psql -U postgres -d geonode-imports -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis.sql
sudo -u postgres psql -U postgres -d geonode-imports -f /usr/share/postgresql/9.3/contrib/postgis-2.1/spatial_ref_sys.sql
sudo -u postgres psql -U postgres -d geonode-imports -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
sudo -u postgres psql -U postgres -d geonode-imports -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'
sudo -u postgres psql -U postgres -d geonode -c 'create extension postgis;'

echo 'Cloning geonode from git geode/geonode master'
cd /home/
#git clone https://github.com/GeoNode/geonode.git
#rm /home/geonode/.gitignore
#rm -rf /home/geonode/*
#rm -rf /home/geonode/.??*
#cd /home/geonode/
#git init
#git remote add origin https://github.com/Geode/geonode.git
#git fetch
#git checkout -t origin/master
#cp /home/vagrant/.gitignore /home/geonode/.gitignore
git clone -b master https://github.com/Geode/geonode.git
cd geonode
echo 'Installing geonode with pip and paver setup into geonode venv'
pip install -e .
paver setup
echo 'overriding local_setup'
cp -f /setup/local_settings.py /home/geonode/geonode/local_settings.py

echo 'installing databases'
python manage.py syncdb --noinput
python manage.py createsuperuser --username=geode --email=info@opengeode.be --noinput
/usr/sbin/geonode-updateip localhost:1780
python manage.py collectstatic
mkdir -p /home/geonode/geonode/uploaded
chown www-data -R /home/geonode/geonode/uploaded

echo 'Configuring Apache'
#sed -i "$ a\ServerName localhost" /etc/apache2/apache2.conf
cp -f /setup/apache2.conf /etc/apache2/apache2.conf
a2enmod wsgi
a2enmod proxy_http
cp -f /setup/wsgi.py /home/geonode/geonode/wsgi.py
cp -f /setup/geonode.conf /etc/apache2/sites-available/geonode.conf
a2ensite geonode
a2dissite 000-default
chown www-data:www-data /home/geonode/geonode/static/
chown www-data:www-data /home/geonode/geonode/uploaded/
mkdir /home/geonode/geonode/static_root/
chown www-data:www-data /home/geonode/geonode/static_root/
service apache2 reload

cd /home/geonode
python manage.py collectstatic --noinput

echo 'Moving to tomcat7'
service tomcat7 stop
cp downloaded/geoserver.war /var/lib/tomcat7/webapps/
service tomcat7 start

echo 'Installation dev tools for translation with transifex'
apt-get install -y python-sphinx
apt-get install -y transifex-client
pip install sphinx_rtd_theme
cp /setup/.transifexrc /root/.transifexrc
echo 'just update /root/.transifexrc with our credentials if you are going to manage translations.'

echo '@todo ? installing custom geonode project'
