local logwatchconfig = {}
local config = {
    {
        path = "/tmp/test.log" ,                                                  --(Required) 需要监控的日志文件路径
        logNameSuffix = '.%Y-%m-%d' ,                                             --(Optional) 针对文件末尾是日期格式的文件，表达式参见lua的日期表达式 
        origin = true ,                                                           --(Optional) 是否从文件起始开始读取，否则就是从logwatch程序启动时刻开始读取文件增量
        rule = "accesslog" ,                                                      --(Required) 日志解析规则，对应parseconfig中的内容
        multiline = true ,                                                        --(Optional) 文件中是否含有多行结构的日志
        multilineIdentify = '^"([%d]+%-[%d]+%-[%d]+% [%d]+:[%d]+:[%d]+"' ,        --(Optional) 前提是multiline为true，设置多行结构的起始特征，使用正则表达
        javaLog = true ,                                                          --(Optional) 前提是multiline为true，提取java异常关键字和异常堆栈等信息
        jsonLog = true ,                                                          --(Optional) 前提是multiline为false，单行jsonlog的处理，会对json进行解析
        tags = {team = "xx" , app = "yy" , type = "zz" , tags = {"mm"}} ,         --(Required) 自定义tag
        topic = 'pe_jl_nginxlog' ,                                                --(Optional) 指定发送的topic，需要在kafkaconfig的topics中存在
    } ,
}
function logwatchconfig.getconfig() return config end
return logwatchconfig
