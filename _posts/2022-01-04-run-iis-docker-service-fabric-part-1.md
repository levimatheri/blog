---
title: How to run ASP.NET web application on Service Fabric using a docker container (Part 1)
tags:
  - Docker
  - Service Fabric
  - ASP.NET
  - IIS
---

I have recently been working on a project at work to migrate an [Umbraco v7](https://umbraco.com/) on-prem service to [Service Fabric](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-overview). Typically, we configure our Service Fabric applications using self-hosted [OWIN](https://github.com/uglide/azure-content/blob/master/articles/service-fabric/service-fabric-reliable-services-communication-webapi.md). However, Umbraco heavily utilizes `HttpContext` in their code, which is unavailable in the OWIN context, therefore this approach did not work.

Luckily, Service Fabric supports running docker containers in a highly available, distributed, and resilient environment. It is relatively simple to set up since Service Fabric provides most of the configuration needed to run the containers. Therefore I was able to take the existing WebAPI project, containerize it, and run it in Service Fabric.

I'll walk you through how to get a Web API up and running in a local Service Fabric cluster within a container.

<!--more-->

**Adding Service Fabric Container Orchestrator**

Visual Studio provides an easy way to configure Service Fabric as a container orchestrator. To do this, right-click on your existing Web API project, then click 'Add' -> 'Container Orchestator Support'. Select 'Service Fabric' then hit 'OK'. This should add a Service Fabric application project, as well as a Dockerfile and a Package Root folder in the WebAPI project.

<div class="card mb-3">
    <img class="card-img-top" src="https://raw.githubusercontent.com/levimatheri/blog/main/_includes/images/container_orchestrator_support.png"/>
    <div class="card-body bg-light">
        <div class="card-text">
            Add container orchestrator support
        </div>
    </div>
</div>

<div class="card mb-3">
    <img class="card-img-top" src="https://raw.githubusercontent.com/levimatheri/blog/main/_includes/images/service_fabric_orchestrator.png"/>
    <div class="card-body bg-light">
        <div class="card-text">
            Add Service Fabric container orchestrator support
        </div>
    </div>
</div>

The Dockerfile pulls from a .NET framework image provided by Microsoft, then copies your WebAPI files into the container under `/inetpub/wwwroot/` which is the typical IIS applications folder.

```docker
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
ARG source
WORKDIR /inetpub/wwwroot
COPY ${source:-obj/Docker/publish} .
```

The ApplicationManifest.xml in the Service Fabric application under the ApplicationPackageRoot folder has a `ContainerHostPolicies` section that provides port binding between the host and container.

```xml
<ContainerHostPolicies CodePackageRef="Code" Isolation="[MyTestAPI_Isolation]">
    <PortBinding ContainerPort="80" EndpointRef="MyTestAPITypeEndpoint" />
</ContainerHostPolicies>
```

You can change the `ContainerPort` if you want to have the container listen on a different port, however, to do that requires some additional IIS setup, which is discussed in the following section.

To run the application, you can set the Service Fabric application as the Startup project. This would attach a debugger that helps with stepping through your code during development.

You can also right click on your Service Fabric application and select 'Publish' to your local cluster.

<div class="card mb-3">
    <img class="card-img-top" src="https://raw.githubusercontent.com/levimatheri/blog/main/_includes/images/publish_application.png"/>
    <div class="card-body bg-light">
        <div class="card-text">
            Add container orchestrator support
        </div>
    </div>
</div>

<!--more-->

**Run container on a different port**
<!--more-->
By default the ASP.NET docker image is set up to run on port 80, therefore even if one changes the `PortBinding` in the Service Fabric application manifest, the container would not be listening on the custom port.

In order to achieve this, we need to create our own `ENTRYPOINT` and set up an IIS web binding for our desired port. We create a powershell script file called `init.ps1` and have it copied into the container. The Dockerfile would look like so:

```docker
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
ARG source

WORKDIR /inetpub/wwwroot
COPY ${source:-publish} .

WORKDIR /
COPY init.ps1 .

EXPOSE 8080
ENTRYPOINT ["powershell.exe", "C:\\init_local.ps1", "8080"]
```

The powershell script would look like so:

```powershell
Param(
   [Parameter(Mandatory=$true)]
   [string]$portNumberStr
)

Write-Host "Setting up IIS..." -ForegroundColor Magenta

$websiteName = "Default Web Site"  

Import-Module WebAdministration

Write-Host "Binding http to container listening port $portNumberStr..." -ForegroundColor Magenta
$portNumber = [int]$portNumberStr
New-WebBinding -Name $websiteName -IP "*" -Port $portNumber -Protocol http

#Ensure Application Initialization is available
$webAppInit = Get-WindowsFeature -Name "Web-AppInit"

if(!$webAppInit.Installed) 
{
    Write-Host "$($webAppInit.DisplayName) not present, installing"
    Install-WindowsFeature $webAppInit -ErrorAction Stop
    Write-Host "`nInstalled $($webAppInit.DisplayName)`n" -ForegroundColor Green
}
else 
{
    Write-Host "$($webAppInit.DisplayName) was already installed" -ForegroundColor Yellow
}
 
$appPool = Get-Item IIS:\Sites\$websiteName | Select-Object applicationPool  
$appPoolName = $appPool.applicationPool  
    
Set-ItemProperty IIS:\Sites\$websiteName -Name applicationDefaults.preloadEnabled -Value True
Set-ItemProperty IIS:\AppPools\$appPoolName -Name autoStart -Value True  
Set-ItemProperty IIS:\AppPools\$appPoolName -Name startMode -Value 1
Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout -Value "00:00:00" 

Write-Host "Completed initialization successfully!" -ForegroundColor Green

Write-Host "Starting service monitor for IIS service" -ForegroundColor Magenta

# Start service monitor for IIS service
C:\ServiceMonitor.exe w3svc
```

In the script, we add the port binding and also set up Application Initialization settings.
Now, we can update our port binding to this:

```xml
<ContainerHostPolicies CodePackageRef="Code" Isolation="[MyTestAPI_Isolation]">
    <PortBinding ContainerPort="8080" EndpointRef="MyTestAPITypeEndpoint" />
</ContainerHostPolicies>
```

It's good practice to configure a health check for your container so that if it's unhealthy, a warning state can be reported to the Service Fabric cluster. To do this, add a `HEALTHCHECK` in the Dockerfile as so:

```docker
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019
ARG source

WORKDIR /inetpub/wwwroot
COPY ${source:-publish} .

WORKDIR /
COPY init_local.ps1 .

HEALTHCHECK --interval=3m --timeout=1m \
  CMD curl.exe -f -k http://localhost:8080/api/public/ping || exit 1

EXPOSE 8080
ENTRYPOINT ["powershell.exe", "C:\\init_local.ps1", "8080"]
```

To configure this on Service Fabric, add the following under `ContainerHostPolicies`:
```xml
<HealthConfig RestartContainerOnUnhealthyDockerHealthStatus="true" />
```

The health check tries to access an endpoint in the API every 3 minutes with a timeout of 1 minute. If it fails, it reports the state as _unhealthy_, and propagates this event to the Service Fabric cluster. Service Fabric then tries to restart the container to mitigate the issue.

Next time, we'll go through how to set up https for the container using Managed Identity and Key Vault.

Thanks for reading!