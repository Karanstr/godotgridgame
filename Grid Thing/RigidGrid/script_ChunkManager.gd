extends Node2D

var chunkScript = preload("res://RigidGrid/script_Chunk.gd")
var blockTypes:BlockTypes = BlockTypes.create();

func defineBlocks(object_BlockTypes):
	object_BlockTypes.addNewBlock("green", preload("res://RigidGrid/Textures/green.png"), false)
	object_BlockTypes.addNewBlock("red", preload("res://RigidGrid/Textures/red.png"), true, 1)

func _ready():
	defineBlocks(blockTypes)
	addNewChunk(Vector2i(0,0), blockTypes)
	updateCOM(Vector2(1,1))

func addNewChunk(_chunkLocation:Vector2i, blockTypes):
	var newChunk:Node2D = Node2D.new();
	newChunk.set_script(chunkScript);
	newChunk.name = "0";
	newChunk.init(Vector2(64, 64), blockTypes, Vector2i(8,8));
	add_child(newChunk)

func removeChunk(chunkName:String):
	var removedChunk = get_node("../" + chunkName)
	removedChunk.grid.save()
	#Delete Physics and Render meshes
	removedChunk.free()

func updateCOM(COM:Vector2):
	get_node("../").center_of_mass = COM
	#Go up the line, get COMs and weights for each chunk, then recalculate and get real COM
	pass
#
