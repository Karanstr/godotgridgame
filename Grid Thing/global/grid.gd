class_name Grid
#Variables
var blocks:bitField;
var dimensions:Vector2i;
var length:Vector2;
var com:Vector2;
var blockLength:Vector2;
var yOffset:int;
var area:int;
#Constructor
static func create(dims: Vector2i, conLength: Vector2):
	var newGrid = Grid.new();
	newGrid.dimensions = dims;
	newGrid.length = conLength;
	newGrid.com = conLength/2;
	newGrid.blockLength = conLength/Vector2(dims);
	newGrid.yOffset = Util.bitCount(dims.x);
	newGrid.area = dims.x * dims.y;
	#The one in the following constructor is based on
	#how many types of blocks need saving, 2**n
	newGrid.blocks = bitField.create(newGrid.area, 5);
	return newGrid

#Instance function start
func decode(key:int):
	return Vector2i(key%dimensions.x, key/dimensions.x)

func encode(coord:Vector2i):
	return coord.y*dimensions.x + coord.x

func assign(key:int, value:int):
	var oldVal = blocks.read(key);
	blocks.modify(key, value);
	return oldVal
	
func read(key:int):
	return blocks.read(key)

func pointKey(point:Vector2):
	var offset:Vector2 = Vector2(.01,.01)
	var keys:Array[int] = [];
	for x in range(0, 2):
		for y in range(0, 2):
			var woint:Vector2 = offset - 2*offset*Vector2(x,y) + point
			if woint.x > 0 && woint.x < length.x && woint.y > 0 && woint.y < length.y:
				keys.append(encode(woint/blockLength))
			else:
				keys.append(-1)
	return keys

func greedyMesh():
	
	pass







