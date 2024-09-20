class_name BinUtil

static var maxInt = (2**63)-1
static var boxSize = 64

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

#Idk if I like these two being here yet..
static func keyToCell(key:int, rowSize:int) -> Vector2i:
	return Vector2i(key%rowSize, key/rowSize)

static func cellToKey(cell:Vector2i, rowSize:int) -> int:
	return cell.y*rowSize + cell.x

#endregion

#region Mask Functions 

static func genMask(packSize:int, numOfPacks:int, instanceMask:int) -> int:
	var mask:int = 0;
	for pack in numOfPacks:
		mask = (mask << packSize) | instanceMask
	return mask

static func findMasksInInt(num:int) -> Array:
	var masks:Array = [];
	var leading0s:int = 0;
	while num != 0:
		var curMask:int = 0;
		var maskSize:int = 0;
		while num & 1 == 0:
			num = rightShift(num, 1)
			leading0s += 1
		while num & 1 == 1:
			curMask = (curMask << 1) + 1
			num = rightShift(num, 1)
			maskSize += 1;
		curMask = leftShift(curMask, leading0s);
		masks.push_back([curMask, leading0s, maskSize]);
		leading0s += maskSize;
	return masks

static func findFirstMask(num:int):
	var mask:int = findRightSetBit(num);
	var size = 1
	while true:
		var nextMask = ((mask << 1) | mask) & num
		if (mask == nextMask):
			break
		mask = nextMask
		size += 1
	return [mask, size]

static func extendMask(num:int, mask:int):
	var leftExpands:int = 0
	var rightExpands:int = 0
	while true:
		var newMask = (leftShift(mask, 1) & num) | mask
		if (newMask == mask):
			break
		mask = newMask
		leftExpands += 1
	while true:
		var newMask = (rightShift(mask, 1) & num) | mask
		if (newMask == mask):
			break
		mask = newMask
		rightExpands += 1
	return [mask, [leftExpands, rightExpands]]

#endregion

#region binArray Deriving Functions

static func makeNextChecks(mask:int, rowNum:int, maxRow:int):
	return [
	false if rowNum + 1 == maxRow else Vector2i(mask, rowNum + 1),
	false if rowNum - 1 == -1 else Vector2i(mask, rowNum - 1)
	]

class Group:
	var blockCount:int
	var binGrid:Array[int]
	func _init(data:Array[int], blocks:int):
		binGrid = data
		blockCount = blocks

static func findGroups(binArray:Array[int], numOfRows:int):
	var binaryArray = binArray.duplicate()
	var groups:Array = []
	while (binaryArray.any(func(r): return r != 0)):
		var blockCount:int = 0;
		var groupArray:Array[int] = []
		for row in numOfRows: groupArray.push_back(0)
		var checks:Array = []
		for row in binaryArray.size(): #Find first row with data
			if (binaryArray[row] != 0):
				var fullMask = findFirstMask(binaryArray[row])
				blockCount += fullMask[1]
				checks.append_array(makeNextChecks(fullMask[0], row, binaryArray.size()))
				binaryArray[row] &= ~fullMask[0]
				groupArray[row] |= fullMask[0]
				break
		while checks.is_empty() == false:
			var curCheck = checks.pop_back()
			while typeof(curCheck) == 1: curCheck = checks.pop_back()
			if curCheck == null: break #checks is empty
			var newMask = binaryArray[curCheck.y] & curCheck.x
			while newMask != 0:
				var foundMask = findFirstMask(newMask)
				blockCount += foundMask[1]
				newMask &= ~foundMask[0]
				var fullMask = extendMask(binaryArray[curCheck.y], foundMask[0]) 
				binaryArray[curCheck.y] &= ~fullMask[0]
				groupArray[curCheck.y] |= fullMask[0]
				checks.append_array(makeNextChecks(fullMask[0], curCheck.y, binaryArray.size()))
				blockCount += fullMask[1][0] + fullMask[1][1]
		groups.push_back(Group.new(groupArray, blockCount))
	return groups

