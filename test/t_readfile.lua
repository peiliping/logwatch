local parserConfig         = (require 'conf.parserconfig'  ).init()
local customParserConfig   = (require 'conf.parserconfig'  ).getconfig()
local tunningConfig        = (require 'conf.tunningconfig' ).getconfig()
local customLogWatchConfig = (require 'conf.logwatchconfig').getconfig()

local singlelineW = require 'watchlog.watchlogfilesingleline'
local multilineW  = require 'watchlog.watchlogfilemultiline'

local debug = false
local ts = os.time()
for _ , task in ipairs(customLogWatchConfig) do
    local watchlogFac = (task.multiline and multilineW or singlelineW)
    local wtcLogFile = watchlogFac:new(task, customParserConfig, tunningConfig, first)
    local kafakClient = {safeSendMsg = function(topic , key , msg , retrytimes) if debug then print(msg) end end}
    while wtcLogFile:readFile(kafakClient , nil) > 0 do
    end
end
local te = os.time()
print(te - ts)