class_name SparseDimensionalDAG

class Nodes:
	var pot:Array = [
			{0 : Branch.new()} , #One above leaf nodes
	]
	
	func findFirstOpenSpot(layer):
		for i in pot[layer].size():
			if not pot[layer].has(i):
				return i
		return pot[layer].size()
	
	#Disgusting
	func get_or_add(layer, node):
		var options = pot[layer]
		for curKey in options.keys():
			var option = options[curKey]
			if option.children == node.children:
				return curKey
		var index = findFirstOpenSpot(layer)
		pot[layer][index] = node
		return index

class Branch:
	var kidMask:int
	var children:Array[int] #Use u16s
	func _init(mask:int = 0b0000, kids:Array[int] = [0,0,0,0]):
		kidMask = mask
		children = kids

var layersFromRootToLeaf = 1
var nodes:Nodes = Nodes.new()
var root:Branch = nodes.pot[0][0]

#Address should be read right to left, leaf to root

func readLeaf(address:int):
	var curNode = root
	for i in layersFromRootToLeaf - 1: #Descend until we're in a level one node (or find an empty section)
		var curLayer = layersFromRootToLeaf - i
		var kidAddress = (address >> (curLayer * 2)) & 0b11
		if (curNode.kidMask >> kidAddress) & 1 == 0:
			return 0
		curNode = nodes.pot[curLayer - 1][curNode.children[kidAddress]]
	return curNode.children[address & 0b11]

func insertNodeToGraph(layersFromLeaf:int, travAddress:int, nodeIndex:int):
	var curNode = root
	for i in layersFromRootToLeaf - layersFromLeaf:
		var curLayer = layersFromRootToLeaf - i
		var kidAddress = (travAddress >> (2 * curLayer)) & 0b11
		if (curNode.kidMask >> kidAddress) & 1 == 0: 
			printerr("Write cannot access address " + String.num_int64(travAddress))
			return -1
		curNode = nodes.pot[curLayer - 1][curNode.children[kidAddress]]
	curNode.children[travAddress & 0b11] = nodeIndex
	curNode.kidMask |= (1 << (travAddress & 0b11))

#Disgusting
#func insertData(leavesToBeAdded:Array[int], _leavesToRemove:Array[int]):
	#leavesToBeAdded.sort()
	#var curIndex = 0
	#while curIndex != leavesToBeAdded.size():
		#var indiThisSweep = 1
		#var kids:Array[int] = []
		#var curCase = leavesToBeAdded[curIndex] >> 2
		#var curKid = leavesToBeAdded[curIndex] & 0b11
		#var kidMask = 1 << curKid
		#for i in min(4 - (curKid + 1), leavesToBeAdded.size() - 1 - curIndex): #Prevent array overflow
			#var case = leavesToBeAdded[curIndex + 1 + i] >> 2
			#if case == curCase:
				#indiThisSweep += 1
				#kidMask |= 1 << (case & 0b11)
func insertData(leavesAdded:Array[int]):
	leavesAdded.sort() #Make sure leaves can be updated
	#After we have a list of all updated pathways and their number of updates
	#Use this list to run the algorithm in the comments above, accounting for cells already within the graph
	var branchesUpdated:Dictionary =  {} 
	for invlayer in layersFromRootToLeaf:
		var curLayer = layersFromRootToLeaf - invlayer
		var curMask = 0b11 << ((curLayer - 1) * 2)
		for leaf in leavesAdded: 
			var key = leaf & curMask
			branchesUpdated.get_or_add(key, 0)
			branchesUpdated[key] += 1 #Count number of blocks being added to each branch

func expandTree(_filledQuadrant:int):
	#Make root a child of a larger root with three empty segments
	#Incrememnt layersFromRootToLeaf
	pass
