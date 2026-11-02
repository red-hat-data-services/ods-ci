#!/usr/bin/env bash

set -euo pipefail
umask 077

GATEWAY_NAME="default-gateway"
INGRESS_NAMESPACE="openshift-ingress"
OAUTH_NAMESPACE="openshift-config"
OAUTH_SECRET="nip-secret"
PROVIDER_CA_SECRET="rhoai-oauth-provider-ca"
GATEWAY_ROUTE_NAME="data-science-gateway"
APPLICATIONS_NAMESPACE="${1:-redhat-ods-applications}"
DSCI_NAME="${2:-default-dsci}"
MODEL_REGISTRY_UI_DEPLOYMENT="model-registry-ui"
AUTH_PROXY_DEPLOYMENT="kube-auth-proxy"
WAIT_TIMEOUT="10m"

for command in oc base64 jq openssl timeout grep date; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

certificate_file="$tmp_dir/oauth.crt"
key_file="$tmp_dir/oauth.key"
ca_bundle_file="$tmp_dir/provider-ca.crt"
gatewayconfig_patch_file="$tmp_dir/gatewayconfig-patch.json"
dsci_patch_file="$tmp_dir/dsci-patch.json"
route_patch_file="$tmp_dir/route-patch.json"
existing_dsci_ca_bundle_file="$tmp_dir/existing-dsci-ca-bundle.crt"
dsci_ca_bundle_file="$tmp_dir/dsci-ca-bundle.crt"

echo "Waiting for the MAPT DSCI and GatewayConfig to be ready..."
oc wait --for=jsonpath='{.status.phase}'=Ready "dscinitialization/${DSCI_NAME}" \
  --timeout="$WAIT_TIMEOUT"
oc wait --for=condition=GatewayConfigReady "gatewayconfig/${GATEWAY_NAME}" \
  --timeout="$WAIT_TIMEOUT"

gateway_host=""
for attempt in {1..60}; do
  gateway_host="$(oc get route "$GATEWAY_ROUTE_NAME" -n "$INGRESS_NAMESPACE" \
    -o jsonpath='{.spec.host}' 2>/dev/null || true)"
  if [[ -n "$gateway_host" ]]; then
    break
  fi
  sleep 2
done

if [[ -z "$gateway_host" ]]; then
  echo "Route $INGRESS_NAMESPACE/$GATEWAY_ROUTE_NAME has no host" >&2
  exit 1
fi

oc get secret "$OAUTH_SECRET" -n "$OAUTH_NAMESPACE" \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > "$certificate_file"
oc get secret "$OAUTH_SECRET" -n "$OAUTH_NAMESPACE" \
  -o jsonpath='{.data.tls\.key}' | base64 -d > "$key_file"

if [[ ! -s "$certificate_file" || ! -s "$key_file" ]]; then
  echo "Secret $OAUTH_NAMESPACE/$OAUTH_SECRET must contain tls.crt and tls.key" >&2
  exit 1
fi

if ! openssl x509 -in "$certificate_file" -noout -ext subjectAltName \
    > "$tmp_dir/certificate-san.txt" 2>/dev/null ||
    ! grep -q "X509v3 Subject Alternative Name" "$tmp_dir/certificate-san.txt" ||
    ! grep -q "DNS:" "$tmp_dir/certificate-san.txt"; then
  echo "Certificate in $OAUTH_NAMESPACE/$OAUTH_SECRET has no valid SAN extension" >&2
  exit 1
fi

if ! openssl x509 -in "$certificate_file" -noout -checkend 0 >/dev/null 2>&1; then
  echo "Certificate in $OAUTH_NAMESPACE/$OAUTH_SECRET has expired" >&2
  exit 1
fi

not_before="$(openssl x509 -in "$certificate_file" -noout -startdate)"
not_before="${not_before#notBefore=}"
if ! not_before_epoch="$(date -u -d "$not_before" +%s 2>/dev/null)"; then
  echo "Unable to read notBefore for certificate in $OAUTH_NAMESPACE/$OAUTH_SECRET" >&2
  exit 1
fi
current_epoch="$(date -u +%s)"
if (( not_before_epoch > current_epoch )); then
  echo "Certificate in $OAUTH_NAMESPACE/$OAUTH_SECRET is not yet valid" >&2
  exit 1
fi

if ! openssl x509 -in "$certificate_file" -noout -checkhost "$gateway_host" \
    >/dev/null 2>&1; then
  echo "Certificate SAN does not cover gateway host $gateway_host" >&2
  exit 1
fi

certificate_public_key="$(openssl x509 -in "$certificate_file" -pubkey -noout |
  openssl pkey -pubin -outform DER | openssl dgst -sha256)"
private_key_public_key="$(openssl pkey -in "$key_file" -pubout -outform DER |
  openssl dgst -sha256)"
if [[ "$certificate_public_key" != "$private_key_public_key" ]]; then
  echo "Certificate and private key in $OAUTH_NAMESPACE/$OAUTH_SECRET do not match" >&2
  exit 1
fi

