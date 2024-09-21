extends RigidBody2D

func initialize(chunks:Dictionary):
	for chunk in chunks:
		var hasData:bool = true
		if chunks[chunk].size() == 0:
			hasData = false
		createChunk(chunk, hasData, chunks[chunk])
	freeze = false

const chunkScript = preload("script_Chunk.gd")

func createChunk(chunkName:String, hasData:bool = false, data:Array = []):
	var chunkData = data#.duplicate(true) #Remember to duplicate data because object pointers are funny Unless we don't jkjk unless..
	var chunk:Node2D = Node2D.new();
	chunk.set_script(chunkScript);
	var blockSize:Vector2 = Vector2(10, 10) #Units
	var gridSize:Vector2i = Vector2i(2, 2) #Cells
	chunk.name = chunkName;
	add_child(chunk)
	chunk.initialize(blockSize, gridSize, hasData, chunkData);

#region Chunk Management

func dumpPhysicsStuff():
	return ObjectManager.physicsDataDump.new(position, linear_velocity, angular_velocity)

func updateMass(newMass:int, newCOM:Vector2):
	mass = newMass
	center_of_mass = newCOM

#endregion

#
