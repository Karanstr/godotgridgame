class_name packedGrid

#Supposed to be consts but it hates me
static var bitsPerBlock:int = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1) #Must store all blockTypes +  null value
static var blocksPerBox:int = BinUtil.boxSize/bitsPerBlock
static var blockMask:int = BinUtil.genMask(bitsPerBlock)

var boxesPerRow:int
var blocksPerRow:int #grid.x

var rows:Array = [] #rows.size() is grid.y
var binRows:Array[Dictionary] = [] #For each row there is a dictionary with each non-zero blockType binRow
var bitBinRows:Dictionary = {} #For each blockType in the grid, this stores which rows contain that block 
var changedBGrids:Dictionary = {} #Keep track of which blockTypes the chunk needs to update

func _init(rowCount:int, gridBlocksPerRow:int, hasData:bool = false, data:Array = []):
	if gridBlocksPerRow > BinUtil.boxSize: push_error("packedGrid cannot support row lengths longer than " + String.num_int64(BinUtil.boxSize) + ", if something is broken this is probably why")
	blocksPerRow = gridBlocksPerRow
	boxesPerRow = ceili(float(blocksPerRow)/blocksPerBox)
	rows.resize(rowCount)
	binRows.resize(rowCount)
	for row in rowCount:
		if hasData: #Load data
			rows[row] = data[row]
			binRows[row] = {} #Dictionary
			_recalcBinaryRow(row)
		else: #Fill in null data
			var packedRow:Array = []
			packedRow.resize(boxesPerRow)
			packedRow.fill(0)
			rows[row] = packedRow

#region Grid Editing

#Used for reading and writing to cells
func accessCell(cell:Vector2i, modify:int = -1) -> int:
	var pos = BinUtil.getPosition(cell.x, bitsPerBlock)
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask
	if (modify != -1 && modify != curVal):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift) #Funny trick to modify value easily
		var bitMask = 1 << cell.x
		if (modify != 0): #0 is our null value so we don't keep a binaryGrid to track it, we can track it through inversion
			addToBinRow(cell, modify)
		if (curVal != 0):
			subtractFromBinRow(cell, curVal)
	return curVal

#Used for loading
func modifyRow(rowNum:int, startingIndex:int, numOfInserts:int, data:Array, treat0asNull:bool = false):
	if numOfInserts + startingIndex > blocksPerRow: #Sanity check to make sure we aren't trying to import data outside of row
		print("Cannot insert row of length " + String.num_int64(numOfInserts + startingIndex) + " into row of " + String.num_int64(blocksPerRow))
		return false
	var startBox:int = startingIndex / blocksPerBox
	var curIndex:int = startingIndex - startBox * blocksPerBox
	var boxes:int = ceil((numOfInserts + curIndex) / float(blocksPerBox))
	var packsInserted:int = 0
	for box in boxes:
		var packsInsertingThisPass = min(blocksPerBox - curIndex, numOfInserts - packsInserted)
		var currentInsertBox = BinUtil.readSection(data, packsInsertingThisPass, packsInserted, bitsPerBlock)[0]
		var mask:int
		if treat0asNull: #If we want to preserve pre-existing data inside our write region instead of overwriting it with our null value
			mask = 0
			var shiftedMask = blockMask
			for index in packsInsertingThisPass:
				if currentInsertBox & shiftedMask != 0: mask |= shiftedMask
				shiftedMask <<= bitsPerBlock
		else: #If we want to overwrite the data with our null value
			mask = BinUtil.repMask(bitsPerBlock, packsInsertingThisPass, blockMask) 
		mask <<= curIndex * bitsPerBlock #Only relevant for first box
		rows[rowNum][startBox + box] &= ~mask #Remove old data
		rows[rowNum][startBox + box] |= BinUtil.leftShift(currentInsertBox, curIndex * bitsPerBlock) #Insert new data
		packsInserted += packsInsertingThisPass
		curIndex = 0
	_recalcBinaryRow(rowNum)

func subtractGrid(gridArray:Array):
	for row in rows.size():
		for box in rows[row].size():
			rows[row][box] &= ~gridArray[row][box]
		_recalcBinaryRow(row)

#endregion

