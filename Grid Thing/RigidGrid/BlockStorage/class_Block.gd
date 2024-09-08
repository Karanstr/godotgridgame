class_name Block

var name:String;
var texture;
var collision:bool;
var weight:int

func _init(blockName:String, image, doesCollide:bool, blockWeight:int = 0):
	name = blockName;
	texture = image;
	collision = doesCollide;
	weight = blockWeight
