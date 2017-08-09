Logwatch
----------

### 简介

1. 用途

    采集Linux服务器上的应用日志，通过正则或其他方式进行解析，build成Json，发送到Kafka

2. 同类

    Flume、Logstash、Filebeats、Fluentd等

3. 技术

    Logwatch采用Lua语言编写，主要依赖有：[rapidjson](https://github.com/miloyip/rapidjson)、[luardkafka](https://github.com/mistsv/luardkafka)、[librdkafka](https://github.com/edenhill/librdkafka)、[luajit](http://luajit.org/download.html)、[lfs](https://github.com/keplerproject/luafilesystem)

4. 优势

    资源占用少(1 cpu core , 128m memory)，性能优异

    测试结果:NginxAccessLog(平均长度200字节)，每秒可以处理八万行，Java应用Log每秒可以处理十万行以上

    通过协程来进行多任务的调度，最多占用1个Cpu Core

### 安装

1. 编译安装Luajit（LuaJIT-2.1.0-beta3）

    安装后需要为/usr/local/bin/luajit-2.1.0-beta3创建一个link（/usr/local/bin/luajit），保证luajit命令可用

2. 编译安装librdkafka（0.9.5）

    安装后需要为创建一个link -s /usr/local/lib/librdkafka.so.1 /usr/lib/librdkafka.so.1

3. 编译安装rapidjson(0.5.1)

    将编译好的rapidjson.so放在luajit能够找到的lib路径下即可，编译时依赖cmake3

4. 安装luardkafka

    luardkafka的代码在rdkafka目录下，不需要单独安装，其中produce的接口做了少量改动，处理一些异常情况

5. 安装lfs(1.6.3)

    主要是丰富lua对文件和目录读取的api

### 代码结构

1. agent.lua

    程序启动入口，负责初始化任务和调度执行

2. watchlog/*.lua

    多种类型文件处理的具体实现，其中watchlogfilesingleline.lua为基类，多行日志解析也是在其基础上完成

3. rdkafka/kafkaclient.lua

    封装的kafkaclient，包括初始化和容错等

4. util/*.lua

    简单的函数工具类

5. conf目录

    存放logwatch的配置

6. test/*.lua

    测试用的代码


### 配置说明

1. conf/kafkaconfig.lua

    配置关于Kafka的参数，必须要填写brokers，还有topics里面的default

    logwatch不支持同时发送到多个Kafka集群，可以支持发送到同一个Kafka集群的不同topic

    默认发送到default，可以在logwatchconfig.lua里针对日志文件配置要发送的topic

2. conf/tunningconfig.lua

    配置logwatch的一些常量，具体含义参见代码注释

3. conf/parseconfig.lua

    配置日志解析的正则、字段命名、转化函数等，其中的grok字段，是针对简单日志类型提供的便捷配置方法

4. conf/logwatchconfig.lua

    需要根据采集的日志文件情况进行编写，可以参考logwatchconfig.lua的例子
