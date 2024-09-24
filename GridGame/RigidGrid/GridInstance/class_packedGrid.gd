class_name packedGrid

#Supposed to be consts but it hates me
static var bitsPerBlock:int = BinUtil.bitsToStore(BlockTypes.maxBlockIndex+1) #Must store all blockTypes +  null value
static var blocksPerBox:int = BinUtil.boxSize/bitsPerBlock
static var blockMask:int = BinUtil.genMask(bitsPerBlock)

var boxesPerRow:int
var blocksPerRow:int #grid.x

var rows:Array = [] #rows.size() is grid.y

var bgTempArray:Array[int] = [] #Template for the binaryGrids
var binGrids:Dictionary = {}

var changedBGrids:Dictionary = {} #Keep track of which blockTypes the chunk needs to update, potentiallyEmptyBGrids is a subset of this set and should be .merged() whenever it is used
var potentiallyEmptyBGrids:Dictionary = {} #Keep track of bgrids which may need to be culled


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
	var curVal = BinUtil.rightShift(rows[cell.y][pos.box], pos.shift) & blockMask
	if (modify != -1):
		rows[cell.y][pos.box] += BinUtil.leftShift(modify - curVal, pos.shift) #Funny trick to modify value easily
		var bitMask = 1 << cell.x
		if (modify != 0): #0 is our null value so we don't keep a binaryGrid to track it
			binGrids.get_or_add(modify, bgTempArray.duplicate())[cell.y] |= bitMask
			changedBGrids[modify] = null
		if (curVal != 0 && curVal != modify): #Same reasoning as above
			binGrids[curVal][cell.y] &= ~bitMask
			potentiallyEmptyBGrids[curVal] = null
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
	_recacheBinaryRow(rowNum)

func subtractGrid(gridArray:Array):
	for row in rows.size():
		for box in rows[row].size():
			rows[row][box] &= ~gridArray[row][box]
		_recacheBinaryRow(row)

#endregion

#region Meta Grid Editing

#Gotta do this one
func _findUselessRows(side:bool): #If side == false start at bottom (row 0), if side == true start at top (row rows.size()-1)
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
		var trailingMask:int = BinUtil.repMask(bitsPerBlock, newTrailingIndex, blockMask)
		for row in rows.size():
			var newRow:Array[int] = []
			for box in newBoxCount: #Get all the boxes we're keeping
				newRow.push_back(rows[row][box])
			newRow[newBoxCount - 1] &= trailingMask #Cull the last box to chop off any extra
			rows[row] = newRow
		potentiallyEmptyBGrids.merge(binGrids) #Any of the rows we just changed may have only had data where we cut, so we've gotta check
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
			potentiallyEmptyBGrids[grid] = null #There may have only been data in these rows, so we've gotta check

#endregion

#region Binary Grid Management

func _mergeBinGrids(values:Dictionary) -> Array[int]:
	var binaryGrid:Array[int] = []
	for row in rows.size():
		binaryGrid.push_back(0)
		for value in values: #Combine BStrings into single string per row
			if (binGrids.has(value)):
				binaryGrid[row] |= binGrids[value][row]
	return binaryGrid

#This function hurts a bit bc it has to loop through all blockTypes
func _recacheBinaryRow(rowNum:int):
	var newRows:Dictionary = BinUtil.packedArrayToInt(rows[rowNum], BlockTypes.blocks)
	for blockGrid in newRows:
		if newRows[blockGrid] != 0:
			binGrids.get_or_add(blockGrid, bgTempArray.duplicate())
			if (binGrids[blockGrid][rowNum] != newRows[blockGrid]): 
				changedBGrids[blockGrid] = null
				binGrids[blockGrid][rowNum] = newRows[blockGrid]
		elif binGrids.has(blockGrid):
			potentiallyEmptyBGrids[blockGrid] = null #Note that this may have made the bGrid empty
			binGrids[blockGrid][rowNum] = 0

func removeEmptyBGrids():
	for grid in potentiallyEmptyBGrids:
		if (binGrids[grid].any(func(r): return r != 0) == false): #Check if the entire bgrid is 0 (there are no of the current block in the grid
			binGrids.erase(grid)
		potentiallyEmptyBGrids.erase(grid)

#endregion

#region Loading & Splitting

func identifySubGroups() -> Array:
	var mergedBinGrid = _mergeBinGrids(binGrids)
	var groups:Array = BinUtil.findGroups(mergedBinGrid, rows.size())
	return groups

#endregion
