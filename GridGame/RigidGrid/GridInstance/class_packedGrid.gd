class_name packedGrid

#Supposed to be consts but it hates me
static var bitsPerBlock:int = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1) #Must store all blockTypes +  null value
static var blocksPerBox:int = BinUtil.boxSize/bitsPerBlock
static var blockMask:int = BinUtil.genMask(1, bitsPerBlock, 1)

var boxesPerRow:int
var blocksPerRow:int #grid.x

var rows:Array = [] #rows.size() is grid.y

var bgTempArray:Array[int] = [] #Template for the binaryGrids
var binGrids:Dictionary = {}

var dirtyBins:Dictionary = {} #Keep track of which binary grids need to be updated so at the end of a tick
#so the chunk can update them

func _init(rowCount:int, gridBlocksPerRow:int, hasData:bool = false, data:Array = []):
	if gridBlocksPerRow > BinUtil.boxSize: push_error("packedGrid cannot support row lengths longer than " + String.num_int64(BinUtil.boxSize) + ", if something is broken this is probably why")
	blocksPerRow = gridBlocksPerRow
	boxesPerRow = ceili(float(blocksPerRow)/blocksPerBox)
	rows.resize(rowCount)
	bgTempArray.resize(rowCount)
	bgTempArray.fill(0) #This has to be initialized before I start goofing with the bgrids
	for row in rowCount:
		if hasData: #Load data
			rows[row] = data[row]
			_recacheBinaryRow(row)
		else: #Fill in null data
			var packedRow:Array = []
			packedRow.resize(boxesPerRow)
			packedRow.fill(0)
			rows[row] = packedRow

#region Grid Editing

#Used for reading and writing to cells
func accessCell(cell:Vector2i, modify:int = -1) -> int:
	var pos = BinUtil.getPosition(cell.x, bitsPerBlock)
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask #Shift out current value of cell
	if (modify != -1):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift) #Funny trick to modify value easily
		var bitMask = 1 << cell.x
		if (modify != 0): #0 is a null value so we don't do this
			binGrids.get_or_add(modify, bgTempArray.duplicate())[cell.y] |= bitMask #Get current bGrid or make a new one
		if (curVal != 0 && curVal != modify): #We still don't update 0
			binGrids[curVal][cell.y] &= ~bitMask
			dirtyBins[curVal] = null #Note that this may have made the bGrid empty
	return curVal

func modifyRow(rowNum:int, startingIndex:int, numOfInserts:int, data:Array, treat0asNull:bool = false):
	if numOfInserts + startingIndex > blocksPerRow: #Sanity check to make sure we aren't trying to import data outside of row
		print("Cannot insert row of length " + String.num_int64(numOfInserts + startingIndex) + " into row of " + String.num_int64(blocksPerRow))
		return false
	var startBox:int = startingIndex / blocksPerBox
	var curIndex:int = startingIndex - startBox * blocksPerBox
	var boxes:int = ceil((numOfInserts + curIndex) / float(blocksPerBox))
	var packsInserted:int = 0
	for box in boxes:
		var packsThisPass = min(blocksPerBox - curIndex, numOfInserts - packsInserted) #Number of packs(blocks) we insert in this pass
		var currentInsertBox = BinUtil.readSection(data, packsThisPass, packsInserted, blockMask, bitsPerBlock)[0]
		var mask:int
		if treat0asNull: #If we want to preserve pre-existing data over any 0 (null) block
			mask = 0
			var shiftedMask = blockMask
			for index in packsThisPass:
				if currentInsertBox & shiftedMask != 0: mask |= shiftedMask
				shiftedMask <<= bitsPerBlock
		else: mask = BinUtil.genMask(bitsPerBlock, packsThisPass, blockMask) #If we want to overwrite the data with the null block
		mask <<= curIndex * bitsPerBlock #Move the mask to the right place (only relevant for first box)
		rows[rowNum][startBox + box] &= ~mask #Remove old data
		rows[rowNum][startBox + box] |= BinUtil.leftShift(currentInsertBox, curIndex * bitsPerBlock) #Insert new data
		packsInserted += packsThisPass
		curIndex = 0
	_recacheBinaryRow(rowNum) #The row has changed and it's faster to just update the whole thing

func removeMaskFromRow(rowNum:int, mask:Array[int]):
	for box in rows[rowNum].size():
		rows[rowNum][box] &= ~mask[box]
	_recacheBinaryRow(rowNum)

func zeroRow(rowNum:int):
	for box in boxesPerRow:
		rows[rowNum][box] = 0
	for grid in binGrids:
		binGrids[grid][rowNum] = 0
		dirtyBins[grid] = null #We may have made the grid 0, so mark it as dirty

#endregion

#region Meta Grid Editing

#Gotta do this one
func findUselessRows(side:bool): #If side == false start at bottom (row 0), if side == true start at top (row rows.size()-1)
	pass

func changeXDim(newBPR:int):
	if newBPR > 64 || newBPR < 0: return false
	var newBoxCount:int = ceili(float(newBPR)/blocksPerBox)
	if newBoxCount > boxesPerRow: #If we're adding more to the end (easy way)
		for row in rows:
			for box in newBoxCount - boxesPerRow: 
				row.push_back(0) #Add another box as needed
	elif newBPR < blocksPerRow: #If we're cutting the end off (harder)
		var newTrailingIndex:int = newBPR - blocksPerBox * (newBoxCount - 1) #Number of blocks we want in the last box
		var trailingMask:int = BinUtil.genMask(bitsPerBlock, newTrailingIndex, blockMask)
		for row in rows.size():
			var newRow:Array[int] = []
			for box in newBoxCount: #Get all the boxes we're keeping
				newRow.push_back(rows[row][box])
			newRow[newBoxCount - 1] &= trailingMask #Cull the last box to chop off any extra
			rows[row] = newRow
		dirtyBins.merge(binGrids) #Any of the rows we just changed may have only had data where we cut, so we've gotta check
	blocksPerRow = newBPR
	boxesPerRow = newBoxCount

func changeYDim(newNor:int):
	var curNor = rows.size()
	rows.resize(newNor)
	bgTempArray.resize(newNor)
	if newNor > curNor: #If we're adding rows
		var rowTemp = [] #Template to push into new row slots
		rowTemp.resize(boxesPerRow)
		rowTemp.fill(0)
		for row in newNor - curNor:
			bgTempArray[curNor + row] = 0 #Add a row to the bgTempArray
			for grid in binGrids:
				binGrids[grid].push_back(0)
			rows[curNor + row] = rowTemp.duplicate()
	elif newNor < curNor: #If we're cutting rows
		for grid in binGrids:
			binGrids[grid].resize(newNor)
			dirtyBins[grid] = null #There may have only been data in these rows, so we've gotta check

#endregion

#region Binary Grid Management

func mergeBinGrids(values:Array) -> Array[int]:
	var binaryGrid:Array[int] = []
	for row in rows.size():
		binaryGrid.push_back(0)
		for value in values: #Combine BStrings into single string per row
			if (binGrids.has(value)):
				binaryGrid[row] |= binGrids[value][row]
	return binaryGrid

func _recacheBinaryRow(rowNum:int):
	var newRows = rowToInt(rows[rowNum], BlockTypes.blocks)
	for blockGrid in newRows:
		binGrids.get_or_add(blockGrid, bgTempArray.duplicate()) #Kinda gross, creating a row for each potential block but we gotta
		binGrids[blockGrid][rowNum] = newRows[blockGrid]
		dirtyBins[blockGrid] = null #Note that this may have made the bGrid empty

func cleanBinGrids():
	for grid in dirtyBins:
		if (binGrids[grid].any(func(r): return r != 0) == false): #Check if the entire bgrid is 0 (there are no of the current block in the grid
			binGrids.erase(grid)
		dirtyBins.erase(grid)

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
			if (curMask > 0): curMask <<= 1 #Stop from shifting negative number on the last check of a 64 block row (bc godot is stupid)
	return bitRows

#endregion

#region Loading & Splitting

func identifySubGroups() -> Array:
	var mergedBinArray = mergeBinGrids(BlockTypes.solidBlocks.keys())
	var groups:Array = BinUtil.findGroups(mergedBinArray, rows.size())
	return groups

func intToRow(rowNum, bitRow:int):
	var row:Array[int] = []
	var rowMask:Array[int] = [0]
	var length:int = 0
	var start:int = 0
	var curBlock:int = 0
	var curBox:int = 0
	while bitRow != 0:
		if (curBlock == blocksPerBox): #Yeah I could do this with division instead of two variables, shut up this is better
			curBlock = 0
			curBox += 1
			rowMask.push_back(0)
		if bitRow & 1: rowMask[curBox] |= blockMask << curBlock*bitsPerBlock #Put in the blockMask on the current block
		if bitRow & 1 || length != 0: length += 1 #If current block is set, we've found a block which is set
		if length == 0: start += 1 #If current block isn't set but there was already at least one set block, this unset block is sandwiched by set ones
		bitRow = BinUtil.rightShift(bitRow, 1)
		curBlock += 1
	for box in rows[rowNum].size():
		row.push_back(rows[rowNum][box] & rowMask[box])
	return [row, [start, length]] #Preserve start and length for grid culling later

func groupToGrid(group:BinUtil.Group) -> Array:
	var newGrid:Array = []
	var culledGrid:Array = []
	var minStart:int = BinUtil.boxSize
	var maxLength:int = 0
	var data = group.binGrid
	for row in data.size():
			var curRow = intToRow(row, data[row])
			newGrid.push_back(curRow[0])
			if curRow[0].any(func(r): return r != 0): #If the row isn't 0
				if curRow[1][0] < minStart: minStart = curRow[1][0]
				if curRow[1][1] > maxLength: maxLength = curRow[1][1]
	var firstCell = Vector2i(minStart, -1) #Top left corner of culled grid
	for row in data.size(): #find y of firstCell
		if data[row] != 0:
			if firstCell.y == -1: firstCell.y = row
			culledGrid.push_back(BinUtil.readSection(rows[row], maxLength, minStart, blockMask, bitsPerBlock))
		else:
			break #If an entire row is null, we know the object can't extend through it
	return [newGrid, [culledGrid, firstCell]]

#endregion
