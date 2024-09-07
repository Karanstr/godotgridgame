extends Node

const rigidGrid = preload("./GridInstance/RigidGrid.scn")

var rigidGridCount = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	createRigidGrid(Vector2(-20, -20), null)

func createRigidGrid(position:Vector2, _data:Util.fixedPackedArray):
	var instance = rigidGrid.instantiate()
	instance.position = position
	instance.name = "Grid " + String.num_int64(rigidGridCount)
	add_child(instance)
	rigidGridCount += 1
