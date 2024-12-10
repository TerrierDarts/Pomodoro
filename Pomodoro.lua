-- Pomodoro Pro Timer V1 for OBS By Animal shadow
-- V2 Edits Added By TerrierDarts
obs = obslua
source_name_timer = "PomodoroTimer"
source_name_state = "PomodoroState"
source_name_progress = "PomodoroProgress"
focus_duration_minutes = 90 -- default 90 minutes
short_break_minutes = 15  -- default 15 minutes
long_break_minutes = 20 -- default 20 minutes
short_break_counts = 4
timer_active = false
time_left = focus_duration_minutes * 60
session_count = 1
session_target = 5
mode = "focus"  -- Initialize the mode as focus

-- Customizable messages
focus_message = "Focus Time!"  -- Default focus message
short_break_message = "Short Break!"  -- Default short break message
long_break_message = "Long Break!"  -- Default long break message
session_text = "%C/%T"
-- Function to set the timer text

function set_timer_text(text)
    local source = obs.obs_get_source_by_name(source_name_timer)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function set_state_text(text)
    local source = obs.obs_get_source_by_name(source_name_state)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function set_progress_text(textRaw)

    text = textRaw:gsub("%%C",session_count):gsub("%%T",session_target)
    local source = obs.obs_get_source_by_name(source_name_progress)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

-- Timer callback function
function timer_callback()
    if not timer_active then return end

    time_left = time_left - 1

    if time_left <= 0 then
        if session_count % short_break_counts == 0 and session_count ~= 0 then
            time_left = long_break_minutes * 60
            set_state_text(long_break_message)
            mode = "long_break"
        elseif mode == "focus" then
            time_left = short_break_minutes * 60
            set_state_text(short_break_message)
            mode = "break"
        else
            time_left = focus_duration_minutes * 60
            set_state_text(focus_message)
            mode = "focus"
            session_count = session_count + 1
            set_progress_text(session_text)
        end
    else
        local minutes = math.floor(time_left / 60)
        local seconds = time_left % 60
        set_timer_text(string.format("%02d:%02d", minutes, seconds))
    end
end

-- Function to start the timer
function start_timer(pressed)
    if not timer_active then
        timer_active = true
        time_left = focus_duration_minutes * 60  -- Reset time to full duration
        mode = "focus"  -- Reset mode to focus
        session_count = 1  -- Reset session count
        set_state_text(focus_message)  -- Show the initial focus message
        set_progress_text(session_text)
        obs.timer_add(timer_callback, 1000)
    end
end

-- Function to stop the timer
function stop_timer(pressed)
    if timer_active then
        timer_active = false
        obs.timer_remove(timer_callback)
        set_state_text("Timer Stopped")  -- Update text to indicate stopped timer
    end
end

-- Function to stop the timer
function pause_timer(pressed)
    if timer_active then
        timer_active = false
        set_state_text("Timer Paused")  -- Update text to indicate stopped timer
    else
        timer_active = true
        set_state_text(mode)
    end
end







-- Script properties for customization in OBS
function script_properties()
    local props = obs.obs_properties_create()
    local text_sources1 = obs.obs_properties_add_list(props, "source_name_timer", "Timer Source Name",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local text_sources2 = obs.obs_properties_add_list(props, "source_name_state", "State Source Name",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local text_sources3 = obs.obs_properties_add_list(props, "source_name_progress", "Progress Source Name",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    populate_text_sources(text_sources1)
    populate_text_sources(text_sources2)
    populate_text_sources(text_sources3)

    obs.obs_properties_add_int(props, "focus_duration_minutes", "Focus Duration (minutes)", 1, 180, 1)
    obs.obs_properties_add_int(props, "short_break_minutes", "Short Break (minutes)", 1, 30, 1)
    obs.obs_properties_add_int(props, "long_break_minutes", "Long Break (minutes)", 1, 60, 1)
    obs.obs_properties_add_int(props, "short_break_counts", "Short Breaks Counts", 1, 60, 4)
    obs.obs_properties_add_int(props, "session_target", "Session Target", 1, 60, 5)
    obs.obs_properties_add_text(props, "focus_message", "Focus State", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "short_break_message", "Short Break State", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "long_break_message", "Long Break State", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "session_text", "Progress Format(%C & %T)", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_button(props, "start_button", "Start Timer", start_timer)
    obs.obs_properties_add_button(props, "pause_button", "Pause Timer", pause_timer)
    obs.obs_properties_add_button(props, "stop_button", "Stop Timer", stop_timer)

    return props
end

-- Load the script settings
function script_load(settings)
    source_name_timer = obs.obs_data_get_string(settings, "source_name_timer") or source_name_timer
    source_name_state = obs.obs_data_get_string(settings, "source_name_state") or source_name_state
    source_name_progress = obs.obs_data_get_string(settings, "source_name_progress") or source_name_progress
    focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
    short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
    long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes
    short_break_counts = obs.obs_data_get_int(settings, "short_break_counts") or short_break_counts
    session_target = obs.obs_data_get_int(settings, "session_target") or session_target
    focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
    short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
    long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message
    session_text = obs.obs_data_get_string(settings, "session_text") or session_text

    obs.obs_hotkey_register_frontend("startPomo","Start Pomodoro", start_timer)
    obs.obs_hotkey_register_frontend("togglePomo","Pause/Resume Pomodoro", pause_timer)
    obs.obs_hotkey_register_frontend("stopPomo","Stop Pomodoro", stop_timer)
end

-- Save the script settings
function script_save(settings)
    obs.obs_data_set_string(settings, "source_name_timer", source_name_timer)
    obs.obs_data_set_string(settings, "source_name_state", source_name_state)
    obs.obs_data_set_string(settings, "source_name_state", source_name_progress)
    obs.obs_data_set_int(settings, "focus_duration_minutes", focus_duration_minutes)
    obs.obs_data_set_int(settings, "short_break_minutes", short_break_minutes)
    obs.obs_data_set_int(settings, "long_break_minutes", long_break_minutes)
    obs.obs_data_set_int(settings, "short_break_counts", short_break_counts)
    obs.obs_data_set_int(settings, "session_target", session_target)
    obs.obs_data_set_string(settings, "focus_message", focus_message)
    obs.obs_data_set_string(settings, "short_break_message", short_break_message)
    obs.obs_data_set_string(settings, "long_break_message", long_break_message)
    obs.obs_data_set_string(settings, "session_text", long_break_message)
end

-- Update the script settings
function script_update(settings)
    source_name_timer = obs.obs_data_get_string(settings, "source_name_timer") or source_name_timer
    source_name_state = obs.obs_data_get_string(settings, "source_name_state") or source_name_state
    source_name_progress = obs.obs_data_get_string(settings, "source_name_progress") or source_name_progress
    focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
    short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
    long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes
    short_break_counts = obs.obs_data_get_int(settings, "short_break_counts") or short_break_counts
    session_target = obs.obs_data_get_int(settings, "session_target") or session_target
    focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
    short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
    long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message
    session_text = obs.obs_data_get_string(settings, "session_text") or session_text
end

function populate_text_sources(list)
    obs.obs_property_list_clear(list)

    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_type = obs.obs_source_get_id(source)
            if source_type == "text_gdiplus_v3" or allow_all_sources then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(list, name, name)
            end
        end

        obs.source_list_release(sources)
    end
end