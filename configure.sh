#!/bin/sh

#Setting up python environment

if [ ! -d venv ]
then
	echo "creating virtualenv"
	virtualenv ./venv
	echo "sourcing virtualenv"
	source ./venv/bin/activate
	pip install --upgrade pip
	pip install -r requirements.txt
else
	echo "virtualenv already created"
fi
