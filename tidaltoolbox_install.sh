#! /bin/sh
### Install Tools and POCViP
# Some documentation at :
# https://sirocco.obs-mip.fr/other-tools/prepost-processing/comodo-tools/installation/

### RECOMMENDATION
# the tools need to be compile with gcc>=7.3
# verify with gcc --version

ipocvip=false
ncpu=11

INSTALL_PATH=$PWD
LOCAL_INSTALL_PATH=$PWD/local

for name in 'poc-solvers' 'tools' 'pocvip'
do
    if [ $name = 'pocvip' ]
        then
        if [ $ipocvip = 'false' ]
            then
            break
        fi
    fi

    mkdir $name
    mkdir $name/.hg
    mv $name.*.hgbundle $name/
    cd $name
    hg undundle $name.*.hgbundle
    hg up
    cd $INSTALL_PATH
done

mkdir $LOCAL_INSTALL_PATH
mkdir $LOCAL_INSTALL_PATH/lib
mkdir $LOCAL_INSTALL_PATH/include
mkdir $LOCAL_INSTALL_PATH/ubin
mkdir $LOCAL_INSTALL_PATH/bin

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LOCAL_INSTALL_PATH/lib
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LOCAL_INSTALL_PATH/lib:$CONDA_PREFIX/lib
export CMAKE_LIBRARY_PATH=$LD_LIBRARY_PATH
export CMAKE_INCLUDE_PATH=$LOCAL_INSTALL_PATH/include
#FOR CALMIP
# export CPATH=$CPATH:/usr/local/intel/2018.2.046/impi/2018.2.199/intel64/include
# export CC=mpicc -std=gnu11
# export CXX='mpicxx -std=gnu++11'

# Remove previous configured librairies
# rm -r $LOCAL_INSTALL_PATH/{lib,include,bin,share/man}/*


echo '#######################################################\n'
echo '                 INSTALL SOLVERS'
echo '#######################################################\n\n'

#Download the poc-solver librairies
wget http://www.netlib.org/blas/blas.tgz
wget http://www.netlib.org/lapack/lapack-3.5.0.tgz
wget http://www.netlib.org/scalapack/scalapack-2.0.2.tgz
wget http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-4.4.3.tar.gz
wget https://download.open-mpi.org/release/hwloc/v2.5/hwloc-2.5.0.tar.bz2

# Unfold the librairies sources
tar -xf blas.tgz
tar -xf lapack-3.5.0.tgz
tar -xf scalapack-2.0.2.tgz
tar -xf SuiteSparse-4.4.3.tar.gz
tar -xf hwloc-2.5.0.tar.bz2

### COMPILATION
# BLAS
cd BLAS-3.12.0
make
cp -v *.a $LOCAL_INSTALL_PATH/lib/libblas.a
cd ..

# LAPACK
cd lapack-3.5.0
sed -re "s|= (-O)|= -g \1|;s|-O2|-O3|;\
s|^( *BLASLIB *= *).*|\1$LOCAL_INSTALL_PATH/lib/libblas.a|" make.inc.example >make.inc
make
make lapackelib
cp -v liblapack.a $LOCAL_INSTALL_PATH/lib
cd ..

# SCALAPACK
cd scalapack-2.0.2
sed -re "s|= (-O)|= -g \1|" SLmake.inc.example >SLmake.inc
make
cp -v libscalapack.a $LOCAL_INSTALL_PATH/lib
cd ..

# SuiteSparse
cd SuiteSparse/SuiteSparse_config
sed -re "s|^( *INSTALL_[^ ]+ *= *).*/([^/]+$)|\1$LOCAL_INSTALL_PATH/\2|;\
s|^( *(LAPACK\|BLAS) *= *)|\1-L$LOCAL_INSTALL_PATH/lib |;\
/^\s*#/! s| -O| -g -O|#;" \
SuiteSparse_config_linux.mk >SuiteSparse_config.mk
cd ..
make -j$ncpu library
make install
cd ..

# HWLOC
cd hwloc-2.5.0
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..

echo '#######################################################\n'
echo '                 INSTALL poc-solvers'
echo '#######################################################\n\n'
#POC-SOLVERS
cd poc-solvers
mkdir cmade-mpi
cd  cmade-mpi
cmake ../src -DLOCAL_INSTALL=$LOCAL_INSTALL_PATH/ -DHIPS=NO -DMUMPS=NO -DPASTIX_5=NO -DPASTIX_6=NO -DPETSC=NO -DUMFPACK=NO -DARPACK=NO -DPARPACK=NO
make -j$ncpu install
cd ../..

echo '#######################################################\n'
echo '                 INSTALL tools'
echo '#######################################################\n\n'

#Download the poc-solver librairies
wget https://sqlite.org/2024/sqlite-autoconf-3460100.tar.gz
wget http://download.osgeo.org/proj/proj-6.3.1.tar.gz
wget http://ftpmirror.gnu.org/gsl/gsl-1.16.tar.gz
# wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.6/src/hdf5-1.10.6.tar.bz2
# wget https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-c-4.9.2.tar.gz
wget https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.27.1-Source.tar.gz
# wget http://download.osgeo.org/shapelib/shapelib-1.5.0.tar.gz
wget https://github.com/OSGeo/gdal/releases/download/v3.5.2/gdal-3.5.2.tar.gz
wget http://download.osgeo.org/geotiff/libgeotiff/libgeotiff-1.6.0.tar.gz
wget https://github.com/LASzip/LASzip/releases/download/v2.2.0/laszip-src-2.2.0.tar.gz
# wget http://download.osgeo.org/liblas/libLAS-1.8.1.tar.bz2


