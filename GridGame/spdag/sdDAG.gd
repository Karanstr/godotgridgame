class_name SparseDimensionalDAG

#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class Nodes:
	var pot:Array = []
	
	func _init(layers:int):
		for layer in layers:
			pot.push_back([])
		addNode(layers - 1, Branch.new())
	
	#This feels like it should be reworked at some point, doesn't matter yet tho
	func findFirstOpenSpot(layer):
		for i in pot[layer].size():
			if typeof(pot[layer][i]) == 2:
				return i
		pot[layer].push_back(-1)
		return pot[layer].size() - 1
	
	func getNodeIndex(layer, node) -> int:
		for branch in pot[layer].size():
			if typeof(pot[layer][branch]) == 2: #Is type int
				continue
			if pot[layer][branch].mask == node.mask && pot[layer][branch].children == node.children:
				return branch
		return -1
	
	func addNode(layer, node) -> int:
		var potIndex = getNodeIndex(layer, node)
		if potIndex != -1:
			return potIndex
		var index = findFirstOpenSpot(layer)
		pot[layer][index] = node
		return index
	
	func removeIfNeeded(layer, index):
		if pot[layer][index].refCount < 1:
			pot[layer][index] = -1
	
	func modifyRefCount(layer, index, deltaRef):
		print("Layer " + String.num(layer) + " Index " + String.num(index))
		pot[layer][index].refCount += deltaRef
		removeIfNeeded(layer, index)

class Branch:
	var children:Array[int]
	var mask:int
	var refCount:int = 0
	var blockCount:int = 0
	func _init(childMask:int = 0b00, kids:Array[int] = [0,0]):
		children = kids
		mask = childMask
	
	func duplicate():
		var newBranch = Branch.new(mask, children.duplicate())
		newBranch.blockCount = blockCount
		return newBranch

var nodes:Nodes
var topLayer:int

func _init(layerCount:int = 1):
	nodes = Nodes.new(layerCount)
	topLayer = layerCount - 1

func getPathIndi(path) -> Array[int]:
	var trail:Array[int] = []
	trail.resize(topLayer + 1)
	trail.fill(-1)
	trail[topLayer] = 0
	var curNode = nodes.pot[topLayer][0]
	var curLayer = topLayer
	while curLayer != 0: #Descend until we're at the bottom
		var kidDirection = path >> curLayer
		if (curNode.mask >> kidDirection) & 1 == 0: #The path ends
			return trail
		var kidIndex = curNode.children[kidDirection & 0b1]
		trail[curLayer - 1] = kidIndex
		curNode = nodes.pot[curLayer - 1][kidIndex]
		curLayer -= 1
	return trail

func addData(path:int):
	var pathIndexes = getPathIndi(path) #Path from leaf[0] to root[size-1]
	if pathIndexes[0] != -1 && nodes.pot[0][pathIndexes[0]].children[path & 0b1] == 1: 
		return #Node exists and is already set
	var lastIndex = 1 #We want to set our leaf to 1
	for layer in pathIndexes.size():
		var curIndex:int = pathIndexes[layer]
		var curNode:Branch
		if curIndex == -1:
			curNode = Branch.new()
		else: #Node already exists and is referenced in our path
			curNode = nodes.pot[layer][curIndex].duplicate()
			nodes.modifyRefCount(layer, curIndex, -1)
		var kidDirection = (path >> layer) & 0b1
		curNode.children[kidDirection] = lastIndex
		curNode.mask |= 1 << kidDirection
		curNode.blockCount += 1
		curIndex = nodes.addNode(layer, curNode)
		if layer != 0: #Our leaf node technically doesn't exist on layer 0
			nodes.modifyRefCount(layer - 1, lastIndex, 1)
		lastIndex = curIndex

func readLeaf(path:int):
	var pathIndexes = getPathIndi(path) #Path from leaf to root
	if pathIndexes[0] == -1:
		return 0
	return nodes.pot[0][pathIndexes[0]].children[path & 0b1]



func expandTree(_filledQuadrant:int):
	pass
