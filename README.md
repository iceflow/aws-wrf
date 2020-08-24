1.安装配置ParallelCluster

## 1.1. 管理控制机器配置
准备一台管理服务器，用于ParallelCluster的集群配置和管理，对性能没有高要求，使用T系列EC2即可，或者直接使用自己的工作站笔记本都可以。
要求安装awscli、python（推荐python3）和pip(推荐pip3)。

1.2. 安装ParallelCluster
在管理服务器上安装ParallelCluster
如果已经有 pip 和支持的 Python 版本，则可通过使用以下命令安装 AWS ParallelCluster。如果您安装了 Python 3 版本，我们建议您使用 pip3 命令。
 ```
 $ pip3 install aws-parallelcluster --upgrade --user
 ```
环境配置及安装可参考(https://docs.aws.amazon.com/zh_cn/parallelcluster/latest/ug/install.html)
 
 
1.3. 配置AWS IAM Credentials
准备一个高权限AWS IAM用户（比如adiministrator），创建访问密钥的ID与私有访问密钥（Access Key与Secret Key），将之配置到管理服务器里用于配置AWS实例的访问权限。
```
$ aws configure
AWS Access Key ID [None]: ABCD***********
AWS Secret Access Key [None]: wJalrX********
Default region name [us-east-1]: cn-northwest-1
Default output format [None]: json
```
