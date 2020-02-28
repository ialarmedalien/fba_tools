#!/bin/bash

if [ -L $0 ] ; then
    script_dir=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    script_dir=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi
base_dir=$(cd $script_dir && cd .. && pwd);

if hash kb-sdk 2>/dev/null; then
   echo "using pre-installed kb-sdk"
else
    docker pull kbase/kb-sdk:latest
    docker run kbase/kb-sdk genscript > $base_dir/bin/kb-sdk
    chmod 755 $base_dir/bin/kb-sdk
    export PATH=$PATH:$base_dir/bin/kb-sdk
fi
