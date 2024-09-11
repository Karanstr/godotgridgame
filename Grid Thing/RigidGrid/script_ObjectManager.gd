extends Node

const rigidGrid = preload("./GridInstance/RigidGrid.scn")

var rigidGridCount = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	createRigidGrid(Vector2(-32, -32))

func createRigidGrid(position:Vector2):
	var instance = rigidGrid.instantiate()
	instance.position = position
	instance.name = "Grid " + String.num_int64(rigidGridCount)
	add_child(instance)
	instance.addChunk("0")
	rigidGridCount += 1
