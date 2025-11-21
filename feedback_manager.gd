extends Node2D

@onready var feedback_layer: Node2D = $FeedbackLayer

func show_feedback(type: String):
	match type:
		"not_enough_coins":
			feedback_layer.show_message("not_enough_coins", "Not enough coins!")
		
		"no_slots_left":
			feedback_layer.show_message("no_slots_left", "Defender Slots Full!")
