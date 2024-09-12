class_name packedGrid

var rows:Array = []; #rows.size() == dim.y/columns
var blocksPerRow:int; #Dim.x

var bitsPerBlock:int;
var blocksPerBox:int;
var boxesPerRow:int;
var blockMask:int;

var binArrays:Dictionary = {};

func _init(rowCount:int, blocksInRow:int, _gridDataToWrite:Array):
	if blocksPerRow > BinUtil.boxSize:
		push_error("packedGrid cannot support row lengths longer than " + String.num_int64(BinUtil.boxSize) + ", if something is broken this is probably why")
	
	bitsPerBlock = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1)
	blocksPerBox = BinUtil.boxSize/bitsPerBlock
	blocksPerRow = blocksInRow
	boxesPerRow = ceili(float(blocksPerRow)/blocksPerBox)
	blockMask = BinUtil.genMask(1, bitsPerBlock, 1)
	
	for row in rowCount:
		var packedRow:Array[int] = [];
		for block in boxesPerRow:
			packedRow.push_back(0)
		rows.push_back(packedRow) 
	
	for block in BlockTypes.blocks.keys():
		binArrays.get_or_add(block, [])
	
	recacheBinaryStrings()

func accessCell(cell:Vector2i, modify:int = 0) -> int:
	var pos = BinUtil.getPosition(cell.x, bitsPerBlock);
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask
	if (modify != 0):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift)
		var bitMask = 1 << cell.x
		binArrays[modify][cell.y] |= bitMask
		if (curVal != 0):
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
		row[curBox] = BinUtil.rightShift(row[curBox], bitsPerBlock)
		if matchedValues.has(val): bitRows[val] |= curMask
		curPack += 1
		if (curPack == blocksPerBox):
			curPack = 0
			curBox += 1
		if (curMask > 0): curMask <<= 1
	return bitRows

func mergeStrings(values:Array) -> Array[int]:
	var binaryArray:Array[int] = [];
	for row in rows.size():
		binaryArray.push_back(0)
		for value in values: #Combine BStrings into single string per row
			binaryArray[row] |= binArrays[value][row]
	return binaryArray

func recacheBinaryStrings() -> void:
	var newBinaryStrings:Dictionary = {};
	var tempArrays:Array = [];
	for row in rows.size(): 
		tempArrays.push_back(rowToInt(row, BlockTypes.blocks));
	for block in BlockTypes.blocks:
		newBinaryStrings.get_or_add(block, []);
		for row in rows.size():
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binArrays.merge(newBinaryStrings, true)

func identifySubGroups():
	var mergedBinArray = mergeStrings(BlockTypes.solidBlocks.keys())
	var groups:Array = BinUtil.findGroups(mergedBinArray, rows.size())
	for group in groups:
		pass
	return groups
#
