extends Node

const rigidGrid = preload("./GridInstance/RigidGrid.scn")

var blockTypes:BlockTypes = BlockTypes.new();

func defineBlocks(object_BlockTypes):
	object_BlockTypes.addNewBlock("green", preload("res://RigidGrid/Textures/green.png"), false)
	object_BlockTypes.addNewBlock("red", preload("res://RigidGrid/Textures/red.png"), true, 1)

var rigidGridCount = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	defineBlocks(blockTypes);
	createRigidGrid(Vector2(-25, -30), null)

func createRigidGrid(position:Vector2, data:Util.fixedPackedArray):
	var instance = rigidGrid.instantiate()
	instance.position = position
	instance.name = "Grid " + String.num_int64(rigidGridCount)
	add_child(instance)
	get_node("././")
	rigidGridCount += 1
