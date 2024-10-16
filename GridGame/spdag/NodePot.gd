#For now we're going to use arrays and o(n) it instead of hashing/lookups.
class_name FixedDimensionDAG

var n:int
var pot:Array = []

func _init(dimensions):
	n = dimensions

class Branch:
	var children:Array[int]
	var refCount:int = 0
	
	func _init(n, kids:Array[int] = []):
		if kids.size() == 0:
			kids.resize(1 << n) #Number of children scale by powers of 2
			kids.fill(0)
		children = kids.duplicate()
	
	func duplicate():
		#var newBranch = Branch.new(children)
		#return newBranch
		return Branch.new("Ignore This", children)
	
	func isSame(node):
		return children == node.children

#We reserve 0 for the empty node so we can use 0 as the sparse index
#func isEmpty(node):
	#return node.children == pot[0][0].children

class NodeAddress:
	var layer:int = 0;
	var index:int = 0;
	
	func _init(nodeLayer, nodeIndex):
		layer = nodeLayer
		index = nodeIndex

#region Read

#Idk if we give duplicate a default value
func getNode(node:NodeAddress, duplicate:bool) -> Branch:
	if duplicate:
		return pot[node.layer][node.index].duplicate()
	return pot[node.layer][node.index]

func readKid(node:NodeAddress, childDirection) -> int:
	return getNode(node, false).children[childDirection]

#This is just readkid but with a path input. Not a fan
func readLeaf(root:NodeAddress, path:int) -> int:
	var leafAddr = getPathToLayer(root, path, 0)[0] #Path from leaf to root
	return readKid(NodeAddress.new(0, leafAddr), path & 0b1)

#Make getNodeChildrenAddresses which returns an array, then when on layer 0 we can iterate over 0 elements?
func getNodeChildren(node:NodeAddress) -> Array[int]:
	return getNode(node, false).children

func findNodeIndex(layer, node) -> int:
	var firstNode = pot[layer].size() 
	for index in firstNode:
		var realIndex = firstNode - index - 1 #Iterate from last to first
		if node.isSame(pot[layer][realIndex]):
			return realIndex
	return 0 #If node doesn't exist/is the empty node

func findOpenEmptyNode(layer) -> int:
	var emptyNode = Branch.new(n)
	var index = findNodeIndex(layer, emptyNode)
	if index != 0:
		return index
	pot[layer].push_back(emptyNode)
	return pot[layer].size() - 1

#endregion

#region Binary Conversions

#I hate recursion | Also only works with depths of up to log2(64/n) rn bc I'm not implementing packedArrays yet
func DFSGraphToBin(node:NodeAddress) -> int:
	if node.index == 0:
		return 0
	var childBinSize = 2 ** node.layer #Number of children per node ** curLayer
	var binRep:int = 0b0
	var children:Array[int] = getNodeChildren(node)
	for child in children.size():
		if node.layer != 0:
			binRep |= DFSGraphToBin(NodeAddress.new(node.layer - 1, children[child])) << (childBinSize * child)
		elif children[child] != 0:
			binRep |= 1 << (childBinSize * child)
	return binRep

func BinToGraph():
	pass

#endregion

#region Write

#Hate recursion
func modifyReference(node:NodeAddress, deltaRef:int):
	var emptyNode = Branch.new(n)
	var curNode = getNode(node, false)
	if curNode.isSame(emptyNode):
		pot[node.layer][node.index] = emptyNode
	else:
		curNode.refCount += deltaRef
		if curNode.refCount < 1:
			if node.layer != 0:
				for child in curNode.children:
					if child != 0: #If was pointing somewhere
						modifyReference(NodeAddress.new(node.layer - 1, child), -1)
			pot[node.layer][node.index] = emptyNode #Node is hanging, delete it

func swapReference(oldNode:NodeAddress, newNode:NodeAddress):
	if newNode.layer < 0:
		print("Can't lower root into leaf")
		return
	modifyReference(newNode, 1)
	modifyReference(oldNode, -1)

func addNode(layer, node) -> int:
	var potIndex = findNodeIndex(layer, node)
	if potIndex != 0: #Node already exists
		return potIndex
	if layer != 0: #If the node has node children
		for child in node.children:
			if child != 0: #We are now pointing to this child from the new node
				modifyReference(NodeAddress.new(layer - 1, child), 1) 
	var index = findOpenEmptyNode(layer)
	pot[layer][index] = node
	return index

func addAlteredNode(referenceNode:NodeAddress, childDirection:int, newChildIndex:int) -> int:
	var newNode = getNode(referenceNode, true)
	newNode.children[childDirection] = newChildIndex
	if not newNode.isSame(Branch.new(n)):
		return addNode(referenceNode.layer, newNode)
	return 0

