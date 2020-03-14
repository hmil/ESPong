
dofile('config.lc')

tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
    dofile('game.lc')
    dofile('networking.lc')
    dofile('display.lc')
    
    setupDisplay()
    mainMenu()
end)


gpio.mode(BTN_DOWN, gpio.INPUT, gpio.PULLUP)
gpio.mode(BTN_UP, gpio.INPUT, gpio.PULLUP)

function debounce (func)
    local last = 0
    local delay = 200000 -- 200ms * 1000 as tmr.now() has μs resolution

    return function (...)
        local now = tmr.now()
        local delta = now - last
        if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
        if delta < delay then return end;

        last = now
        return func(...)
    end
end

mainMenu = function ()
    local menuChoice = 0
    local MENU_WIDTH = SCREEN_WIDTH - 20

    local drawMenu = function()
        disp:setDrawColor(1)

        disp:clearBuffer()
        disp:drawLine(MENU_WIDTH, 0, MENU_WIDTH, SCREEN_HEIGHT)
        disp:setFont(u8g2.font_6x10_tf)
        disp:drawStr(2, 12, "Solo game")
        disp:drawStr(2, 26, "Host party")
        disp:drawStr(2, 40, "Join party")
    
        disp:drawRFrame(SCREEN_WIDTH - 14, -3, 19, 19, 3)
        disp:drawRFrame(SCREEN_WIDTH - 14, SCREEN_HEIGHT - 16, 19, 19, 3)
        disp:setFont(u8g2.font_unifont_t_symbols)
        disp:drawUTF8(SCREEN_WIDTH - 11, 11, "↪")
        disp:drawUTF8(SCREEN_WIDTH - 11, SCREEN_HEIGHT, "▼")
        disp:setFont(u8g2.font_6x10_tf)
        
        disp:setDrawColor(2)
        disp:drawBox(0, 2 + 14 * menuChoice, MENU_WIDTH, 14)

        disp:sendBuffer()
    end

    local choiceUp = function()
        -- Stops the menu
        gpio.mode(BTN_UP, gpio.INPUT, gpio.PULLUP)
        gpio.mode(BTN_DOWN, gpio.INPUT, gpio.PULLUP)
        if menuChoice == 0 then
            startGame({ isMultiplayer = false }, mainMenu)
        elseif menuChoice == 1 then
            hostGame()
        else
            joinGame()
        end
    end

    local choiceDown = function()
        menuChoice = menuChoice + 1
        if menuChoice > 2 then
            menuChoice = 0
        end
        drawMenu()
    end

    gpio.mode(BTN_DOWN, gpio.INT, gpio.PULLUP)
    gpio.trig(BTN_DOWN, "down", debounce(choiceDown))
    gpio.mode(BTN_UP, gpio.INT, gpio.PULLUP)
    gpio.trig(BTN_UP, "down", debounce(choiceUp))

    drawMenu()
end
