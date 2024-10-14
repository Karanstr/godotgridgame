#Right now only compatible with 1 dimensional binary tree
class_name SparseDimensionalDAG
#(Root Layer, Root Index)
var rootAddress:Vector2i

func _init(rootLayer:int = 0):
	Nodes.ensureDepth(rootLayer)
	#No data is currently associated with root
	#Index 0 of each layer is reserved for empty
	rootAddress = Vector2i(rootLayer, 0) 

func getPathToLayer(path:int, targetLayer:int = 0) -> Array[int]:
	var layersToStore = 1 + rootAddress[0] - targetLayer
	var trail:Array[int] = []
	trail.resize(layersToStore)
	trail.fill(0)
	trail[layersToStore - 1] = rootAddress[1]
	for i in layersToStore - 1:
		var layer = rootAddress[0] - i
		var kidDirection = (path >> layer) & 0b1
		trail[layer - 1] = Nodes.readKid(layer, trail[layer], kidDirection)
		if trail[layer - 1] == 0: #The path ends
			break
	return trail

func readLeaf(path:int) -> int:
	var leafAddr = getPathToLayer(path, 0)[0] #Path from leaf to root
	if leafAddr == 0:
		return 0
	return Nodes.readKid(0, leafAddr, path & 0b1)

#region Graph Editing

func setNodeChild(path:int, childIndex:int, targetLayer:int = 0):
	var steps:Array = getPathToLayer(path, targetLayer)
	for step in steps.size():
		var curLayer = targetLayer + step
		childIndex = Nodes.addAlteredNode(curLayer, steps[step], (path >> step) & 0b1, childIndex)
	#Gotta handle this part manually, WE are pointing to the root node instead of it's parent
	reIndexRoot(childIndex)

#endregion

#region Root Handling

func reIndexRoot(newIndex:int):
	if newIndex != 0:
		Nodes.modifyReference(rootAddress[0], newIndex, 1)
	if rootAddress[1] != 0:
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress[1] = newIndex

#Merge this and below into one modifyRootLayer function.
func raiseRootOneLevel(filledChildDirection:int):
	var newLayer = rootAddress[0] + 1
	Nodes.ensureDepth(newLayer)
	var newRootIndex:int = Nodes.addAlteredNode(newLayer, 0, filledChildDirection, rootAddress[1])
	if rootAddress[1] != 0: #If the root/tree is not currently empty
		Nodes.modifyReference(newLayer, newRootIndex, 1)
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress = Vector2i(newLayer, newRootIndex)

func lowerRootOneLevel(preserveChildDirection:int):
	var newLayer = rootAddress[0] - 1
	if rootAddress[0] == 0:
		print("Can't lower into leaf")
		return
	var newRootIndex:int = Nodes.readKid(rootAddress[0], rootAddress[1], preserveChildDirection)
	if newRootIndex != 0: #We are referencing the new root
		Nodes.modifyReference(newLayer, newRootIndex, 1)
	if rootAddress[1] != 0: #We aren't referencing the old root anymore
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress = Vector2i(newLayer, newRootIndex)

func growToContain(cell) -> Array:
	var maxCell = 2 ** (rootAddress[0] + 1)
	var side = 0 if cell.x > 0 else 1
	var totalBlocksShifted:Vector2i = Vector2i(0, 0)
	while cell.x < 0 || cell.x >= maxCell: #Cell isn't within bounds
		var numOfBlocksShifted = maxCell / 2
		raiseRootOneLevel(side)
		maxCell = 2 ** (rootAddress[0] + 1)
		cell.x += numOfBlocksShifted * 2 * side
		totalBlocksShifted.x -= 2 * numOfBlocksShifted * side
	return [cell, totalBlocksShifted]

func shrinkToFit() -> int:
	var foundNum = 1
	var found:int
	var blocksShifted = 0
	while foundNum == 1:
		if rootAddress[0] == 0:
			break
		var children = Nodes.getChildrenIndexes(rootAddress[0], rootAddress[1])
		foundNum = 0
		for child in children.size():
			if children[child] != 0:
				foundNum += 1
				found = child
		if foundNum == 1:
			blocksShifted += (2 ** rootAddress[0]) * found / 2 #Cheap hack, doesn't generalize
			lowerRootOneLevel(found)
	return blocksShifted

#endregion

#region Binary Stuff

#I hate recursion. 
#Also only works with depths of up to 6 rn bc I'm not implementing multiInts
func DFSGraphToBin(curLayer:int = rootAddress[0], curIndex:int = rootAddress[1]) -> int:
	if curIndex == 0:
		return 0
	var childBinSize = 2 ** curLayer #Number of children per node ** curLayer
	var binRep:int = 0b0
	var children:Array[int] = Nodes.getChildrenIndexes(curLayer, curIndex)
	for child in children.size():
		if curLayer != 0:
			binRep |= DFSGraphToBin(curLayer - 1, children[child]) << (childBinSize * child)
		elif children[child] != 0:
			binRep |= 1 << (childBinSize * child)
	return binRep

func BinToGraph():
	pass

#endregion
