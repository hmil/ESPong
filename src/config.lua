BTN_COM=0
BTN_DOWN=1
BTN_UP=2
FRAME_DURATION=60
MIN_SLEEP_TIME=10 -- Minimum amount of milliseconds to sleep between frames
MAX_TILES_PER_FRAME=6
BALL_RADIUS=2
PADDLE_WIDTH=4
PADDLE_HEIGHT=15
PADDLE_OFFSET=3 -- How much empty space is between the paddle and the side wall

SCREEN_WIDTH=128
SCREEN_HEIGHT=64
N_TILES_X=SCREEN_WIDTH / 8
N_TILES_Y=SCREEN_HEIGHT / 8

WIFI_SSID="pong66"
WIFI_PASS="pingpong"


getDelta = function(timeBegin)
    local timeEnd = tmr.now()
    local totalTime = timeEnd - timeBegin
    if totalTime < 0 then
        totalTime = totalTime + 0x7fffffff
    end
    totalTime = math.floor(totalTime / 1000)
    return totalTime
end
