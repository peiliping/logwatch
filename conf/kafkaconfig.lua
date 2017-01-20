local kafkaconfig = {}
local config = {
    topics = {
        default = "pe_jl_nginxlog" ,
        "pe_jl_nginxlog" ,
        "pe_jl_bizlog" ,
    } ,
    brokers = {
        "1.1.1.1:9092",
        "1.1.1.2:9092",
    } ,
    properties = {
        global = {
            broker_version_fallback = "0.10.1" ,
            statistics_interval_ms = "600000" ,
            batch_num_messages = "2000" ,
            compression_codec = "lz4" ,
            message_max_bytes = "2000000" ,
            queue_buffering_max_ms = "3000" ,
            queue_buffering_max_messages = "16384" ,
            queue_buffering_max_kbytes = "131072"
        } ,
        topic = {
            request_required_acks = "1"
        }
    }
}
function kafkaconfig.getconfig() return config end
return kafkaconfig
