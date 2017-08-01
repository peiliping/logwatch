local cjson = require 'cjson'
local customParserConfig = require 'conf.parserconfig'
customParserConfig.init()
local util = require 'util'

local accessMsgs = {
    '"10/Oct/2016:13:44:43 +0800" 80.40.134.103 10.44.200.160:8080 : 10.44.200.251:8080 0.003 GET 404 "http://bi-collector.oneapm.com/robots.txt" 340 564 "http://bi-collector.oneapm.com/robots.txt" "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2)"' ,  
    '"10/Oct/2016:13:44:43 +0800" 80.40.134.103 10.44.200.160:8080 0.003 GET 404 "https://bi-collector.oneapm.com/robots.txt" 340 564 "http://bi-collector.oneapm.com/robots.txt" "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2)"' ,
    '"10/Oct/2016:13:44:43 +0800" 80.40.134.103 - 0.003 GET 404 "http://bi-collector.oneapm.com/robots.txt" 340 564 "http://bi-collector.oneapm.com/robots.txt" "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2)"' ,
    '"10/Oct/2016:15:27:20 +0800" 106.39.189.45 10.44.200.251:8080 0.001 GET 200 "http://bi-collector.oneapm.com/beacon/rum/nodejs/1/RR~6uueA7VI2QbaB/?a=2279061&pl=1476084437364&v=411.4.8%20&to=AgkjEDAJHis1AhBeXDtDBDwyGhUrJwsXGHQQOG4nIwYEMToGSl9HOABu&pnet=2&phost=3g.weimob.com&ap=1&ptid=778447&f=%5B%22err%22,%22xhr%22%5D&mbi=1&perf=%7B%22timing%22:%7B%22of%22:1476084437364,%22n%22:0,%22dl%22:235,%22di%22:966,%22ds%22:966,%22de%22:976,%22dc%22:1784,%22l%22:1821,%22le%22:1836,%22f%22:46,%22dn%22:46,%22dne%22:46,%22c%22:46,%22ce%22:46,%22rq%22:46,%22rp%22:46,%22rpe%22:275%7D,%22navigation%22:%7B%7D%7D&allTime=1836&jsonp=BWEUM.setToken" 801 29 "http://3g.weimob.com/canting.html?" ""' ,
    '"10/Oct/2016:15:27:20 +0800" 106.39.189.45 10.44.200.251:8080, 10.172.177.156:8080, 10.44.200.160:8080, 10.44.157.105:8080 0.001 GET 200 "http://bi-collector.oneapm.com/beacon/rum/nodejs/1/RR~6uueA7VI2QbaB/?a=2279061&pl=1476084437364&v=411.4.8%20&to=AgkjEDAJHis1AhBeXDtDBDwyGhUrJwsXGHQQOG4nIwYEMToGSl9HOABu&pnet=2&phost=3g.weimob.com&ap=1&ptid=778447&f=%5B%22err%22,%22xhr%22%5D&mbi=1&perf=%7B%22timing%22:%7B%22of%22:1476084437364,%22n%22:0,%22dl%22:235,%22di%22:966,%22ds%22:966,%22de%22:976,%22dc%22:1784,%22l%22:1821,%22le%22:1836,%22f%22:46,%22dn%22:46,%22dne%22:46,%22c%22:46,%22ce%22:46,%22rq%22:46,%22rp%22:46,%22rpe%22:275%7D,%22navigation%22:%7B%7D%7D&allTime=1836&jsonp=BWEUM.setToken" 801 29 "http://3g.weimob.com/canting.html?" ""' ,
    '"16/Nov/2016:14:00:50 +0800" 222.187.81.114 10.172.255.204:8080 : mi-dc.oneapm.ali.bj 15.111 GET 502 "https://mobile.oneapm.com/mobile/data" 1183 166 "-" "Dalvik/1.6.0 (Linux; U; Android 4.4.2; eagle-pos Build/KOT49H)"'
}

