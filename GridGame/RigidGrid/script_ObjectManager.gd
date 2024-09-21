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

var rigidGridCount = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	createRigidGrid("Test", physicsDataDump.new(Vector2(-32, -32)), 
	{"0":[
		[ #Row 1
			0b1001 #Boxes
		] , [ #Row 2
			0b0101 #Boxes
		],
	]}
	)

func createRigidGrid(rgName:String, physDump:physicsDataDump, data:Dictionary):
	var newRigidGrid = RigidGrid.instantiate()
	newRigidGrid.freeze_mode = 1
	newRigidGrid.freeze = true
	newRigidGrid.position = physDump.pos
	newRigidGrid.linear_velocity = physDump.lvel
	newRigidGrid.angular_velocity = physDump.avel
	newRigidGrid.name = rgName
	add_child(newRigidGrid)
	newRigidGrid.initialize(data)

func breakUpRigidGrid(rgName:String):
	var grid = get_node(rgName)
