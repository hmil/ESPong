

onMultiplayerGameEnd = function()
    s:close()
    wifi.setmode(wifi.NULLMODE)
    mainMenu()
end

hostGame = function()
    disp:clearBuffer()
    disp:drawStr(10, 40, "Waiting for client...")
    disp:sendBuffer()

    wifi.setmode(wifi.SOFTAP)
    local cfg={}
    cfg.ssid=WIFI_SSID
    cfg.pwd=WIFI_PASS
    wifi.ap.config(cfg)

    wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
        print("\n\tAP - STATION CONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)

        disp:clearBuffer()
        disp:drawStr(0, 40, "New client: ")
        disp:drawStr(0, 50, T.MAC) 
        disp:sendBuffer()
    end)

    local hasStarted = false
    local slaveIP = nil

    s = net.createUDPSocket()
    s:listen(42)

    local updateCb = function(paddlePos, ballX, ballY, ballVx, ballVy)
        s:send(42, slaveIP, string.format("u%c%c%c%c%c", paddlePos, ballX, ballY, ballVx, ballVy))
    end

    s:on("receive", function(s, data, port, ip)
        slaveIP = ip
        if hasStarted == false then
            if data == "start" then
                startGame({
                    isMultiplayer = true,
                    isMaster = true,
                    updateCb = updateCb
                }, onMultiplayerGameEnd)
                hasStarted = true
            end
        else
            requestGameUpdate(data:byte(2))
        end
    end)
end

joinGame = function()
    disp:clearBuffer()
    disp:drawStr(10, 40, "Connecting...")
    disp:sendBuffer()

    wifi.setmode(wifi.STATION)
    local cfg={}
    cfg.ssid=WIFI_SSID
    cfg.pwd=WIFI_PASS
    cfg.save = false
    wifi.sta.config(cfg)

    local masterIP = nil

    local updateCb = function(paddlePos, ballX, ballY, ballVx, ballVy)
        s:send(42, masterIP, string.format("u%c", paddlePos))
    end

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
        print('\n\tSTA - GOT IP'..'\n\tStation IP: '..T.IP..'\n\tSubnet mask: '..
        T.netmask..'\n\tGateway IP: '..T.gateway)

        masterIP = T.gateway

        disp:clearBuffer()
        disp:drawStr(0, 30, "Got IP: " .. T.IP)
        disp:drawStr(0, 40, "Master: " .. masterIP)
        disp:sendBuffer()

        s = net.createUDPSocket()
        s:listen(42)
        s:on("receive", function(s, data, port, ip)
            requestGameUpdate(data:byte(2), data:byte(3), data:byte(4), data:byte(5), data:byte(6))
        end) 

        s:send(42, masterIP, "start")
        startGame({
            isMultiplayer = true,
            isMaster = false,
            updateCb = updateCb
        }, onMultiplayerGameEnd)
        hasStarted = true
    end)
end