echo "Creating the provider CA secret..."
oc get configmap kube-root-ca.crt -n "$INGRESS_NAMESPACE" \
  -o jsonpath='{.data.ca\.crt}' > "$ca_bundle_file"
printf '\n' >> "$ca_bundle_file"
cat "$certificate_file" >> "$ca_bundle_file"
oc create secret generic "$PROVIDER_CA_SECRET" -n "$INGRESS_NAMESPACE" \
  --from-file=ca.crt="$ca_bundle_file" --dry-run=client -o yaml |
  oc apply -f -

jq -n --arg secret "$PROVIDER_CA_SECRET" \
  '{spec:{providerCASecretName:$secret}}' > "$gatewayconfig_patch_file"
oc patch gatewayconfig "$GATEWAY_NAME" --type=merge \
  --patch-file="$gatewayconfig_patch_file"

certificate="$(cat "$certificate_file")"
oc get dscinitialization "$DSCI_NAME" \
  -o jsonpath='{.spec.trustedCABundle.customCABundle}' \
  > "$existing_dsci_ca_bundle_file"
existing_dsci_ca_bundle="$(cat "$existing_dsci_ca_bundle_file")"
if [[ "$existing_dsci_ca_bundle" == *"$certificate"* ]]; then
  printf '%s\n' "$existing_dsci_ca_bundle" > "$dsci_ca_bundle_file"
elif [[ -n "$existing_dsci_ca_bundle" ]]; then
  printf '%s\n%s\n' "$existing_dsci_ca_bundle" "$certificate" \
    > "$dsci_ca_bundle_file"
else
  printf '%s\n' "$certificate" > "$dsci_ca_bundle_file"
fi

jq -n --rawfile certificate "$dsci_ca_bundle_file" \
  '{spec:{trustedCABundle:{customCABundle:$certificate}}}' > "$dsci_patch_file"
oc patch dscinitialization "$DSCI_NAME" --type=merge \
  --patch-file="$dsci_patch_file"

jq -n --rawfile certificate "$certificate_file" --rawfile key "$key_file" \
  '{spec:{tls:{certificate:$certificate,key:$key}}}' > "$route_patch_file"
oc patch route "$GATEWAY_ROUTE_NAME" -n "$INGRESS_NAMESPACE" \
  --type=merge --patch-file="$route_patch_file"

echo "Waiting for DSCI, GatewayConfig, and the trusted CA bundle to reconcile..."
oc wait --for=jsonpath='{.status.phase}'=Ready "dscinitialization/${DSCI_NAME}" \
  --timeout="$WAIT_TIMEOUT"
oc wait --for=condition=GatewayConfigReady "gatewayconfig/${GATEWAY_NAME}" \
  --timeout="$WAIT_TIMEOUT"

trusted_bundle=""
for attempt in {1..60}; do
  trusted_bundle="$(oc get configmap odh-trusted-ca-bundle \
    -n "$APPLICATIONS_NAMESPACE" \
    -o jsonpath='{.data.odh-ca-bundle\.crt}' 2>/dev/null || true)"
  if [[ "$trusted_bundle" == *"$certificate"* ]]; then
    break
  fi
  if [[ "$attempt" == 60 ]]; then
    echo "odh-trusted-ca-bundle did not receive the OAuth certificate in time" >&2
    exit 1
  fi
  sleep 2
done

expected_fingerprint="$(openssl x509 -in "$certificate_file" \
  -noout -fingerprint -sha256)"
echo "Waiting for the gateway route to serve the validated certificate..."
for attempt in {1..60}; do
  actual_fingerprint="$(timeout 10s openssl s_client -connect "${gateway_host}:443" \
    -servername "$gateway_host" -showcerts </dev/null 2>/dev/null |
    openssl x509 -noout -fingerprint -sha256 2>/dev/null || true)"
  if [[ "$actual_fingerprint" == "$expected_fingerprint" ]]; then
    break
  fi
  if [[ "$attempt" == 60 ]]; then
    echo "Gateway route $gateway_host did not start serving the configured certificate" >&2
    exit 1
  fi
  sleep 2
done

echo "Waiting for the GatewayConfig-managed authentication proxy rollout..."
oc rollout status "deployment/${AUTH_PROXY_DEPLOYMENT}" \
  -n "$INGRESS_NAMESPACE" --timeout="$WAIT_TIMEOUT"

if oc get deployment "$MODEL_REGISTRY_UI_DEPLOYMENT" \
    -n "$APPLICATIONS_NAMESPACE" >/dev/null 2>&1; then
  echo "Restarting model-registry-ui to load the trusted CA bundle..."
  oc rollout restart "deployment/${MODEL_REGISTRY_UI_DEPLOYMENT}" \
    -n "$APPLICATIONS_NAMESPACE"
  oc rollout status "deployment/${MODEL_REGISTRY_UI_DEPLOYMENT}" \
    -n "$APPLICATIONS_NAMESPACE" --timeout="$WAIT_TIMEOUT"
else
  echo "model-registry-ui deployment not found; skipping its rollout"
fi

echo "MAPT certificate trust and route configuration is ready."
