local probability = require("scripts.probability")

---------------------------------------------------------------------------------------------------
-- Initialization & migration
---------------------------------------------------------------------------------------------------
script.on_init(function()
    -- init the probability calculator
    probability.init()

    -- Init some working global variables
    global.default_surface = {}
    global.default_solar_power_multiplier = -1
    global.default_ticks_per_day = -1
    global.ticks_since_last_day = 0
    global.current_ticks_per_day = -1
    global.init_coomplete = false
end)

---------------------------------------------------------------------------------------------------
-- Tick event
---------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function()
    if not global.init_complete then
        -- Set global variables on first possible tick
        global.default_surface = game.surfaces["nauvis"]
        global.default_solar_power_multiplier = global.default_surface.solar_power_multiplier
        global.default_ticks_per_day = global.default_surface.ticks_per_day
        global.current_ticks_per_day = global.default_ticks_per_day

        -- Remember global init init_complete
        global.init_complete = true
    end
    -- Calculate new probability factor & get latest probability factor
    probability.tick_update()
    local probability = probability.get_probability_factor()

    -- Set solar power multiplier
    global.default_surface.solar_power_multiplier = global.default_solar_power_multiplier * probability * 2

    -- Increase tick since last day count
    global.ticks_since_last_day = global.ticks_since_last_day + 1

    -- Update game ticks per day if a "full day" in ticks has passed
    if (global.ticks_since_last_day > global.current_ticks_per_day) or (game.ticks_played == 0) then

        -- Calculate new ticks per day (if retrieved)
        if probability then
            local new_ticks_per_day = math.floor(global.default_ticks_per_day * probability * 2)
            global.current_ticks_per_day = new_ticks_per_day
            global.default_surface.ticks_per_day = new_ticks_per_day
        end
        global.ticks_since_last_day = 0

        -- Announce new day duration (if set)
        if settings.global["announce-day-duration"].value then
            local sec = math.floor(global.current_ticks_per_day / 60)
            local min = math.floor(sec / 60)
            local sec = sec - (min * 60)
            game.print("A new day has started, duration: " .. min .. "min " .. sec .. "sec   [" ..
                           global.current_ticks_per_day .. "ticks]")
        end
    end
end)

---------------------------------------------------------------------------------------------------
-- DEBUGGING
---------------------------------------------------------------------------------------------------

commands.add_command("debug", "Custom debug for development, not for production!", function(command)
    game.print("Default ticks per day: " .. global.default_ticks_per_day .. "  -  Current ticks per day: " ..
                   global.current_ticks_per_day)
end)
