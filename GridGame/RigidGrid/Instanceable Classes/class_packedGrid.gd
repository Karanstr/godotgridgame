class_name packedGrid

#Supposed to be consts but it hates me
static var bitsPerBlock:int = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1)
static var blocksPerBox:int = BinUtil.boxSize/bitsPerBlock
static var blockMask:int = BinUtil.genMask(1, bitsPerBlock, 1)

var rows:Array = [] #rows.size() is grid.y
var blocksPerRow:int #grid.x
var boxesPerRow:int
var templateArray:Array[int] = []
var binGrids:Dictionary = {}

func _init(rowCount:int, gridBlocksPerRow:int):
	if gridBlocksPerRow > BinUtil.boxSize: push_error("packedGrid cannot support row lengths longer than " + String.num_int64(BinUtil.boxSize) + ", if something is broken this is probably why")
	blocksPerRow = gridBlocksPerRow
	boxesPerRow = ceili(float(blocksPerRow)/blocksPerBox)
	for row in rowCount: #Fill grid with null data
		templateArray.push_back(0)
		var packedRow:Array[int] = [];
		for block in boxesPerRow:
			packedRow.push_back(0)
		rows.push_back(packedRow) 

func accessCell(cell:Vector2i, modify:int = -1) -> int:
	var pos = BinUtil.getPosition(cell.x, bitsPerBlock);
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask
	if (modify != -1):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift)
		var bitMask = 1 << cell.x
		if (modify != 0):
			var newBinArr = binGrids.get_or_add(modify, templateArray.duplicate())
			newBinArr[cell.y] |= bitMask
		if (curVal != 0):
			binGrids[curVal][cell.y] &= ~bitMask
			if binGrids[curVal][cell.y] == 0:
				if (binGrids[curVal].any(func(r): return r != 0) == false):
					binGrids.erase(curVal)
	return curVal

func mergeBinGrids(values:Array) -> Array[int]:
	var binaryGrid:Array[int] = [];
	for row in rows.size():
		binaryGrid.push_back(0)
		for value in values: #Combine BStrings into single string per row
			if (binGrids.has(value)):
				binaryGrid[row] |= binGrids[value][row]
	return binaryGrid

func modifyRow(rowNum:int, newData:Row, preserve:bool = false):
	if newData.length > blocksPerRow:
		print("Cannot insert row of length " + String.num_int64(newData.length) + " into row of " + String.num_int64(blocksPerRow))
		return false
	if preserve == false:
		for box in boxesPerRow:
			rows[rowNum][box] = 0
			if newData.data.size() < box:
				rows[rowNum][box] = newData.data[box]
	_recacheBinaryRow(rowNum)

func _recacheBinaryRow(rowNum:int) -> void:
	var newRows = rowToInt(rows[rowNum], BlockTypes.blocks)
	for blockRow in newRows.size():
		if (newRows[blockRow] != 0): binGrids[blockRow][rowNum] = newRows[blockRow]

#Figure out how to define 'main' grid, or do we just destroy this grid and create a new one for each group
func identifySubGroups() -> Array:
	var mergedBinArray = mergeBinGrids(BlockTypes.solidBlocks.keys())
	var groups:Array = BinUtil.findGroups(mergedBinArray, rows.size())
	return groups

#region working on it

class Row:
	var data:Array[int]
	var start:int
	var length:int
	func _init(rowData, rowStart, rowLength):
		data = rowData
		start = rowStart
		length = rowLength

static func intToRow(rowData, bitRow:int):
	var row:Array[int] = []
	var rowMask:Array[int] = [0]
	var totalBlocks:int = 0
	var offset:int = 0
	var curBlock:int = 0
	var curBox:int = 0
	while bitRow != 0:
		if (curBlock == blocksPerBox):
			curBlock = 0
			curBox += 1
			rowMask.push_back(0)
		if bitRow & 1: rowMask[curBox] |= blockMask << curBlock*bitsPerBlock
		if bitRow & 1 || totalBlocks != 0: totalBlocks += 1
		if totalBlocks == 0: offset += 1
		bitRow = BinUtil.rightShift(bitRow, 1)
		curBlock += 1
	for box in rowData.size():
		row.push_back(rowData[box] & rowMask[box])
	return Row.new(row, offset, totalBlocks)

static func rowToInt(rowData:Array, matchedValues:Dictionary) -> Dictionary:
	var bitRows:Dictionary = {}
	for block in matchedValues.keys(): bitRows.get_or_add(block, 0)
	var curPack:int = 0
	var curBox:int = 0
	var curMask = 1
	var row = rowData.duplicate()
	for block in rowData:
		var val:int = row[curBox] & blockMask
		row[curBox] = BinUtil.rightShift(row[curBox], bitsPerBlock)
		if matchedValues.has(val): bitRows[val] |= curMask
		curPack += 1
		if (curPack == blocksPerBox):
			curPack = 0
			curBox += 1
		if (curMask > 0): curMask <<= 1
	return bitRows

static func groupToGrid(group:Array[int]) -> Array:
	var newGrid:Array = []
	var culledGrid:Array = []
	var minOffset:int = 64
	var maxLength:int = 0
	for row in group.size():
		var curRow = intToRow(row, group[row])
		newGrid.push_back(curRow.data)
		if curRow.start > minOffset: minOffset = curRow.start
		if curRow.length < maxLength: maxLength = curRow.length
	for row in newGrid:
		culledGrid.push_back(BinUtil.readSection(row, maxLength, minOffset, bitsPerBlock))
	return culledGrid

#endregion
