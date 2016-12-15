logwatch
==========

1) 用途：采集日志，通过正则或其他方式进行解析，build成Json，发送到Kafka。

2) 同类：Flume，Logstash等

3) 简介：Lua语言编写，主要依赖cjson(https://github.com/mpx/lua-cjson/)、luardkafka(https://github.com/mistsv/luardkafka)、librdkafka(https://github.com/edenhill/librdkafka) ，luajit（http://luajit.org/download.html）

4) 优势：资源占用少，性能优异（NginxLog，每秒处理4W行，Java应用Log每秒百万行以上），通过协程来进行多任务的调度，最多占用1个CPU Core

5) 仅支持Linux操作系统，文本类型的日志文件，换行符号为\n


安装
==========

1) 编译安装Luajit（LuaJIT-2.1.0-beta2），安装后需要为/usr/local/bin/luajit-2.1.0-beta2创建一个link（/usr/local/bin/luajit），保证luajit命令可用。

2) 编译安装librdkafka（0.9.2），安装后需要为创建一个link /usr/lib64/librdkafka.so.1 -> /安装目录/librdkafka-0.9.2/lib/librdkafka.so.1

3) 编译安装cjson，将编译好的cjson.so放在luajit能够找到的lib路径下即可。

4) luardkafka项目已经放在本项目的工程里了，不需要单独安装，对其produce接口做了少量改动，处理一些异常情况。


代码结构
==========

1) agent.lua为程序启动入口，完成初始化任务和调度执行工作

2) watchlog*.lua为多种类型文件处理的具体实现

3) kafkaclient.lua为封装的kafkaclient，包括初始化和容错等 

4) util.lua你懂的

5) conf目录下是logwatch的配置存放路径

6) z_t_*.lua是测试用的代码


配置说明
==========

1) conf/kafkaconfig.lua用来配置关于kafka的参数，必须要填写brokers，还有topics里面的default，logwatch不支持同时发送到多个kafka集群，可以支持发送到一个kafka集群的不同topic，默认发送到default，也可以在logwatchconfig.lua里针对日志文件进行配置发送的topic。

2) conf/tunningconfig.lua用来配置logwatch的一些常量，具体含义参见代码注释

3) conf/parseconfig.lua用来配置日志解析的正则、字段命名、转化函数等，其中的grok字段，是针对简单日志类型提供的便捷配置方法。

4) conf/logwatchconfig.lua，需要根据采集的日志文件情况进行就编写，可以参考z_t_logwatchconfig.lua的内容
