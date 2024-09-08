class_name BlockTypes

var array: Array[Block];
var solidBlocks:Dictionary = {}

func addNewBlock(name:String, texture, doesCollide:bool, weight:int = 0):
	var newBlock:Block = Block.new(name, texture, doesCollide, weight)
	array.push_back(newBlock)
	if doesCollide: solidBlocks.get_or_add(array.size()-1)
	return array.size()-1 #Index of new block

func addExistingBlock(block:Block):
	array.push_back(block)
	if block.collision: solidBlocks.get_or_add(array.size()-1)
	return array.size()-1 #Index of new block

func removeBlock(index:int):
	var deletedBlock:Block = array[index];
	array.remove_at(index)
	return deletedBlock

func replaceBlock(index:int, newBlock):
	var oldBlock = array[index];
	array[index] = newBlock
	if newBlock.collision: solidBlocks.get_or_add(index)
	else: solidBlocks.erase(index)
	return oldBlock
