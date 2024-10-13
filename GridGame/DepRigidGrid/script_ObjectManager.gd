extends Node
class_name ObjectManager

class physicsDataDump:
	var pos:Vector2
	var lvel:Vector2
	var avel:float
	func _init(position:Vector2 = Vector2(0,0), linearvelocity:Vector2 = Vector2(0,0), angularvelocity:float = 0):
		pos = position
		avel = angularvelocity
		lvel = linearvelocity

const RigidGrid = preload("./GridInstance/RigidGrid.scn")

var rigidGridCount = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	createRigidGrid(physicsDataDump.new(Vector2(0,0)), "World", Rect2i(0, 4, 5, 1), [[0b1010101010]])

func createRigidGrid(physDump:physicsDataDump, rgName:String, insert:Rect2i = Rect2i(0, 0, 0, 0), data:Array = []):
	var newRigidGrid = RigidGrid.instantiate()
	newRigidGrid.freeze_mode = 1
	if rgName == "World": 
		newRigidGrid.freeze = true
	newRigidGrid.position = physDump.pos
	newRigidGrid.linear_velocity = physDump.lvel
	newRigidGrid.angular_velocity = physDump.avel
	newRigidGrid.name = rgName
	add_child(newRigidGrid)
	newRigidGrid.createChunk(insert, data)
	rigidGridCount += 1
