local cjson = require 'cjson'
local util = require 'util'

local groks = {
    '"$time_local" $remote_addr $upstream_addr $request_time $request_method $status "$scheme://$host$request_uri" $request_length $body_bytes_sent "$http_referer" "$http_user_agent"'
}
local rule = {grok = groks[1]}
util.grok(rule)
print(rule.regex)
print(cjson.encode(rule.mapping))