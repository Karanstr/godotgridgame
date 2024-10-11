extends Node2D

var tree:SparseDimensionalDAG
var pot = Nodes.pot

func _ready():
	tree = SparseDimensionalDAG.new(3)
	tree.setNodeChild(0b000, 1)
	tree.raiseRootOneLevel(1)
	tree.raiseRootOneLevel(0)
	tree.setNodeChild(0b01001, 1)
	tree.lowerRootOneLevel(0)
	tree.lowerRootOneLevel(1)
