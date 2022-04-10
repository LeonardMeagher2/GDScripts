@tool
extends HBoxContainer

@export var icon:Texture2D :
	set(value):
		icon = value
		if is_inside_tree():
			$TextureRect.texture = icon

@export var path:String :
	set(value):
		path = value
		if is_inside_tree():
			$Label.text = path

func _enter_tree():
	$TextureRect.texture = icon
	$Label.text = path
