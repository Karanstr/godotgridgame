extends Node

static var maxInt = 9223372036854775807

func bitCount(number:int):
	var bits:int = 0
	while number != 0:
		number >>=1;
		bits+=1
	return bits

func genMask(packSize:int, numOfPacks:int, instanceMask:int):
	var mask:int = 0;
	for pack in numOfPacks:
		mask = (mask << packSize) + instanceMask
	return mask

func leftShift(number:int, bits:int):
	if (bits == 0):
		return number
	return (number & Util.maxInt) << bits

func rightShift(number:int, bits:int):
	if (bits == 0):
		return number
	var shiftedNumber:int = (number & Util.maxInt) >> bits;
	if (number < 0):
		var saveB64:int = 1 << (64 - bits)
		shiftedNumber |= saveB64
	return shiftedNumber