local errorMsgs = {
    '2016/10/10 15:27:57 [crit] 1816#1816: *755091759 SSL_do_handshake() failed (SSL: error:1408A0D7:SSL routines:ssl3_get_client_hello:required cipher missing) while SSL handshaking, client: 217.92.189.190, server: 0.0.0.0:443' ,
    '2016/10/10 03:43:39 [error] 1818#1818: *724169223 open() "/oneapm/local/nginx-1.10.0/html/404.html" failed (2: No such file or directory), client: 111.175.127.166, server: 127.0.0.1, request: "GET /static/js/bw-loader-411.4.5.js HTTP/1.1", host: "www.liezoom.com", referrer: "http://www.liezoom.com/index.php/resume/edit?id=1702145&9XUu"' ,
    '2016/10/10 04:07:17 [error] 1815#1815: *724447799 readv() failed (104: Connection reset by peer) while reading upstream, client: 222.244.98.169, server: bi-collector.oneapm.com, request: "GET /beacon/error/browser/2/IAU7i~iiMEJe33Bf/?a=2286174&pl=1476043595862&v=411.4.5%20&t=/&tbt=sa&tbv=4&pnet=unknown&phost=richest.dreamo100.com&xhr=%5B%7B%22params%22:%7B%22method%22:%22post%22,%22host%22:%22gameanalysis.egret.com:80%22,%22pathname%22:%22/loadingStat.php%22,%22status%22:200%7D,%22metrics%22:%7B%22count%22:1,%22txSize%22:%7B%22t%22:254%7D,%22duration%22:%7B%22t%22:116%7D,%22rxSize%22:%7B%22t%22:21%7D,%22cbTime%22:%7B%22t%22:5%7D,%22time%22:%7B%22t%22:1304%7D%7D%7D,%7B%22params%22:%7B%22method%22:%22GET%22,%22host%22:%22richestres.dreamo100.com:80%22,%22pathname%22:%22/default_2016062101.res.json%22,%22status%22:200%7D,%22metrics%22:%7B%22count%22:1,%22duration%22:%7B%22t%22:62%7D,%22rxSize%22:%7B%22t%22:10336%7D,%22cbTime%22:%7B%22t%22:0%7D,%22time%22:%7B%22t%22:1605%7D%7D%7D,%7B%22params%22:%7B%22method%22:%22GET%22,%22host%22:%22richestres.dreamo100.com:80%22,%22pathname%22:%22/assets/image/uis_2016062100.json%22,%22status%22:200%7D,%22metrics%22:%7B%22count%22:1,%22duration%22:%7B%22t%22:16%7D,%22rxSize%22:%7B%22t%22:17165%7D,%22cbTime%22:%7B%22t%22:0%7D,%22time%22:%7B%22t%22:1697%7D%7D%7D,%7B%22params%22:%7B%22method%22:%22GET%22,%22host%22:%22richest.dreamo100.com:80%22,%22pathname%22:%22/resource/default.thm.json%22,%22status%22:200%7D,%22metrics%22:%7B%22count%22:1,%22duration%22:%7B%22t%22:75%7D,%22rxSize%22:%7B%22t%22:11369%7D,%22cbTime%22:%7B%22t%22:0%7D,%22time%22:%7B%22t%22:1689%7D%7D%7D,%7B%22params%22:%7B%22method%22:%22GET%22,%22host%22:%22richestres.dreamo100.com:80%22,%22pathname%22:%22/assets/image/ladders_2016032305.json%22,%22status%22:200%7D,%22metrics%22:%7B%22count%22:1,%22duration%22:%7B%22t%22:26%7D,%22rxSize%22:%7B%22t%22:8245%7D,%22cbTime%22:%7B%22t%22:0%7D,%22time%22:%7B%22t%22:2129%7D%7D%7D,%7B%22params%22:%7B%22method%22:%22GET%22,%22host%22:%22richestres.dreamo100.com:80%22,%22path' ,
    '2016/10/27 21:39:58 [error] 3570#3570: *1934693526 open() "/var/www/oneapmjs/static/js/skin/layer.css" failed (2: No such file or directory), client: 116.22.199.100, server: tpm.oneapm.com, request: "GET /static/js/skin/layer.css HTTP/1.1", host: "tpm.oneapm.com", referrer: "https://www.dataeye.com/ptlogin/pages/home.jsp"' ,
    '2016/11/10 13:13:27 [error] 15639#15639: send() failed (111: Connection refused)' ,
    '2016/11/10 13:13:37 [error] 15639#15639: disable check peer: 10.173.5.62:8080' ,
}

