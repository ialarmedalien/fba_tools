#!/bin/bash
echo "Running $0 with args $@"

if [ -L $0 ] ; then
    script_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    script_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

base_dir=$(cd $script_dir && cd .. && pwd);

cd $base_dir
$script_dir/run_docker.sh run -v $script_dir/workdir:/kb/module/work -v $base_dir:/kb/module -e "SDK_CALLBACK_URL=$1" test/fba_tools:latest test
