class_name GameNotification
## Informs a specific [Country] of something.
## The country can either dismiss the notification
## or choose between some predefined outcome options.
## The notification is automatically dismissed after some number of turns.
##
## This is a base class, so it doesn't do anything.
## Extend this class to give it functionality, outcome options, etc.


signal handled(this: GameNotification)

const DEFAULT_TURNS_BEFORE_DISMISS: int = 3

## The unique id assigned to this notification.
## Each notification has its own id.
## Useful for saving/loading, networking, etc.
var id: int = -1

var _game: Game
var _recipient_country: Country

## The turn on which this notification was created.
var _creation_turn: int = 1

## The number of turns before this notification is automatically dismissed.
var _turns_before_dismiss: int

## The number of turns before automatically dismissing will only
## go down when the recipient country has seen the notification.
var _was_seen_this_turn: bool

## To be setup by subclasses.
## Please make sure there is the same number of names and functions,
## even if the outcome is meant to do nothing.
## If these are left empty, then there will be no outcome, in which case
## the only way to get rid of the notification is to dismiss it.
var _outcome_names: Array[String] = []
var _outcome_functions: Array[Callable] = []


func _init(
		game: Game,
		recipient_country: Country,
		creation_turn_: int = game.turn.current_turn(),
		turns_before_dismiss: int = DEFAULT_TURNS_BEFORE_DISMISS,
		was_seen_this_turn: bool = false,
) -> void:
	_game = game
	_recipient_country = recipient_country
	_creation_turn = creation_turn_
	_turns_before_dismiss = turns_before_dismiss
	_was_seen_this_turn = was_seen_this_turn
	_on_player_changed(game.turn.playing_player())

	game.turn.turn_changed.connect(_on_turn_changed)
	game.turn.player_changed.connect(_on_player_changed)


## Returns the turn on which this notification was created.
func creation_turn() -> int:
	return _creation_turn


func number_of_outcomes() -> int:
	return _outcome_names.size()


func outcome_names() -> Array[String]:
	return _outcome_names.duplicate()


## The icon to display on screen. May be null.
## Meant to be overridden by subclasses.
func icon() -> Texture2D:
	return null


## Human-friendly text that gives information about the notification.
## Meant to be overridden by subclasses.
func description() -> String:
	return ""


func select_outcome(outcome_index: int) -> void:
	if not _outcome_can_be_selected():
		return

	if outcome_index < 0:
		dismiss()
		return
	elif outcome_index >= _outcome_names.size():
		push_error(
				"Tried to select a notification's outcome, but "
				+ "the given outcome index is out of bounds! "
				+ "The notification will be dismissed."
		)
		dismiss()
		return

	_outcome_functions[outcome_index].call()
	handled.emit(self)


func dismiss() -> void:
	handled.emit(self)


func _outcome_can_be_selected() -> bool:
	if _game == null:
		return true

	var playing_country: Country = _game.turn.playing_player().playing_country

	if playing_country != _recipient_country:
		push_warning(
				"Tried to select an outcome for a notification, but "
				+ "a country cannot handle another country's notifications!"
		)
		return false

	return true


func _on_player_changed(player: GamePlayer) -> void:
	if player.playing_country == _recipient_country:
		_was_seen_this_turn = true


func _on_turn_changed(_turn: int) -> void:
	if _was_seen_this_turn:
		_turns_before_dismiss -= 1
		if _turns_before_dismiss < 1:
			dismiss()
	_was_seen_this_turn = false
