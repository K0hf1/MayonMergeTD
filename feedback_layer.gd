# FeedbackLayer.gd
extends Node2D

# Dictionary of labels keyed by feedback type
@onready var labels := {
	"not_enough_coins": $NotEnoughCoins,
	"no_slots_left": $NoSlotsLeft
}

var tweens := {}

func show_message(feedback_type: String, text: String):
	if not labels.has(feedback_type):
		push_warning("No label found for feedback type: %s" % feedback_type)
		return
	
	var lbl = labels[feedback_type]
	lbl.text = text
	lbl.visible = true
	lbl.modulate.a = 1.0

	# Kill previous tween for this label if exists
	if tweens.has(feedback_type) and is_instance_valid(tweens[feedback_type]):
		tweens[feedback_type].kill()

	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tweens[feedback_type] = tween
