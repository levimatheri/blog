---
title: Generating Storage Account SAS Token in Linked ARM Templates
tags:
  - Azure
  - ARM Templates
---

One of the main challenges when setting up [Linked ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates?tabs=azure-powershell#linked-template) is how to store the templates so that they are accessible by ARM without making them completely public. Microsoft recommends storing the templates in an Azure Storage Account and securing them with a SAS token.
Shared Access Signature (SAS) tokens provide secure access to Azure Storage Account. The scope of the access can be limited to the account, containers, or objects.
You can read more about SAS tokens [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview).

<!--more-->
Until recently, one had to either use a Powershell script or a [Copy to blob storage](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-file-copy?view=azure-devops) in Devops. However, you can now use the [linkAccountSas](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-resource#list-example) function within the ARM template itself.
You can set the SAS token properties based on the access you want to give. Below are some common properties:

1. **signedServices**: Storage service to access - 'b' (blob), 'f' (file), 't' (table), 'q' (queue)
2. **signedPermission**: Type of permission - 'r' (read), 'w' (write), 'd' (delete), 'l' (list)
3. **signedExpiry**: Expiration datetime of the token. You can use the [`utcNow('u')`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-date) function to dynamically create the expiration date
4. **signedResourceTypes**: Scope - 's' (service), 'c' (container), 'o' (object)

You can also add other properties like **signedIP** to restrict access by IP address or range.

See below for an example:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "LinkedTemplateBaseUrl": {
            "type": "string",
            "metadata": {
                "description": "Base url for the linked templates"
            }
        },
        "StorageAccountName": {
            "type": "string",
            "metadata": {
                "description": "Storage account for the linked templates"
            }
        },
        "CurrentTime": {
            "type": "string",
            "defaultValue": "[utcNow('u')]"
        }
    },
    "variables": {
        "SasTokenProperties": {
            "signedServices": "b",
            "signedPermission": "r",
            "signedExpiry": "[dateTimeAdd(parameters('CurrentTime'), 'PT30M')]",
            "signedResourceTypes": "o"
        }
    },
    "resources": [
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2020-10-01",
            "name": "templateDeployment",
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[concat(parameters('LinkedTemplateBaseUrl'), '/yetanother.template.json?', listAccountSas(resourceId('Microsoft.Storage/storageAccounts', parameters('StorageAccountName')), '2020-10-01', variables('SasTokenProperties')).accountSasToken)]",
                    "contentVersion": "1.0.0.0"
                },
                "parametersLink": {
                    "uri": "[concat(parameters('LinkedTemplateBaseUrl'), '/yetanother.parameters.json?', listAccountSas(resourceId('Microsoft.Storage/storageAccounts', parameters('StorageAccountName')), '2020-10-01', variables('SasTokenProperties')).accountSasToken)]",
                    "contentVersion": "1.0.0.0"
                }
            }
        }
    ]
}
```