#!/bin/bash

if [ -z $RESTAPIPATH ];
then
    echo "please source init.sh from restapi project"
    exit
fi


export PYTHONPATH=$PYTHONPATH:$RESTAPI/tools
echo "Setting PYTHONPATH => $PYTHONPATH"

