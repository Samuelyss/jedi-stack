#!/bin/bash

# tkdiff is a side-by-side diff viewer, editor, and merge provider
# this script installs into /usr/local/bin so it requires root privileges

set -ex

name="tkdiff"
version=$1

if $MODULES; then
    prefix="${PREFIX:-"/opt/modules"}/core/$name/$version"
    if [[ -d $prefix ]]; then
        [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
            || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi
else
    prefix="/usr/local"
fi

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}

software=tkdiff-$(echo $version | sed 's/\./-/g')
url="https://sourceforge.net/projects/tkdiff/files/tkdiff/$version/$software.zip"
[[ -d $software ]] || (wget $url; unzip $software.zip)
$SUDO mkdir -p $prefix/bin
$SUDO mv $software/tkdiff $prefix/bin

# generate modulefile from template
$MODULES && update_modules core $name $version

exit 0
