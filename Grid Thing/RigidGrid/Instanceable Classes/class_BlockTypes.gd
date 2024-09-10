class_name BlockTypes

class Block:
	var name:String;
	var texture;
	var collision:bool;
	var weight:int
	func _init(blockName:String, image, doesCollide:bool, blockWeight:int = 0):
		name = blockName;
		texture = image;
		collision = doesCollide;
		weight = blockWeight

var array: Array[Block];
var solidBlocks:Dictionary = {}

func _init():
	addNewBlock("green", preload("res://RigidGrid/Textures/green.png"), false)
	addNewBlock("red", preload("res://RigidGrid/Textures/red.png"), true, 1)

func addNewBlock(name:String, texture, doesCollide:bool, weight:int = 0):
	var newBlock:Block = Block.new(name, texture, doesCollide, weight)
	array.push_back(newBlock)
	if doesCollide: solidBlocks.get_or_add(array.size()-1)
	return array.size()-1 #Index of new block
