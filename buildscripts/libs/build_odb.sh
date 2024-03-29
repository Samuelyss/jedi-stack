#!/bin/bash

set -ex

name="odb-api"
version=$1

# Hyphenated version used for install prefix
compiler=$(echo $COMPILER | sed 's/\//-/g')
mpi=$(echo $MPI | sed 's/\//-/g')

[[ $MAKE_VERBOSE =~ [yYtT] ]] && verb="VERBOSE=1" || unset verb

if $MODULES; then
    set +x
    source $MODULESHOME/init/bash
    module load jedi-$COMPILER
    module load jedi-$MPI
    module load ecbuild
    module load netcdf
    module load eckit
    
    module list
    set -x

    prefix="${PREFIX:-"/opt/modules"}/$compiler/$mpi/$name/$version"
    if [[ -d $prefix ]]; then
	[[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!";$SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                                   || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
    fi
    
else
    prefix="/usr/local"
fi
    
export FC=$MPI_FC
export CC=$MPI_CC
export CXX=$MPI_CXX

export F9X=$FC
export FFLAGS="-fPIC"
export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC -std=c++11"
export FCFLAGS="$FFLAGS"

cd ${JEDI_STACK_ROOT}/${PKGDIR:-"pkg"}

software=odb_api_bundle-$version-Source
[[ -d $software ]] || ( curl -s https://confluence-test.ecmwf.int/download/attachments/61117379/$software.tar.gz | tar xvz )
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
sed -i -e '/^ecbuild_bundle.* ecbuild /s/^/#/' CMakeLists.txt
sed -i -e '/^ecbuild_bundle.* eckit /s/^/#/' CMakeLists.txt
sed -i -e '/^ecbuild_bundle.* metkit /s/^/#/' CMakeLists.txt
[[ -d build_metkit ]] && $SUDO rm -rf build_metkit
[[ -d build_odb ]] && $SUDO rm -rf build_odb
mkdir -p build_metkit build_odb
cd build_metkit
ecbuild --build=Release --prefix=$prefix -DENABLE_GRIB=OFF -DCMAKE_CXX_FLAGS=${CXXFLAGS} \
         -DHAVE_CXX11=1 ../metkit
make $verb -j${NTHREADS:-4}
$SUDO make install
cd ../build_odb
ecbuild --build=Release --prefix=$prefix -DENABLE_FORTRAN=1 -DENABLE_PYTHON=1 -DHAVE_CXX11=1 \
        -DMETKIT_PATH=$prefix --DCMAKE_CXX_FLAGS=${CXXFLAGS} ..
make $verb -j${NTHREADS:-4}
$SUDO make install

# generate modulefile from template
$MODULES && update_modules mpi $name $version

exit 0
