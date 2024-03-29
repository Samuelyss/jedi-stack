#!/bin/bash

set -ex

name="eigen"
version=$1

[[ $USE_SUDO =~ [yYtT] ]] && export SUDO="sudo" || unset SUDO

# this is only needed if MAKE_CHECK is enabled
if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$COMPILER
    module load boost-headers
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/core/$name/$version"
    if [[ -d $prefix ]]; then
	[[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix ) \
            || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi

else
    prefix="/usr/local"
fi    

cd $JEDI_STACK_ROOT/${PKGDIR:-"pkg"}

software="eigen-eigen-b3f3d4950030"
url="https://bitbucket.org/eigen/eigen/get/$version.tar.gz"
[[ -d $software ]] || ( wget $url; tar -xf $version.tar.gz )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
[[ -d build ]] && rm -rf build
mkdir -p build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix
[[ $MAKE_CHECK =~ [yYtT] ]] && make check
$SUDO make install

# generate modulefile from template
$MODULES && update_modules core $name $version

exit 0