# Unfold the librairies sources
tar -xf sqlite-autoconf-3460100.tar.gz
tar -xf proj-6.3.1.tar.gz
tar -xf gsl-1.16.tar.gz
# tar -xf hdf5-1.10.6/src/hdf5-1.10.6.tar.bz2
# tar -xf netcdf-c-4.9.2.tar.gz
tar -xf eccodes-2.27.1-Source.tar.gz
# tar -xf shapelib-1.5.0.tar.gz
tar -xf gdal-3.5.2.tar.gz
tar -xf libgeotiff-1.6.0.tar.gz
tar -xf laszip-src-2.2.0.tar.gz
# tar -xf libLAS-1.8.1.tar.bz2

### COMPILATION
# SQLITE3
cd sqlite-autoconf-3460100
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..

#PROJ (need sqlite3)
cd proj-6.3.1
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..

#GSL
cd gsl-1.16
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..

#ECCODES
cd eccodes-2.27.1-Source
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$LOCAL_INSTALL_PATH \
    -DENABLE_{PYTHON,FORTRAN,NETCDF,JPG,AEC}=OFF
make -j$ncpu
make install
# cp -v lib/libgrib_api.so $LOCAL_INSTALL_PATH/lib/
cd ../../

# GDAL (need proj)
cd gdal-3.5.2
# ./configure --prefix=$LOCAL_INSTALL_PATH --without-sqlite3
./configure --prefix=$LOCAL_INSTALL_PATH --with-mpi
make -j$ncpu
make install
cd ..
# ln -s $CONDA_PREFIX/lib/libgdal.so $LOCAL_INSTALL_PATH/lib/libgdal.so

#libGEOTIFF
cd libgeotiff-1.6.0
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..
# ln -s $CONDA_PREFIX/lib/libgeotiff.so $LOCAL_INSTALL_PATH/lib/libgeotiff.so

#LASzip
cd laszip-src-2.2.0
./configure --prefix=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..

# libLAS (need libgeotiff)
cd libLAS-1.8.1
mkdir build
cd build
cmake .. -DGEOTIFF_INCLUDE_DIR=$LOCAL_INSTALL_PATH/include -DCMAKE_INSTALL_PREFIX=$LOCAL_INSTALL_PATH
make -j$ncpu
make install
cd ..


#TOOLS
cd tools
autoreconf -si
# WARNING about pkg-config error during the configuration
# if not found, add pkg.m4 into $LOCAL_INSTALL_PATH/share/aclocal/ then run
# autoreconf -si -I$LOCAL_INSTALL_PATH/share/aclocal


#FOR MPI CALCULATION (cluster only)
export CXX='mpicxx -std=gnu++11'
rm -r parallel
mkdir parallel
cd parallel
../configure --with-parallel POCSOLVERBUILDDIR=$INSTALL_PATH/poc-solvers/cmade-mpi

# #FOR STANDARD CALCULATION (PC)
# # export CXX='mpicxx -std=gnu++11'
# rm -r fast
# mkdir fast
# cd fast
# ../configure POCSOLVERBUILDDIR=$INSTALL_PATH/poc-solvers/cmade-mpi

### for all the command (11Go)
# make -j$ncpu -k

### for POCViP only
# make -j$ncpu tools-config

### for custom install
make -j$ncpu tools-config 

for name in vertical-eigenmodes comodo-detidor showarg concatenator
do
make -j$ncpu $name
# rm $LOCAL_INSTALL_PATH/bin/$name
# ln -s $PWD/src/$name $LOCAL_INSTALL_PATH/bin/$name
done

#verifier que le fichier ./src/tools-config exist

#installation:
exe_path=$PWD/src
cp -v src/*.a $LOCAL_INSTALL_PATH/lib/
cp -s $exe_path/* $LOCAL_INSTALL_PATH/ubin/
rm $LOCAL_INSTALL_PATH/ubin/*.*
cd ../../

#POCViP

if [ $ipocvip = 'true' ]
then

    cd pocvip

    autoreconf -si
    # WARNING about pkg-config error during the configuration
    # if not found, add pkg.m4 into $LOCAL_INSTALL_PATH/share/aclocal/ then run
    # autoreconf -si -I$LOCAL_INSTALL_PATH/share/aclocal

    rm -r fast
    mkdir fast
    cd fast


    # #FOR MPI CALCULATION (cluster only)
    # export CXX='mpicxx -std=gnu++11'
    # ../configure TOOLSCONFIG=$INSTALL_PATH/tools/parallel/src/tools-config

    #FOR STANDARD CALCULATION (PC)
    ../configure TOOLSCONFIG=$INSTALL_PATH/tools/fast/src/tools-config

    make -j $ncpu

    #installation:
    ln -s $PWD/pocvip $LOCAL_INSTALL_PATH/ubin

fi

### Gain storage after the proper installation, you can remove all the *.o files in the binary directories (especially the one of tools):
# rm $INSTALL_PATH/tools/fast/src/*.o
