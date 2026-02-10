# Service Token Authentication Tests

This directory contains automated tests for Service Account Token Authentication through the OpenShift AI Gateway.

## What These Tests Validate

1. **Infrastructure Configuration**
   - kube-auth-proxy has `--enable-k8s-token-validation=true` flag
   - kube-auth-proxy uses dedicated ServiceAccount (not default)
   - ClusterRoleBinding grants `system:auth-delegator` permissions

2. **Functional Authentication**
   - Service accounts can authenticate via bearer tokens
   - Tokens are validated via Kubernetes TokenReview API
   - User identity is properly extracted from tokens
   - Auth headers are forwarded to upstream services

3. **Security**
   - Invalid tokens are rejected
   - Requests without tokens are challenged
   - Dedicated ServiceAccount scopes permissions appropriately

## Files Created

### Test Infrastructure
```
tests/Resources/Files/echo-service/
├── echo-deployment.yaml              # Echo service with kube-rbac-proxy sidecar
├── echo-httproute.yaml               # HTTPRoute to expose via gateway
├── test-serviceaccount.yaml          # Test ServiceAccount for tokens
└── test-serviceaccount-rbac.yaml     # RBAC permissions for test SA
```

### Test Resources (Keywords)
```
tests/Resources/CLI/
├── EchoService.resource         # Deploy/manage echo service
└── ServiceTokenAuth.resource    # Token creation and validation helpers
```

### Test Suite
```
tests/Tests/0100__platform/0101__deploy/0102__auth_providers_and_rbac/
└── 0104__service_token_auth.robot    # Test cases
```

### Convenience Scripts
```
run-service-token-tests.sh          # Wrapper script to run tests against current cluster
```

## Running the Tests

### Prerequisites
1. OpenShift AI or Open Data Hub cluster
2. Gateway deployed with service token auth enabled
3. Python 3.11 installed
4. Poetry 2.3+ installed (install via `curl -sSL https://install.python-poetry.org | python3 -`)
5. `oc` CLI configured and logged into the cluster

### Run All Service Token Auth Tests

**Quick Start (Recommended):**
```bash
# Use the wrapper script (automatically handles Poetry setup)
./run-service-token-tests.sh
```

**Or run manually:**
```bash
cd ods_ci

# Run the full test suite
sh run_robot_test.sh \
  --skip-oclogin true \
  --test-variable PRODUCT:ODH \
  --test-variable APPLICATIONS_NAMESPACE:opendatahub \
  --test-variable OPERATOR_NAMESPACE:openshift-operators \
  --test-case tests/Tests/0100__platform/0101__deploy/0102__auth_providers_and_rbac/0104__service_token_auth.robot
```

### Run Specific Tests by Tag

```bash
# Run smoke tests only
sh run_robot_test.sh --include ServiceTokenAuth AND Smoke

# Run E2E tests
sh run_robot_test.sh --include E2E

# Run security-focused tests
sh run_robot_test.sh --include Security

# Run negative test cases
sh run_robot_test.sh --include Negative
```

### Run a Single Test Case

```bash
sh run_robot_test.sh \
  --test "Verify Service Account Can Authenticate Via Token" \
  tests/Tests/0100__platform/0101__deploy/0102__auth_providers_and_rbac/0104__service_token_auth.robot
```

## Test Flow

1. **Suite Setup**
   - Deploy echo service with kube-rbac-proxy sidecar
     - Echo container: HTTP echo server on port 8080
     - kube-rbac-proxy sidecar: Enforces RBAC on port 8443
     - ServiceAccount with system:auth-delegator permissions
   - Create test ServiceAccount with proxy access permissions
   - Create HTTPRoute to expose echo service via gateway on `/echo` path
   - Wait for HTTPRoute to be accepted by gateway controller
   - Wait for Envoy configuration to propagate (5s)

2. **Test Execution**
   - Create service account token via `oc create token` (10m duration minimum)
   - Call gateway endpoint `https://<gateway-url>/echo` with bearer token
   - Verify HTTP 200 response with JSON body
   - Validate auth headers in JSON response:
     - `x-auth-request-user`: Service account identity
     - `x-auth-request-email`: Service account email
     - `x-auth-request-access-token`: Token forwarded
     - `x-forwarded-access-token`: Token forwarded

3. **Suite Teardown**
   - Remove HTTPRoute
   - Remove echo service deployment and service
   - Remove test ServiceAccount and RBAC
   - Remove ClusterRoleBinding

## Test Cases

| Test Case | Type | What It Tests |
|-----------|------|---------------|
| Verify Service Token Auth Is Enabled On Gateway | Config | `--enable-k8s-token-validation=true` flag present |
| Verify Dedicated ServiceAccount For Kube Auth Proxy | Security | Uses dedicated SA, not default |
| Verify ClusterRoleBinding For TokenReview | Config | Correct RBAC for TokenReview API |
| Verify Service Account Can Authenticate Via Token | E2E | Full authentication flow works |
| Verify Service Account Token Has User Identity | E2E | User identity extracted correctly |
| Verify Invalid Token Is Rejected | Negative | Invalid tokens don't authenticate |
| Verify No Token Results In Auth Challenge | Negative | Missing tokens are challenged |

## Echo Service Architecture

The test echo service mimics the architecture used by real ODH/RHOAI workloads:

