DATABASES = {
    'default': {
         'ENGINE': 'django.db.backends.postgresql_psycopg2',
         'NAME': 'geonode',
         'USER': 'geonode',
         'PASSWORD': 'geonode',
     },
    # vector datastore for uploads
    'datastore' : {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        #'ENGINE': '', # Empty ENGINE name disables 
        'NAME': 'geonode-imports',
        'USER' : 'geonode',
        'PASSWORD' : 'geonode',
        'HOST' : 'localhost',
        'PORT' : '5432',
    }
}

# OGC (WMS/WFS/WCS) Server Settings
OGC_SERVER = {
    'default' : {
        'BACKEND' : 'geonode.geoserver',
        'LOCATION' : 'http://localhost:8080/geoserver/',
        'PUBLIC_LOCATION' : 'http://localhost:8080/geoserver/',
        'USER' : 'admin',
        'PASSWORD' : 'geoserver',
        'MAPFISH_PRINT_ENABLED' : True,
        'PRINT_NG_ENABLED' : True,
        'GEONODE_SECURITY_ENABLED' : True,
        'GEOGIT_ENABLED' : False,
        'WMST_ENABLED' : False,
        'BACKEND_WRITE_ENABLED': True,
        'WPS_ENABLED' : False,
        # Set to name of database in DATABASES dictionary to enable
        'DATASTORE': '', #'datastore',
    }
}

# Reconcile with ``settings.py``
MAP_BASELAYERS = [{
	"source": {"ptype": "gxp_olsource"},
	"type": "OpenLayers.Layer",
	"args": ["No background"],
	"visibility": False,
	"fixed": True,
	"group":"background"
}, {
	"source": {"ptype": "gxp_osmsource"},
	"type": "OpenLayers.Layer.OSM",
	"name": "mapnik",
	"visibility": False,
	"fixed": True,
	"group": "background"
}, {
	"source": {"ptype": "gxp_mapquestsource"},
	"name": "osm",
	"group": "background",
	"visibility": True
}, {
	"source": {"ptype": "gxp_bingsource"},
	"name": "AerialWithLabels",
	"fixed": True,
	"visibility": False,
	"group": "background"
}, {
	"source": {"ptype": "gxp_mapboxsource"},
}]

# Default preview library
#LAYER_PREVIEW_LIBRARY = 'geoext'

ALLOWED_HOST = ['localhost:1780','localhost']