#region Meta Grid Editing

#Gotta do this one
func _findUselessRows(side:bool): #If side == false start at bottom (row 0), if side == true start at top (row rows.size()-1)
	pass

func changeXDim(newBpR:int):
	if newBpR > 64 || newBpR < 1: return false
	var newBoxCount:int = ceili(float(newBpR)/blocksPerBox)
	if newBoxCount > boxesPerRow: #No changes to the binRow or Chunk needed
		for row in rows:
			row.resize(newBoxCount)
			for box in newBoxCount - boxesPerRow: 
				row[boxesPerRow + box] = 0 #Add extra boxes
	elif newBpR < blocksPerRow:
		for row in rows.size():
			rows[row].resize(newBoxCount)
			var newTrailingIndex:int = newBpR - blocksPerBox * (newBoxCount - 1) #Number of blocks we want in the last box
			var trailingMask:int = BinUtil.repMask(bitsPerBlock, newTrailingIndex, blockMask)
			rows[row][newBoxCount - 1] &= trailingMask
			_recalcBinaryRow(row)
	blocksPerRow = newBpR
	boxesPerRow = newBoxCount

func changeYDim(newNor:int):
	var curNor = rows.size()
	rows.resize(newNor) #All we need to do if we're removing rows
	binRows.resize(newNor) # ^^
	if newNor > curNor: #If we're adding rows
		var rowTemp = [] #Template to push into new row slots
		rowTemp.resize(boxesPerRow)
		rowTemp.fill(0)
		for row in newNor - curNor:
			binRows[curNor + row] = {}
			rows[curNor + row] = rowTemp.duplicate()

#endregion

#region Binary Grid Management

func mergeBinGrids(blockTypes:Dictionary) -> Array[int]:
	var binaryGrid:Array[int] = []
	binaryGrid.resize(rows.size())
	binaryGrid.fill(0)
	for row in rows.size():
		for blockType in blockTypes: #Combine BStrings into single string per row
			if (binRows[row].has(blockType)):
				binaryGrid[row] |= binRows[row][blockType]
	return binaryGrid

func addToBinRow(cell:Vector2i, blockType:int):
	var binMask = 1 << cell.x
	var bitMask = 1 << cell.y
	binRows[cell.y].get_or_add(blockType, 0)
	binRows[cell.y][blockType] |= binMask
	bitBinRows.get_or_add(blockType, 0)
	bitBinRows[blockType] |= bitMask
	changedBGrids[blockType] = true

func subtractFromBinRow(cell:Vector2i, blockType:int):
		var binMask = 1 << cell.x
		var bitMask = 1 << cell.y
		binRows[cell.y][blockType] &= ~binMask
		if binRows[cell.y][blockType] == 0:
			binRows[cell.y].erase(blockType)
			bitBinRows[blockType] &= ~bitMask
			if bitBinRows[blockType] == 0:
				bitBinRows.erase(blockType)
		changedBGrids[blockType] = true

func _recalcBinaryRow(rowNum:int):
	var newRows:Dictionary = BinUtil.packedArrayToInt(rows[rowNum], BlockTypes.blocks)
	var bitBinMask = 1 << rowNum
	for block in bitBinRows.merged(newRows): #For each block either already in the grid or entering the grid
		if binRows[rowNum].has(block) && !newRows.has(block): #If the block was in the row but now is not
			changedBGrids[block] = true
			bitBinRows[block] &= ~bitBinMask #Remove
			if bitBinRows[block] == 0: #If the block is no longer in the grid
				bitBinRows.erase(block)
		elif !binRows[rowNum].has(block) && newRows.has(block): #Block wasn't in row but is about to be
			changedBGrids[block] = true
			if bitBinRows.has(block): #If block was already in the grid
				bitBinRows[block] |= bitBinMask
			else: #First instance of block appearing in grid
				bitBinRows[block] = bitBinMask
	binRows[rowNum] = newRows

#endregion

#region Loading & Splitting

func identifySubGroups() -> Array:
	var mergedBinGrid = mergeBinGrids(bitBinRows)
	var groups:Array = BinUtil.findGroups(mergedBinGrid, rows.size())
	return groups

#endregion
