---
title: How to parameterize Azure API management policy files when using Bicep
tags:
  - Azure
  - Bicep
  - API management
---

I recently started working with Bicep to setup deployments of APIs to Azure. [Bicep modules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules) provide an easy-to-manage process when single-API deployment is needed.

<!--more-->
In most cases, we need to customize the policy files (API level, or operation level) to accommodate different environments. For example, in the following simple policy, we might want to replace the value with "abc" in development environment, but use "def" in production environment.

```xml
<policies>
    <inbound>
        <base />
        <find-and-replace from="xyz" to="abc" />
    </inbound>
</policies>
```

Imagine our Bicep looks like this:

```typescript
param apiName string

module api 'api.module.bicep' = {
  name: '${apiName}-API'
  params: {
    apiManagementServiceName: apimServiceName
    name: apiName
    ...
    policy: {
      format: 'rawxml'
      value: loadTextContent('policies/apiPolicy.xml')
    }
  }
}
```

...and the API module looks like this:

```typescript
param policy object = {}
...
// API policy
resource api_policy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = if (!empty(policy)) {
  name: 'policy'
  parent: api
  properties: {
    format: contains(policy, 'format') ? policy.format : 'rawxml'
    value: policy.value
  }
}
```

The simplest way would be to create a policy.xml file for each environment and then use a conditional in the Bicep to select which policy to use, i.e.

```xml
<!-- DEV policy-->
<policies>
    <inbound>
        <base />
        <find-and-replace from="xyz" to="abc" />
    </inbound>
</policies>
```

```xml
<!-- PROD policy-->
<policies>
    <inbound>
        <base />
        <find-and-replace from="xyz" to="def" />
    </inbound>
</policies>
```


```typescript
param apiName string
@allowed([
  'DEV'
  'PROD'
])
param environment string

module api 'api.module.bicep' = {
  name: '${apiName}-API'
  params: {
    apiManagementServiceName: apimServiceName
    name: apiName
    ...
    policy: {
      format: 'rawxml'
      value: environment == 'DEV' ? loadTextContent('policies/apiPolicy.DEV.xml') : loadTextContent('policies/apiPolicy.PROD.xml')
    }
  }
}
```

However this doesn't scale well, and you have to create a policy.xml file for each environment, even when they don't differ by much.

<!--more-->
A better way is to introduce parameterization within the policy file itself, i.e.

```xml
<policies>
    <inbound>
        <base />
        <find-and-replace from="xyz" to="$(replacement)" />
    </inbound>
</policies>
```

Then we can introduce the replacement parameter when we pass the module parameters for the policy, i.e.

```typescript
param apiName string
param replacement string

module api 'api.module.bicep' = {
  name: '${apiName}-API'
  params: {
    apiManagementServiceName: apimServiceName
    name: apiName
    ...
    policy: {
      format: 'rawxml'
      value: loadTextContent('policies/apiPolicy.xml')
      params: {
        replacement: replacement
      }
    }
  }
}
```

...and then use the [`reduce` function](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-lambda#reduce) in the module to do the string replacement:

```typescript
param policy object = {}
...
// API policy
resource api_policy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = if (!empty(policy)) {
  name: 'policy'
  parent: api
  properties: {
    format: contains(policy, 'format') ? policy.format : 'rawxml'
    value: !contains(policy, 'params') ? policy.value : reduce(items(policy.params), policy.value, (result, param) => replace(string(result), '\$(${param.key})', param.value))
  }
}
```

Hope this helps, thanks for reading!