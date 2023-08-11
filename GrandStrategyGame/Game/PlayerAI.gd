class_name PlayerAI
extends Player
# This is the base AI class.
# You can use it as a default AI that does nothing.
# If you want to make your own AI, make a subclass of this class.

## This is where the AI generates its actions based on a given game state
func play(_game_state: GameState) -> Array[Action]:
	return []
