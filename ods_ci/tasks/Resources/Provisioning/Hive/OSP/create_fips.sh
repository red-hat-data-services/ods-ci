#!/bin/bash
# shellcheck source=/dev/null
# Assuming you have installed aws and openstack CLIs and configured AWS and OSP (PSI) access

# Global vars
export CLUSTER_NAME=${1:-$CLUSTER_NAME}
export AWS_DOMAIN=${2:-$AWS_DOMAIN}
export OSP_NETWORK=${3:-$OSP_NETWORK}
export OUTPUT_DIR=${4:-.${CLUSTER_NAME}_conf}

# Cluster name should converted to lowercase
export CLUSTER_NAME=${CLUSTER_NAME,,} 

if [[ -z $CLUSTER_NAME || -z $AWS_DOMAIN || -z $OSP_NETWORK ]] ; then
  echo -e "Some global variables are missing, for example: 
  # export CLUSTER_NAME=${CLUSTER_NAME:-"rhods-qe-007"} # To set the cluster Subdomain (A Record) in AWS. 
  # export AWS_DOMAIN=${AWS_DOMAIN:-"rhods.ccitredhat.com"} # To set the cluster Domain in AWS.
  # export OSP_NETWORK=${OSP_NETWORK:-"shared_net_5"} # The external network for the new Floating IPs on OSP.
  "
  exit 1
else
  echo "Creating Floating IPs on OSP external network '$OSP_NETWORK' and A records in AWS domain: $CLUSTER_NAME.$AWS_DOMAIN"
fi

export OS_CLOUD=openstack

if ! openstack catalog list -c Endpoints ; then
  echo -e "Openstack access is not properly configured."
  exit 1
fi

if ! aws sts get-caller-identity ; then
  echo -e "AWS access is not properly configured."
  exit 1
fi

osp_dashboard="$(openstack catalog show keystone -c endpoints -c name -c type \
| grep public | awk -F ':' '{print $3}'| sed 's#//api#https://dashboard#')" || :

echo "Connected to Openstack: ${osp_dashboard}"

echo "Allocating a floating IP for cluster's API"
FIP_API=$(openstack floating ip create --description "$CLUSTER_NAME API" -f value -c floating_ip_address "$OSP_NETWORK") || rc=$?
if [ "$rc" != 0 ]; then
  echo "Failed to allocate a floating IP for API"
  exit 10
fi

echo "Allocating a floating IP for cluster's ingress"
FIP_APPS=$(openstack floating ip create --description "$CLUSTER_NAME APPS" -f value -c floating_ip_address "$OSP_NETWORK") || rc=$?
if [ "$rc" != 0 ]; then
  echo "Failed to allocate a floating IP for ingress"
  exit 10
fi

echo ""
echo ""
echo "FLOATING IP'S"
echo "========================================================================"
echo "cluster's apiFloatingIP api.$CLUSTER_NAME.$AWS_DOMAIN -> $FIP_API"
echo ""
echo ""
echo "cluster's ingressFloatingIP *.apps.$CLUSTER_NAME.$AWS_DOMAIN -> $FIP_APPS"
echo ""
echo ""
echo "========================================================================"


echo "Getting zone ID in Route53"
ZONES=$(aws route53 list-hosted-zones --output json)
ZONE_ID=$(echo "$ZONES" | jq -r ".HostedZones[] | select(.Name==\"$AWS_DOMAIN.\") | .Id")
if [ -z "$ZONE_ID" ]; then
  echo "Domain $AWS_DOMAIN not found in Route53"
  exit 20
fi

echo "Updating DNS records (cluster api's) in Route53"
RESPONSE=$(aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch \
'{ "Comment": "Update A record for cluster API", "Changes": 
[ { "Action": "CREATE", "ResourceRecordSet": { "Name": "api.'"$CLUSTER_NAME"'.'"$AWS_DOMAIN"'", 
"Type": "A", "TTL":  172800, "ResourceRecords": [ { "Value": "'"$FIP_API"'" } ] } } ] }' --output json) || rc=$?
if [ "$rc" != 0 ]; then
  echo "Failed to update A record for cluster"
  echo "Releasing previously allocated floating IP"
  openstack floating ip delete "$FIP_API"
  exit 25
fi

echo "Waiting for DNS change to propagate"
aws route53 wait resource-record-sets-changed --id "$(echo "$RESPONSE" | jq -r '.ChangeInfo.Id')"

echo "Updating DNS records (cluster ingress) in Route53"
RESPONSE=$(aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch \
'{ "Comment": "Update A record for cluster API", "Changes": 
[ { "Action": "CREATE", "ResourceRecordSet": { "Name": "*.apps.'"$CLUSTER_NAME"'.'"$AWS_DOMAIN"'", 
"Type": "A", "TTL":  172800, "ResourceRecords": [ { "Value": "'"$FIP_APPS"'" } ] } } ] }' --output json) || rc=$?

if [ "$rc" != 0 ]; then
  echo "Failed to update A record for cluster"
  echo "Releasing previously allocated floating IP"
  openstack floating ip delete "$FIP_APPS"
  exit 25
fi

echo "Waiting for DNS change to propagate"
aws route53 wait resource-record-sets-changed --id "$(echo "$RESPONSE" | jq -r '.ChangeInfo.Id')"

mkdir -p "$OUTPUT_DIR"
export CLUSTER_FIPS="$OUTPUT_DIR/$CLUSTER_NAME.$AWS_DOMAIN.fips"
echo "Exporting Floating IPs of API '$FIP_API' and *APPS '$FIP_APPS', and saving into: $CLUSTER_FIPS"

: > "$CLUSTER_FIPS"

echo "export FIP_API=$FIP_API" >> "$CLUSTER_FIPS"
echo "export FIP_APPS=$FIP_APPS" >> "$CLUSTER_FIPS"

cat "$CLUSTER_FIPS"

. "$CLUSTER_FIPS"

