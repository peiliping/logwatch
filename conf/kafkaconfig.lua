local kafkaconfig = {}
local config = {
    topics = {
        default = "pe_jl_nginxlog" ,
        "pe_jl_nginxlog" ,
        "pe_jl_bizlog" ,
        "test"
    } ,
    brokers = {
        "10.128.106.119:9092",
    } ,
    properties = {
        global = {
            broker_version_fallback = "0.10.1" ,
            statistics_interval_ms = "60000" ,
            batch_num_messages = "2000" ,
            compression_codec = "snappy" ,
            message_max_bytes = "2000000" ,
            queue_buffering_max_ms = "3000" ,
            queue_buffering_max_messages = "16384" ,
            queue_buffering_max_kbytes = "131072"
        } ,
        topic = {
            request_required_acks = "0"
        }
    }
}
function kafkaconfig.getconfig() return config end
return kafkaconfig
