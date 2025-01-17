class_name GameToJSON
## Class responsible for converting a game into JSON data.


var error: bool = true
var error_message: String = ""
var result: Variant


func convert_game(game: Game) -> void:
	var json_data: Dictionary = {}
	
	# Rules
	var rules_data: Dictionary = {}
	rules_data["population_growth"] = game._game_state.rules.population_growth
	rules_data["fortresses"] = game._game_state.rules.fortresses
	rules_data["turn_limit_enabled"] = game._game_state.rules.turn_limit_enabled
	rules_data["turn_limit"] = game._game_state.rules.turn_limit
	rules_data["global_attacker_efficiency"] = game._game_state.rules.global_attacker_efficiency
	rules_data["global_defender_efficiency"] = game._game_state.rules.global_defender_efficiency
	json_data["rules"] = rules_data
	
	# Players
	var players_data: Array = []
	for player in game._game_state.players.players:
		var player_data: Dictionary = {}
		player_data["id"] = player.id
		player_data["playing_country_id"] = player.playing_country.id
		players_data.append(player_data)
	json_data["players"] = players_data
	
	# Countries
	var countries_data: Array = []
	for country in game._game_state.countries.countries:
		var country_data: Dictionary = {}
		country_data["id"] = country.id
		country_data["country_name"] = country.country_name
		country_data["color"] = country.color.to_html()
		countries_data.append(country_data)
	json_data["countries"] = countries_data
	
	# World
	var world_data: Dictionary = {}
	
	if game._game_state.world is GameWorld2D:
		var world: GameWorld2D = game._game_state.world as GameWorld2D
		world_data["limits"] = {
			"top": world.limits.limit_top(),
			"bottom": world.limits.limit_bottom(),
			"left": world.limits.limit_left(),
			"right": world.limits.limit_right(),
		}
	
	var provinces_data: Array = []
	for province in game._game_state.world.provinces.get_provinces():
		var province_data: Dictionary = {
			"id": province.id,
			"position": {"x": province.position.x, "y": province.position.y},
			"owner_country_id": province._owner_country.id,
			"position_army_host_x": province.armies.position_army_host.x,
			"position_army_host_y": province.armies.position_army_host.y,
		}
		
		# Links
		var links_json: Array = []
		for link in province.links:
			links_json.append(link.id)
		province_data["links"] = links_json
		
		# Shape
		var shape_vertices := Array(province.province_shape().polygon)
		var shape_vertices_x: Array = []
		var shape_vertices_y: Array = []
		for i in shape_vertices.size():
			shape_vertices_x.append(shape_vertices[i].x)
			shape_vertices_y.append(shape_vertices[i].y)
		province_data["shape"] = {
			"x": shape_vertices_x,
			"y": shape_vertices_y,
		}
		
		# Armies
		var armies_data: Array = []
		for army in province.armies.armies:
			var army_data: Dictionary = {
				"id": army.id,
				"army_size": army.army_size.current_size(),
				"owner_country_id": army._owner_country.id,
			}
			armies_data.append(army_data)
		province_data["armies"] = armies_data
		
		# Population
		province_data["population"] = {
			"size": province.population.population_size,
		}
		
		# Buildings
		var buildings_data: Array = []
		for building in province.buildings._buildings:
			# Ugly, but I'll bother when we have more buildings
			buildings_data.append({"type": "fortress"})
		province_data["buildings"] = buildings_data
		
		provinces_data.append(province_data)
	world_data["provinces"] = provinces_data
	json_data["world"] = world_data
	
	# Turn
	json_data["turn"] = float(game._game_state.turn._turn)
	
	# Success!
	error = false
	result = json_data
