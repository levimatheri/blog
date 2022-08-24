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

- **Kubernetes setup**

Firstly, make sure you have the required tools setup, and you have a local Kubernetes cluster running. You can follow instructions to setup a local cluster [using Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation), which I prefer. Or you can use [docker with minikube](https://minikube.sigs.k8s.io/docs/start/).