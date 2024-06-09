local mod_gui = require("mod-gui")

local model = {}

local function build_interface(player)
    -- Build the main frame
    local screen = player.gui.top
    local main_frame = screen.add {
        type = "frame",
        name = "daytime_speed",
        direction = "vertical"
    }
    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        style = "inside_shallow_frame",
        direction = "vertical"
    }
    content_frame.style.top_padding = 5
    content_frame.style.right_padding = 15
    content_frame.style.bottom_padding = 10
    content_frame.style.left_padding = 15
    local label = content_frame.add {
        type = "label",
        name = "probability_label",
        caption = "Daytime speed & solar intensity variability"
    }
    label.style.bottom_margin = 5
    content_frame.add {
        type = "progressbar",
        name = "daytime_speed",
        value = 0
    }
end

function model.init()
    -- Set global variables
    global.probability = {}
    global.probability.functions = {}
    global.probability.history = {}
    global.probability.history.current = 0.5
    global.probability.history.seconds = {}
    global.probability.history.minutes = {}
    global.probability.history.tenminutes = {}
    global.probability.history.max_records = 100

    local tot = 100 - 42
    local aTot = 0
    for i = 1, 7, 1 do
        -- Extend the table with the parameters
        local prop = {
            -- A = a,
            -- B = math.random(1, 1000),
            -- C = math.random(-100, 100)
            A = math.random(1, 100),
            B = math.random(1, 100),
            C = math.random(1, 100)
        }
        table.insert(global.probability.functions, prop)
    end

    local prop = {}
    for i = 1, 7, 1 do
        table.insert(prop, {
            i = global.probability.functions[i].A
        })
    end
    for _, player in pairs(game.players) do
        build_interface(player)
    end

end

local function log_probability(tbl, prob)
    if not prob then
        prob = 0
    end
    -- Remove first item if there are more entries than allowed
    if #tbl > global.probability.history.max_records then
        table.remove(table, 1)
    end
    table.insert(tbl, {
        tick = game.tick,
        probability = prob
    })
end

function model.tick_update()
    if not game then
        return
    end
    -- Calculate probability based on functions
    local prob = 0
    for i = 1, 7, 1 do
        local fn = global.probability.functions[i]
        local Ap = (((8 * fn.A) / 100) + 10)
        local Bp = (60 * ((fn.B / 2) + 5))
        local Cp = fn.C / 100
        local phase = (2 * math.pi * game.tick)
        local p = (Ap * math.sin((phase / Bp) + (Cp * math.pi))) + Ap
        p = p / 2
        prob = prob + p
    end
    prob = prob / 2

    -- Update the progress bar
    for _, player in pairs(game.players) do
        local frame = player.gui.top.daytime_speed
        if not frame then
            build_interface(player)
        else
            frame.content_frame.daytime_speed.value = (prob / 100)
        end
    end

    -- Log probability history
    global.probability.history.current = prob
    if game.tick % 60 == 0 then
        -- Every second
        log_probability(global.probability.history.seconds, prob)
    end
    if game.tick % (60 * 60) == 0 then
        -- Every minute
        log_probability(global.probability.history.minutes, prob)
    end
    if game.tick % (60 * 60 * 10) == 0 then
        -- Every 10 minutes
        log_probability(global.probability.history.tenminutes, prob)
    end
end

function model.get_probability_factor()
    -- Returns a value between 0 and 1
    return global.probability.history.current / 100
end

return model
