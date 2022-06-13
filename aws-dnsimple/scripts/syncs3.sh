#!/bin/bash
#   This script requires some environment variables
#       AWS_ACCESS_KEY_ID
#       AWS_SECRET_ACCESS_KEY
#       
#
#   Usage: $(basename $0) SRC DEST  [OPTIONS] [-h]
#   Syncronise database file from aws s3
#       SRC           The names of the LoadBalancer to query for
#       DEST   The name of the zone to check in DNSimple
#

SRC=$1 
DEST=$2

if [[ -z $SRC ]]; then
    echo "Missing s3 source bucket"
    exit 1
fi
if [[ -z $DEST ]]; then
    echo "Missing destination"
    exit 1
fi

if [ -f $DEST/*.sql.gz ]; then
    echo "Database file present"
    exit 0
else
    aws s3 sync $SRC $DEST --exclude="*" --include="*.sql.gz"
fi