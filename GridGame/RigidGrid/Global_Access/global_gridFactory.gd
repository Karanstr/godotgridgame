class_name GridFactory

const chunkScript = preload("../GridInstance/script_Chunk.gd")

static func createChunk(name:String):
	var chunk:Node2D = Node2D.new();
	chunk.set_script(chunkScript);
	var blockSize:Vector2 = Vector2(8, 8) #Units
	var gridSize:Vector2i = Vector2i(2,2) #Cells
	chunk.name = name;
	chunk.initialize(blockSize, gridSize);
	return chunk

static func formatGrid(_data):
	pass
