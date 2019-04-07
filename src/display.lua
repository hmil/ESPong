
setupDisplay = function()
    local id  = 0
    local sda = 5
    local scl = 6
    local sla = 0x3c
    i2c.setup(id, sda, scl, i2c.SLOW)
    disp = u8g2.ssd1306_i2c_128x64_noname(id, sla)
    disp:setFont(u8g2.font_6x10_tf)
end

markDirtyArea = function(lx, ly, hx, hy)
    local minTileX = math.max(0, math.floor(lx / 8))
    local maxTileX = math.min(N_TILES_X - 1, math.floor(hx / 8))
    local minTileY = math.max(0, math.floor(ly / 8))
    local maxTileY = math.min(N_TILES_Y - 1, math.floor(hy / 8))
    for x = minTileX, maxTileX do
        for y = minTileY, maxTileY do
            dirtyTiles[x * N_TILES_Y + y] = true
        end
    end
end

-- Memorize the last tile scanned in case of incomplete paint operations
tilesScannIndex = 0

-- Map of the tiles which need to be redrawn
dirtyTiles = {}
for i = 0, N_TILES_X * N_TILES_Y do
    dirtyTiles[i] = false
end

-- Paint the areas marked with markDirtyArea. The operation is allowed `budget` milliseconds to complete.
-- If all the tiles could not be painted within `budget` milliseconds, then the next call to paintDirtyAreas
-- will continue where this one left off
paintDirtyAreas = function(budget)
    local timeBegin = tmr.now()
    for i = tilesScannIndex, N_TILES_X * N_TILES_Y do
        if dirtyTiles[i] == true then
            dirtyTiles[i] = false
            disp:updateDisplayArea(math.floor(i / N_TILES_Y), i % N_TILES_Y, 1, 1)
            local timeLeft = budget - getDelta(timeBegin)
            if timeLeft <= 0 then
                tilesScannIndex = i
                return timeLeft
            end
        end
    end
    for i = 0, tilesScannIndex do
        if dirtyTiles[i] == true then
            dirtyTiles[i] = false
            disp:updateDisplayArea(math.floor(i / N_TILES_Y), i % N_TILES_Y, 1, 1)
            local timeLeft = budget - getDelta(timeBegin)
            if timeLeft <= 0 then
                tilesScannIndex = i
                return timeLeft
            end
        end
    end
end

-- debugFPS = function(timeBegin)
--     local totalTime = getDelta(timeBegin)
--     disp:setDrawColor(0)
--     disp:drawBox(0, 0, 64, 8)
--     disp:setDrawColor(1)
--     disp:drawStr(0, 8, totalTime)
--     disp:drawFrame(15, 0, FRAME_DURATION, 8)
--     disp:drawBox(17, 2, totalTime, 4)
--     disp:updateDisplayArea(0, 0, 16, 1)
-- end
