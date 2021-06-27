---
layout: defaults/page
permalink: index.html
narrow: true
title: Home
---

Hello there!

I will post content about projects I'm working on and whatever stumbling blocks I've encountered and how I've solved them.


### Recent Posts

{% for post in site.posts limit:3 %}
{% include components/post-card.html %}
{% endfor %}