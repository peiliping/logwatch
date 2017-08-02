local kafkaConfig      = require 'rdkafka.config'
local kafkaProducer    = require 'rdkafka.producer'
local kafkaTopicConfig = require 'rdkafka.topic_config'
local kafkaTopic       = require 'rdkafka.topic'

local util = require 'util.util'

local kafkaclient , topics = {} , {}

local customKafkaConfig
local producer
local QUEUE_GUARD_LINE
local MSG_MAX_SIZE

local function propertiesTool(properties , configure)
    table.foreach(properties , function(key , value)
        local t_key = string.gsub(key , "_" , ".")
        configure[t_key] = value
    end)
end

function kafkaclient.initKafkaClient(_KafkaConfig , metrics)
    customKafkaConfig = _KafkaConfig
    QUEUE_GUARD_LINE = _KafkaConfig.properties.global.queue_buffering_max_messages - 1
    MSG_MAX_SIZE = _KafkaConfig.properties.global.message_max_bytes - 0
    local globalConfig = kafkaConfig.create()
    propertiesTool(customKafkaConfig.properties.global , globalConfig)
    globalConfig:set_delivery_cb(function(payload , err) end)
    globalConfig:set_stat_cb(function(payload) 
        local ts = os.time()
        for name , metric in pairs(metrics) do
            print(ts , name , metric)
        end
        print(payload)
    end)
    producer = kafkaProducer.create(globalConfig)
    for _ , address in pairs(customKafkaConfig.brokers) do
        producer:brokers_add(address)
    end
    for _ , topicName in ipairs(customKafkaConfig.topics) do
        local topicConfig = kafkaTopicConfig.create()
        propertiesTool(customKafkaConfig.properties.topic , topicConfig)
        topics[topicName] = kafkaTopic.create(producer , topicName , topicConfig)
    end
    topics.default = topics[customKafkaConfig.topics.default]
end

local function sendMsg(topic , key , msg)
    producer:produce(topic , -1 , msg , key)
    if producer:outq_len() < QUEUE_GUARD_LINE then
        return
    end
    while producer:outq_len() >= QUEUE_GUARD_LINE  do
        producer:poll(3000)
    end
end

function kafkaclient.safeSendMsg(topic , key , msg , retrytimes)
    if string.len(msg) > MSG_MAX_SIZE  then
        return
    end
    local status , errorinfo = pcall(sendMsg , topic , key , msg)
    if status then
        return
    else
        print(errorinfo)
        util.sleep(1)
        if retrytimes > 0 then
            kafkaclient.safeSendMsg(topic , key , msg , retrytimes - 1)
        end
    end
end

function kafkaclient.getTopicInst(topicName)
    return topicName and topics[topicName] or topics.default
end

return kafkaclient