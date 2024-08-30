class_name BlockTypes

var array: Array[Block];
#var map: Dictionary;

#Constructor
static func create() -> BlockTypes:
	var newBlockTypes:BlockTypes = BlockTypes.new()
	return newBlockTypes 

func addBlock(name:String, texture, doesCollide:bool):
	var newBlock:Block = Block.create(name, texture, doesCollide)
	array.push_back(newBlock)
	return array.size()-1 #Index of new block

func addExistingBlock(block:Block):
	array.push_back(block)
	return array.size()-1 #Index of new block

func removeBlock(index:int):
	var deletedBlock:Block = array[index];
	array.remove_at(index)
	return deletedBlock
