class_name Util

static var maxInt = (2**63)-1

#region Bit Functions

static func bitsToStore(number:int) -> int:
	if (number == 1):
		return 1
	var bits:int = 1;
	var oneCount:int = number & 1;
	number >>= 1;
	while number != 0:
		oneCount += number & 1;
		bits += 1;
		number >>= 1;
	if (oneCount == 1):
		return bits - 1
	return bits

static func findRightSetBit(number:int) -> int:
	return number & -number

static func leftShift(number:int, bits:int) -> int:
	if (bits == 0):
		return number
	return (number & maxInt) << bits

static func rightShift(number:int, bits:int) -> int:
	if (bits == 0):
		return number
	var shiftedNumber:int = (number & maxInt) >> bits;
	if (number < 0):
		var saveSign:int = 1 << (63 - bits)
		shiftedNumber |= saveSign
	return shiftedNumber

#endregion

#region Mask Functions 

static func genMask(packSize:int, numOfPacks:int, instanceMask:int) -> int:
	var mask:int = 0;
	for pack in numOfPacks:
		mask = (mask << packSize) | instanceMask
	return mask

static func findMasksInBitRow(row:int) -> Array:
	var masks:Array = [];
	var leading0s:int = 0;
	while row != 0:
		var curMask:int = 0;
		var maskSize:int = 0;
		while row & 1 == 0:
			row = rightShift(row, 1)
			leading0s += 1
		while row & 1 == 1:
			curMask = (curMask << 1) + 1
			row = rightShift(row, 1)
			maskSize += 1;
		curMask = leftShift(curMask, leading0s);
		masks.push_back([curMask, leading0s, maskSize]);
		leading0s += maskSize;
	return masks

static func findFirstMask(row:int) -> int:
	var mask:int = findRightSetBit(row);
	while true:
		var nextMask = ((mask << 1) | mask) & row
		if (mask == nextMask):
			break
		mask = nextMask
	return mask

static func extendMask(row:int, mask:int) -> int:
	while true:
		var newMask = (leftShift(mask, 1) & row) | mask
		if (newMask == mask):
			break
		mask = newMask
	while true:
		var newMask = (rightShift(mask, 1) & row) | mask
		if (newMask == mask):
			break
		mask = newMask
	return mask

#endregion

#region BStrings & BArrays

static func makeNextChecks(mask:int, row:int, maxRow:int):
	var checks:Array = [
	false if row + 1 == maxRow else Vector2i(mask, row + 1),
	false if row - 1 == -1 else Vector2i(mask, row - 1)
	]
	return checks 

static func walkGrid(binaryArray:Array[int]):
	var foundBlocks = 1;
	var checks:Array = []
	#Can't search an empty array
	if (binaryArray.all(func(r): return r == 0)): return 0
	for row in binaryArray.size(): #Find first row with data
		if (binaryArray[row] != 0):
			var fullMask = Util.findFirstMask(binaryArray[row])
			checks.append_array(makeNextChecks(fullMask, row, binaryArray.size()))
			binaryArray[row] &= ~fullMask
			break
	while checks.is_empty() == false:
		var curCheck = checks.pop_back()
		while typeof(curCheck) == 1: curCheck = checks.pop_back()
		if curCheck == null: break #checks is empty
		var newMask = binaryArray[curCheck.y] & curCheck.x
		while newMask != 0:
			foundBlocks += 1;
			var foundMask = Util.findFirstMask(newMask)
			newMask &= ~foundMask
			var fullMask = Util.extendMask(binaryArray[curCheck.y], foundMask) 
			binaryArray[curCheck.y] &= ~fullMask
			checks.append_array(makeNextChecks(fullMask, curCheck.y, binaryArray.size()))
	if (binaryArray.any(func(r): return r != 0)): print("Not attached")
	return foundBlocks


#endregion

#
