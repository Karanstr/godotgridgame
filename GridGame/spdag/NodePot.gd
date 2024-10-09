#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class_name Nodes

static var pot:Array = []
static var emptyNode = Branch.new()
#Node Address is as follows: Vector2i(layer, index)
#static var rootList:Dictionary = {}

class Branch:
	var children:Array[int]
	
	func _init(kids:Array[int] = [-1, -1]):
		children = kids.duplicate()
	
	func duplicate():
		var newBranch = Branch.new(children)
		return newBranch
	
	func isEmpty():
		return children == Nodes.emptyNode.children

static func ensureDepth(layersAboveLeafBranch:int = 0):
	for i in layersAboveLeafBranch - (pot.size() - 1):
		pot.push_back([])

static func readKid(layer, index, childDirection):
	if index == -1:
		return -1
	return pot[layer][index].children[childDirection]

static func getNodeDup(layer, index):
	if index == -1: #Stop lookups on empty arrays
		return emptyNode.duplicate()
	return pot[layer][index].duplicate()

static func addAlteredNode(layer, index, childDirection, newChild):
	var curNode = getNodeDup(layer, index)
	curNode.children[childDirection] = newChild
	if not curNode.isEmpty():
		return addNode(layer, curNode)
	return -1

static func getNodeIndex(layer, node) -> int:
	for index in pot[layer].size():
		if pot[layer][index].children == node.children:
			return index
	return -1

static func findFirstOpenSpot(layer):
	var index = getNodeIndex(layer, emptyNode)
	if index != -1:
		return index
	pot[layer].push_back(emptyNode)
	return pot[layer].size() - 1

static func addNode(layer, node) -> int:
	var potIndex = getNodeIndex(layer, node)
	if potIndex != -1:
		return potIndex
	var index = findFirstOpenSpot(layer)
	pot[layer][index] = node
	return index
