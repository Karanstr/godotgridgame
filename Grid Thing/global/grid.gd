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

#Ew gross code refactor at some point
func _rowToBits(rowNum:int, matchedValues:Array[int]):
	var rows:Array = [];
	for block in matchedValues.size():
		rows.push_back([0])
	var index:int = dimensions.x*rowNum;
	var rowData:Array[int] = blocks.readSection(dimensions.x, index);
	var packCounter:int = 0;
	for i in dimensions.x:
		var dataBox:int = packCounter/blocks.packsPerBox;
		var val:int = rowData[dataBox] & blocks.packMask;
		rowData[dataBox] = Util.rightShift(rowData[dataBox], blocks.packSize);
		var blockBox:int = packCounter/blocks.boxSize;
		for block in matchedValues.size():
			if (matchedValues[block] == val):
				rows[block][blockBox] += 1 << (packCounter % blocks.boxSize);
		packCounter += 1;
		if (blockBox != int(packCounter/blocks.boxSize)):
			for block in matchedValues.size():
				rows[block].push_back(0)
	return rows

#Assumes row != 0
func _findMasksInBitRow(row:int):
	var masks:Array = [];
	var remShift:int = 0;
	while row != 0:
		var curMask:int = 0;
		var maskSize:int = 0;
		while row & 1 == 0:
			row = Util.rightShift(row, 1)
			remShift += 1
		while row & 1 == 1:
			curMask = (curMask << 1) + 1
			row = Util.rightShift(row, 1)
			maskSize += 1;
		curMask <<= remShift;
		masks.push_back([curMask, remShift, maskSize]);
		remShift += maskSize;
	return masks

func reCacheMeshes(blocksChanged:Array[int]):
	var newMesh:Array = greedyMesh(blocksChanged);
	for block in blocksChanged.size():
		cachedMeshes[blocksChanged[block]] = newMesh[block]

#Assumes (requires) row length of no more than 64 (one box)
func greedyMesh(blocksToBeMeshed:Array[int]):
	var blockGrids:Array = [];
	var meshedBoxes:Array = []
	#Set up initial arrays
	for block in blocksToBeMeshed.size():
		blockGrids.push_back([])
		blockGrids[block].resize(dimensions.y)
		meshedBoxes.push_back([]);
	for row in dimensions.y:
		var rowData:Array = _rowToBits(row, blocksToBeMeshed);
		for block in blockGrids.size():
			blockGrids[block][row] = rowData[block][0] #THIS 0 TRUNCS ANY ROWS LARGER THAN 1 BOX
	#Actual meshing
	for block in blocksToBeMeshed.size():
		while (blockGrids[block].max() != 0): #While grid hasn't been fully swept
			for row in dimensions.y: #Search each row
				var rowData:int = blockGrids[block][row];
				if (rowData != 0): #If a mask exists in current row
					var masks:Array = _findMasksInBitRow(rowData); 
					for maskData in masks: #For each mask found
						var curMask:int = maskData[0]
						var box:Rect2i = Rect2i(0,0,0,0)
						box.position.y = row;
						box.position.x = maskData[1];
						box.size.x = maskData[2];
						for searchRow in range(row, dimensions.y): #Search each row (ascending)
							if (blockGrids[block][searchRow] & curMask == curMask):
								blockGrids[block][searchRow] &= ~curMask; #Eliminate mask
								box.size.y += 1
							else:
								break #Mask continuity broken
						meshedBoxes[block].push_back(box);
				else: #Check the next row
					continue
	return meshedBoxes
