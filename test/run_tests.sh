#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export KB_DEPLOYMENT_CONFIG=$script_dir/../deploy.cfg
export KB_AUTH_TOKEN=`cat /kb/module/work/token`
export PERL5LIB=$script_dir/../lib:$PERL5LIB
cd $script_dir/..

env

echo "running perl .t tests"
prove -I test/lib -lvrm -j9 test
echo "running .pl tests"
prove -I test/lib -lvm --ext pl test
