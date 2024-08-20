class_name bitField

static var boxSize = 64 #64 bit Int

var totalPacks:int;
var packSize:int;
var packMask:int;
var packsPerBox:int;
var totalBoxes:int;
var data:Array[int] = [];

#Constructor
static func create(packNum:int, packSiz:int):
	var field = bitField.new();
	field.totalPacks = packNum;
	field.packSize = packSiz; 
	field.packMask = 2**packSiz - 1;
	field.packsPerBox = boxSize/packSiz
	field.totalBoxes = ceil(float(packNum)/field.packsPerBox);
	for box in field.totalBoxes:
		field.data.push_back(0);
	return field;

#Instance function start
func _getBox(index:int):
	return int (index/packsPerBox)

func _getPadding(index:int, boxNum:int):
	var packNum:int = index - boxNum*packsPerBox
	return packNum*packSize

func read(index:int):
	var boxNum:int = _getBox(index);
	var padding:int = _getPadding(index, boxNum);
	return Util.rightShift(data[boxNum], padding) & packMask 

func readSection(packsRemaining:int, startIndex:int):
	var section:Array[int] = [];
	var currentBox:int = _getBox(startIndex);
	var curPadding:int = _getPadding(startIndex, currentBox);
	var remPacksInCurBox:int = (boxSize - curPadding)/packSize
	while packsRemaining > 0:
		var rightSideMask:int = Util.genMask(packSize, min(remPacksInCurBox, packsRemaining), packMask);
		var packsInNextBox = min(boxSize, packsRemaining) - remPacksInCurBox
		var leftSideMask:int = Util.genMask(packSize, packsInNextBox, packMask) if (remPacksInCurBox > packsRemaining) else 0;
		var rightSide = Util.rightShift(data[currentBox], curPadding) & rightSideMask;
		var leftSide = Util.leftShift(data[currentBox+1] & leftSideMask, remPacksInCurBox * packSize) if (remPacksInCurBox < packsRemaining) else 0;
		section.push_back(rightSide + leftSide);
		packsRemaining -= packsPerBox;
		currentBox += 1;
		remPacksInCurBox = boxSize - packsInNextBox;
	return section

func modify(index:int, newVal:int):
	if (Util.bitsToStore(newVal) > packSize):
		print("Value exceeds packing size: " + String.num_int64(newVal))
		return false
	if (index >= totalPacks):
		print("Cannot access index " + String.num_int64(index))
		return false
	var boxNum:int = _getBox(index);
	var oldValue:int = read(index);
	data[boxNum] += Util.leftShift(newVal - oldValue, _getPadding(index, boxNum))
	return oldValue
