class_name packedGrid #Rename this class

var rows:Array = [];
var blocksPerRow:int;

var bitsPerBlock:int;
var blocksPerBox:int;
var boxesPerRow:int;
var blockMask:int;

var blockTypes:BlockTypes;
var binArrays:Array = [];

func _init(rowCount:int, blocksInRow:int, gridBlockTypes:BlockTypes, _gridDataToWrite:Array):
	if blocksPerRow > Util.boxSize:
		push_error("packedGrid cannot support row lengths longer than " + String.num_int64(Util.boxSize) + ", if something is broken this is probably why")
	blockTypes = gridBlockTypes
	
	bitsPerBlock = Util.bitsToStore(blockTypes.array.size())
	blocksPerBox = Util.boxSize/bitsPerBlock
	blocksPerRow = blocksInRow
	boxesPerRow = ceili(float(blocksInRow)/blocksPerBox)
	blockMask = Util.genMask(bitsPerBlock, 1, 1)
	
	for row in rowCount:
		var packedRow:Array[int] = [];
		for block in blocksPerRow:
			packedRow.push_back(0)
		rows.push_back(packedRow) 	
	
	for type in blockTypes.array.size():
		binArrays.push_back([])
	
	recacheBinaryStrings()

func accessCell(cell:Vector2i, modify:int = 0):
	var data = rows[cell.y];
	var pos = Util.getPosition(cell.x, bitsPerBlock);
	var curVal = Util.rightShift(data[pos.box], pos.shift) & blockMask
	if (modify != 0):
		data[pos.box] += Util.leftShift(modify - curVal, pos.shift)
		var bitMask = 1 << cell.x
		binArrays[modify][cell.y] |= bitMask
		binArrays[curVal][cell.y] &= ~bitMask
	return curVal

func rowToInt(rowNum:int, matchedValues:Dictionary) -> Dictionary:
	var bitRows:Dictionary = {}
	for block in matchedValues.keys(): bitRows.get_or_add(block, 0)
	var curPack:int = 0
	var curBox:int = 0
	var curMask = 1
	var row = rows[rowNum].duplicate()
	for block in blocksPerRow:
		var val:int = row[curBox] & blockMask
		row[curBox] = Util.rightShift(row[curBox], bitsPerBlock)
		if matchedValues.has(val): bitRows[val] |= curMask
		curPack += 1
		if (curPack == blocksPerBox):
			curPack = 0
			curBox += 1
		if (curMask > 0): curMask <<= 1
	return bitRows

func mergeStrings(values:Array):
	var binaryArray:Array[int] = [];
	for row in rows.size():
		binaryArray.push_back(0)
		for value in values: #Combine BStrings into single string per row
			binaryArray[row] |= binArrays[value][row]
	return binaryArray

func recacheBinaryStrings():
	var newBinaryStrings:Array = [];
	var tempArrays:Array = [];
	var allBlocks:Dictionary = {};
	for block in blockTypes.array.size():
		allBlocks.get_or_add(block);
		newBinaryStrings.push_back([]);
	for row in rows.size(): 
		tempArrays.push_back(rowToInt(row, allBlocks));
	for block in blockTypes.array.size():
		for row in rows.size():
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binArrays = newBinaryStrings

func identifySubGroups():
	var mergedBinArray = mergeStrings(blockTypes.solidBlocks.keys())
	return Util.findGroups(mergedBinArray, rows.size());
#
