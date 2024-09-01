class_name Util

static var maxInt = 9223372036854775807

static func bitsToStore(n:int):
	if (n == 1):
		return 1
	var bits:int = 1;
	var oneCount:int = n & 1;
	n >>= 1;
	while n != 0:
		oneCount += n & 1;
		bits += 1;
		n >>= 1;
	if (oneCount == 1):
		return bits - 1
	return bits

static func genMask(packSize:int, numOfPacks:int, instanceMask:int):
	var mask:int = 0;
	for pack in numOfPacks:
		mask = (mask << packSize) + instanceMask
	return mask

static func leftShift(number:int, bits:int):
	if (bits == 0):
		return number
	return (number & maxInt) << bits

static func rightShift(number:int, bits:int):
	if (bits == 0):
		return number
	var shiftedNumber:int = (number & maxInt) >> bits;
	if (number < 0):
		var saveSign:int = 1 << (63 - bits)
		shiftedNumber |= saveSign
	return shiftedNumber

static func findMasksInBitRow(row:int):
	var masks:Array = [];
	var remShift:int = 0;
	while row != 0:
		var curMask:int = 0;
		var maskSize:int = 0;
		while row & 1 == 0:
			row = rightShift(row, 1)
			remShift += 1
		while row & 1 == 1:
			curMask = (curMask << 1) + 1
			row = rightShift(row, 1)
			maskSize += 1;
		curMask <<= remShift;
		masks.push_back([curMask, remShift, maskSize]);
		remShift += maskSize;
	return masks
