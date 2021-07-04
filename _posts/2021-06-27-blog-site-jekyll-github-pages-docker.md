---
title: How I built this blog site with Jekyll, Docker-Compose, and Github Pages
tags:
  - Jekyll
  - Docker-Compose
  - Github Pages
---

It started with me hoping to start a blog site because I thought it would be cool to have one. However, I didn't want to go through the hassle
of setting up a web application to host the site, which would need a database to host the content. After some digging, I came across [Jekyll](https://jekyllrb.com/).
Setting up a blog site using Jekyll is a piece of cake! All the posts are just markdown files (text files on steroids), and you can get up and running with a [curated
prebuilt assortment of themes](http://jekyllthemes.org/).
Kudos to the [creators of Jekyll](https://jekyllrb.com/team/)!

<!--more-->

So once I had a [Jekyll theme](http://jekyllthemes.org/themes/friday-theme/) downloaded and a repo set up, I gasped at the [requirements](https://jekyllrb.com/docs/installation/) I had to have installed on my machine before I could run the site. I did not want to have to download Ruby and C++ tools (no hassles allowed). Luckily, there is Docker images for Jekyll created by amazing folks; see their [GitHub repo](https://github.com/envygeeks/jekyll-docker). I decided that the [minimal image version](https://hub.docker.com/r/jekyll/minimal) would serve me well.

<!--more-->

Below is my docker-compose yml file for production

_docker-compose.yml_

```yaml
version: '3'
services:
    jekyll-serve:
        image: jekyll/minimal:pages
        volumes:
            - '.:/srv/jekyll:cached'
        ports:
            - 4000:4000
        command: 'jekyll serve' 
```

Launching the site is as easy as running `docker-compose up`.

<!--more-->

One thing I had to change was the `baseUrl` in the `_config.yml` for Jekyll since it was pointing to `/friday_theme` from the downloaded theme. I set it to `""` and replaced all
instances of `/friday-theme` in the repo with the empty string. This worked fine when I ran `docker-compose up` and launched the site on my local machine. However, after deploying to 
GitHub pages, the css and js were not loaded causing the site to look horrendous.
So after some troubleshooting, I realized that for the css and js to render in prod, I had to set the `baseUrl` to `"/"`. What I ended up having are the `_config.yml` for prod having `baseUrl` set to `"/"` and a `_config.dev.yml` for testing having `baseUrl` set to `""`. I also have a `docker-compose.dev.yml` file that I've been using for testing. See below:

_docker-compose.dev.yml_

```yaml
version: '3'
services:
    jekyll-serve:
        image: jekyll/minimal:pages
        volumes:
            - '.:/srv/jekyll:cached'
        ports:
            - 4000:4000
        command: 'jekyll serve --watch --force_polling --config _config.dev.yml' 
```

In order to use the dev version of docker-compose, I run `docker-compose -f docker-compose.dev.yml up`.
The `--watch` and `--force_polling` flags are helpful for hotreloading the site, enabling you to see instant changes as you work on your site. See full configuration options list [here](https://jekyllrb.com/docs/configuration/options/).

<!--more-->

Once I had tested my site locally, I created a [repo](https://github.com/levimatheri/blog) on GitHub, and then under *Settings* -> *Pages*, I configured the site to build from the `main` branch.

<div class="card mb-3">
    <img class="card-img-top" src="https://raw.githubusercontent.com/levimatheri/blog/main/_includes/images/github_pages_setup.PNG"/>
    <div class="card-body bg-light">
        <div class="card-text">
            GitHub Pages setup.
        </div>
    </div>
</div>

<!--more-->

And that's it!

Thanks for reading.
