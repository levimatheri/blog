# Blog

This repo contains files for my [blog site](https://levimatheri.github.io/blog/). It is built using [Jekyll](https://jekyllrb.com/), [Friday Theme](https://github.com/sfreytag/friday-theme), and [Docker Compose](https://docs.docker.com/compose/).

## How to run
### Prerequisites
1. Docker/Docker Desktop
2. Fork and clone the repo
### Steps to run the site
* Using Docker Desktop
1. Ensure Docker service is running
2. On a terminal, `cd` into the root of the repo
3. Run `docker-compose -f docker-compose.dev.yml up` 
4. Once the container is running, launch a tab on your browser and go to `localhost:4000`

* Using Rancher Desktop
1. Ensure Rancher Desktop is running
2. On a terminal, `cd` into the root of the repo
3. Run `nerdctl compose -f docker-compose.dev.yml up`. You can also set up an alias for `nerdctl` to use `docker` if you'd like
