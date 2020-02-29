#!/bin/bash
echo "Running $0 with args $@"

/Users/gwg/code/kbase/fba_tools/test_local/run_docker.sh run --rm -v /Users/gwg/code/kbase/fba_tools/test_local/subjobs/$1/workdir:/kb/module/work -v /Users/gwg/code/kbase/fba_tools/test_local/workdir/tmp:/kb/module/work/tmp $4 -e "SDK_CALLBACK_URL=$3" $2 async
