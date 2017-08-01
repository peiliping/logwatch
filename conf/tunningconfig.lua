local tunningconfig = {}
local config = {
    CHECK_FILE_EXIST_INTERVAL = 3 ,              --检查文件是否生成、切换的间隔时间（秒）
    BUFFER_SIZE = 2^15 ,                          --每次readfile的buffer大小
    NO_DATA_INTERVAL = 2 ,                        --当所有文件都没有新增数据时，程序休眠的时间（秒）
    MULTILINE_MAX_NUM = 1024 ,                    --多行日志如java exception log，最多保留多少行，超过最大行数的会被忽略掉
}
function tunningconfig.getconfig() return config end
return tunningconfig
