extends Node2D

const chunkScript = preload("./script_Chunk.gd")

func _ready():
	addNewChunk()

func addNewChunk():
	add_child(GridFactory.createChunk("0"))

func removeChunk(chunkName:String):
	var removedChunk = get_node("../" + chunkName)
	#Delete Physics and Render meshes
	removedChunk.free()

func updateRigidGrid(COM:Vector2, mass:int):
	var rigidgrid = get_node("../")
	rigidgrid.center_of_mass = COM
	rigidgrid.mass = mass
	#Go up the line, get COMs and weights for each chunk, then recalculate and get real COM
#
