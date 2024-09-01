class_name Block

var name:String;
var texture;
var collision:bool;
var weight:int

#Constructor
static func create(blockName:String, image, doesCollide:bool, weight:int = 0) -> Block:
	var block:Block = Block.new();
	
	block.name = blockName;
	block.texture = image;
	block.collision = doesCollide;
	block.weight = weight;
	
	return block
