---
title: How to run ASP.NET Core eShopWeb sample in a local Kubernetes cluster
tags:
  - Kubernetes
  - ASP.NET Core
  - Rancher Desktop
---

Lately, I've been learning Kubernetes, arguably the most popular container orchestrator. Since I'm a .NET developer, I thought it would be helpful to try out what I'd learned so far by hosting the [eShopOnWeb](https://github.com/dotnet-architecture/eShopOnWeb) project on my local Kubernetes cluster. Let's walk through this together.

<!--more-->

- **Prerequisite setup**

First, fork and clone a copy of the [repository from GitHub](https://github.com/dotnet-architecture/eShopOnWeb) onto your local machine. The application comprises of a user-facing Blazor web app, including an admin view, along with a backing ASPNET Core API which uses a SQL Server database. Alternatively, you can use an in-memory database. There's also an Identity piece which enables Authentication and Authorization mechanisms. In my case, I decided to use an Azure SQL database and updated the connection strings in the `appsettings.json` files.

Next, run the EF Core migrations as outlined [here in the README](https://github.com/dotnet-architecture/eShopOnWeb#configuring-the-sample-to-use-sql-server). This will create the required databases and seed data into corresponding tables.

Test out the application by running the PublicAPI project and the Web projects.

<!--more-->

- **Kubernetes (k8s) setup and deployment**

Firstly, make sure you have the required tools setup, and you have a local Kubernetes cluster running. You can follow instructions to setup a local cluster [using Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation), which I prefer. Or you can use [docker with minikube](https://minikube.sigs.k8s.io/docs/start/).

> Tip: For Rancher Desktop, I setup an alias for `nerdctl` as `docker` so I could still use `docker` commands.

In order to make sure the path references work, we need to create separate `appsettings.json` for our Kubernetes deployments to use. Create the following files, pasting content from the main corresponding `appsettings.json`:

- `/src/BlazorAdmin/wwwroot/appsettings.Kubernetes.json`
- `/src/PublicApi/appsettings.Kubernetes.json`
- `/src/Web/appsettings.Kubernetes.json`

In each of the above files, modify the `apiBase` and `webBase` to point to the ingress controller host which we'll talk about later in the article, i.e:
```json
{
  "baseUrls": {
    "apiBase": "http://demo.localdev.me:8080/publicapi/api/",
    "webBase": "http://demo.localdev.me:8080/"
  },
  ...
}
```

Additionally, we need to reference this Kubernetes environment variable in the Blazor css/js links, i.e.

```xml
<environment include="Development,Docker,Kubernetes">
```

In the following files, add `Kubernetes` as an additional environment after `Docker`.
- `src/Web/Areas/Identity/Pages/_ValidationScriptsPartial.cshtml`
- `src/Web/Pages/Admin/Index.cshtml`
- `src/Web/Views/Shared/_Layout.cshtml`
- `src/Web/Views/Shared/_ValidationScriptsPartial.cshtml`

<!--more-->
**Building container images and deploying to cluster**

Next, build container images for both the PublicAPI and the Web projects based on the `Dockerfile`s in `src/PublicApi` and `src/WebApi` directories, i.e.:
- Web: `docker build -t eshop-web -f .\src\Web\Dockerfile .`
- PublicApi: `docker build -t eshop-api -f .\src\PublicApi\Dockerfile .`

Next, create a yaml deployment file for the PublicApi. This will create a k8s deployment along with a service.
> Please review the following articles about Deployments and Services:
> - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
> - https://kubernetes.io/docs/concepts/services-networking/service/

Notice the `image` name is named `eshop-api` to match the container image we built above.

***eshop-api.yml***

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eshop-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: eshop-api
  template:
    metadata:
      labels:
        app: eshop-api
    spec:
      containers:
      - name: eshop-api
        image: eshop-api
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        env:
          - name: ASPNETCORE_ENVIRONMENT
            value: Kubernetes
---
apiVersion: v1
kind: Service
metadata:
  name: eshop-api
spec:
  type: ClusterIP
  selector:
    app: eshop-api
  ports:
  - port: 80
    protocol: TCP
```

Additionally, let's create a deployment yaml file for the Web project:

<!--more-->
***eshop-web.yaml***

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eshop-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: eshop-web
  template:
    metadata:
      labels:
        app: eshop-web
    spec:
      containers:
      - name: eshop-web
        image: eshop-web
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        env:
          - name: ASPNETCORE_ENVIRONMENT
            value: Kubernetes
---
apiVersion: v1
kind: Service
metadata:
  name: eshop-web
spec:
  type: ClusterIP
  selector:
    app: eshop-web
  ports:
  - port: 80
    protocol: TCP
```

We set the `imagePullPolicy` to `Never`. This tells Kubernetes to not try pulling the image from a remote container registry, and to instead look for the image locally. You could alternatively push the image to a container registry like Dockerhub or Azure Container Registry and remove the `imagePullPolicy`.

The `ASPNETCORE_ENVIRONMENT` environment variable is used to make sure the apps use the corresponding `appsettings.json` file.


Next, run `kubectl apply -f eshop-api.yaml` and `kubectl apply -f eshop-web.yaml` to create the deployment/pods and services. You can confirm they are created by running `kubectl get deployments` and `kubectl get services`.

<!--more-->
**Setting up Ingress controllers**
> Prerequisites:
> Follow the corresponding articles referenced here to set up NGINX Ingress for your cluster:
> - Rancher Desktop -> https://docs.rancherdesktop.io/how-to-guides/setup-NGINX-Ingress-Controller/
> - minikube -> https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

Once you have enabled Ingress on your k8s cluster, create the following deployment yaml to deploy the ingress controllers:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eshop-ingress-api
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
  labels:
    name: eshop-ingress-api
spec:
  ingressClassName: nginx
  rules:
  - host: demo.localdev.me
    http:
      paths:
      - pathType: Prefix
        path: /publicapi(/|$)(.*)
        backend:
          service:
            name: eshop-api
            port: 
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eshop-ingress-web
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  labels:
    name: eshop-ingress-web
spec:
  ingressClassName: nginx
  rules:
  - host: demo.localdev.me
    http:
      paths:
      - pathType: Prefix
        path: /(.*)
        backend:
          service:
            name: eshop-web
            port: 
              number: 80         
```

To access the web app and the public api locally through the ingress, we need to use port forwarding, this can be done by running the following command:

`kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80`

Now, you should be able to access the web app by going to http://demo.localdev.me:8080/. The API can be accessed by going to http://demo.localdev.me:8080/publicapi

<!--more-->
**Source code**

You can access this code in [my GitHub fork of eShopWeb](https://github.com/levimatheri/eShopOnWeb) under the `kubernetes-hosting` branch. A commit outlining the changes outlined in this article is [here](https://github.com/levimatheri/eShopOnWeb/commit/d8cd813de6fe2a15cb16ba38d15bbc6d020651a6).


<!--more-->
Thanks for reading, and happy coding!