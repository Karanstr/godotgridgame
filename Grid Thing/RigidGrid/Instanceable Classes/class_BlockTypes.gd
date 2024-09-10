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

var blocks:Dictionary = {}
var solidBlocks:Dictionary = {}
#var blockCount:int = 0;
var maxBlockIndex = 0;

func _init():
	addNewBlock(1, "green", preload("res://RigidGrid/Textures/green.png"), false)
	addNewBlock(2, "red", preload("res://RigidGrid/Textures/red.png"), true, 1)

func addNewBlock(index:int, name:String, texture, doesCollide:bool, weight:int = 0):
	var newBlock:Block = Block.new(name, texture, doesCollide, weight)
	blocks.get_or_add(index, newBlock)
	if doesCollide: solidBlocks.get_or_add(index)
	if (index > maxBlockIndex): maxBlockIndex = index
