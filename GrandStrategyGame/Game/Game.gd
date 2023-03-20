extends Node2D


@export var world_scene: PackedScene
@export var province_scene: PackedScene
@export var number_of_troops_scene: PackedScene

var current_turn: int = 1


func _ready():
	var world: Node = world_scene.instantiate()
	var scenario := world.get_node("Scenarios/Scenario1") as Scenario4
	
	# Set the camera's limits
	var camera := $Camera2D as Camera2D
	var world_size_node := world.get_node("WorldSize") as Marker2D
	camera.limit_right = int(world_size_node.position.x)
	camera.limit_bottom = int(world_size_node.position.y)
	
	var countries: Array[Country] = scenario.get_playable_countries()
	var you := $Players/You as PlayerHuman
	you.playing_country = countries[randi() % countries.size()]
	($CanvasLayer/GameUI/Chat as Chat).system_message(
		"You are playing as " + you.playing_country.country_name
	)
	for country in countries:
		if country != you.playing_country:
			var country_ai: PlayerAI = scenario.get_new_ai_for(country)
			country_ai.init(country)
			$Players.add_child(country_ai)
		$Countries.add_child(country)
	
	# Setup provinces
	var shapes: Node = world.get_node("Shapes")
	var links: Array = []
	var provinces: Array[Province] = []
	var province_count: int = shapes.get_child_count()
	for i in province_count:
		# Setup the province itself
		var province_instance := province_scene.instantiate() as Province
		var shape := shapes.get_child(i) as ProvinceTestData
		links.append(shape.links)
		province_instance.set_shape(shape.polygon)
		province_instance.position = shape.position
		provinces.append(province_instance)
		
		# Setup the armies component
		var armies := Armies.new()
		armies.name = "Armies"
		var army_host_node := shape.get_node("ArmyHost") as Marker2D
		armies.position_army_host = army_host_node.global_position
		province_instance.add_component(armies)
		
		# Connect the signals
		province_instance.connect(
			"selected", Callable(self, "_on_province_selected")
		)
	
	# Setup links
	for i in province_count:
		provinces[i].links = []
		var number_of_links: int = links[i].size()
		for j in number_of_links:
			provinces[i].links.append(provinces[links[i][j] - 1])
		$Provinces.add_child(provinces[i])
	
	# Setup the game's scenario
	var provinces_node := $Provinces as Provinces
	scenario.populate_provinces(provinces_node.get_provinces(), countries)


func _on_game_over(country: Country):
	var game_over_node := $CanvasLayer/GameUI/GameOverScreen as GameOver
	game_over_node.show()
	game_over_node.set_text(country.country_name + " wins!")


func _on_province_selected(province: Province):
	var player_country: Country = ($Players/You as PlayerHuman).playing_country
	var provinces_node := $Provinces as Provinces
	if provinces_node.a_province_is_selected():
		var selected_province: Province = provinces_node.selected_province
		var selected_armies := selected_province.get_node("Armies") as Armies
		if selected_armies.country_has_active_army(player_country):
			var army: Army = selected_armies.get_active_armies_of(player_country)[0]
			if selected_armies.army_can_be_moved_to(army, province):
				# Show interface for selecting a number of troops
				var troop_ui := number_of_troops_scene.instantiate() as RecruitUI
				troop_ui.name = "RecruitUI"
				troop_ui.setup(army, selected_province, province)
				troop_ui.connect(
					"cancelled", Callable(self, "_on_recruit_cancelled")
				)
				troop_ui.connect(
					"move_troops", Callable(self, "move_troops")
				)
				$CanvasLayer.add_child(troop_ui)
				return
	provinces_node.select_province(province)
	
	var armies_node := province.get_node("Armies") as Armies
	if armies_node.country_has_active_army(player_country):
		province.show_neighbours(2)
	else:
		province.show_neighbours(3)


func _on_background_clicked():
	unselect_province()


func _on_recruit_cancelled():
	unselect_province()


func _on_chat_requested_province_info():
	var provinces_node := $Provinces as Provinces
	var chat_node := $CanvasLayer/GameUI/Chat as Chat
	
	if not provinces_node.a_province_is_selected():
		chat_node.system_message("No province selected.")
		return
	
	var selected_province: Province = provinces_node.selected_province
	var population_node := selected_province.get_node("Population") as Population
	var population_count: int = population_node.population_count
	chat_node.system_message(
		"Population count: " + str(population_count)
	)


func unselect_province():
	($Provinces as Provinces).unselect_province()


func move_troops(
	army: Army,
	number_of_troops: int,
	source: Province,
	destination: Province
):
	unselect_province()
	
	var rules_node := $Rules as Rules
	var action_move := ActionArmyMovement.new(army, destination)
	if not rules_node.action_is_legal(action_move):
		return
	
	# Split the army into two if needed
	var action_split := ActionArmySplit.new(
		army,
		source,
		[number_of_troops, army.troop_count - number_of_troops]
	)
	if army.troop_count > number_of_troops:
		if not rules_node.action_is_legal(action_split):
			return
		$Players/You/Actions.add_child(action_split)
	
	$Players/You/Actions.add_child(action_move)
	
	# Play the movement animation
	army.play_movement_to(
		army.position
		- army.global_position
		+ (destination.get_node("Armies") as Armies).position_army_host
	)


func end_turn():
	var provinces: Array[Province] = ($Provinces as Provinces).get_provinces()
	var rules_node := $Rules as Rules
	var players: Array[Node] = $Players.get_children()
	for player in players:
		# Have the AI play their moves
		if player is PlayerAI:
			(player as PlayerAI).play(provinces)
		
		# Go through each player's actions
		var actions: Array[Action] = (player as Player).get_actions()
		for action in actions:
			rules_node.connect_action(action)
			if rules_node.action_is_legal(action):
				action.play_action()
			else:
				action.queue_free()
	
	# Merge armies
	provinces = ($Provinces as Provinces).get_provinces()
	for province in provinces:
		(province.get_node("Armies") as Armies).merge_armies()
	
	current_turn += 1
	rules_node.start_of_turn(provinces, current_turn)
