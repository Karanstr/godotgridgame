class_name Block

var name:String;
var color;
var collision:bool;

#Constructor
static func create(blockName:String, blockColor:Color, doesCollide:bool) -> Block:
	var block:Block = Block.new();
	
	block.name = blockName;
	block.color = blockColor;
	block.collision = doesCollide;
	
	return block
