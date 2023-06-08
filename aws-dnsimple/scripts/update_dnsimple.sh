
#!/bin/bash
#   This script requires some environment variables:
#       DNSIMPLE_ACCESS_TOKEN
#   Optional environment variables:
#       These are only needed if running in an environment that is not already running with an assumed role with the correct permissions.
#       You need "elasticloadbalancing:DescribeLoadBalancers"
#       AWS_ACCESS_KEY_ID           AWS key with permission to query Loadbalancer resources
#       AWS_SECRET_ACCESS_KEY
#
#
#   Usage: $(basename $0) [-r REGION] [-s SUBDOMAIN][-h] NAMES DNSIMPLE_ZONE
#   Update DNSimple CNAME record using AWS ALB DNS record
#       NAMES           The names of the LoadBalancer to query for
#       DNSIMPLE_ZONE   The name of the zone to check in DNSimple
#       -r REGION       Specify the AWS region. Default: eu-west-2
#       -s SUBDOMAIN    Specify the subdomain e.g.  mydendra-review-develop from {mydendra-review-develop}.sk.ai. Default: '*'"
#

SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}") 

function usage {
    echo "Usage: $(basename $0) [-r REGION] [-s SUBDOMAIN][-h] NAMES DNSIMPLE_ZONE" 2>&1
    echo "Update DNSimple CNAME record using AWS ALB DNS record"
    echo "  NAMES               The names of the LoadBalancer to query for"
    echo "  DNSIMPLE_ZONE       The name of the zone to check in DNSimple"
    echo "  -r REGION           Specify the AWS region. Default: eu-west-2"
    echo "  -s SUBDOMAIN.       Specify the subdomain e.g.  mydendra-review-develop from {mydendra-review-develop}.sk.ai. Default: '*'"
    echo
    echo "For authentication this script expects either AWS KEY and SECRET or to be run in an environment with assumerole"
    exit 1
}

# Default region
REGION=eu-west-2

# Default SUBDOMAIN
SUBDOMAIN="*"

while getopts ':hr:s:' opt; do
    case ${opt} in
        h)
            usage
            ;;
        r)
            REGION=${OPTARG}
            ;;
        s)
            SUBDOMAIN=${OPTARG}
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

shift $((OPTIND - 1))

# Extract the command line args
NAMES=$1
DNSIMPLE_ZONE=$2

# Check we have required env vars
ALL_REQS=1

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

# Run the script
set -e

TARGET=`aws elbv2 describe-load-balancers --region ${REGION} --names ${NAMES} --query "LoadBalancers[0].DNSName"`
python3 ${SCRIPT_RELATIVE_DIR}/dnsimple_api.py $DNSIMPLE_ACCESS_TOKEN $DNSIMPLE_ZONE $TARGET --name $SUBDOMAIN --create
