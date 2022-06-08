
#!/bin/bash
#   This script requires some environment variables
#       AWS_ACCESS_KEY_ID
#       AWS_SECRET_ACCESS_KEY
#       DNSIMPLE_ACCESS_TOKEN
#       
#
#   Usage: $(basename $0) NAMES DNSIMPLE_ZONE [-r REGION] [-h]
#   Update DNSimple CNAME record using AWS ALB DNS record
#       NAMES           The names of the LoadBalancer to query for
#       DNSIMPLE_ZONE   The name of the zone to check in DNSimple
#       -r REGION       Specify the AWS region. Default: eu-west-2
#

SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}") 

function usage {
    echo "Usage: $(basename $0) NAMES DNSIMPLE_ZONE [-r REGION] [-h]" 2>&1
    echo "Update DNSimple CNAME record using AWS ALB DNS record"
    echo "  NAMES           The names of the LoadBalancer to query for"
    echo "  DNSIMPLE_ZONE   The name of the zone to check in DNSimple"
    echo "  -r REGION       Specify the AWS region. Default: eu-west-2"
    exit 1
}

# Default region
REGION=eu-west-2

# Extract the command line args
NAMES=$1
DNSIMPLE_ZONE=$2

# Check we have required env vars
ALL_REQS=1
if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
    ALL_REQS=0
    echo "$(tput setaf 1)REQUIRED env var AWS_ACCESS_KEY_ID has not been set.$(tput sgr0)"
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
    ALL_REQS=0  
    echo "$(tput setaf 1)REQUIRED env var AWS_SECRET_ACCESS_KEY has not been set.$(tput sgr0)"
fi

if [[ -z ${DNSIMPLE_ACCESS_TOKEN} ]]; then
    ALL_REQS=0  
    echo "$(tput setaf 1)REQUIRED env var DNSIMPLE_ACCESS_TOKEN has not been set.$(tput sgr0)"
fi

if [[ -z ${NAMES} ]]; then
    echo "$(tput setaf 1)Missing position argument NAMES $(tput sgr0)"
    usage
fi

if [[ -z ${DNSIMPLE_ZONE} ]]; then
    echo "$(tput setaf 1)Missing position argument DNSIMPLE_ZONE $(tput sgr0)"
    usage
fi

if [ $ALL_REQS == 0 ]; then
    echo "$(tput setaf 1)Missing required env variables.$(tput sgr0)"
    exit 1
fi

# Expected arguments
optstring=":hr"

while getopts ${optstring} arg; do
    case ${arg} in
        h)
            usage
            ;;
        r)
            REGION="${OPTARG}"
            ;;
        :)
            echo "$0: Must supply an argument to -$OPTARG." >&2
            exit 1
            ;;
        ?)
            echo "Invalid option: -${OPTARG}."
            exit 2
            ;;
        esac
    done

# Run the script
set -e
TARGET=`aws elbv2 describe-load-balancers --region $REGION --names $NAMES --query "LoadBalancers[0].DNSName"`
echo $TARGET
python3 ${SCRIPT_RELATIVE_DIR}/dnsimple_api.py $DNSIMPLE_ACCESS_TOKEN $DNSIMPLE_ZONE $TARGET --name "*"