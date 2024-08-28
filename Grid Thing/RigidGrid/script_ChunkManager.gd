extends Node2D

var chunkScript = load("res://RigidGrid/script_Chunk.gd")

func _ready():
	addNewChunk(Vector2i(0,0))

func addNewChunk(_chunkLocation:Vector2i):
	var newChunk:Node2D = Node2D.new();
	newChunk.set_script(chunkScript)
	newChunk.name = "0"
	newChunk.init(Vector2(50, 50), Vector2i(8,8))
	add_child(newChunk)

func removeChunk(chunkName:String):
	var removedChunk = get_node("../" + chunkName)
	removedChunk.grid.save()
	#Delete Physics and Render meshes
	removedChunk.free()
