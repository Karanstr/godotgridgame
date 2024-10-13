#Right now only compatible with 1 dimensional binary tree
class_name SparseDimensionalDAG

#(Root Layer, Root Index)
var rootAddress:Vector2i

func _init(layerCount:int = 1):
	Nodes.ensureDepth(layerCount - 1)
	rootAddress = Vector2i(layerCount - 1, -1) #No data is currently associated with root

func getPathToLayer(path:int, targetLayer:int = 0) -> Array[int]:
	var layersToStore = 1 + rootAddress[0] - targetLayer
	var trail:Array[int] = []
	trail.resize(layersToStore)
	trail.fill(-1)
	trail[layersToStore - 1] = rootAddress[1]
	for i in layersToStore - 1:
		var layer = rootAddress[0] - i
		var kidDirection = (path >> layer) & 0b1
		trail[layer - 1] = Nodes.readKid(layer, trail[layer], kidDirection)
		if trail[layer - 1] == -1: #The path ends
			break
	return trail

func setNodeChild(path:int, childIndex:int, targetLayer:int = 0):
	var steps:Array = getPathToLayer(path, targetLayer)
	for step in steps.size():
		var curLayer = targetLayer + step
		childIndex = Nodes.addAlteredNode(curLayer, steps[step], (path >> step) & 0b1, childIndex)
	#Gotta handle this part manually, WE are pointing to the root node instead of it's parent
	reIndexRoot(childIndex)

func readLeaf(path:int):
	var leafAddr = getPathToLayer(path, 0)[0] #Path from leaf to root
	if leafAddr == -1:
		return 0
	return Nodes.readKid(0, leafAddr, path & 0b1)

#region Root Handling

func reIndexRoot(newIndex:int):
	if newIndex != -1:
		Nodes.modifyReference(rootAddress[0], newIndex, 1)
	if rootAddress[1] != -1:
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress[1] = newIndex

#Merge this and below into one modifyRootLayer function.
func raiseRootOneLevel(filledChildDirection:int):
	var newLayer = rootAddress[0] + 1
	Nodes.ensureDepth(newLayer)
	var newRootIndex:int = Nodes.addAlteredNode(newLayer, -1, filledChildDirection, rootAddress[1])
	if rootAddress[1] != -1: #If the root/tree is not currently empty
		Nodes.modifyReference(newLayer, newRootIndex, 1)
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress = Vector2i(newLayer, newRootIndex)

func lowerRootOneLevel(preserveChildDirection:int):
	var newLayer = rootAddress[0] - 1
	if rootAddress[0] == 0:
		print("Can't lower into leaf")
		return
	var newRootIndex:int = Nodes.readKid(rootAddress[0], rootAddress[1], preserveChildDirection)
	if newRootIndex != -1: #We are referencing the new root
		Nodes.modifyReference(newLayer, newRootIndex, 1)
	if rootAddress[1] != -1: #We aren't referencing the old root anymore
		Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
	rootAddress = Vector2i(newLayer, newRootIndex)

#endregion

#region Binary it

#I hate recursion. Also only works with depths of up to 6 rn bc I'm not implementing binSizes of larger than 64 yet
func DFSGraphToBin(curLayer:int = rootAddress[0], curIndex:int = rootAddress[1]):
	var childBinSize = 2 ** curLayer #Number of children per node * curLayer
	var binRep:int = 0b0
	var children:Array[int] = Nodes.getChildrenIndexes(curLayer, curIndex)
	for child in children.size():
		if children[child] == -1: #If child doesn't exist
			pass
			#Don't do anything
		elif curLayer != 0:
			binRep |= DFSGraphToBin(curLayer - 1, children[child]) << (childBinSize * child)
		else:
			binRep |= 1 << (childBinSize * child)
	return binRep

#endregion
