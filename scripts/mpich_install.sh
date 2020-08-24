#!/bin/sh
#MPICH

#install
source ~/.bashrc
cd /shared
#wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/mpich-3.0.4.tar.gz
wget https://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz
tar xzvf mpich-3.3.2.tar.gz
cd mpich-3.3.2
./configure --prefix=/shared/mpich
make
make install

#setenv
echo "export PATH=/shared/mpich/bin:$PATH" >> ~/.bashrc
