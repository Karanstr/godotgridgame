extends Node
class_name ObjectManager

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
	rigidGridCount += 1
	instance.addChunk("0")


const chunkScript = preload("./GridInstance/script_Chunk.gd")

static func createChunk(chunkName:String, _grid:Array):
	var chunk:Node2D = Node2D.new();
	chunk.set_script(chunkScript);
	var blockSize:Vector2 = Vector2(8, 8) #Units
	var gridSize:Vector2i = Vector2i(4, 4) #Cells
	chunk.name = chunkName;
	chunk.initialize(blockSize, gridSize);
	return chunk
