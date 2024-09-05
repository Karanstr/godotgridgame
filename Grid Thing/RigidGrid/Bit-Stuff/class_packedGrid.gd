class_name packedGrid extends Util

var packedData:fixedPackedArray;
var gridDims:Vector2i;
var typeCount:int;
var binArrays:Array = [];

func _init(dimensions:Vector2i, uniqueBlocks:int):
	if dimensions.x > 64 || dimensions.y > 64:
		push_error("packedGrid cannot support dimensions larger than 64, if something is broken this is probably why")
	packedData = fixedPackedArray.new(dimensions.x * dimensions.y, Util.bitsToStore(uniqueBlocks));
	gridDims = dimensions
	typeCount = uniqueBlocks
	for type in typeCount: 
		binArrays.push_back([])
	recacheBinaryStrings()

#Use instead of super.readIndex
func read(index):
	var position = getPosition(index, packedData.packSize, packedData.packsPerBox);
	return [rightShift(packedData.array[position.x], position.y) & genMask(packedData.packSize, 1, 1), position]

#Use instead of super.modifyIndex
func modify(index:int, newVal:int):
	if (Util.bitsToStore(newVal) > packedData.packSize):
		print("Value exceeds packing size: " + String.num_int64(newVal))
		return false
	if (index >= packedData.totalPacks):
		print("Cannot access index " + String.num_int64(index))
		return false
	var oldVal = read(index)
	var pos = getPosition(index, packedData.packSize, packedData.packsPerBox)
	packedData.array[oldVal[1].x] += leftShift(newVal - oldVal[0], oldVal[1].y)
	var coords = decode(index, gridDims.x)
	var mask = 1 << coords.x
	binArrays[newVal][coords.y] |= mask
	binArrays[oldVal[0]][coords.y] &= ~mask
	return oldVal[0]

func rowToInt(rowNum:int, matchedValues:Array[int]) -> Array[int]:
	var rows:Array[int] = [];
	for block in matchedValues.size():
		rows.push_back(0)
	var index:int = gridDims.x*rowNum;
	var rowData:Array[int] = readSection(packedData.array, gridDims.x, index, packedData.packSize, packedData.packsPerBox);
	var packCounter:int = 0;
	for i in gridDims.x:
		var dataBox:int = packCounter/packedData.packsPerBox;
		var val:int = rowData[dataBox] & packedData.packMask;
		rowData[dataBox] = rightShift(rowData[dataBox], packedData.packSize);
		for block in matchedValues.size():
			if (matchedValues[block] == val):
				rows[block] += 1 << (packCounter % boxSize);
		packCounter += 1;
	return rows

func mergeStrings(values:Array):
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

func exportGroup(group):
	pass
#
