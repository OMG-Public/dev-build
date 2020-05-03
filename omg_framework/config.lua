config = {
    lang = "english",
    debug = true
}

omg_framework = {

    _language = config.lang, -- Languege
	_IPLs = true, -- Load IPLs (fix holes in the map)

    _display_logs = config.debug, -- Display logs serveur (true / false)
	
    _sufix = 'OMG Framework', -- Sufix / Server Name

    _player_first_spawn_location = vector3(-1015.0816650391, -2752.2185058594,  0.80036240816116), -- First spawn location {x, y, z}

    _default_player_money = 2000, -- Default player money
    _default_player_bank_balance = 3000, -- Default player bank balance
    _default_player_dirty_money = 0, -- Default player dirty money
    _default_player_job = 'police',
    _default_player_group = "user",
    _default_player_permission_level = 0,

    _default_player_max_weight = 50.0, -- Default player weight


}


