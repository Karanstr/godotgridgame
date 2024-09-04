var binaryStrings_block_row:Array = [];
newGrid._recacheBinaryStrings()

func _recacheBinaryStrings():
	var newBinaryStrings:Array = [];
	var tempArrays:Array = [];
	var allBlocks:Array[int] = [];
	for block in uniqueBlocks:
		allBlocks.push_back(block);
	for row in dimensions.y:
		tempArrays.push_back(blocks.rowToInt(dimensions.x, row, allBlocks));
	for block in uniqueBlocks:
		newBinaryStrings.push_back([]);
		for row in dimensions.y:
			newBinaryStrings[block].push_back(tempArrays[row][block])
	binaryStrings_block_row = newBinaryStrings
	return true

#Move this function at some point to Util
func mergeStrings(values:Array[int]):
	var binaryArray:Array[int] = [];
	for row in dimensions.y:
		binaryArray.push_back(0)
		for value in values: #Combine BStrings into single string per row
			binaryArray[row] |= binaryStrings_block_row[value][row]
	return binaryArray

func assign(key:int, value:int) -> int:
	var oldVal = blocks.modify(key, value);
	var coords = decode(key)
	var mask = 1 << coords.x
	binaryStrings_block_row[value][coords.y] |= mask
	binaryStrings_block_row[oldVal][coords.y] &= ~mask
	return oldVal

#
