
ball = {}

isMultiplayer = false

updateBall = function()
    markDirtyArea(ball.x - BALL_RADIUS, ball.y - BALL_RADIUS, ball.x + BALL_RADIUS, ball.y + BALL_RADIUS)

    if isMultiplayer and ballRequest.x ~= nil then
        ball.x = ballRequest.x
        ball.y = ballRequest.y
        ball.vx = ballRequest.vx
        ball.vy = ballRequest.vy
        ballRequest.x = nil
    else
        ball.x = ball.x + ball.vx
        ball.y = ball.y + ball.vy

        -- Collision with paddle
        if ball.x - BALL_RADIUS < PADDLE_OFFSET + PADDLE_WIDTH
                and ball.y > paddlePos - BALL_RADIUS
                and ball.y < paddlePos + PADDLE_HEIGHT + BALL_RADIUS then
            ball.x = 2 * (PADDLE_OFFSET + PADDLE_WIDTH + BALL_RADIUS) - ball.x
            ball.vx = -ball.vx;
        -- Collision with second player's paddle
        elseif isMultiplayer and ball.x + BALL_RADIUS > SCREEN_WIDTH - PADDLE_OFFSET - PADDLE_WIDTH
                and ball.y > paddle2Pos - BALL_RADIUS
                and ball.y < paddle2Pos + PADDLE_HEIGHT + BALL_RADIUS then
            local penetration = ball.x + BALL_RADIUS - SCREEN_WIDTH + PADDLE_OFFSET + PADDLE_WIDTH
            ball.x = 2 * (SCREEN_WIDTH - PADDLE_OFFSET - PADDLE_WIDTH) - ball.x - BALL_RADIUS
            ball.vx = -ball.vx
        else -- no collision with paddle, test collision with wall
            if ball.x + BALL_RADIUS >= SCREEN_WIDTH then
                if isMultiplayer == true and isMaster then
                    endGame()
                else
                    ball.x = 2 * (SCREEN_WIDTH - BALL_RADIUS) - ball.x
                    ball.vx = -ball.vx;
                end
            elseif ball.x < 0 then
                if isMultiplayer == false or isMaster then
                    endGame()
                end
                -- ball.x = BALL_RADIUS - ball.x
                -- ball.vx = -ball.vx
            end
        end

        -- Collision with top and bottom walls
        if ball.y + BALL_RADIUS >= SCREEN_HEIGHT then
            ball.y = 2 * (SCREEN_HEIGHT - BALL_RADIUS) - ball.y
            ball.vy = -ball.vy;
        elseif ball.y - BALL_RADIUS < 0 then
            ball.y = BALL_RADIUS - ball.y
            ball.vy = -ball.vy
        end
    end

    -- Add dirty tiles for the new position of the ball
    markDirtyArea(ball.x - BALL_RADIUS, ball.y - BALL_RADIUS, ball.x + BALL_RADIUS, ball.y + BALL_RADIUS)
end

updatePaddle = function()
    local update = 0
    
    if gpio.read(BTN_DOWN) == 0 then
        update = update + 1
    end
    if gpio.read(BTN_UP) == 0 then
        update = update - 1
    end
    
    if update ~= 0 then
        markDirtyArea(0, paddlePos, PADDLE_OFFSET + PADDLE_WIDTH, paddlePos + PADDLE_HEIGHT)
        disp:setDrawColor(0)
        drawPaddle()
        paddlePos = paddlePos + update
        markDirtyArea(0, paddlePos, PADDLE_OFFSET + PADDLE_WIDTH, paddlePos + PADDLE_HEIGHT)
    end
end

updatePaddle2 = function()
    if paddlePosRequest ~= nil then
        markDirtyArea(SCREEN_WIDTH - PADDLE_OFFSET - PADDLE_WIDTH, paddle2Pos, SCREEN_WIDTH, paddle2Pos + PADDLE_HEIGHT)
        disp:setDrawColor(0)
        drawPaddle2()
        paddle2Pos = paddlePosRequest
        paddlePosRequest = nil
        markDirtyArea(SCREEN_WIDTH - PADDLE_OFFSET - PADDLE_WIDTH, paddle2Pos, SCREEN_WIDTH, paddle2Pos + PADDLE_HEIGHT)
    end