static func greedyRect(binArray:Array) -> Array:
	var binaryArray = binArray.duplicate()
	var meshedBoxes:Array = []
	#Actual meshing
	for row in binaryArray.size(): #Search each row
		var rowData:int = binaryArray[row];
		if (rowData == 0):
			continue #Row is empty, go on to next row
		#else: At least one mask exists in current row
		var masks:Array = findMasksInInt(rowData);
		for maskData in masks: #For each mask found
			var curMask:int = maskData[0]
			var box:Rect2i = Rect2i(0,0,0,0)
			box.position.y = row;
			box.position.x = maskData[1];
			box.size.x = maskData[2];
			for curRowSearching in range(row, binaryArray.size()): #Search each remaining row
				if (binaryArray[curRowSearching] & curMask == curMask): #Mask exists in row
					binaryArray[curRowSearching] &= ~curMask; #Eliminate mask from row
					box.size.y += 1
				else:
					break #Mask does not exist in row, shape is complete
			meshedBoxes.push_back(box);
	return meshedBoxes

#endregion

#region binArray Handling Functions

class fixedPackedArray:
	var array:Array[int] = [];
	var totalPacks:int;
	var packSize:int;
	var packMask:int;
	var packsPerBox:int;
	var totalBoxes:int;
	func _init(storageNeeded:int, sizeOfPack:int):
		totalPacks = storageNeeded
		packSize = sizeOfPack
		packMask = 2**packSize - 1;
		packsPerBox = BinUtil.boxSize/packSize
		totalBoxes = ceili(float(totalPacks)/packsPerBox);
		for box in totalBoxes:
			array.push_back(0);

static func packArray(array:Array[int]):
	if array.min() < 0:
		print("Packing negative numbers, how silly")
		return "NOPE"
	var packedArray = fixedPackedArray.new(array.size(), bitsToStore(array.max()))
	var curPack = 0
	for box in packedArray.totalBoxes:
		for pack in packedArray.packsPerBox:
			packedArray.array[box] |= array[box*packedArray.packsPerBox + pack] << pack*packedArray.packSize
			curPack += 1 
			if (curPack >= packedArray.totalPacks): break
	return packedArray

static func unpackArray(packedArray:fixedPackedArray):
	var unpackedArray = [];
	var curPack = 0
	for box in packedArray.totalBoxes:
		for pack in packedArray.packsPerBox:
			unpackedArray.push_back(rightShift(packedArray.array[box], pack*packedArray.packSize) & packedArray.packMask)
			curPack += 1 
			if (curPack >= packedArray.totalPacks): break
	return unpackedArray

class Address:
	var box:int;
	var shift:int;
	func _init(boxNum:int, padding:int):
		box = boxNum;
		shift = padding;

static func getPosition(index, packSize:int = 1):
	var packsPerBox:int = boxSize/packSize
	var boxNum = index/packsPerBox
	var padding = (index - boxNum*packsPerBox)*packSize
	return Address.new(boxNum, padding)

static func accessIndex(data:Array[int], index:int, packSize:int, modify:int = 0):
	var pos = getPosition(index, packSize);
	var curVal = rightShift(data[pos.box], pos.shift) & genMask(packSize, 1, 1)
	if (modify != 0):
		data[pos.box] += leftShift(modify - curVal, pos.shift)
	return curVal

static func readSection(array:Array, packs:int, startIndex:int, packMask:int, packSize:int = 1):
	var packsPerBox:int = boxSize/packSize
	var section:Array[int] = [];
	var pos = getPosition(startIndex, packSize)
	var remPacksInCurBox:int = (boxSize - pos.shift)/packSize
	while packs > 0:
		var rightSideMask:int = genMask(packSize, min(remPacksInCurBox, packs), packMask);
		var packsInNextBox = min(boxSize, packs) - remPacksInCurBox
		var leftSideMask:int = genMask(packSize, packsInNextBox, packMask) if (remPacksInCurBox > packs) else 0;
		var rightSide = rightShift(array[pos.box], pos.shift) & rightSideMask;
		var leftSide = leftShift(array[pos.box+1] & leftSideMask, remPacksInCurBox * packSize) if (remPacksInCurBox < packs) else 0;
		section.push_back(rightSide | leftSide);
		packs -= packsPerBox;
		pos.box += 1;
		remPacksInCurBox = boxSize - packsInNextBox;
	return section

#endregion

#
