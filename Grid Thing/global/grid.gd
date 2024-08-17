class_name Grid

#Variables
var blocks:bitField;
var dimensions:Vector2i;
var length:Vector2;
var com:Vector2;
var blockLength:Vector2;
var yOffset:int;
var area:int;
var cachedMeshes:Array = [];
var uniqueBlocks:int;

#Constructor
static func create(dims: Vector2i, conLength: Vector2, blockCount:int):
	var newGrid = Grid.new();
	newGrid.dimensions = dims;
	newGrid.length = conLength;
	newGrid.com = conLength/2;
	newGrid.blockLength = conLength/Vector2(dims);
	newGrid.yOffset = Util.bitCount(dims.x);
	newGrid.area = dims.x * dims.y;
	newGrid.cachedMeshes.resize(blockCount)
	newGrid.blocks = bitField.create(newGrid.area, Util.bitCount(blockCount)-1);
	newGrid.uniqueBlocks = blockCount;
	return newGrid

#Instance function start
func decode(key:int):
	return Vector2i(key%dimensions.x, key/dimensions.x)

func encode(coord:Vector2i):
	return coord.y*dimensions.x + coord.x

func assign(key:int, value:int):
	var oldVal = blocks.modify(key, value);
	return oldVal

func read(key:int):
	return blocks.read(key)

func pointToKey(point:Vector2):
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

func keyToPoint(key):
	return blockLength*Vector2(decode(key)) - com

#Will only read up to the first 64 packs of the row
func _rowToInt(rowNum:int, matchedValues:Array[int]):
	var rows:Array = [];
	for block in matchedValues.size():
		rows.push_back(0)
	var index:int = dimensions.x*rowNum;
	var rowData:Array[int] = blocks.readSection(dimensions.x, index);
	var packCounter:int = 0;
	for i in dimensions.x:
		var dataBox:int = packCounter/blocks.packsPerBox;
		var val:int = rowData[dataBox] & blocks.packMask;
		rowData[dataBox] = Util.rightShift(rowData[dataBox], blocks.packSize);
		for block in matchedValues.size():
			if (matchedValues[block] == val):
				rows[block] += 1 << (packCounter % blocks.boxSize);
		packCounter += 1;
	return rows

func reCacheMeshes(blocksChanged:Array[int]):
	var newMesh:Array = greedyMesh(blocksChanged);
	for block in blocksChanged.size():
		cachedMeshes[blocksChanged[block]] = newMesh[block]

#Cannot mesh grids larger than 64 in any dimension
func greedyMesh(blocksToBeMeshed:Array[int]):
	var blockGrids:Array = [];
	var meshedBoxes:Array = []
	#Set up initial arrays
	for block in blocksToBeMeshed.size():
		blockGrids.push_back([])
		meshedBoxes.push_back([]);
	for row in dimensions.y:
		var rowData:Array = _rowToInt(row, blocksToBeMeshed);
		for block in blockGrids.size():
			blockGrids[block].push_back(rowData[block])
	#Actual meshing
	for block in blocksToBeMeshed.size():
		while (blockGrids[block].max() != 0): #While grid hasn't been fully swept
			for row in dimensions.y: #Search each row
				var rowData:int = blockGrids[block][row];
				if (rowData == 0): #Row is empty
					continue #Go on to next row
				else: #At least one mask exists in current row
					var masks:Array = Util.findMasksInBitRow(rowData); 
					for maskData in masks: #For each mask found
						var curMask:int = maskData[0]
						var box:Rect2i = Rect2i(0,0,0,0)
						box.position.y = row;
						box.position.x = maskData[1];
						box.size.x = maskData[2];
						for curRowSearching in range(row, dimensions.y): #Search each remaining row
							if (blockGrids[block][curRowSearching] & curMask == curMask): #Mask exists in row
								blockGrids[block][curRowSearching] &= ~curMask; #Eliminate mask from row
								box.size.y += 1
							else:
								break #Mask can
						meshedBoxes[block].push_back(box);
	return meshedBoxes
