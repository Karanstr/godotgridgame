class_name packedGrid

var rows:Array = []; #rows.size() == dim.y/columns
var blocksPerRow:int; #Dim.x
var boxesPerRow:int;
var binArrays:Dictionary = {};

func _init(rowCount:int, blocksInRow:int, _gridDataToWrite:Array):
	if blocksInRow > BinUtil.boxSize: push_error("packedGrid cannot support row lengths longer than " + String.num_int64(BinUtil.boxSize) + ", if something is broken this is probably why")
	blocksPerRow = blocksInRow
	boxesPerRow = ceili(float(blocksPerRow)/GridFactory.blocksPerBox)
	
	for block in BlockTypes.blocks.keys():
		binArrays.get_or_add(block, [])
	for row in rowCount:
		var packedRow:Array[int] = [];
		for block in boxesPerRow:
			packedRow.push_back(0)
		rows.push_back(packedRow) 
		
	recacheBinaryStrings()

func accessCell(cell:Vector2i, modify:int = 0) -> int:
	var pos = BinUtil.getPosition(cell.x, GridFactory.bitsPerBlock);
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & GridFactory.blockMask
	if (modify != 0):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift)
		var bitMask = 1 << cell.x
		binArrays[modify][cell.y] |= bitMask
		if (curVal != 0):
			binArrays[curVal][cell.y] &= ~bitMask
	return curVal

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
	for row in rows: 
		tempArrays.push_back(GridFactory.rowToInt(row, BlockTypes.blocks));
	for block in BlockTypes.blocks:
		newBinaryStrings.get_or_add(block, []);
		for row in rows.size():
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binArrays.merge(newBinaryStrings, true)

#Figure out how to define 'main' grid, or do we just destroy this grid and create a new one for each group
func identifySubGroups() -> Array:
	var mergedBinArray = mergeStrings(BlockTypes.solidBlocks.keys())
	var groups:Array = BinUtil.findGroups(mergedBinArray, rows.size())
	return groups

func changeGridDims(_newX:int, _newY:int):
	pass
