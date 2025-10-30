extends Button

# 1. Add this export variable.
#    This will let you link the music node in the editor.
@export var main_menu_music_node : Node

func _on_pressed() -> void:
	# 2. Check if the node is linked
	if main_menu_music_node:
		# 3. Tell the music node to fade out and change the scene
		main_menu_music_node.fade_out_and_change_scene("res://main.tscn")
	else:
		# Failsafe in case you forgot to link it
		print("❌ ERROR: MainMenuMusic node not linked to StartButton!")
		get_tree().change_scene_to_file("res://main.tscn")
