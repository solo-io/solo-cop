# Get gateway config to inspect config issues locally

To run the script:

```bash
./get-gateway-conigs.sh
```

Output

```bash
[INFO] Gateway specific Custom Resources saved in: all-gateway-related-custom-resources-20260119130244.yaml
```

## Extracting and organizing the custom resources

Please run the [extract-files-from-yaml.sh](../extract-files-from-yaml/extract-files-from-yaml.sh) script

To run:

Copy the [extract-files-from-yaml.sh](../extract-files-from-yaml/extract-files-from-yaml.sh) script to the path where the `all-gateway-related-custom-resources-20260119130244.yaml` file got created and run the following

```bash
./extract-files-from-yaml.sh all-gateway-related-custom-resources-20260119130244.yaml
```

Output:

```bash
Extracting YAML resources from all-gateway-related-custom-resources-20260119130244.yaml...
Organizing files into directories...
Processing files: 14/14 (100%)
Extraction complete! Files organized in: extracted-files-from-all-gateway-related-custom-resources-20260119130244

Summary of extracted resources:
   3 GatewayClass
   2 HTTPRoute
   2 Gateway
   2 EnterpriseKgatewayTrafficPolicy
   1 HTTPListenerPolicy
   1 EnterpriseAgentgatewayParameters
   1 AuthConfig
   1 AgentgatewayBackend
   1 _.yml
```

`tree` output shows the output folder structure:

```bash
├── _.yml
├── AgentgatewayBackend
│   └── AgentgatewayBackend_openai-all-models.yml
├── AuthConfig
│   └── AuthConfig_apikey-auth.yml
├── EnterpriseAgentgatewayParameters
│   └── EnterpriseAgentgatewayParameters_agentgateway-params.yml
├── EnterpriseKgatewayTrafficPolicy
│   ├── EnterpriseKgatewayTrafficPolicy_httpbin-response-transformation.yml
│   └── EnterpriseKgatewayTrafficPolicy_test-extauth-policy.yml
├── Gateway
│   ├── Gateway_agentgateway.yml
│   └── Gateway_http.yml
├── GatewayClass
│   ├── GatewayClass_enterprise-agentgateway-waypoint.yml
│   ├── GatewayClass_enterprise-agentgateway.yml
│   └── GatewayClass_enterprise-kgateway.yml
├── HTTPListenerPolicy
│   └── HTTPListenerPolicy_access-logs.yml
└── HTTPRoute
    ├── HTTPRoute_httpbin.yml
    └── HTTPRoute_openai.yml

9 directories, 14 files
```
