class_name Util

static var maxInt = (2**63)-1

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

static func genMask(packSize:int, numOfPacks:int, instanceMask:int) -> int:
	var mask:int = 0;
	for pack in numOfPacks:
		mask = (mask << packSize) | instanceMask
	return mask

static func findFirstMask(row:int) -> int:
	var mask:int = findRightSetBit(row);
	row &= ~mask;
	while true:
		var nextMask = (mask << 1) | mask
		if (mask == nextMask):
			break
		mask = nextMask
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
		curMask <<= leading0s;
		masks.push_back([curMask, leading0s, maskSize]);
		leading0s += maskSize;
	return masks
