apt-get update

echo '1 installing essentials'
apt-get install -y build-essential libxml2-dev libxslt1-dev libpq-dev zlib1g-dev
apt-get install -y python-dev python-imaging python-lxml python-pyproj python-shapely python-nose python-httplib2 python-pip python-software-properties
apt-get install -y postgresql-9.3 postgresql-9.3-postgis-2.1 postgresql-contrib postgresql-contrib-9.3
pip install virtualenvwrapper

apt-get install -y --force-yes openjdk-6-jdk ant maven2 --no-install-recommends

echo '2 installing dev tools'
apt-get install -y git gettext
add-apt-repository -y ppa:chris-lea/node.js
apt-get update
apt-get install -y nodejs
npm install -y -g bower
npm install -y -g grunt-cli
apt-get install -y python-sphinx transifex-client
pip install sphinx_rtd_theme
cp /setup/.transifexrc /root/.transifex.rc
echo '@todo : update /root/transifex.rc with credentials'

echo '3 installing gdal osgeo problem, see installing dev env geonode'
add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
apt-get update
apt-get -y install libgdal1h libgdal-dev python-gdal

echo '4 creating virtualenv'
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
export WORKON_HOME=~/.venvs
source /usr/local/bin/virtualenvwrapper.sh
export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
mkvirtualenv geonode --system-site-package
workon geonode

echo '5 working with postgis otherwise will be sqlite db'
pip install psycopg2

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

echo '6 cloning and installing geonode'
git clone https://github.com/Geode/geonode.git
pip install -e geonode --use-mirrors --allow-external pyproj --allow-unverified pyproj

echo '7 paver setup: geoserver install'
cd geonode
paver setup

echo '8 local settings and creating first superuser / syncdb / test'
cp -f /setup/local_settings.py /home/vagrant/geonode/local_settings.py
python manage.py syncdb --noinput
python manage.py createsuperuser --username=geode --email=info@opengeode.be --noinput
python manage.py collectstatic --noinput
#mkdir /home/vagrant/geonode/geonode/uploaded
#mkdir /home/vagrant/geonode/staticroot

echo '@todo : install Geonode custom site, from geode/imio_geonode github repo' 

echo 'final : see comments below into bottstrap.sh for starting geonode with paver' 
#paver start
#vagrant ssh
#sudo su
#export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python
#export WORKON_HOME=~/.venvs
#source /usr/local/bin/virtualenvwrapper.sh
#export PIP_DOWNLOAD_CACHE=$HOME/.pip-downloads
#workon geonode
#tmux
#ctrl+b --> c
#workon geonode
#paver start_geoserver
#ctrl+b --> n
#workon geonode
#paver start_django
