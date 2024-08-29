class_name Block

var name:String;
var color;
var collision:bool;
var weight:int

#Constructor
static func create(blockName:String, blockColor:Color, doesCollide:bool, weight:int = 0) -> Block:
	var block:Block = Block.new();
	
	block.name = blockName;
	block.color = blockColor;
	block.collision = doesCollide;
	block.weight = weight;
	
	return block
