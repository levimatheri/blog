#!/bin/bash

rm -f Gemfile
rm -f Gemfile.lock
bundle init
touch Gemfile.lock
chmod a+w Gemfile.lock
chmod 777 Gemfile
bundle add webrick
bundle add jekyll-watch
bundle add kramdown-parser-gfm
bundle add kramdown rouge