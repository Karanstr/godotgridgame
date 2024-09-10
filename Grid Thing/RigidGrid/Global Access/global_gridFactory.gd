class_name GridFactory

static var blockArray:BlockTypes = BlockTypes.new();

const chunkScript = preload("../GridInstance/script_Chunk.gd")



static func createChunk(name:String):
	var chunk:Node2D = Node2D.new();
	chunk.set_script(chunkScript);
	var chunkSize:Vector2 = Vector2(64, 64) #Units
	var gridSize:Vector2i = Vector2i(8,8) #Cells
	chunk.name = name;
	chunk.initialize(chunkSize, blockArray, gridSize);
	return chunk
