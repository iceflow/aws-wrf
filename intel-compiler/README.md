
# 1.install preferred software
```
yum install -y gcc gcc-c++ csh wget time cmake unzip git libstdc++-devel libstdc++-static m4
```

# 2.install intel compiler
```
wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16225/tar zxvf parallel_studio_xe_2020_cluster_edition.tgz
tar zxvf parallel_studio_xe_2020_cluster_edition.tgz
cd parallel_studio_xe_2020_cluster_edition
./install.sh
```


# 3.Path setup
```
vi ~/.bash_profile
```
```
## intel compiller
source /opt/intel/bin/compilervars.sh intel64
```
# 4. test intel compiller
```
source ~/.bash_profile
ifort -v
```
----
ifort version 19.1.0.166


# 5.install preferred library
netcdf
libpng
jasper

## 5.1 install netcdf library
```
cd /shared
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-c-4.7.3.tar.gz
wget ftp://ftp.unidata/ucar.edu/pub/netcdf/netcdf-fortran-4.5.2.tar.gz
tar zxvf netcdf-c-4.7.3.tar.gz
cd netcdf-c-4.7.3
CC=icc CXX=icc FC=ifort CPP='icpc -E' CPPFLAGS='-fPIC' ./configure --prefix=/shared/netcdf --disable-netcd4 --disable-shared --disable-dap
make -j2
make install
```

```
cd ..
tar zxvf netcdf-fortran-4.5.2.tar.gz
cd netcdf-fortran-4.5.2
CC=icc CXX=icc FC=ifort CPP='icpc -E' CPPFLAGS='-fPIC' CPPFLAGS='-l/shared/netcdf/includ' LDFLAGS='-L/shared/netcdf/lib' ./configure --prefix=/shared/netcdf 
make
make install
```

## 5.2variable setup
```
vi ~/.bash_profile
```

```
export PAHT=/shared/netcdf/bin:$PATH
export NETCDF=/shared/netcdf
export LD_LIBRARY_PATH=/shared/netcdf/lib:$LD_LIBRARY_PATH
```

```
soruce ~/.bash_profile
```

## 5.3 install zlib jasper libpng
```
$ sudo yum upgrade -y \
&& sudo yum install  jasper jasper-libs.x86_64 jasper-devel libpng-devel zlib -y
```

# 6.install WRF
```
ulimit -s unlimited
export MALLOC_CHECK=0
export EM_CORE=1
export NMM_CORE=0
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
cd /shared
wget https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
tar zxvf v4.1.2.tar.gz
cd WFF-4.1.2
./configure
```

选择16.(dm+sm) INTEL (ifort/icc)
然后选择1
and nesting is 1.



编译complie em_real mode
```
./compile -j 2 em_real 2>&1 |tee compile_wrf.log
```
等待30-50分钟完成

```
ls -alh main/*.exe
```

# 7.install WPS
```
cd /shared
ln -sf WRF-4.1.2 WRF
```

```
wget https://github.com/wrf-model/WPS/archive/v4.1.tar.gzz
tar zxvf v4.1.tar.gz
cd WPS-4.1
#export JASPERLIB=
#export JASPERLIB=
./configure
```

选择19. linux x86_64,intel compiler(dmpar)

```
vi configure.wps
```