local bizMsgs = {
    '00:00:00.377 INFO  [http-nio-8080-exec-196] [com.blueocn.das.core.service.AppService@107] not found app by accountId:5780,userId:957035146,pkName:com.fungoapple003.zhibo,version:2.1.1' ,
    '00:00:00.422 WARN  [http-nio-8080-exec-196] [com.blueocn.das.data.collector.controller.MobileAgentDataV2Collector@138] app not found or created, token[ECCFA4CF8D0634955D64DF442D083BF646]' ,
    '00:02:34.646 ERROR [http-nio-8080-exec-118] [com.alibaba.druid.filter.stat.StatFilter@465] slow sql 87 millis. \nselect real_id from real_android_device\twhere\nimsi = ?["000000000000000"]' ,
    '00:00:10.089 ERROR [pool-14-thread-1] [com.blueocn.das.data.consumer.topics.TopicConsumer$1@65] consume message occur an error:The validated expression is false\njava.lang.IllegalArgumentException: The validated expression is false\n\tat org.apache.commons.lang3.Validate.isTrue(Validate.java:180) ~[commons-lang3-3.3.jar:3.3]\n\tat com.blueocn.das.common.util.ValidateZ.checkEachExceedZero(ValidateZ.java:58) ~[das-common-4.3.32.jar:na]\n\tat com.blueocn.das.core.repo.DeviceInfoRepo.getDeviceInfoId(DeviceInfoRepo.java:85) ~[core-dao-4.3.32.jar:na]\n\tat com.blueocn.das.core.repo.DeviceInfoRepo$$FastClassBySpringCGLIB$$be6bcb56.invoke(<generated>) ~[spring-core-4.1.6.RELEASE.jar:na]'
}

local biz2Msgs = {
    '"2016-12-09 14:35:32.178" "io.cloudinsight.dc.service.LicenseService" [-] ERROR LICENSE ERROR : license length must between [64, 71], but the license_key [http://cloud.oneapm.com/]\'s lenght is 24.' ,
    '"2016-12-09 14:35:32.178" "io.cloudinsight.dc.service.LicenseService" [-] ERROR LICENSE ERROR : license length must between [64, 72], but the license_key [http://cloud.oneapm.com/]\'s lenght is 24.' ,
    '"2016-12-09 14:35:32.178" "io.cloudinsight.dc.service.LicenseService" [-] ERROR LICENSE ERROR : license length must between [64, 73], but the license_key [http://cloud.oneapm.com/]\'s lenght is 24.' ,
    '"2016-12-09 14:35:32.178" "io.cloudinsight.dc.service.LicenseService" [-] ERROR LICENSE ERROR : license length must between [64, 74], but the license_key [http://cloud.oneapm.com/]\'s lenght is 24.' ,
}

local biz3Msgs = {
    '09:12:23.169 com.blueocn.tps.frame.cache.CacheManager WARN  alert-rule-id-name-info title: alert-rule-id-name-info in: 0 hit: 0' ,
    '09:12:23.169 com.blueocn.tps.frame.cache.CacheManager WARN  AgentCache  title: AgentCache in: 0 hit: 0' ,
    '09:12:32.958 com.blueocn.tps.jdbc.driver.druid.RestfulConnection INFO  test sql :SELECT \'x\' FROM DUAL    result:[{"result":{"sample_name2":"sample_name1","sample_name1":"sample_name1","sample_divide":"sample_name1"},"timestamp":"2012-01-01T00:00:00.000Z"},{"result":{"sample_name2":"sample_name1","sample_name1":"sample_name1","sample_divide":"sample_name1"},"timestamp":"2012-01-02T00:00:00.000Z"}]' ,
}

local function matchMsg(msgs , rule , container , perf)
    if not perf then
        print(rule.regex)
        print(cjson.encode(rule.mapping))
        print('---------------------------')
    end
    for idx , msg in ipairs(msgs) do
        local handled = util.parseData(msg , rule , container)
        local event = cjson.encode(container)
        if handled then
            if perf then
                return event
            else
                print(idx , event)
            end
        else
            print('ERROR' , idx , msg)
            error("Parse Failed")
        end
    end
end

matchMsg(accessMsgs , customParserConfig.getconfig()['accesslog'] , {})
matchMsg(errorMsgs  , customParserConfig.getconfig()['errorlog']  , {})
matchMsg(bizMsgs    , customParserConfig.getconfig()['bizlog']    , {})
matchMsg(biz2Msgs   , customParserConfig.getconfig()['bizlog2']   , {})
matchMsg(biz3Msgs   , customParserConfig.getconfig()['bizlog3']   , {})

function perf()
    local c1 , c2 , c3 , c4 , c5 = {} , {} , {} , {} , {}
    local st = os.time()    
    for i = 1 , 1000000 do
        matchMsg(accessMsgs , customParserConfig.getconfig()['accesslog'] , c1 , true)
        matchMsg(errorMsgs  , customParserConfig.getconfig()['errorlog']  , c2 , true)
        matchMsg(bizMsgs    , customParserConfig.getconfig()['bizlog']    , c3 , true)
        matchMsg(biz2Msgs   , customParserConfig.getconfig()['bizlog2']   , c4 , true)
        matchMsg(biz3Msgs   , customParserConfig.getconfig()['bizlog3']   , c5 , true)
    end
    local et = os.time()
    print(et - st)
end

--perf()