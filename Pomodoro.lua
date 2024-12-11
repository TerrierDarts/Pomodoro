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
filter_progress = ""
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

        if mode == "break" then
            if session_count % short_break_counts == 0 and session_count ~= 0 then 
                time_left = long_break_minutes * 60
                trigger_filter()
                set_state_text(long_break_message)
                mode = "focus"
            else
                time_left = short_break_minutes * 60
                trigger_filter()
                set_state_text(short_break_message)
                mode = "focus"   
            end
        else
            time_left = focus_duration_minutes * 60
            trigger_filter()
            set_state_text(focus_message)
            mode = "break"
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
        mode = "break"  -- Reset mode to focus
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

function trigger_filter()
    local sourceSelected = obs.obs_get_source_by_name(filter_progress) --or obs.obs_get_sceene_by_name(filter_progress)
    local filter_id = obs.obs_source_get_filter_by_name(sourceSelected,"Pomo Change")
    obs.obs_source_set_enabled(filter_id, true)
end





-- Script properties for customization in OBS
function script_properties()
    local props = obs.obs_properties_create()
    -- Timer Source
    local text_sources1 = obs.obs_properties_add_list(props, "source_name_timer", "Source which will hold the Timer",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    populate_text_sources(text_sources1)
    -- State Source
    local text_sources2 = obs.obs_properties_add_list(props, "source_name_state", "Source which will hold the State",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    populate_text_sources(text_sources2)
    --- Progress Source
    local text_sources3 = obs.obs_properties_add_list(props, "source_name_progress", "Source which will hold the Progress",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    populate_text_sources(text_sources3)
    -- Focus Time
    obs.obs_properties_add_int(props, "focus_duration_minutes", "Time in Minutes the Focus Time will last (1-180)", 1, 180, 1)
    -- Short Break Time
    obs.obs_properties_add_int(props, "short_break_minutes", "Time in Minutes the Short Break will last (1-30)", 1, 30, 1)
    -- Long Break Time
    obs.obs_properties_add_int(props, "long_break_minutes", "Time in Minutes the Long Break will last (1-60)", 1, 60, 1)
    -- Short Break Counts 
    obs.obs_properties_add_int(props, "short_break_counts", "How many Short Breaks do want before a long one (1-60)", 1, 60, 1)
    -- Target Sessions
    obs.obs_properties_add_int(props, "session_target", "How many focus sessions are you aiming to do (1-60)", 1, 60, 1)
    -- Focus Message
    obs.obs_properties_add_text(props, "focus_message", "What should the 'State' be during focus time.", obs.OBS_TEXT_DEFAULT)
    -- Short Break Message
    obs.obs_properties_add_text(props, "short_break_message", "What should the 'State' be during short break time.", obs.OBS_TEXT_DEFAULT)
    -- Long Break Message
    obs.obs_properties_add_text(props, "long_break_message", "LWhat should the 'State' be during long break time.", obs.OBS_TEXT_DEFAULT)
    -- Format of Progress
    obs.obs_properties_add_text(props, "session_text", "How should the Progress be formatted. ", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "session_info", "Use %C for Current and %T for Target", obs.OBS_TEXT_INFO)
    -- Filter On Change
    local filters = obs.obs_properties_add_list(props, "filter_progress", "Progress Enable Source",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_properties_add_text(props, "filter_info", "Add Filter 'Pomo Change' to that will be enabled", obs.OBS_TEXT_INFO)
    populate_filters(filters)
    -- Buttons
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
    filter_progress = obs.obs_data_get_string(settings, "filter_progress") or filter_progress
    
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
    obs.obs_data_set_string(settings, "session_text", session_text)
    obs.obs_data_set_string(settings, "filter_progress", filter_progress)
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
    filter_progress = obs.obs_data_get_string(settings, "filter_progress") or filter_progress
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

function populate_filters(list)
    obs.obs_property_list_clear(list)

    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            local source_type = obs.obs_source_get_id(source)
           
                local name = obs.obs_source_get_name(source)
                --local filters = obs.obs_source_enum_filters(source)
                obs.obs_property_list_add_string(list, name, name)
            
        end

        obs.source_list_release(sources)
    end

    -- local sources = obs.obs_source_enum_filters()
     
end

