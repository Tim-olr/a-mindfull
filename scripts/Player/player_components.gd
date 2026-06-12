extends Node2D
class_name PlayerComponents

func add_component(component):
	add_child(component)

func find_component(component_name: String):
	for i: Component in get_children():
		if i.component_name == component_name: return i

func remove_component(component_name: String):
	for i: Component in get_children():
		if i.component_name == component_name: remove_child(i)
