local util = require 'util'
local MONTHS = {Jan = 1 , Feb = 2 , Mar = 3 , Apr = 4 , May = 5 , Jun =6 , Jul =7  , Aug =8  , Sep =9 , Oct = 10 , Nov = 11 , Dec =12}

local parserconfig = {}

--创建下面两个ctr主要是为了复用，减少创建table、resizetable的开销，提高性能
local timeformatCtrTS = {year = nil , month = nil , day = nil , hour = nil , min = nil , sec = nil}
local timeformatCtrFD = {nil , '/' , nil , '/' , nil , ' ' , nil , ':' , nil , ':' , nil}
local timeformatCtrTSCache = {nil , nil}
local timeformatCtrFDCache = {nil , nil}

--字段格式转化函数列表
local convertFunctions = {
    number = tonumber ,
    ngxtimeformatTS = function(w)
            if w == timeformatCtrTSCache[1] then
                return timeformatCtrTSCache[2]
            end
            timeformatCtrTS.year = string.sub(w,8,11)
            timeformatCtrTS.month = MONTHS[string.sub(w,4,6)]
            timeformatCtrTS.day = string.sub(w,1,2)
            timeformatCtrTS.hour = string.sub(w,13,14)
            timeformatCtrTS.min = string.sub(w,16,17)
            timeformatCtrTS.sec = string.sub(w,19,20)
            timeformatCtrTSCache[1] = w
            timeformatCtrTSCache[2] = os.time(timeformatCtrTS)
            return timeformatCtrTSCache[2]
        end ,
    ngxtimeformatFD = function(w)
            if w == timeformatCtrFDCache[1] then
                return timeformatCtrFDCache[2]
            end
            timeformatCtrFD[1] = string.sub(w,8,11)
            timeformatCtrFD[3] = MONTHS[string.sub(w,4,6)]
            timeformatCtrFD[5] = string.sub(w,1,2)
            timeformatCtrFD[7] = string.sub(w,13,14)
            timeformatCtrFD[9] = string.sub(w,16,17)
            timeformatCtrFD[11] = string.sub(w,19,20)
            timeformatCtrFDCache[1] = w
            timeformatCtrFDCache[2] = table.concat(timeformatCtrFD , '')
            return timeformatCtrFDCache[2]
        end ,
}

--config的key值，可以用在logwatchcofig.lua中，作为task的rule
--regex和mapping需要同时提供，如果配置grok则不需要配置regex和mapping
--如果没有格式转化要求，conversion可以不填写
local config = {
    rawlog = {
        regex = '(.*)' ,
        mapping = {
            "raw" ,
        } ,
    } ,
    applog = {
        regex = '"([%d]+%-[%d]+%-[%d]+% [%d]+:[%d]+:[%d]+%.[%d]+)" "(.-)" %[(.-)%] ([%u]+)[%s]+(.*)' , 
        --regex = '"(.-)" "(.-)" %[(.-)%] (.-) (.*)' ,
        --grok = '"$time" "$logger_name" [$params] $level $message' ,
        mapping = {
            "time" ,
            "logger_name" ,
            "params" ,
            "level" ,            
            "message" ,
        } ,
    } ,
    simplebizlog = {
        regex = '([^ ]*)[%s]+([^ ]*)[%s]+([^ ]*)[%s]+(.*)' , 
        --grok = '$time $logger_name $level %message'
        mapping = {
            "time" ,
            "logger_name" ,
            "level" ,
            "message" ,
        } ,
    } ,
    bizlog = {
        regex = '([%d]+:[%d]+:[%d]+%.[%d]+) ([%u]+)[%s]+%[(.-)%] %[(.-)%] (.*)' , 
        mapping = {
            "time" ,
            "level" ,
            "thread_name" ,
            "logger_name" ,
            "message" ,
        } ,
    } ,
    accesslog = {
        regex = '"([%d]+/[%a]+/[%d]+:[%d]+:[%d]+:[%d]+ %+0800)" ([%d|%.]+) (.-) ([%d|%.]+) ([%a|%-]+) ([%d]+) "([http|https]+)://([^"]*)" ([%d]+) ([%d]+) "([^"]*)" "(.*)"' ,
        --regex = '"([^"]*)" ([^ ]*) (.-) ([^ ]*) ([^ ]*) ([^ ]*) "([^:]*)://([^"]*)" ([^ ]*) ([^ ]*) "([^"]*)" "(.*)"' ,
        --regex = '"(.-)" (.-) (.-) (.-) (.-) (.-) "(.-)://(.-)" (.-) (.-) "(.-)" "(.*)"'  , 
        --grok = '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host$request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"' ,
        --optimization = true , --optimization 4 grok from ungreedy to limit greedy
        mapping = {
            "nginx_time" ,
            "remote_ip" ,
            "upstream_ip" ,
            "rt" ,
            "method" ,
            "status_code" ,
            "scheme",
            "url" ,
            "request_size" ,
            "response_size" ,
            "refer",
            "ua"
        } ,
        conversion = {
            rt = "number" ,
            status_code = "number" ,
            request_size = "number" ,
            response_size = "number" ,
            nginx_time = "ngxtimeformatFD" ,
        }
    } ,
    errorlog = {
        regex = '([%d]+/[%d]+/[%d]+ [%d]+:[%d]+:[%d]+) %[([%a]+)%] ([%d]+)#[%d]+%: (.+)' ,
        mapping = {
            "nginx_time" ,
            "log_level" ,
            "pid" ,
            "message"
        } ,
    }
}
function parserconfig.getconfig() return config end
function parserconfig.init() 
    for _ , rule in pairs(config) do
        rule.conversion = (rule.conversion and rule.conversion or {})
        rule.conversionByIndex = {}
        if rule.grok then
            util.grok(rule)
            if rule.optimization then
                util.grokP(rule)
            end
        end
        for index , fdn in ipairs(rule.mapping) do
            rule.conversion[fdn] = rule.conversion[fdn] and convertFunctions[rule.conversion[fdn]] or nil
            rule.conversion[index] = rule.conversion[fdn]
        end
    end
end
return parserconfig
