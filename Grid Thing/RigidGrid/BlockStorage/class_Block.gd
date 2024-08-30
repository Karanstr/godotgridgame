class_name Block

var name:String;
var image;
var collision:bool;
var weight:int

#Constructor
static func create(blockName:String, blockColor, doesCollide:bool, weight:int = 0) -> Block:
	var block:Block = Block.new();
	
	block.name = blockName;
	block.image = blockColor;
	block.collision = doesCollide;
	block.weight = weight;
	
	return block
