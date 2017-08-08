local util = {}

local ffi   = require 'ffi'

ffi.cdef[[
    unsigned int sleep(unsigned int seconds);
]]

function util.sleep(sec)
    ffi.C.sleep(sec)
end

function util.getHostName()
    local v = io.popen("hostname")
    local result = v:lines()()
    v:close()
    return result
end

return util