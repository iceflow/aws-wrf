# 1.安装配置ParallelCluster

## 1.1. 管理机器配置
准备一台管理服务器，用于ParallelCluster的集群配置和管理，对性能没有高要求，使用T系列EC2即可，或者直接使用自己的工作站笔记本都可以。
要求安装awscli、python（推荐python3）和pip(推荐pip3)。

## 1.2. 安装ParallelCluster
在管理服务器上安装ParallelCluster
如果已经有 pip 和支持的 Python 版本，则可通过使用以下命令安装 AWS ParallelCluster。如果您安装了 Python 3 版本，我们建议您使用 pip3 命令。
 ```
 $ pip3 install aws-parallelcluster --upgrade --user
 ```
环境配置及安装可参考(https://docs.aws.amazon.com/zh_cn/parallelcluster/latest/ug/install.html)
 
 
## 1.3. 配置AWS IAM Credentials
准备一个高权限AWS IAM用户（比如adiministrator），创建访问密钥的ID与私有访问密钥（Access Key与Secret Key），将之配置到管理服务器里用于配置AWS实例的访问权限。
```
$ aws configure
AWS Access Key ID [None]: ABCD***********
AWS Secret Access Key [None]: wJalrX********
Default region name [us-east-1]: cn-northwest-1
Default output format [None]: json
```

## 1.4. 初始化ParallelCluster
配置好权限后，使用以下命令开始ParallelCluster的初始化。
```
$ pcluster configure
```

跟着Configure 向导的步骤，选择区域、VPC、子网、密钥等资源，创建集群配置

```
WARNING: Configuration file /home/ec2-user/.parallelcluster/config will be overwritten.
Press CTRL-C to interrupt the procedure.


Allowed values for AWS Region ID:
1. sa-east-1
2. us-east-1
3. us-east-2
4. us-west-1
5. us-west-2
AWS Region ID [us-west-2]: 5
Allowed values for EC2 Key Pair Name:
1. pcluster_us
EC2 Key Pair Name [pcluster_us]: 1
Allowed values for Scheduler:
1. sge
2. torque
3. slurm
4. awsbatch
Scheduler [torque]: 2
Allowed values for Operating System:
1. alinux
2. alinux2
3. centos6
4. centos7
5. ubuntu1604
6. ubuntu1804
Operating System [alinux]: 1
Minimum cluster size (instances) [1]: 1
Maximum cluster size (instances) [30]: 30
Master instance type [m5.xlarge]: m5.xlarge
Compute instance type [c5.18xlarge]: c5.18xlarge
Automate VPC creation? (y/n) [n]: n
Allowed values for VPC ID:
1. vpc-7efe4806 | 4 subnets inside
2. vpc-05905e5dc43199178 | ParallelClusterVPC-20200720130552 | 3 subnets inside
VPC ID [vpc-05905e5dc43199178]: 2
Automate Subnet creation? (y/n) [y]: n
Allowed values for Master Subnet ID:
1. subnet-0bfbfc0271a9cea5b | ParallelClusterPublicSubnet | Subnet size: 4096
Master Subnet ID [subnet-0bfbfc0271a9cea5b]: 1
Allowed values for Compute Subnet ID:
1. subnet-0bfbfc0271a9cea5b | ParallelClusterPublicSubnet | Subnet size: 4096
Compute Subnet ID [subnet-0bfbfc0271a9cea5b]: 1
```

## 1.5. 创建S3存储桶
打开AWS控制台，选择S3服务，创建一个S3存储桶(比如s3://nwcdworkshop)，用于存储集群运行产生的数据。  
下载计算节点运行的[post_install脚本文件](https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/pcluster_postinstall.sh)，上传到存储桶中本例s3://nwcdworkshop/pcluster/pcluster_postinstall.sh， 由于WRF不能得益于超线程，通过post_instal脚本关闭EC2实例的超线程，按照物理核来运行。  


## 1.6. 编辑parallelcluster配置
使用以下命令编辑ParallelCluster配置
```
$ vim ~/.parallelcluster/config
```
可以看到上一步初始化时VPC、子网等信息都在此配置文件中，依然沿用之前的设置；其他根据需求做相应配置。
```
[aws]
aws_region_name = cn-northwest-1

[global]
cluster_template = default
update_check = true
sanity_check = true

[cluster default]
key_name = pcluster_us
base_os = alinux
scheduler = torque
master_instance_type = m5.xlarge
compute_instance_type = c5.18xlarge
initial_queue_size = 1
max_queue_size = 30
maintain_initial_size = false
vpc_settings = default
master_root_volume_size = 100
compute_root_volume_size = 100
scaling_settings = WRF-ASG
placement = cluster
placement_group = DYNAMIC
cluster_type = spot
ebs_settings = ebs
extra_json = { "cluster" : { "cfn_scheduler_slots" : "cores", "ganglia_enabled" : "yes" } }
post_install = s3://nwcdworkshop/pcluster/pcluster_postinstall.sh
s3_read_write_resource = arn:aws:s3:::nwcdworkshop/*

[scaling WRF-ASG]
scaledown_idletime = 5

[ebs ebs]
volume_type = gp2
volume_size = 2000

[vpc default]
vpc_id = vpc-05905e5dc43199178
master_subnet_id = subnet-0bfbfc0271a9cea5b

[aliases]
ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}
```



脚本分为AWS区域、集群信息配置、自动扩展设置、共享数据卷设置、VPC与子网设置等几个部分。重点关注以下几个参数：

   * post_install 设置的是集群节点启动时运行的脚本位置，修改YOUR_S3_BUCKET_NAME为你自己的存储桶名称，由于WRF不能得益于超线程，因此这个脚本中会关闭EC2实例的超线程，按照物理核来运行。
   * s3_read_write_resource 设置的是集群访问的S3存储桶，修改YOUR_S3_BUCKET_NAME为你自己的存储桶名称。
   * compute_instance_type 设置的是计算节点的类型，建议尽可能使用较大的实例类型，在并行计算场景中提高更多的效率，此处设定为18xlarge；默认新账户这个实例类型limit较少，建议提前开support case提高limit
   * master_instance_type 设置的是主节点的类型，主节点用于安装软件、下载数据，不参与并行计算，所以不需要太大，此处设定为xlarge
   * max_queue_size 设置的是集群计算节点的数量上限，可以根据需求更改，此处设置为5台
   * scheduler 设置的是批处理计划，此处使用torque，还可以根据您的习惯选择sge或slurm
   * volume_size 设置的是共享EBS卷的大小，其他节点会NFS挂载到这个卷的文件系统中，由于数据量较大，建议设置大一些，此处设置为2000G
   * 使用单可用区部署，并使用Placement Group可以降低集群节点间通信的延迟，提高并行计算效率，在此脚本中均已设置。



## 1.7. 创建ParallelCluster集群
```
$ pcluster create WRFcluster
```
使用命令创建集群，并等待集群创建完成。如果集群创建失败，请检查相应Region的EC2限制是否小于设定的集群最大节点数，点击EC2界面左边“限制”查看。如果受限于EC2 limit，可以开support case提高limit，或者修改设置降低最大节点数。

 
# 2. 配置WRF软件和环境

WRF依赖于gfortan编译器和gcc、cpp的库，在此基础之上依赖于基本库NetCDF和用于并行计算的库MPICH，在运行WRF任务之前，还需要通过WPS（WRF Pre-processing System）做数据的预处理。所以在WRF的安装过程中，首先要更新依赖的编译器和库，然后安装NetCDF和MPICH，然后安装和编译WRF，设定好目录后安装和编译WPS。

如果使用intel编译环境，参考[intel compiler](intel-compiler/)


## 2.1. 登录主节点
打开AWS控制台，选择EC2服务，找到集群主节点（默认标签为Master），ssh登录。
```
$ pcluster ssh WRFcluster
```

## 2.2. 更新并安装gcc编译器和jasper、libpng依赖库
```
$ sudo yum upgrade -y \
&& sudo yum install gcc64-gfortran.x86_64 libgfortran.x86_64 jasper jasper-libs.x86_64 jasper-devel.x86_64 libpng-devel.x86_64 -y
```

## 2.3. 下载代码仓库并进入相应目录
代码仓库托管在GitHub，包含安装脚本等资源，建议下载到共享卷目录/shared 下。
```
$ cd /shared
$ git clone https://github.com/BlastShadowsong/wrf-cluster-on-aws-pcluster.git
$ cd wrf-cluster-on-aws-pcluster/
```

## 2.4. 安装 NetCDF 4.1.3
```
sh scripts/netcdf_install.sh
```

## 2.5. 安装 MPICH 3.0.4
```
sh scripts/mpich_install.sh
```

MPICH 3.0.4有一个bug，集群超过一定规模后会job会卡住，建议升级至mpich-3.3.2(修改scripts/mpich_install.sh，将mpich下载地址改为https://www.mpich.org/static/downloads/3.3.2/mpich-3.3.2.tar.gz)

## 2.6. 安装 WRF 4.0
```
sh scripts/wrf_install.sh
```
出现选项时
```
Please select from among the following Linux x86_64 options:

  1. (serial)   2. (smpar)   3. (dmpar)   4. (dm+sm)   PGI (pgf90/gcc)
  5. (serial)   6. (smpar)   7. (dmpar)   8. (dm+sm)   PGI (pgf90/pgcc): SGI MPT
  9. (serial)  10. (smpar)  11. (dmpar)  12. (dm+sm)   PGI (pgf90/gcc): PGI accelerator
 13. (serial)  14. (smpar)  15. (dmpar)  16. (dm+sm)   INTEL (ifort/icc)
                                         17. (dm+sm)   INTEL (ifort/icc): Xeon Phi (MIC architecture)
 18. (serial)  19. (smpar)  20. (dmpar)  21. (dm+sm)   INTEL (ifort/icc): Xeon (SNB with AVX mods)
 22. (serial)  23. (smpar)  24. (dmpar)  25. (dm+sm)   INTEL (ifort/icc): SGI MPT
 26. (serial)  27. (smpar)  28. (dmpar)  29. (dm+sm)   INTEL (ifort/icc): IBM POE
 30. (serial)               31. (dmpar)                PATHSCALE (pathf90/pathcc)
 32. (serial)  33. (smpar)  34. (dmpar)  35. (dm+sm)   GNU (gfortran/gcc)
 36. (serial)  37. (smpar)  38. (dmpar)  39. (dm+sm)   IBM (xlf90_r/cc_r)
 40. (serial)  41. (smpar)  42. (dmpar)  43. (dm+sm)   PGI (ftn/gcc): Cray XC CLE
 44. (serial)  45. (smpar)  46. (dmpar)  47. (dm+sm)   CRAY CCE (ftn/cc): Cray XE and XC
 48. (serial)  49. (smpar)  50. (dmpar)  51. (dm+sm)   INTEL (ftn/icc): Cray XC
 52. (serial)  53. (smpar)  54. (dmpar)  55. (dm+sm)   PGI (pgf90/pgcc)
 56. (serial)  57. (smpar)  58. (dmpar)  59. (dm+sm)   PGI (pgf90/gcc): -f90=pgf90
 60. (serial)  61. (smpar)  62. (dmpar)  63. (dm+sm)   PGI (pgf90/pgcc): -f90=pgf90
 64. (serial)  65. (smpar)  66. (dmpar)  67. (dm+sm)   INTEL (ifort/icc): HSW/BDW
 68. (serial)  69. (smpar)  70. (dmpar)  71. (dm+sm)   INTEL (ifort/icc): KNL MIC
选择“34” (dmpar)，然后再选择 “1”

Enter selection [1-71] : 34
------------------------------------------------------------------------
Compile for nesting? (1=basic, 2=preset moves, 3=vortex following) [default 1]: 1
之后进行编译，以下是编译选项

em_real (3d real case)
em_quarter_ss (3d ideal case)
em_b_wave (3d ideal case)
em_les (3d ideal case)
em_heldsuarez (3d ideal case)
em_tropical_cyclone (3d ideal case)
em_hill2d_x (2d ideal case)
em_squall2d_x (2d ideal case)
em_squall2d_y (2d ideal case)
em_grav2d_x (2d ideal case)
em_seabreeze2d_x (2d ideal case)
em_scm_xy (1d ideal case)
```

在本次实验中选择em_real模式
```
$ cd /shared/WRF/WRF
$ source ~/.bashrc
$ ./compile em_real 2>&1 | tee compile.log
```
如果安装成功，则可以看到如下信息
```
==========================================================================
build started:   Fri Jul 19 12:16:09 UTC 2019
build completed: Fri Jul 19 12:21:41 UTC 2019

--->                  Executables successfully built                  <---

-rwxrwxr-x 1 ec2-user ec2-user 38094992 Jul 19 12:21 main/ndown.exe
-rwxrwxr-x 1 ec2-user ec2-user 37975624 Jul 19 12:21 main/real.exe
-rwxrwxr-x 1 ec2-user ec2-user 37595344 Jul 19 12:21 main/tc.exe
-rwxrwxr-x 1 ec2-user ec2-user 41805008 Jul 19 12:21 main/wrf.exe

==========================================================================
```

## 2.7. 安装 WPS 4.0
```
$ sh scripts/wps_install.sh
```
出现选项列表时
```
Please select from among the following supported platforms.

   1.  Linux x86_64, gfortran    (serial)
   2.  Linux x86_64, gfortran    (serial_NO_GRIB2)
   3.  Linux x86_64, gfortran    (dmpar)
   4.  Linux x86_64, gfortran    (dmpar_NO_GRIB2)
   5.  Linux x86_64, PGI compiler   (serial)
   6.  Linux x86_64, PGI compiler   (serial_NO_GRIB2)
   7.  Linux x86_64, PGI compiler   (dmpar)
   8.  Linux x86_64, PGI compiler   (dmpar_NO_GRIB2)
   9.  Linux x86_64, PGI compiler, SGI MPT   (serial)
  10.  Linux x86_64, PGI compiler, SGI MPT   (serial_NO_GRIB2)
  11.  Linux x86_64, PGI compiler, SGI MPT   (dmpar)
  12.  Linux x86_64, PGI compiler, SGI MPT   (dmpar_NO_GRIB2)
  13.  Linux x86_64, IA64 and Opteron    (serial)
  14.  Linux x86_64, IA64 and Opteron    (serial_NO_GRIB2)
  15.  Linux x86_64, IA64 and Opteron    (dmpar)
  16.  Linux x86_64, IA64 and Opteron    (dmpar_NO_GRIB2)
  17.  Linux x86_64, Intel compiler    (serial)
  18.  Linux x86_64, Intel compiler    (serial_NO_GRIB2)
  19.  Linux x86_64, Intel compiler    (dmpar)
  20.  Linux x86_64, Intel compiler    (dmpar_NO_GRIB2)
  21.  Linux x86_64, Intel compiler, SGI MPT    (serial)
  22.  Linux x86_64, Intel compiler, SGI MPT    (serial_NO_GRIB2)
  23.  Linux x86_64, Intel compiler, SGI MPT    (dmpar)
  24.  Linux x86_64, Intel compiler, SGI MPT    (dmpar_NO_GRIB2)
  25.  Linux x86_64, Intel compiler, IBM POE    (serial)
  26.  Linux x86_64, Intel compiler, IBM POE    (serial_NO_GRIB2)
  27.  Linux x86_64, Intel compiler, IBM POE    (dmpar)
  28.  Linux x86_64, Intel compiler, IBM POE    (dmpar_NO_GRIB2)
  29.  Linux x86_64 g95 compiler     (serial)
  30.  Linux x86_64 g95 compiler     (serial_NO_GRIB2)
  31.  Linux x86_64 g95 compiler     (dmpar)
  32.  Linux x86_64 g95 compiler     (dmpar_NO_GRIB2)
  33.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (serial)
  34.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (serial_NO_GRIB2)
  35.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (dmpar)
  36.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (dmpar_NO_GRIB2)
  37.  Cray XC CLE/Linux x86_64, Intel compiler   (serial)
  38.  Cray XC CLE/Linux x86_64, Intel compiler   (serial_NO_GRIB2)
  39.  Cray XC CLE/Linux x86_64, Intel compiler   (dmpar)
  40.  Cray XC CLE/Linux x86_64, Intel compiler   (dmpar_NO_GRIB2)
```
选择“1”完成配置。由于 metgrid.exe 和 geogrid.exe 程序以来WRF的I/O库，需要编辑 configure.wps 文件中的相关路径

```
$ vim configure.wps
```
找到其中指定WRF路径的两行，修改为
```
ifneq ($(wildcard $(DEV_TOP)/../WRF), ) # Check for WRF v4.x directory
        WRF_DIR         =       ../../WRF/WRF
else
        WRF_DIR         =       ../../WRF/WRF
```

 编译WPS

```
$ source ~/.bashrc
$ ./compile 2>&1 | tee compile.log
```
如果安装成功则，能看到WPS目录下有如下三个文件
```
  geogrid.exe -> geogrid/src/geogrid.exe  
  ungrib.exe -> ungrib/src/ungrib.exe  
  metgrid.exe -> metgrid/src/metgrid.exe
```  
到此，我们完成WRF的全部安装过程。

 
# 3. 数据准备与WRF运行
WRF任务运行之前，需要准备数据并进行预处理，数据包括静态地理数据和实时气象数据，都可以从NCEP的官网获取；之后分别用WPS的geogrid、ungrib和metgrid进行数据预处理，产生相应的文件，之后就可以执行WRF任务了。

## 3.1. 下载静态地理数据
在/shared 目录下新建文件夹Build_WRF，下载到其中，Global可从官方网站获取：http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html ，国内从中国镜像站获取： https://wrf-data.s3.cn-north-1.amazonaws.com.cn/geog_high_res_mandatory.tar.gz
```
$ cd /shared
$ mkdir Build_WRF
$ cd Build_WRF
$ wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
$ tar zxvf geog_high_res_mandatory.tar.gz
```
然后修改 namelist.wps 文件中的 &geogrid 部分，将静态文件目录提供给geogrid程序。
```
$ cd /shared/WPS/WPS
$ vim namelist.wps
$ geog_data_path ='/shared/Build_WRF/WPS_GEOG/'
```

## 3.2. 下载实时气象数据
实时气象数据可从官方网站获取：ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod 考虑到NOAA官方数据在海外，推荐使用AWS海外账户来就近分析，节省数据迁移时间。

在 /shared/Build_WRF 目录下创建一个目录 DATA，将实时数据下载到 DATA 中。 本例中下载2020年7月15日12点起未来12小时（f000、f006、f012共3个数据作为测试数据）
```
$ cd /shared/Build_WRF
$ mkdir DATA
$ cd DATA
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20200715/12/gfs.t00z.pgrb2.0p50.f000
$ mv gfs.t00z.pgrb2.0p50.f000 GFS_00h
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20200715/12/gfs.t00z.pgrb2.0p50.f006
$ mv gfs.t00z.pgrb2.0p50.f006 GFS_06h
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20200715/12/gfs.t00z.pgrb2.0p50.f012
$ mv gfs.t00z.pgrb2.0p50.f012 GFS_12h
```
如果需要未来三天半的数据，则下载f000、f006、f012到f084共计15个数据作为测试数据

## 3.3. 运行geogrid
转到WPS目录中，运行geogrid
```
$ cd /shared/WPS/WPS
$ ./geogrid.exe>&log.geogrid
```
这一步运行成功的标志是创建了 geo_em.* 文件

## 3.4. 运行ungrib
运行ungrib，首先修改链接到GFS和Vtables的正确位置
```
$ ./link_grib.csh /shared/Build_WRF/DATA/
$ ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable
```
然后修改 namelist.wps 文件的 start_date 和 end_date，与实时数据相契合

start_date = '2020-07-15_12:00:00'
end_date   = '2020-07-19_00:00:00'
然后运行ungrib
```
$ ./ungrib.exe
```

## 3.5. 运行metgrid
```
$ ./metgrid.exe>&log.metgrid
```
这一步运行成功的标志是创建了 met_em* 文件

## 3.6. 复制数据到WRF工作目录
进入WRF目录，将 met_em.* 文件复制到工作目录
```
$ cd /shared/WRF/WRF/run $ cp /shared/WPS/WPS/met_em* /shared/WRF/WRF/run/
```

## 3.7. 修改namelist.input文件
修改 namelist.input 文件中的开始和结束时间，每一行三项设置为相同时间，开始和结束时间与实时数据相契合；修改 num_metgrid_levels 参数为34，与实时数据相契合。

## 3.8. 运行real程序
```
$ cd /shared/WRF/WRF/run
$ ./real.exe
```
检查输出文件以确保运行成功，运行成功后会看到每个域的 wrfbdy_d01 和 wrfinput_d0* 文件。如果有错误，根据文件中的提示修改 namelist.input 文件中的参数。

$ tail rsl.error.0000

## 3.9. 运行WRF
可自行修改 np 参数，但要小于主节点实例的物理核数。
```
$ mpirun -np 8 ./wrf.exe
```
运行成功的标志是 rsl.out.0000 文件中有 SUCCESS结尾，并生成 wrfout* 文件。

 
# 4. 提交WRF并行计算任务
现在我们已经能通过 mpirun 运行WRF任务，但直接执行是运行在主节点上，接下来我们通过任务脚本和torque命令，将WRF任务提交到计算节点并行完成。

## 4.1. 制作任务脚本
```
$ vim job.sh
```
任务脚本的内容为
```
#!/bin/bash
#PBS -N WRF
#PBS -l nodes=5:ppn=36
#PBS -l walltime=3:00:00
#PBS -o wrf.out
#PBS -e wrf.err
echo "Start time: "
date
cd /shared/WRF/WRF/run
/shared/mpich/bin/mpirun /shared/WRF/WRF/run/wrf.exe
echo "End time: "
date
```
其中 PBS -N 为任务名称，-l 控制并行节点数和每个节点的计算核数，-o 和 -e 为结果日志和错误日志的输出位置。这些参数都可以结合实际需求灵活更改。

## 4.2. 提交任务到计算节点
通过以下命令提交任务
```
$ qsub job.sh
```
之后可以用 qnodes 命令查看节点情况，用 qstat 命令查看任务运行情况，通过 rsl.out.0000 查看运行过程。 任务运行完成后，可以在生成的 wrf.out 文件中查看运行起止时间，来计算实际运行时长。

任务提交后，ParallelCluster会根据任务需求自动启动计算实例，添加到集群中，并行执行任务；任务完成后，一段时间内如果没有任务运行在计算节点，ParallelCluster会将计算节点终止，节约成本。


# 参考文档
1. 使用 AWS ParallelCluster 轻松构建 WRF 集群进行气象预报  
https://aws.amazon.com/cn/blogs/china/use-aws-parallelcluster-easily-build-wrf-for-weatherreport/  
2. AWS HPC Workshop - 	WRF on AWS  
https://github.com/aws-samples/aws-hpc-workshops/blob/master/README-WRF.rst#download-and-install-the-intel-compiler  
3. AWS ParallelCluster配置参考  
https://docs.aws.amazon.com/parallelcluster/latest/ug/cluster-definition.html  
4. How to Compile WRF (From NCAR)：  
http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php
5. WRF 官网地理数据下载：  
http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html
6. NCEP 气象实时数据下载：  
ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod
