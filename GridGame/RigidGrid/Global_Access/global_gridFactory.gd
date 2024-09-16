class_name GridFactory

#Supposed to be consts but it hates me
static var bitsPerBlock:int = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1)
static var blocksPerBox:int = BinUtil.boxSize/bitsPerBlock
static var blockMask:int = BinUtil.genMask(1, bitsPerBlock, 1)

const chunkScript = preload("../GridInstance/script_Chunk.gd")

static func createChunk(name:String, _grid:Array):
	var chunk:Node2D = Node2D.new();
	chunk.set_script(chunkScript);
	var blockSize:Vector2 = Vector2(8, 8) #Units
	var gridSize:Vector2i = Vector2i(4, 4) #Cells
	chunk.name = name;
	chunk.initialize(blockSize, gridSize);
	return chunk

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
		if (curBlock == GridFactory.blocksPerBox):
			curBlock = 0
			curBox += 1
			rowMask.push_back(0)
		if bitRow & 1: rowMask[curBox] |= GridFactory.blockMask << curBlock*GridFactory.bitsPerBlock
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
		var val:int = row[curBox] & GridFactory.blockMask
		row[curBox] = BinUtil.rightShift(row[curBox], GridFactory.bitsPerBlock)
		if matchedValues.has(val): bitRows[val] |= curMask
		curPack += 1
		if (curPack == GridFactory.blocksPerBox):
			curPack = 0
			curBox += 1
		if (curMask > 0): curMask <<= 1
	return bitRows

class Grid:
	var rows:Array = []
	var blocksPerRow:int
	var boxesPerRow:int
	
	func _init(gridRows:int, gridBlocksPerRow:int):
		blocksPerRow = gridBlocksPerRow
		boxesPerRow = ceili(float(blocksPerRow)/GridFactory.blocksPerBox)
		
		for row in gridRows: #Fill grid with null data
			var packedRow:Array[int] = [];
			for block in boxesPerRow:
				packedRow.push_back(0)
			rows.push_back(packedRow) 
		
	func accessCell(cell:Vector2i, modify:int = 0) -> int:
		var pos = BinUtil.getPosition(cell.x, GridFactory.bitsPerBlock);
		var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & GridFactory.blockMask
		if (modify != 0):
			rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift)
		return curVal
	
	func fillWithData():
		pass


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
		culledGrid.push_back(BinUtil.readSection(row, maxLength, minOffset, GridFactory.bitsPerBlock))
	return culledGrid
