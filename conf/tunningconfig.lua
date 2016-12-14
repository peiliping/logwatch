local tunningconfig = {}
local config = {
    BUFFER_SIZE = 2^15 ,
    CHECK_FILE_EXIST_INTERVAL = 600 , 
    NO_DATA_INTERVAL = 4 ,
    MULTILINE_MAX_NUM = 1024 ,
}
function tunningconfig.getconfig() return config end
return tunningconfig