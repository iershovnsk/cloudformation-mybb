#!/bin/bash

#
# MyBB installation script.
# (C) Valeriu Paloş <valeriupalos@gmail.com>
#
# Apache2, Php5x and required dependencies for MyBB are expected to be
# proertly added to the system by this point. This installation script
# was tested on an Ubuntu AMI. Invoke from **this** working directory!
#

TEMPPATH=`mktemp -d`
MYBBBASE="http://resources.mybb.com/downloads"
MYBBFILE="mybb_1806.zip"

pushd
curl "$MYBBBASE/$MYBBFILE" -o "$MYBBFILE"


rm -rf "$TEMPDIR"