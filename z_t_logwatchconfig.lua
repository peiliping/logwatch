local logwatchconfig = {}
local config = {
    {
        path = "/tmp/test.log" ,
        rule = "accesslog" ,
        tags = {team = "ai" , app = "dc" , type = "nginx_access_log" , tags = {"ai" , "dc" , "nginx" , "access"}}
    } ,
}
function logwatchconfig.getconfig() return config end
return logwatchconfig
