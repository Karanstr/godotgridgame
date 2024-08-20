extends Node

var chunkScript = load("res://RigidGrid/chunk_Script.gd")

func _ready():
	addNewChunk(Vector2i(0,0))

func addNewChunk(chunkLocation:Vector2i):
	var newChunk:Node2D = Node2D.new();
	newChunk.set_script(chunkScript)
	newChunk.name = "0"
	newChunk.init(Vector2(500, 500), 8)
	add_child(newChunk)

func removeChunk(chunkName:String):
	var removedChunk = get_node("../" + chunkName)
	removedChunk.grid.save()
	#Delete Physics and Render meshes
	removedChunk.free()
