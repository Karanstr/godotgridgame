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

static var maxBlockIndex = 2;

static var blocks:Dictionary = {
	1: Block.new("green", preload("res://RigidGrid/Textures/green.png"), true, 1),
	2: Block.new("red", preload("res://RigidGrid/Textures/red.png"), true, 2)
}
static var solidBlocks:Dictionary = {
	2: null,
}