#Maybe just modify root?
func modifyRootLayerBy1(root:NodeAddress, relevantChildDirection:int, layerModifier:int) -> NodeAddress:
	var newLayer:int = root.layer + layerModifier
	var newIndex:int
	if layerModifier < 0:
		if newLayer < 0: root.throwError()
		newIndex = readKid(root, relevantChildDirection)
	elif layerModifier > 0:
		ensureDepth(newLayer)
		newIndex = addAlteredNode(NodeAddress.new(newLayer, 0), relevantChildDirection, root.index)
	var newRoot = NodeAddress.new(newLayer, newIndex)
	swapReference(root, newRoot)
	return newRoot

#endregion

#region Meta-Write

func ensureDepth(rootLayer:int = 0):
	for i in 1 + rootLayer - (pot.size()):
		pot.push_back([Branch.new(n)]) #Index 0 is reserved for empty

#endregion

#Make path it's only class, with functions to get each part? This seems like a good way to unlock it's dimension easily and increase functionality?
#Also not a huge fan of the region name, work on itgit 

#region Tree-Level Read/Writes

#Rethink this one, I don't like how it calls readKid. Maybe make it make an array of NodeAddresses? (Could be helpful with variable leaf layering
func getPathToLayer(root:NodeAddress, path:int, targetLayer:int = 0) -> Array[int]:
	var layersToStore = 1 + root.layer - targetLayer
	var trail:Array[int] = []
	trail.resize(layersToStore)
	trail.fill(0)
	trail[layersToStore - 1] = root.index
	for i in layersToStore - 1:
		var layer = root.layer - i
		var kidDirection = (path >> layer) & 0b1
		trail[layer - 1] = readKid(NodeAddress.new(layer, trail[layer]), kidDirection)
		if trail[layer - 1] == 0: #The path ends
			break
	return trail

func setNodeChild(root:NodeAddress, path:int, childIndex:int, targetLayer:int = 0) -> NodeAddress:
	var steps:Array = getPathToLayer(root, path, targetLayer)
	for step in steps.size():
		var curLayer = targetLayer + step
		childIndex = addAlteredNode(NodeAddress.new(curLayer, steps[step]), (path >> step) & 0b1, childIndex)
	#Gotta handle this part manually, WE are pointing to the root node instead of it's parent
	var newRoot:NodeAddress = NodeAddress.new(root.layer, childIndex)
	swapReference(root, newRoot)
	return newRoot

#endregion

func AAA(): pass #Used so setNodeChild doesn't absorb the below commented region when minimized :\

#region Need to be reimplemented

#These are, for the moment, silly functions. Idk where I'm going to put them in the grand scheme yet
#func growToContain(root:RootAddress, cell) -> int:
	#var cellCount = 2 ** (root.layer + 1)
	#var side = 0 if cell.x > 0 else 1
	#var totalBlocksShifted:Vector2i = Vector2i(0, 0)
	#while cell.x < 0 || cell.x >= maxCell: #Cell isn't within bounds
		#var numOfBlocksShifted = maxCell / 2
		#modifyRootLayerBy1(root, side, +1)
		#maxCell = 2 ** (rootAddress[0] + 1)
		##cell.x += numOfBlocksShifted * 2 * side
		#totalBlocksShifted.x -= 2 * numOfBlocksShifted * side
	#return totalBlocksShifted
#
#func shrinkToFit() -> int:
	#var foundNum = 1
	#var found:int
	#var blocksShifted = 0
	#while foundNum == 1:
		#if rootAddress[0] == 0:
			#break
		#var children = Nodes.getChildrenIndexes(rootAddress[0], rootAddress[1])
		#foundNum = 0
		#for child in children.size():
			#if children[child] != 0:
				#foundNum += 1
				#found = child
		#if foundNum == 1:
			#blocksShifted += (2 ** rootAddress[0]) * found #Cheap hack, doesn't generalize
			#lowerRootOneLevel(found)
	#return blocksShifted
#
#func compactRoot():
	#var blocksShifted = 0
	#while rootAddress[0] != 0:
		#var newRoot = Nodes.emptyNode.duplicate()
		#var dLookup = [1, 0]
		#var rootKids = Nodes.getChildrenIndexes(rootAddress[0], rootAddress[1])
		#for rootKid in rootKids.size():
			#if rootKids[rootKid] == 0:
				#pass
			#else:
				#var kid0Kids = Nodes.getChildrenIndexes(rootAddress[0] - 1, rootKids[rootKid])
				#var kidCount = 0
				#for kid in kid0Kids.size():
					#if kid0Kids[kid] != 0:
						#kidCount += 1
					#if kidCount > 1:
						#return blocksShifted
				#if kid0Kids[dLookup[rootKid]] == 0:
					#return blocksShifted
				#else:
					#newRoot.children[rootKid] = kid0Kids[dLookup[rootKid]]
		#var newRootIndex = Nodes.addNode(rootAddress[0] - 1, newRoot)
		#Nodes.modifyReference(rootAddress[0] - 1, newRootIndex, 1)
		#Nodes.modifyReference(rootAddress[0], rootAddress[1], -1)
		#rootAddress = Vector2i(rootAddress[0] - 1, newRootIndex)
		#blocksShifted += 2 ** rootAddress[0]
	#return blocksShifted

#endregion
