class_name SparseDimensionalDAG

#For now we're going to use arrays and search instead of hashing/lookups.
#This is very likely to change, don't worry about it
class Nodes:
	var pot:Array = []
	
	func _init(layers:int):
		for layer in layers:
			pot.push_back([])
		pot[layers - 1].push_back(Branch.new())
	
	func findFirstOpenSpot(layer):
		for i in pot[layer].size():
			if typeof(pot[layer][i]) == 2:
				return i
		pot[layer].push_back(-1)
		return pot[layer].size() - 1
		
	func getNodeIndex(layer, node) -> int:
		for branch in pot[layer].size():
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

class Branch:
	var children:Array[int]
	var mask:int
	var refCount:int = 1
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

#Hybrid Quadtree/Dag rn depending on insertion order
#Figure out how and why references work the way they do
func addData(path:int):
	#Yeah I know I'm gettingPathIndi twice, shut up
	if readLeaf(path) == 1:
		return
	var pathIndexes = getPathIndi(path) #Path from leaf to root
	var lastIndex = 1
	#Placeholder so our loop doesn't break on it's first run
	var lastNode:Branch = Branch.new() 
	for layer in pathIndexes.size():
		var curIndex:int = pathIndexes[layer]
		var curNode:Branch
		var newNode = false
		if curIndex == -1: #Node does not exist
			curNode = Branch.new()
			newNode = true
		else:
			curNode = nodes.pot[layer][curIndex]
			if curNode.refCount == 2:
				curNode.refCount -= 1
				curNode = curNode.duplicate()
				newNode = true
		var kidDirection = (path >> layer) & 0b1
		curNode.children[kidDirection] = lastIndex
		curNode.mask |= 1 << kidDirection
		curNode.blockCount += 1
		lastIndex = nodes.addNode(layer, curNode)
		if newNode == true:
			lastNode.refCount += 1
		lastNode = curNode

func readLeaf(path:int):
	var pathIndexes = getPathIndi(path) #Path from leaf to root
	if pathIndexes[0] == -1:
		return 0
	return nodes.pot[0][pathIndexes[0]].children[path & 0b1]

#Need to be written \/ \/ \/

func mergeDuplicateNodes():
	pass

func expandTree(_filledQuadrant:int):
	#Make root a child of a larger root with three empty segments
	#Incrememnt layersFromRootToLeaf
	pass
