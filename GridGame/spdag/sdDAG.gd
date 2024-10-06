class_name SparseDimensionalDAG

#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class Nodes:
	var pot:Array = []
	var mayNeedRemoving:Array[Dictionary] = []
	
	func _init(layers:int):
		for layer in layers:
			pot.push_back([])
			mayNeedRemoving.push_back({})
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
	
	func removeUneededNodes():
		for layer in mayNeedRemoving.size():
			for node in mayNeedRemoving[layer]:
				if pot[layer][node].refCount < 1:
					pot[layer][node] = -1 #Eliminate node
				mayNeedRemoving[layer].clear()
	
	func removeRef(layer, index):
		pot[layer][index].refCount -= 1
		if pot[layer][index].refCount < 1:
			mayNeedRemoving[layer][index] = true
			if layer != 0:
				var setKids:int = pot[layer][index].mask
				var children:Array[int] = pot[layer][index].children
				var curIndex:int = 0;
				while setKids != 0:
					if setKids & 0b1:
						removeRef(layer - 1, children[curIndex]) #I hate recursion
					setKids >>= 1
					curIndex += 1
	
	#/\ && \/ These are very similar, but not the same.. 
	func addChildRefs(layer, index):
		if layer != 0:
			var setKids:int = pot[layer][index].mask
			var children:Array[int] = pot[layer][index].children
			var curIndex:int = 0;
			while setKids != 0:
				if setKids & 0b1:
					pot[layer - 1][children[curIndex]].refCount += 1
				setKids >>= 1
				curIndex += 1

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
		var kidDirection = (path >> curLayer) & 0b1
		if (curNode.mask >> kidDirection) & 0b1 == 0: #The path ends
			return trail
		var kidIndex = curNode.children[kidDirection & 0b1]
		trail[curLayer - 1] = kidIndex
		curNode = nodes.pot[curLayer - 1][kidIndex]
		curLayer -= 1
	return trail

#Refcount isn't quite working yet
func addData(path:int):
	var pathIndexes = getPathIndi(path) #Path from leaf[0] to root[size-1]
	if pathIndexes[0] != -1 && nodes.pot[0][pathIndexes[0]].children[path & 0b1] == 1: 
		return #Node exists and is already set
	var lastIndex = 1 #We want to set our leaf to 1
	for layer in pathIndexes.size():
		var curIndex:int = pathIndexes[layer]
		var curNode:Branch
		if curIndex == -1: #Node needs to be made
			curNode = Branch.new()
		else: #Node already exists and is referenced in our path
			if layer == topLayer: #Don't mess with the root :(
				curNode = nodes.pot[layer][curIndex]
			else:
				curNode = nodes.pot[layer][curIndex].duplicate()
				nodes.removeRef(layer, curIndex)
		var kidDirection = (path >> layer) & 0b1
		curNode.children[kidDirection] = lastIndex
		curNode.mask |= 1 << kidDirection
		curNode.blockCount += 1
		curIndex = nodes.addNode(layer, curNode)
		nodes.addChildRefs(layer, curIndex)
		lastIndex = curIndex
	nodes.removeUneededNodes()

func readLeaf(path:int):
	var pathIndexes = getPathIndi(path) #Path from leaf to root
	if pathIndexes[0] == -1:
		return 0
	return nodes.pot[0][pathIndexes[0]].children[path & 0b1]

func expandTree(_filledQuadrant:int):
	pass
