#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class_name Nodes

static var n = 1
static var pot:Array = []
#REMEMBER EMPTYNODE DOESNT GET CLONED, ALL EMPTY NODES POINT TO EMPTYNODE
#DO NOT MODIFY THE INITIAL VALUES OF EMPTYNODE!!!
static var emptyNode = Branch.new()

class Branch:
	var children:Array[int]
	var refCount:int = 0
	
	func _init(kids:Array[int] = []):
		if kids.size() == 0:
			kids.resize(2**Nodes.n)
			kids.fill(0)
		children = kids.duplicate()
	
	func duplicate():
		var newBranch = Branch.new(children)
		return newBranch

	func isEmpty():
		return children == Nodes.emptyNode.children

#region Read Node Data

static func readKid(layer, index, childDirection):
	return pot[layer][index].children[childDirection]

static func getChildrenIndexes(layer, index):
	return pot[layer][index].children

#endregion

#region Can Modify Nodes

static func modifyReference(layer, index, deltaRef):
	var node = pot[layer][index]
	if node.isEmpty():
		pot[layer][index] = emptyNode
		node.refCount = 0
	else:
		node.refCount += deltaRef
		if node.refCount < 1:
			if layer != 0:
				for child in node.children:
					if child != 0: #If was pointing somewhere
						modifyReference(layer - 1, child, -1) 
			pot[layer][index] = emptyNode #Node is hanging, delete it

#endregion

#region Populate Graph

static func ensureDepth(rootLayer:int = 0):
	for i in 1 + rootLayer - (pot.size()):
		pot.push_back([emptyNode]) #Index 0 is reserved for empty

static func getNodeDup(layer, index):
	return pot[layer][index].duplicate()

static func getNodeIndex(layer, node) -> int:
	for index in pot[layer].size() - 1:
		var searchableIndex = index + 1
		if pot[layer][searchableIndex].children == node.children:
			return searchableIndex
	return 0

static func findFirstOpenSpot(layer):
	var index = getNodeIndex(layer, emptyNode)
	if index != 0:
		return index
	pot[layer].push_back(emptyNode)
	return pot[layer].size() - 1

static func addNode(layer, node) -> int:
	var potIndex = getNodeIndex(layer, node)
	if potIndex != 0: #Node already exists
		return potIndex
	if layer != 0: #If the node has node children
		for child in node.children:
			if child != 0: #We are now pointing to this child from the new node
				modifyReference(layer - 1, child, 1) 
	var index = findFirstOpenSpot(layer)
	pot[layer][index] = node
	return index

static func addAlteredNode(layer:int, index:int, childDirection:int, newChildIndex:int):
	var curNode = getNodeDup(layer, index)
	curNode.children[childDirection] = newChildIndex
	if not curNode.isEmpty():
		return addNode(layer, curNode)
	return 0

#endregion
