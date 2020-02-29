#!/bin/bash
echo "Running $0 with args $@"

if [ -L $0 ] ; then
    script_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    script_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi
base_dir=$(cd $script_dir && cd .. && pwd);
cd $base_dir

$script_dir/run_docker.sh run -i -t -v $script_dir/workdir:/kb/module/work \
 -v $base_dir:/kb/module test/fba_tools:latest bash
# fbatools:local bash
