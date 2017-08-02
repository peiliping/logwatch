local logwatchconfig = {}
local config = {
    {
        dirpath = "/home/peiliping/dev/logs/" ,                                   --(Required) 需要监控的日志文件目录
        filename = "bccess.log" ,                                                 --(Optional) 需要监控的日志文件名
      --filenameFilter = '(.*).log%-(%d+)%-(%d+)%-(%d+)' ,                        --(Optional) 需要监控的日志文件名正则表达式
        origin = true ,                                                           --(Optional) 是否从文件起始开始读取，否则就是从logwatch程序启动时刻开始读取文件增量
        rule = "accesslog" ,                                                      --(Required) 日志解析规则，对应parseconfig中的内容
      --multiline = true ,                                                        --(Optional) 文件中是否含有多行结构的日志
      --multilineIdentify = '^"([%d]+%-[%d]+%-[%d]+% [%d]+:[%d]+:[%d]+"' ,        --(Optional) 前提是multiline为true，设置多行结构的起始特征，使用正则表达
      --javaLog = true ,                                                          --(Optional) 前提是multiline为true，提取java异常关键字和异常堆栈等信息
      --jsonLog = true ,                                                          --(Optional) 前提是multiline为false，单行jsonlog的处理，会对json进行解析
        tags = {type = "accesslog" , app = "user"} ,                              --(Required) 自定义tag
        topic = 'pe_jl_nginxlog' ,                                                --(Optional) 指定发送的topic，需要在kafkaconfig的topics中存在
    } ,
    {
        dirpath = "/home/peiliping/dev/logs/" ,                                   
        filename = "app.log" ,                                                    
        origin = true ,                                                           
        rule = "bizlog3" ,                                                        
        multiline = true ,                                                        
        multilineIdentify = '^([%d]+:[%d]+:[%d]+%.[%d]+)' ,                       
        javaLog = true ,                                                          
        tags = {type = "app" , app = "user"} ,                                    
        topic = 'pe_jl_bizlog' ,                                                  
    } ,
}
function logwatchconfig.getconfig() return config end
return logwatchconfig
