#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class_name Nodes

static var pot:Array = []
#REMEMBER WE DON'T CLONE EMPTYNODE. WHEN WE DELETE A NODE WE POINT RIGHT TO EMPTYNODE
#DO NOT MODIFY THE INITIAL VALUES OF EMPTYNODE!!!
#THIS WILL CAUSE PROBLEMS
static var emptyNode = Branch.new()

class Branch:
	var children:Array[int]
	var refCount:int = 0
	
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

#region Can Modify Nodes

static func modifyReference(layer, index, deltaRef):
	if index == -1:
		emptyNode.Error()
	var node = pot[layer][index]
	if node.isEmpty():
		pot[layer][index] = emptyNode
		node.refCount = 0
	else:
		node.refCount += deltaRef
		if node.refCount < 1:
			if layer != 0:
				for child in node.children:
					if child != -1: #If was pointing somewhere
						modifyReference(layer - 1, child, -1) 
			pot[layer][index] = emptyNode #Node is hanging, delete it

#endregion

static func addAlteredNode(layer:int, index:int, childDirection:int, newChildIndex:int):
	var curNode = getNodeDup(layer, index)
	curNode.children[childDirection] = newChildIndex
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
	if layer != 0:
		for child in node.children:
			if child != -1: #We are now pointing to this child from the new node
				modifyReference(layer - 1, child, 1) 
	var index = findFirstOpenSpot(layer)
	pot[layer][index] = node
	return index
