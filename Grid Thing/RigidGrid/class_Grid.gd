class_name Grid

#Variables
var blocks:bitField;
var dimensions:Vector2i;
var length:Vector2;
var com:Vector2;
var blockLength:Vector2;
var area:int;
var cachedRects:Array = [];
var uniqueBlocks:int = 0;

var binaryStrings_block_row:Array = [];

#Constructor
static func create(length:Vector2, uniqueBlockCount:int, dimensions:Vector2i = Vector2i(64,64)) -> Grid:
	var newGrid = Grid.new();
	newGrid.dimensions = dimensions;
	newGrid.area = newGrid.dimensions.x * newGrid.dimensions.y;
	
	newGrid.length = length;
	newGrid.com = length/2;
	newGrid.blockLength = length/Vector2(newGrid.dimensions);
	
	newGrid.uniqueBlocks = uniqueBlockCount;
	newGrid.blocks = bitField.create(newGrid.area, Util.bitsToStore(newGrid.uniqueBlocks));
	newGrid._recacheBinaryStrings()
	#Super silly this has to be here but the array has to be initialized somewhere
	for block in newGrid.uniqueBlocks: 
		newGrid.cachedRects.push_back([]);
	
	return newGrid

func _recacheBinaryStrings():
	var newBinaryStrings:Array = [];
	var tempArrays:Array = [];
	var allBlocks:Array[int] = [];
	for block in uniqueBlocks:
		allBlocks.push_back(block);
	for row in dimensions.y:
		tempArrays.push_back(blocks.rowToInt(dimensions.x, row, allBlocks));
	for block in uniqueBlocks:
		newBinaryStrings.push_back([]);
		for row in dimensions.y:
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binaryStrings_block_row = newBinaryStrings
	return true

#region I/Oing
func decode(key:int) -> Vector2i:
	return Vector2i(key%dimensions.x, key/dimensions.x)

func encode(coord:Vector2i) -> int:
	return coord.y*dimensions.x + coord.x

func assign(key:int, value:int) -> int:
	var oldVal = blocks.modify(key, value);
	var coords = decode(key)
	var mask = 1 << coords.x
	binaryStrings_block_row[value][coords.y] |= mask
	binaryStrings_block_row[oldVal][coords.y] &= ~mask
	return oldVal

func read(key:int) -> int:
	return blocks.read(key)

func pointToKey(point:Vector2) -> Array[int]:
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

func keyToPoint(key:int) -> Vector2:
	return blockLength*Vector2(decode(key)) - com

#endregion

#region Recting

func greedyRect(updateBlocks:Array[int]) -> Array:
	#_recacheBinaryStrings()
	var blockGrids:Array = binaryStrings_block_row.duplicate(true);
	var meshedBoxes:Array = []
	#Set up initial arrays
	for block in updateBlocks:
		meshedBoxes.push_back([]);
	#Actual meshing
	for block in updateBlocks.size():
		while (blockGrids[block].max() + blockGrids[block].min() != 0): #While grid hasn't been fully swept
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
								break #Mask does not exist in row, shape is complete
						meshedBoxes[block].push_back(box);
	return meshedBoxes

func reCacheRects(blocksChanged:Array[int]) -> void:
	var newRects:Array = greedyRect(blocksChanged);
	for block in blocksChanged:
		cachedRects[block] = newRects[block]

#endregion

#region Connectivity

func nextChecks(mask:int, row:int):
	var left = Util.leftShift(mask, 1)
	var right = Util.rightShift(mask, 1)
	var checks = [
	false if left == 0 else Vector2i(left, row),
	false if right == 0 else Vector2i(right, row),
	false if row + 1 == dimensions.y else Vector2i(mask, row + 1),
	false if row - 1 == -1 else Vector2i(mask, row - 1)
	]
	return checks

func walkAround(blocksConnected:Array[int]):
	var binaryArray:Array[int] = []
	for row in dimensions.y:
		binaryArray.push_back(0)
		for block in blocksConnected:
			binaryArray[row] |= binaryStrings_block_row[block][row]
	if (binaryArray.max() == 0): #Can't search through a non array
		return 0
	var foundBlocks = 1;
	var dirSave = [
		[0, 2, 3],
		[1, 2, 3],
		[0, 1, 2],
		[0, 1, 3]
	]
	var checks:Array = [[], [], [], []];
	for row in dimensions.y: #Find first row with data
		if (binaryArray[row] != 0):
			var mask = Util.findRightSetBit(binaryArray[row])
			var newChecks = nextChecks(mask, row)
			for direction in 4:
				checks[direction].push_back(newChecks[direction])
			binaryArray[row] &= ~mask
			break
	var allFound = false 
	while !allFound:
		var empty = 0;
		for dir in checks.size():
			var check = checks[dir].pop_back()
			while (typeof(check) == 1): #Typeof is stupid
				check = checks[dir].pop_back()
			if (check == null):
				empty += 1
			else:
				if (binaryArray[check.y] & check.x != 0):
					foundBlocks += 1
					binaryArray[check.y] &= ~check.x
					var newChecks = nextChecks(check.x, check.y)
					for direction in dirSave[dir]:
						checks[direction].push_back(newChecks[direction])
		if empty == 4:
			allFound = true
	if (binaryArray.max() != 0):
		print("Not attached")
	return foundBlocks

func makeNextChecks(mask:int, row:int):
	var checks:Array = [
	false if row + 1 == dimensions.y else Vector2i(mask, row + 1),
	false if row - 1 == -1 else Vector2i(mask, row - 1)
	]
	return checks 

func fasterWalkAround(blocksConnected:Array[int]):
	var foundBlocks = 1;
	var checks:Array = []
	var binaryArray:Array[int] = []
	for row in dimensions.y:
		binaryArray.push_back(0)
		for block in blocksConnected:
			binaryArray[row] |= binaryStrings_block_row[block][row]
	if (binaryArray.max() == 0): #Can't search through a non array
		return 0
	for row in dimensions.y: #Find first row with data
		if (binaryArray[row] != 0):
			var fullMask = Util.findFirstMask(binaryArray[row])
			checks.append_array(makeNextChecks(fullMask, row))
			binaryArray[row] &= ~fullMask
			break
	while checks.is_empty() == false:
		var curCheck = checks.pop_back()
		while typeof(curCheck) == 1:
			curCheck = checks.pop_back()
		if curCheck == null:
			continue
		var newMask = binaryArray[curCheck.y] & curCheck.x
		if (newMask != 0):
			var masks:Array[int] = [];
			while newMask != 0:
				foundBlocks += 1;
				var foundMask = Util.findFirstMask(newMask)
				newMask &= ~foundMask
				masks.push_back(foundMask)
			for mask in masks:
				var fullMask = Util.extendMask(binaryArray[curCheck.y], mask) 
				binaryArray[curCheck.y] &= ~fullMask
				checks.append_array(makeNextChecks(fullMask, curCheck.y))
	if (binaryArray.max() != 0):
		print("Not attached")
	return foundBlocks

#endregion

#