```
┌─────────────────────────────────────────────────────────┐
│ echo-service Pod                                        │
│                                                         │
│  ┌──────────────────┐      ┌─────────────────────────┐ │
│  │ kube-rbac-proxy  │─────▶│   echo container        │ │
│  │  Port: 8443      │      │   Port: 8080            │ │
│  │  (TLS + RBAC)    │      │   (HTTP echo server)    │ │
│  └──────────────────┘      └─────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
                    ▲
                    │
         ┌──────────┴──────────┐
         │ HTTPRoute /echo     │
         │ → echo-service:8443 │
         └──────────┬──────────┘
                    │
         ┌──────────┴──────────────┐
         │ Gateway                  │
         │ (kube-auth-proxy)       │
         │ Token validation        │
         └─────────────────────────┘
```

**Key Components:**
- **kube-rbac-proxy sidecar**: Validates that the authenticated user (from gateway) has permission to access the service via RBAC
- **Echo container**: Simple HTTP server that echoes back request details including auth headers
- **HTTPRoute**: Routes `/echo` path through the gateway to the echo service
- **Test ServiceAccount**: Granted RBAC permissions to access `services/proxy` for `echo-service`

## Expected Results

All tests should **PASS** when:
- Service token auth feature is properly deployed
- Gateway is configured with kube-auth-proxy
- kube-auth-proxy has TokenReview permissions
- Echo service pods are running (2/2 containers ready)

## Troubleshooting

### Tests Fail: "Gateway URL not found"
Check that the Gateway route exists:
```bash
# The route provides the public ingress URL
oc get route data-science-gateway -n openshift-ingress
```

### Tests Fail: "Echo service not ready"
Check echo service deployment and pod status:
```bash
# Check deployment
oc get deployment echo-service -n opendatahub

# Check pods
oc get pods -n opendatahub -l app=echo-service

# Check logs from echo container
oc logs -n opendatahub -l app=echo-service -c echo

# Check logs from kube-rbac-proxy sidecar
oc logs -n opendatahub -l app=echo-service -c kube-rbac-proxy
```

### Tests Fail: "may not specify a duration less than 10 minutes"
Kubernetes requires tokens to have minimum 10-minute duration:
```bash
# Correct: 10m or longer
oc create token test-svc-token-auth -n opendatahub --duration=10m

# Incorrect: Less than 10m
oc create token test-svc-token-auth -n opendatahub --duration=5m
```

### Tests Fail: "Permission denied" or RBAC errors
Check that test ServiceAccount has proxy access:
```bash
# Check Role
oc get role test-svc-token-auth-echo-access -n opendatahub -o yaml

# Check RoleBinding
oc get rolebinding test-svc-token-auth-echo-access -n opendatahub -o yaml

# Check echo-service ServiceAccount has TokenReview permissions
oc get clusterrolebinding echo-service-tokenreview -o yaml
```

### Tests Fail: HTTPRoute not accepted
Check HTTPRoute status:
```bash
# Check if HTTPRoute is accepted
oc get httproute echo-service-route -n opendatahub -o yaml

# Look for Accepted condition in status
oc get httproute echo-service-route -n opendatahub \
  -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")]}'
```

### Tests return dashboard HTML instead of echo JSON
This usually indicates Envoy routing issue:
```bash
# Check HTTPRoute exists and is unique
oc get httproute -n opendatahub

# Verify echo-service-route points to correct backend
oc get httproute echo-service-route -n opendatahub \
  -o jsonpath='{.spec.rules[0].backendRefs[0]}'

# Manual test to verify routing
TOKEN=$(oc create token test-svc-token-auth -n opendatahub --duration=10m)
GATEWAY_URL=$(oc get route data-science-gateway -n openshift-ingress -o jsonpath='{.spec.host}')
curl -k -H "Authorization: Bearer $TOKEN" "https://${GATEWAY_URL}/echo" | jq .
```

## Implementation Notes

### HTTPRoute Acceptance Wait
The test suite waits for HTTPRoute to be accepted by the gateway controller before running tests. This ensures Envoy has the correct routing configuration:

```robot
Wait For HTTPRoute To Be Accepted
    [Arguments]    ${route_name}    ${namespace}    ${timeout}=60s
    Wait Until Keyword Succeeds    ${timeout}    5s    HTTPRoute Is Accepted    ${route_name}    ${namespace}
```

### Token Duration
Kubernetes enforces a minimum 10-minute token duration. The tests use this minimum:
```bash
oc create token test-svc-token-auth -n opendatahub --duration=10m
```

### Header Case Sensitivity
The echo service returns headers in lowercase when echoing back the JSON response. Tests check for lowercase header names:
- `x-auth-request-user` (not `X-Auth-Request-User`)
- `x-auth-request-email` (not `X-Auth-Request-Email`)
- `x-forwarded-access-token` (not `X-Forwarded-Access-Token`)

### Clean State
The suite setup always recreates resources (does not reuse existing deployments). This ensures consistent test results and proper validation of the full deployment flow.

## Integration with CI/CD

These tests can be integrated into ODH/RHOAI CI pipelines:

```yaml
# Example Jenkins/Tekton step
- name: Run Service Token Auth Tests
  script: |
    cd ods_ci
    sh run_robot_test.sh \
      --skip-oclogin true \
      --include ServiceTokenAuth \
      --output-dir ${WORKSPACE}/test-results
```

## Related Documentation

- [Service Token Auth PR](#) - Original feature implementation
- [ODS-CI Framework](../README.md) - General test framework docs
- [Robot Framework](https://robotframework.org/) - Test framework documentation
