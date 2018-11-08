#!/bin/bash

./build.sh
cd ../new-pipeline
git pull origin master
git tag test-myservice-simpleBuildDeploy-${1}
git push origin master --tags
cd ../bootstrap
