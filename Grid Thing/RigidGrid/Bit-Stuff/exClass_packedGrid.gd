class_name packedGrid extends packedArray

var gridDims:Vector2i;
var typeCount:int;
var binArrays:Array = [];

func _init(dimensions:Vector2i, uniqueBlocks:int):
	if dimensions.x > 64 || dimensions.y > 64:
		push_error("packedGrid cannot support dimensions larger than 64, if something is broken this is probably why")
	super(dimensions.x * dimensions.y, Util.bitsToStore(uniqueBlocks))
	gridDims = dimensions
	typeCount = uniqueBlocks
	for type in typeCount:
		binArrays.push_back([])
		for row in gridDims.y:
			binArrays[type].push_back(0)

#region Mostly internal utility functions

#Overloaded super.modify to also update the binArrays
func modify(index:int, newVal:int):
	if (Util.bitsToStore(newVal) > packSize):
		print("Value exceeds packing size: " + String.num_int64(newVal))
		return false
	if (index >= totalPacks):
		print("Cannot access index " + String.num_int64(index))
		return false
	var boxNum:int = _getBox(index);
	var oldVal:int = read(index);
	data[boxNum] += Util.leftShift(newVal - oldVal, _getPadding(index, boxNum))
	var coords = Util.decode(index, gridDims.x)
	var mask = 1 << coords.x
	binArrays[newVal][coords.y] |= mask
	binArrays[oldVal][coords.y] &= ~mask
	return oldVal

func rowToInt(rowNum:int, matchedValues:Array[int]) -> Array[int]:
	var rows:Array[int] = [];
	for block in matchedValues.size():
		rows.push_back(0)
	var index:int = gridDims.x*rowNum;
	var rowData:Array[int] = readSection(gridDims.x, index);
	var packCounter:int = 0;
	for i in gridDims.x:
		var dataBox:int = packCounter/packsPerBox;
		var val:int = rowData[dataBox] & packMask;
		rowData[dataBox] = Util.rightShift(rowData[dataBox], packSize);
		for block in matchedValues.size():
			if (matchedValues[block] == val):
				rows[block] += 1 << (packCounter % boxSize);
		packCounter += 1;
	return rows

func mergeStrings(values:Array[int]):
	var binaryArray:Array[int] = [];
	for row in gridDims.y:
		binaryArray.push_back(0)
		for value in values: #Combine BStrings into single string per row
			binaryArray[row] |= binArrays[value][row]
	return binaryArray

func recacheBinaryStrings():
	var newBinaryStrings:Array = [];
	var tempArrays:Array = [];
	var allBlocks:Array[int] = [];
	for block in typeCount:
		allBlocks.push_back(block);
	for row in gridDims.y: 
		tempArrays.push_back(rowToInt(row, allBlocks));
	for block in typeCount:
		newBinaryStrings.push_back([]);
		for row in gridDims.y:
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binArrays = newBinaryStrings
	return true

#endregion

#
