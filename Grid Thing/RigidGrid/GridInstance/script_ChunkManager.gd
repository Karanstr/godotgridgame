extends Node2D

const chunkScript = preload("./script_Chunk.gd")
var manager; #Const

func _ready():
	manager = get_node("../../")
	addNewChunk(Vector2i(0,0), manager.blockTypes)

func addNewChunk(_chunkLocation:Vector2i, object_BlockTypes):
	var newChunk:Node2D = Node2D.new();
	newChunk.set_script(chunkScript);
	newChunk.name = "0";
	newChunk.initialize(Vector2(64, 64), object_BlockTypes, Vector2i(8,8));
	add_child(newChunk)

func removeChunk(chunkName:String):
	var removedChunk = get_node("../" + chunkName)
	removedChunk.grid.save()
	#Delete Physics and Render meshes
	removedChunk.free()

func updateRigidGrid(COM:Vector2, mass:int):
	var rigidgrid = get_node("../")
	rigidgrid.center_of_mass = COM
	rigidgrid.mass = mass
	#Go up the line, get COMs and weights for each chunk, then recalculate and get real COM
	pass
#
