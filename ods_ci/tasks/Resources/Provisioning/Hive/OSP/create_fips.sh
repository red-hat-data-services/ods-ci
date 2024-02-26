#!/bin/bash
# shellcheck source=/dev/null
# Assuming you have installed aws and openstack CLIs and configured AWS and OSP (PSI) access

# Global vars
export CLUSTER_NAME=${1:-$CLUSTER_NAME}
export BASE_DOMAIN=${2:-$BASE_DOMAIN}
export OSP_NETWORK=${3:-$OSP_NETWORK}
export OSP_CLOUD=${4:-openstack}
export OUTPUT_DIR=${5:-.${CLUSTER_NAME}_conf}

# Cluster name should be converted to lowercase
export CLUSTER_NAME=${CLUSTER_NAME,,} 

if [[ -z $CLUSTER_NAME || -z $BASE_DOMAIN || -z $OSP_NETWORK ]] ; then
  echo -e "Some global variables are missing, for example: 
  # export CLUSTER_NAME=${CLUSTER_NAME:-"rhods-qe-007"} # To set the cluster Subdomain (A Record) in AWS. 
  # export BASE_DOMAIN=${BASE_DOMAIN:-"rhods.ccitredhat.com"} # To set the cluster Domain in AWS.
  # export OSP_NETWORK=${OSP_NETWORK:-"shared_net_5"} # The external network for the new Floating IPs on OSP.
  "
  exit 1
else
  echo "Creating Floating IPs on OSP external network '$OSP_NETWORK' and A records in AWS domain: $CLUSTER_NAME.$BASE_DOMAIN"
fi

export OS_CLOUD=${OSP_CLOUD}

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

echo "Cleaning unused Floating IPs in Openstack Cloud '$OSP_CLOUD' (before creating new IPs in Network '$OSP_NETWORK')"
openstack floating ip list --status DOWN -c 'Floating IP Address' -f value | xargs -n1 -r --verbose openstack floating ip delete || rc=$?
if [[ -n "$rc" ]] ; then
  echo -e "Failure [$rc] cleaning unused floating IPs"
  exit ${rc:+$rc}
fi

echo "Allocating a floating IP for cluster's API"
cmd=(openstack floating ip create --description "$CLUSTER_NAME API" -f value -c floating_ip_address "$OSP_NETWORK")
echo "${cmd[@]}"
FIP_API=$("${cmd[@]}" 2>&1) || rc=$?
if [[ -n "$rc" ]] ; then
  echo -e "Failure [$rc] allocating floating IP for API: \n $FIP_API"
  exit ${rc:+$rc}
fi

echo "Allocating a floating IP for cluster's ingress"
cmd=(openstack floating ip create --description "$CLUSTER_NAME APPS" -f value -c floating_ip_address "$OSP_NETWORK")
echo "${cmd[@]}"
FIP_APPS=$("${cmd[@]}" 2>&1) || rc=$?
if [[ -n "$rc" ]] ; then
  echo -e "Failure [$rc] allocating floating IP for APPS (ingress): \n $FIP_APPS"
  exit ${rc:+$rc}
fi

echo ""
echo ""
echo "FLOATING IP'S"
echo "========================================================================"
echo "cluster's apiFloatingIP api.$CLUSTER_NAME.$BASE_DOMAIN -> $FIP_API"
echo ""
echo ""
echo "cluster's ingressFloatingIP *.apps.$CLUSTER_NAME.$BASE_DOMAIN -> $FIP_APPS"
echo ""
echo ""
echo "========================================================================"


echo "Getting zone ID in Route53"
ZONES=$(aws route53 list-hosted-zones --output json)
ZONE_ID=$(echo "$ZONES" | jq -r ".HostedZones[] | select(.Name==\"$BASE_DOMAIN.\") | .Id")
if [[ -z "$ZONE_ID" ]] ; then
  echo "Domain $BASE_DOMAIN not found in Route53"
  exit 20
fi

echo "Updating DNS records (cluster api's) in AWS Route53"
RESPONSE=$(aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch \
'{ "Comment": "Update A record for cluster API", "Changes": 
[ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "api.'"$CLUSTER_NAME"'.'"$BASE_DOMAIN"'", 
"Type": "A", "TTL":  300, "ResourceRecords": [ { "Value": "'"$FIP_API"'" } ] } } ] }' --output json) || rc=$?
if [[ -n "$rc" ]] ; then
  echo -e "Failed to update DNS A record in AWS for cluster API. 
  \n Releasing previously allocated floating IP in $OS_CLOUD ($FIP_API)"
  openstack floating ip delete "$FIP_API"
  exit ${rc:+$rc}
fi

echo "Waiting for DNS change to propagate"
aws route53 wait resource-record-sets-changed --id "$(echo "$RESPONSE" | jq -r '.ChangeInfo.Id')"

echo "Updating DNS records (cluster ingress) in AWS Route53"
RESPONSE=$(aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch \
'{ "Comment": "Update A record for cluster APPS", "Changes": 
[ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "*.apps.'"$CLUSTER_NAME"'.'"$BASE_DOMAIN"'", 
"Type": "A", "TTL":  300, "ResourceRecords": [ { "Value": "'"$FIP_APPS"'" } ] } } ] }' --output json) || rc=$?

if [[ -n "$rc" ]] ; then
  echo -e "Failed to update DNS A record in AWS for cluster APPS. 
  \n Releasing previously allocated floating IP in $OS_CLOUD ($FIP_APPS)"
  openstack floating ip delete "$FIP_APPS"
  exit ${rc:+$rc}
fi

echo "Waiting for DNS change to propagate"
aws route53 wait resource-record-sets-changed --id "$(echo "$RESPONSE" | jq -r '.ChangeInfo.Id')"

mkdir -p "$OUTPUT_DIR"
export CLUSTER_FIPS="$OUTPUT_DIR/$CLUSTER_NAME.$BASE_DOMAIN.fips"
echo "Exporting Floating IPs of API '$FIP_API' and *APPS '$FIP_APPS', and saving into: $CLUSTER_FIPS"

: > "$CLUSTER_FIPS"

echo "export FIP_API=$FIP_API" >> "$CLUSTER_FIPS"
echo "export FIP_APPS=$FIP_APPS" >> "$CLUSTER_FIPS"

cat "$CLUSTER_FIPS"

. "$CLUSTER_FIPS"

