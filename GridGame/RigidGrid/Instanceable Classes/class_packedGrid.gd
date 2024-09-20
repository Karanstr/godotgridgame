class_name packedGrid

#Supposed to be consts but it hates me
static var bitsPerBlock:int = 4#BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1)
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

#region Meta Grid Editing

#Fix binGrid updating
func changeBlocksPerRow(newBPR:int):
	if newBPR > 64 || newBPR < 0: return false
	var newBoxCount:int = ceili(float(newBPR)/blocksPerBox)
	if newBoxCount > boxesPerRow:
		for row in rows:
			for box in newBoxCount - boxesPerRow: 
				row.push_back(0)
	elif newBPR < blocksPerRow:
		var newBitMask = BinUtil.genMask(1, newBPR, 1) #For updating binGrids
		var newTrailingIndex:int = newBPR - blocksPerBox * (newBoxCount - 1)
		var trailingMask:int = BinUtil.genMask(bitsPerBlock, newTrailingIndex, blockMask)
		for row in rows.size():
			var newRow:Array[int] = []
			for box in newBoxCount:
				newRow.push_back(rows[row][box])
			newRow[newBoxCount - 1] &= trailingMask
			rows[row] = newRow
			for type in binGrids:
				binGrids[type][row] &= newBitMask
	blocksPerRow = newBPR
	boxesPerRow = newBoxCount

#Remember that "Calling array.resize() once and assigning the new values is faster than calling append for every new element."
func changeNumOfRows(newNor:int):
	var curNor = rows.size()
	var rowTemp = []
	for box in boxesPerRow: 
		rowTemp.push_back(0)
	if newNor > curNor:
		for row in newNor - curNor:
			templateArray.push_back(0)
			for grid in binGrids:
				binGrids[grid].push_back(0)
			rows.push_back(rowTemp.duplicate())
	elif newNor < curNor:
		rows.resize(rows.size() - (1 + curNor - newNor))
		for grid in binGrids:
			binGrids[grid].resize(binGrids[grid].size() - (1 + curNor - newNor))

#endregion

#region Grid Editing

func accessCell(cell:Vector2i, modify:int = -1) -> int:
	var pos = BinUtil.getPosition(cell.x, bitsPerBlock);
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask
	if (modify != -1):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift)
		var bitMask = 1 << cell.x
		if (modify != 0):
			var newBinArr = binGrids.get_or_add(modify, templateArray.duplicate())
			newBinArr[cell.y] |= bitMask
		if (curVal != 0 && curVal != modify):
			binGrids[curVal][cell.y] &= ~bitMask
			if binGrids[curVal][cell.y] == 0:
				cleanBinGrids({curVal:null})
	return curVal

func modifyRow(rowNum:int, startingIndex:int, numOfInserts:int, data:Array, treat0asNull:bool = false):
	if numOfInserts + startingIndex > blocksPerRow:
		print("Cannot insert row of length " + String.num_int64(numOfInserts + startingIndex) + " into row of " + String.num_int64(blocksPerRow))
		return false
	var startBox:int = startingIndex / blocksPerBox
	var curIndex:int = startingIndex - startBox * blocksPerBox
	var boxes:int = ceil((numOfInserts + curIndex) / float(blocksPerBox))
	var packsInserted:int = 0;
	for box in boxes:
		var packsToBeHandled = min(blocksPerBox - curIndex, numOfInserts - packsInserted)
		var currentInsertBox = BinUtil.readSection(data, packsToBeHandled, packsInserted, blockMask, bitsPerBlock)[0]
		var mask:int
		if treat0asNull:
			mask = 0
			var shiftedMask = blockMask
			for index in packsToBeHandled:
				if currentInsertBox & shiftedMask != 0: mask |= shiftedMask
				shiftedMask <<= bitsPerBlock
		else: mask = BinUtil.genMask(bitsPerBlock, packsToBeHandled, blockMask)
		mask <<= curIndex * bitsPerBlock
		rows[rowNum][startBox + box] &= ~mask
		rows[rowNum][startBox + box] |= BinUtil.leftShift(currentInsertBox, curIndex * bitsPerBlock)
		packsInserted += packsToBeHandled
		curIndex = 0
	_recacheBinaryRow(rowNum)

func zeroRow(rowNum:int):
	for box in boxesPerRow:
		rows[rowNum][box] = 0
	for grid in binGrids:
		binGrids[grid][rowNum] = 0
		cleanBinGrids({grid:null})

#endregion

#region Binary Grid Management

func mergeBinGrids(values:Array) -> Array[int]:
	var binaryGrid:Array[int] = [];
	for row in rows.size():
		binaryGrid.push_back(0)
		for value in values: #Combine BStrings into single string per row
			if (binGrids.has(value)):
				binaryGrid[row] |= binGrids[value][row]
	return binaryGrid

func cleanBinGrids(values:Dictionary):
	for value in values:
		if (binGrids[value].any(func(r): return r != 0) == false):
			binGrids.erase(value)

func _recacheBinaryRow(rowNum:int):
	var newRows = rowToInt(rows[rowNum], BlockTypes.blocks)
	for blockGrid in BlockTypes.blocks:
		binGrids.get_or_add(blockGrid, templateArray.duplicate()) 
		binGrids[blockGrid][rowNum] = newRows[blockGrid]
		cleanBinGrids({blockGrid:null})
	return true

static func rowToInt(rowData:Array, matchedValues:Dictionary) -> Dictionary:
	var bitRows:Dictionary = {}
	for block in matchedValues.keys(): bitRows.get_or_add(block, 0)
	var curMask = 1
	var row = rowData.duplicate()
	for box in rowData.size():
		for block in blocksPerBox:
			var curVal:int = row[box] & blockMask
			row[box] = BinUtil.rightShift(row[box], bitsPerBlock)
			if matchedValues.has(curVal): bitRows[curVal] |= curMask
			if (curMask > 0): curMask <<= 1
	return bitRows

#endregion

#region Loading & Splitting

func identifySubGroups() -> Array:
	var mergedBinArray = mergeBinGrids(BlockTypes.solidBlocks.keys())
	var groups:Array = BinUtil.findGroups(mergedBinArray, rows.size())
	return groups

static func intToRow(rowData, bitRow:int):
	var row:Array[int] = []
	var rowMask:Array[int] = [0]
	var length:int = 0
	var start:int = 0
	var curBlock:int = 0
	var curBox:int = 0
	while bitRow != 0:
		if (curBlock == blocksPerBox):
			curBlock = 0
			curBox += 1
			rowMask.push_back(0)
		if bitRow & 1: rowMask[curBox] |= blockMask << curBlock*bitsPerBlock
		if bitRow & 1 || length != 0: length += 1
		if length == 0: start += 1
		bitRow = BinUtil.rightShift(bitRow, 1)
		curBlock += 1
	for box in rowData.size():
		row.push_back(rowData[box] & rowMask[box])
	return [row, [start, length]]

static func groupToGrid(group:Array[int]) -> Array:
	var newGrid:Array = []
	var culledGrid:Array = []
	var minStart:int = 64
	var maxLength:int = 0
	for row in group.size():
		var curRow = intToRow(row, group[row])
		newGrid.push_back(curRow.data)
		if curRow[1][0] < minStart: minStart = curRow[1][0]
		if curRow[1][1] > maxLength: maxLength = curRow[1][1]
	for row in newGrid:
		culledGrid.push_back(BinUtil.readSection(row, maxLength, minStart, bitsPerBlock))
	return culledGrid

#endregion
