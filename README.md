# Software Stack for JEDI applications

This repository provides a unified, module-based build system for building the JEDI software stack.
The motivation is to define a common set of software packages and versions to be used for applications, development, testing and across multiple platforms including software containers (Docker, Singularity, Charliecloud), cloud computing instances (e.g. AWS, Azure, Google), and HPC systems (e.g. NOAA, NASA, NCAR).

We want to provide a common set of software libraries to JEDI users and developers in order to minimize problems associated with incompatible or outdated software versions.  However, we also wish to take advantage of site-specific configurations and optimizations that exploit the local hardware.  For this reason, the build process is designed to use native installations of the compiler suite and the MPI libraries.  The rest of the software stack is build from source for the specified compiler/mpi combination.

Building the JEDI software stack is a **Four-Step process**, as described in the following sections.

## Step 1: Set up Basic Environment

This is the most context-dependent part of the build process.  How you proceed depends on the system you are on.  Regardless of how you proceed, this step only needs to be done once for each system.

Note - you can skip this step and move on to Step 2 if you are building a JEDI software container because all of the required software packages are already built into the jcsda/docker_base container, which you can just pull from Docker Hub.

This step is most important for bare linux/unix systems, as you would get with a new cloud computing instance, a container build, or a virtual machine (e.g. [vagrant](https://www.vagrantup.com)).  For such systems, Step 1 consists of running the following script (all paths are relative to the base path of the jedi-stack repository):
```
cd buildscripts
./setup_environment.sh <platform>
```
where `<platform>` depends on your operating system and the context of the build (for example, if you're in a container or on the cloud or on an HPC system).  Examples include `docker-devel` or `ubuntu/18.04`.  To see a list of supported options, run the script without any arguments:
```
./setup_environment.sh 
```
**Warning: for some (not all) options, running this script requires root privileges.**

The purpose of this script is to install some basic software packages, the most important of which are:
* GNU compiler suite (gcc, g++, gfortran)
* [Lmod](https://lmod.readthedocs.io/en/latest/index.html) module management system
* git, [git-lfs](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/developer/developer_tools/gitlfs.html), and [git-flow](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/developer/developer_tools/getting-started-with-gitflow.html)
* wget and curl
* make and [CMake](https://cmake.org)
* [doxygen](http://www.doxygen.nl) and [graphviz](https://www.graphviz.org)
* Debugging tools, including [kdbg](http://www.kdbg.org/) and valgrind

Many of these are installed with package managers such as [apt-get](https://linux.die.net/man/8/apt-get) for Linux and [HomeBrew](https://brew.sh/) for Mac OSX.  A few scripts are also provided in the libs directory for such packages as `Lmod` and `CMake`if you would rather install these from source.

If you are using your own laptop or workstation, it is likely that most of these basic packages are already installed.  If any of these packages are missing from your system (such as Lmod), you can manually install them with a package manager or with the build scripts.  The items near the bottom of the list are not essential - if you don't have them on your system there is no need to install them.

If you're on an HPC system you can largely skip this step (but you still need to set the **OPT** environment variable, see below) because most of these packages are probably already installed and available.  However, there are a few items that you may wish to add by loading the appropriate modules (if they exist) - for example:
```
module load doxygen git-lfs
```
Note, however, if you are using [JEDI Modules](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/developer/jedi_environment/modules.html) you do not have to worry about this (or indeed, about this repository in general) - the JEDI team will make sure that the modules provided will include the packages you need.

**IMPORTANT:** Another reponsibility of the `setup_environment.sh` script is to define the OPT environment variable.  This is needed both for the build and to allow users to load the JEDI modules after you build them.  This specifies where the modules will be installed, with a default value of `OPT=/opt/modules`.  Note that this default value normally requires root permission so you would have to set the `USE_SUDO` flag (see Step 2).  If you do not have root privileges (e.g. on an HPC system), you may wish to install your modules in a home or work directory, e.g. `OPT=$HOME/opt/modules`.

OPT needs to be set in order to complete Steps 2-4.  But, it also needs to be set in order for users to use the modules.  For this reason, the `module_setup.sh` script also modifies bash and cshrc intialization scripts so that OPT is defined and Lmod is initialized properly when users log in.

## Step 2: Configure Build

The next step is to choose what components of the stack you wish to build and to specify any other aspects of the build that you would like.  This is normally done by editing the file `buildscripts/config/config_custom.sh`.  Here we describe some of the parameter settings available.


**COMPILER** This defines the vendor and version of the compiler you wish to use for this build.  The format is the same as what you would typically use in a module load command:
```
export COMPILER=<name>/<version>
```
For eample, `COMPILER=gnu/7.3.0`.

**MPI** is the MPI library you wish to use for this build.  The format is the same as for `COMPILER`, for example: `export MPI=openmpi/3.1.2`.

**PREFIX** is the directory where the sofware packages will be installed.  Normally this is set to be the same as the `OPT` environment variable (default value `/opt/modules`), though this is not required.  If OPT and PREFIX are both the same, then the software installation trees (the top level of each being is the compiler, e.g. `gnu-7.3.0`) will branch directly off of $OPT while the module files will be located in the `modulefiles subdirectory.

**USE_SUDO** If `PREFIX` is set to a value that requires root permission to write to, such as `/opt/modules`, then this flag should be enabled.

_**NOTE: To enable a boolean flag use a single-digit `Y` or `T`.  To disable, use `N` or `F` (case insensitive)**_

**PKGDIR** is the directory where tarred or zipped software files will be downloaded and compiled.  Unlike `PREFIX`, this is a relative path, based on the root path of the repository.  Individual software packages can be downloaded manually to this directory and untarred, but this is not required.  Most build scripts will look for directory `pkg/pkgName-pkgVersion` e.g. `pkg/hdf5-1_10_3`.

**LOGDIR** is the directory where log files from the build will be written, relative to the root path of the repository.

**OVERWRITE** If set, this flag will cause the build script to remove the current installation, if any exists, and replace it with the new version of each software package in question.  If this is not set, the build will bypass software packages that are already installed.

**NTHREADS** The number of threads to use for parallel builds

**MAKE_CHECK** Run `make check` after build

**MAKE_VERBOSE** Print out extra information to the log files during the build

The remaining items enable or disable builds of each software package.  The following software can optionally be built with the scripts under `buildscripts`.  Unless otherwise noted, the packages are built in Step 4 using the `build_scripts.sh` script.

* Compilers and MPI libraries
  - GNU (Step 3)
  - OpenMPI
  - MPICH
  - `jedi-` Meta-modules for all the above as well as Intel and IMPI

* Minimal JEDI Stack
  - SZip (Step 3)
  - Zlib
  - HDF5
  - NetCDF
  - PNetCDF
  - Udunits
  - LAPACK
  - Boost (Headers only)
  - Eigen3
  - ncccmp
  - nco
  - ecbuild, eckit, fckit
  - ODB
 
* Supplementary Libraries
  - Jasper
  - Armadillo
  - Boost (full installation)
  - FFTW
  - ecCodes
  - ESMF
  - ESMA-Baselibs
  - nceplibs

**IMPORTANT: Steps 2, 3, and 4 need to be repeated for each compiler/mpi combination that you wish to install.**  The new packages will be installed alongside any previously-exising packages that may already exist and that are built from other compiler/mpi combinations.

## Step 3: Set Up Compiler, MPI, and Module System

The next step is to run this from the buildscripts directory:
```
./setup_modules.sh [<configuration>]
```
where `<configuration>` points to the configuration script that you wish to use, as described in Step 2.  The name of this file is `config/config_<configuration>`.  For example, to use the `config/config_custom.sh` you would enter this:
```
./setup_modules.sh custom
```
If no arguments are specified, the default is `custom`.  Note that you can skip this step as well for container builds because we currenly include only one compiler/mpi combination in each container.  So, each package is only build once and there is no need for modules.

This script sets up the module directory tree in `$OPT`.  It also sets up the compiler and mpi modules.  The compiler and mpi modules are handled separately from the rest of the build because, when possible, we wish to exploit site-specific installations that maximize performance.

**For this reason, the compiler and mpi modules are preceded by a `jedi-` label**.  For example, to load the gnu compiler module and the openmpi software library, you would enter this:
```
module load jedi-gnu/7.3.0
module load jedi-openmpi/3.2.1
```
These `jedi-` modules are really meta-modules that will both load the compiler/mpi library and modify the `MODULEPATH` so the user has access to the software packages that will be built in Step 4.  On HPC systems, these meta-modules will load the native modules provided by the system administrators.  For example, `module load jedi-openmpi/3.2.1` will first load the native `openmpi/3.2.1` module and then modify the `MODULEPATH` accordingly to allow users to access the JEDI libraries.  If this module is not available (e.g. in a container or in the cloud), then the `openmpi/3.2.1` module will be built from source and installed into `$OPT`.

So, in short, you should never load the compiler or MPI modules directly.  Instead, you should always load the `jedi-` meta-modules as demonstrated above - they will provide everything you need to load and then use the JEDI software libraries.  

Another job of the `setup_modules.sh` script is to install the [SZip library](https://support.hdfgroup.org/doc_resource/SZIP/).  This is done in Step 3 rather than Step 4 because some MPI implementations may make use of SZip compression to boost performance.  If, in the future, the compiler or MPI libraries have any new dependencies, then they should likewise be incorporated into either `setup_modules.sh` or `setup_environment.sh`.

## Step 4: Build JEDI Stack

Now all that remains is to build the stack:
```
./build_stack.sh [<configuration>]
```
Here `<configuration>` is the same as in Step 3, namely a reference to the corresponding configuration file in the `config` directory.  As in Step 2, if this argument is omitted, the default is to use `config/config_custom.sh`.


# Adding a New library/package

If you want to add a new library to the stack you need to follow these steps:
1. write a new build script in buildscripts/libs, using exising scripts as a template
2. define a new control flag and add it to the config files in buildscripts/config
3. Add a call to the new build script in buildscripts/build\_stack.sh
4. Create a new module template at the appropriate place in the modulefiles directory, using exising files as a template
