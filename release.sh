#!/bin/bash

cd $(dirname $0)
release_name=$(basename $PWD)
cd ..
zip -r ~/tmp/$release_name.zip $release_name/[^.r]*
