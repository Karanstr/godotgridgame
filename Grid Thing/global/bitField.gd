class_name bitField

const boxSize = 63 #bits, 63 bc signed :(
var totalPacks:int;
var packSize:int;
var packMask:int;
var packsPerBox:int;
var totalBoxes:int;
var data:Array[int] = [];

#Constructor
static func create(packNum:float, packSiz:int):
	var field = bitField.new();
	field.totalPacks = packNum;
	field.packSize = packSiz; 
	field.packMask = 2**packSiz - 1;
	field.packsPerBox = floor(boxSize/packSiz)
	field.totalBoxes = ceil(packNum/field.packsPerBox);
	for box in field.totalBoxes:
		field.data.append(0);
	return field;

func _getBox(index:int):
	return int (index/packsPerBox)

func _getPadding(index:int, boxNum:int):
	var packNum:int = index - boxNum*packsPerBox
	return packNum*packSize

func read(index:int):
	var boxNum:int = _getBox(index);
	var padding:int = _getPadding(index, boxNum);
	return (data[boxNum] >> padding) & packMask 

func modify(index:int, newVal:int):
	if (Utility.bitCount(newVal) > packSize):
		print("Value exceeds packing size: " + String.num_int64(newVal))
		return false
	if (index >= totalPacks):
		print("Cannot access index " + String.num_int64(index))
		return false
	var boxNum:int = _getBox(index);
	var box:int = data[boxNum]	
	var oldValue:int = read(index);
	box += (newVal - oldValue) << _getPadding(index, boxNum)
	data[boxNum] = box
	return oldValue
