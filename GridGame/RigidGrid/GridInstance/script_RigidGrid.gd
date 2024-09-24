extends RigidBody2D

func initialize(chunks:Dictionary):
	for chunk in chunks:
		var hasData:bool = true
		if chunks[chunk].size() == 0:
			hasData = false
		createChunk(chunk, hasData, chunks[chunk])
	if name != "World": freeze = false

const chunkScript = preload("script_Chunk.gd")

func createChunk(chunkName:String, hasData:bool = false, data:Array = []):
	var chunkData = data#.duplicate(true) #Remember to duplicate data because object pointers are funny Unless we don't jkjk unless..
	var chunk:Node2D = Node2D.new()
	chunk.set_script(chunkScript)
	var blockSize:Vector2 = Vector2(100, 100) #Units
	var gridSize:Vector2i
	if (hasData):
		var rowCount:int = data.size()
		var boxesPR:int = data[0].size()
		var blocksInRow:int = 1
		for row in rowCount:
			var checkData = data[row][boxesPR-1]
			if checkData > blocksInRow && blocksInRow > 0: blocksInRow = checkData
			elif checkData < blocksInRow && blocksInRow < 0: blocksInRow = checkData
		blocksInRow = ceil(float(BinUtil.bitCount(blocksInRow)) / packedGrid.bitsPerBlock)
		gridSize = Vector2i(blocksInRow, rowCount) #Cells
	chunk.name = chunkName
	add_child(chunk)
	chunk.initialize(blockSize, gridSize, hasData, chunkData)

func exileGroup(culledGrid:Array, topLeftCorner:Vector2):
	var physStuff = dumpPhysicsStuff()
	physStuff.pos += topLeftCorner
	get_parent().createRigidGrid(physStuff, {"0":culledGrid})

func dumpPhysicsStuff():
	return ObjectManager.physicsDataDump.new(position, linear_velocity, angular_velocity)

func updateMass(newMass:int, newCOM:Vector2):
	mass = newMass
	center_of_mass = newCOM

#
