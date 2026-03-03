# Service Token Authentication Tests

Automated tests for Service Account Token Authentication through the OpenShift AI Gateway using the dashboard (already deployed during tests).

## What These Tests Validate

1. **Infrastructure Configuration**
   - kube-auth-proxy has `--enable-k8s-token-validation=true` flag
   - kube-auth-proxy uses dedicated ServiceAccount (not default)
   - ClusterRoleBinding grants `system:auth-delegator` permissions

2. **Functional Authentication**
   - Service accounts can authenticate via bearer tokens
   - Tokens are validated via Kubernetes TokenReview API
   - Valid token returns HTTP 200 when calling the dashboard
   - `/api/status` returns `kube.userName` matching the service account when authenticated via Bearer token

3. **Security**
   - Invalid tokens are rejected (403 or 302)
   - Requests without tokens are challenged (403 or 302)
   - Dedicated ServiceAccount scopes permissions appropriately

## Files

### Test Resources (Keywords)
```
tests/Resources/CLI/
└── ServiceTokenAuth.resource    # Token creation, gateway calls, validation
```

### Test Suite
```
tests/Tests/0100__platform/0101__deploy/0102__auth_providers_and_rbac/
└── 0104__service_token_auth.robot    # Test cases
```

## Running the Tests

### Prerequisites
1. OpenShift AI or Open Data Hub cluster
2. Gateway deployed with service token auth enabled
3. Dashboard already deployed (typical during test runs)
4. Python 3.11 installed
5. Poetry 2.3+ installed (install via `curl -sSL https://install.python-poetry.org | python3 -`)
6. `oc` CLI configured and logged into the cluster

### Run All Service Token Auth Tests

```bash
cd ods_ci

sh run_robot_test.sh \
  --skip-oclogin true \
  --test-variable PRODUCT:ODH \
  --test-variable APPLICATIONS_NAMESPACE:opendatahub \
  --test-variable OPERATOR_NAMESPACE:openshift-operators \
  --test-case tests/Tests/0100__platform/0101__deploy/0102__auth_providers_and_rbac/0104__service_token_auth.robot
```

## Test Flow

1. **Config Tests**
   - Verify kube-auth-proxy has token validation enabled
   - Verify dedicated ServiceAccount
   - Verify ClusterRoleBinding for TokenReview

2. **E2E Tests** (use dashboard at gateway root)
   - Create test ServiceAccount if needed
   - Create token via `oc create token` (10m duration minimum)
   - Call dashboard (`/`) with Bearer token
   - Verify HTTP 200 (valid token), 403/302 (invalid or missing token)
   - Call `/api/status` with Bearer token and verify `kube.userName` matches service account

3. **Suite Setup/Teardown**
   - Suite Setup: RHOSi Setup
   - Suite Teardown: RHOSi Teardown
   - Tests use the dashboard already deployed by the operator
   - No custom workloads or HTTPRoute deployment

## Test Cases

| Test Case | Type | What It Tests |
|-----------|------|---------------|
| Verify Service Token Auth Is Enabled On Gateway | Config | `--enable-k8s-token-validation=true` flag present |
| Verify Dedicated ServiceAccount For Kube Auth Proxy | Security | Uses dedicated SA, not default |
| Verify ClusterRoleBinding For TokenReview | Config | Correct RBAC for TokenReview API |
| Verify Service Account Can Authenticate Via Token | E2E | Valid token returns 200 when calling dashboard |
| Verify API Status Returns Service Account Identity | E2E | /api/status returns userName matching the service account |
| Verify Invalid Token Is Rejected | Negative | Invalid tokens return 403 or 302 |
| Verify No Token Results In Auth Challenge | Negative | Missing token returns 403 or 302 |

## Dashboard-Based Approach

Tests call the dashboard at the gateway root (`/`). The dashboard is already deployed during typical test runs, so no custom workloads (echo service, InferenceService) are needed. Verification is simplified to HTTP status codes only (200 for success, 403/302 for auth challenge).

## Expected Results

All tests should **PASS** when:
- Service token auth feature is properly deployed
- Gateway is configured with kube-auth-proxy
- kube-auth-proxy has TokenReview permissions
- Dashboard is deployed and accessible

## Troubleshooting

### Tests Fail: "Gateway URL not found"
Check that ODH_DASHBOARD_URL is set or the Gateway exists:
```bash
oc get gateway data-science-gateway -n openshift-ingress
```

### Tests Fail: "may not specify a duration less than 10 minutes"
Kubernetes requires tokens to have minimum 10-minute duration:
```bash
# Correct: 10m or longer
oc create token test-svc-token-auth -n opendatahub --duration=10m
```

### Manual Test
```bash
# Get gateway host from ODH_DASHBOARD_URL or gateway resource
TOKEN=$(oc create token test-svc-token-auth -n opendatahub --duration=10m)
curl -k -s -i -H "Authorization: Bearer $TOKEN" "https://<GATEWAY_HOST>/"
# Expect HTTP 200
```

## Integration with CI/CD

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

- [ODS-CI Framework](../README.md) - General test framework docs
- [Robot Framework](https://robotframework.org/) - Test framework documentation
