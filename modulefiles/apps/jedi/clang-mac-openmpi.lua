help([[
Load environment for running JEDI applications with clang/gfortran compilers and OpenMPI on Mac OS-X.
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

conflict(pkgName)

load("jedi-clang/10.0.0")
load("szip/2.1.1")
load("jedi-openmpi/3.1.2")

load("hdf5/1.10.3")
load("pnetcdf/1.11.1")
load("netcdf/4.6.1")

load("lapack/3.7.0")
load("boost-headers/1.68.0")
load("eigen/3.3.5")

load("ecbuild/2.9.0")
load("eckit/0.23.0")
load("fckit/jcsda-develop")

whatis("Name: ".. pkgName)
whatis("Version: ".. pkgVersion)
whatis("Category: Application")
whatis("Description: JEDI Environment with clang/OpenMPI")
