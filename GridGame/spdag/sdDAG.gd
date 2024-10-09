class_name SparseDimensionalDAG

#(Root Layer, Root Index)
var rootAddress:Vector2i

func _init(layerCount:int = 1):
	Nodes.ensureDepth(layerCount - 1)
	rootAddress = Vector2i(layerCount - 1, -1) #No data is currently associated with root

func getPathToLayer(path, targetLayer = 0) -> Array[int]:
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

func setNodeChild(path, childIndex, targetLayer = 0):
	var steps:Array = getPathToLayer(path, targetLayer)
	var curChild = Nodes.readKid(targetLayer, steps[0], path & 0b1)
	if curChild == childIndex: #No need to do anything
		return
	for step in steps.size():
		var curLayer = targetLayer + step
		childIndex = Nodes.addAlteredNode(curLayer, steps[step], (path >> step) & 0b1, childIndex)
	rootAddress[1] = childIndex

func readLeaf(path:int):
	var leafAddr = getPathToLayer(path, 0)[0] #Path from leaf to root
	if leafAddr == -1:
		return 0
	return Nodes.readKid(0, leafAddr, path & 0b1)

func expandTree(filledQuadrant:int):
	pass