end


drawBall = function()
    disp:drawDisc(ball.x, ball.y, BALL_RADIUS, u8g2.U8G2_DRAW_ALL)
end

drawPaddle = function()
    disp:drawBox(PADDLE_OFFSET, paddlePos, PADDLE_WIDTH, PADDLE_HEIGHT)
end

drawPaddle2 = function()
    disp:drawBox(SCREEN_WIDTH - PADDLE_OFFSET, paddle2Pos, PADDLE_WIDTH, PADDLE_HEIGHT)
end

eraseScreen = function()
    disp:setDrawColor(0)
    drawBall()
end

drawScreen = function()
    disp:setDrawColor(1)

    disp:drawLine(0, 0, SCREEN_WIDTH, 0)
    disp:drawLine(0, SCREEN_HEIGHT - 1, SCREEN_WIDTH, SCREEN_HEIGHT - 1)

    drawBall()
    drawPaddle()
    if isMultiplayer then
        drawPaddle2()
    end
end

-- The networking code calls this to update the other player's state
requestGameUpdate = function(otherPaddlePos, ballX, ballY, ballVx, ballVy)
    -- We invert everything so that your player is always on the left
    paddlePosRequest = SCREEN_HEIGHT - otherPaddlePos - PADDLE_HEIGHT
    if isMaster == false then
        ballRequest.x = SCREEN_WIDTH - ballX
        ballRequest.y = SCREEN_HEIGHT - ballY
        ballRequest.vx = -ballVx
        ballRequest.vy = -ballVy
    end
end

endGame = function()
    hasLost = true
end

startGame = function(config, endCallback)

    -- TODO
    -- isMaster = config.isMaster

    isMultiplayer = config.isMultiplayer
    if isMultiplayer then
        isMaster = config.isMaster
        updateCb = config.updateCb
    end


    gpio.mode(BTN_DOWN, gpio.INPUT, gpio.PULLUP)
    gpio.mode(BTN_UP, gpio.INPUT, gpio.PULLUP)

    local gameOver = function()
        disp:setDrawColor(1)
        disp:drawStr(40, 40, "Game over")
        disp:sendBuffer()

        endCallback()
    end

    local gameTick = function()
        local timeBegin = tmr.now()
        eraseScreen()
        updatePaddle()
        if isMultiplayer then
            updatePaddle2()
        end
        updateBall()

        if isMultiplayer then
            if isMaster then
                updateCb(paddlePos, ball.x, ball.y, ball.vx, ball.vy)
            else
                updateCb(paddlePos)
            end
        end

        if hasLost then
            node.setcpufreq(node.CPU80MHZ)
            t:unregister()
            tmr.create():alarm(100, tmr.ALARM_SINGLE, gameOver)
        else
            drawScreen()
            paintDirtyAreas(FRAME_DURATION - getDelta(timeBegin) - MIN_SLEEP_TIME)
            local timeLeft = FRAME_DURATION - getDelta(timeBegin)
            t:interval(math.max(timeLeft, MIN_SLEEP_TIME))
            t:start()
        end
    end

    ball.x = 64
    ball.y = 32
    if isMultiplayer ~= true or isMaster then
        ball.vx = 3 -- node.random(-3, 3)
        ball.vy = 2 -- node.random(-3, 3)
    else
        ball.vx = 0
        ball.vy = 0
    end

    ballRequest = {
        x = nil,
        y = 0,
        vx = 0,
        vy = 0
    }

    paddlePos = 20
    paddle2Pos = 20
    paddlePosRequest = nil

    hasLost = false

    disp:clearBuffer()
    drawScreen()
    disp:drawStr(50, 40, "Ready ?")
    disp:sendBuffer()

    t = tmr.create()
    tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
        disp:clearBuffer()
        drawScreen()
        disp:drawStr(55, 40, "Go!")
        disp:sendBuffer()
        tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
            disp:clearBuffer()
            drawScreen()
            disp:sendBuffer()
            node.setcpufreq(node.CPU160MHZ)
            t:alarm(FRAME_DURATION, tmr.ALARM_SEMI, gameTick)
        end)
    end)
end
