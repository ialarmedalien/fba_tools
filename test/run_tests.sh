#!/bin/bash
echo "Running $0 with args $@"

if [ -L $0 ] ; then
    script_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    script_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

export KB_DEPLOYMENT_CONFIG=$script_dir/../deploy.cfg
export KB_AUTH_TOKEN=`cat /kb/module/work/token`
export PERL5LIB=$script_dir/../lib:$PERL5LIB
cd $script_dir/..

echo "running perl .t tests"
prove -I test/lib -lvrm -j9 $script_dir
echo "running .pl tests"
prove -I test/lib -lvm --ext pl test
