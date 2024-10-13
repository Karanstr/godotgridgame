extends RigidBody2D

const gridCells:Vector2i = Vector2i(64, 64)
var blockSize:Vector2

const chunkScript = preload("script_Chunk.gd")
var chunkCount = 0

func createChunk(insert:Rect2i = Rect2i(0, 0, 0, 0), data:Array = [[]]):
	var chunk:Node2D = Node2D.new()
	chunk.set_script(chunkScript)
	blockSize = Vector2(100, 100) #Units
	chunk.name = String.num_int64(chunkCount)
	add_child(chunk)
	chunk.initialize(blockSize, gridCells)
	for row in insert.size.y:
		var realRow:int = row + insert.position.y
		chunk.grid.modifyRow(realRow, insert.position.x, insert.size.x, data[row], true)
	chunkCount += 1

func exileGroup(group:BinUtil.Group):
	var manager = get_parent()
	manager.createRigidGrid(dumpPhysicsStuff(), String.num_int64(manager.rigidGridCount), group.posDim, group.culledGrid)

func dumpPhysicsStuff():
	return ObjectManager.physicsDataDump.new(position, linear_velocity, angular_velocity)

func updateMass(newMass:int, newCOM:Vector2):
	mass = newMass
	center_of_mass = newCOM

#
