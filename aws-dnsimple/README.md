# AWS DNSimple

This container provides a python environment with the AWS CLI and dnsimple API and some
simple scripts.


## Scripts

### `update_dnsimple.sh`

A wrapper shell script which retrives the DNS Name from and AWS loadbalancer and updates a given DNSimple CNAME to point to this target.

```bash
#   This script expects some environment variables
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
```

### `dnsimple_api.py`

A python script which updates/creates a DNSsimple record.

```bash
usage: dnsimple_api.py [-h] --name NAME [--type TYPE] [--sandbox] access_token zone target

positional arguments:
  access_token  DNSimple API Access Token
  zone          DNSimple Zone
  target        The DNS target for the CNAME

optional arguments:
  -h, --help    show this help message and exit
  --name NAME   Record name
  --type TYPE   Record Type
  --sandbox     Use the sandbox account
```
