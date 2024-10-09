extends Node2D

var tree:SparseDimensionalDAG
var pot = Nodes.pot

func _ready():
	tree = SparseDimensionalDAG.new(3)
	tree.setNodeChild(0b000, 1)
	tree.setNodeChild(0b001, 1)
	tree.setNodeChild(0b010, 1)
	tree.setNodeChild(0b011, 1)
	tree.setNodeChild(0b100, 1)
	tree.setNodeChild(0b101, 1)
	tree.setNodeChild(0b110, 1)
	tree.setNodeChild(0b111, 1)
	tree.setNodeChild(0b000, -1)
	tree.setNodeChild(0b001, -1)
	tree.setNodeChild(0b010, -1)
	tree.setNodeChild(0b011, -1)
	tree.setNodeChild(0b100, -1)
	tree.setNodeChild(0b101, -1)
	tree.setNodeChild(0b110, -1)
	tree.setNodeChild(0b111, -1)
	tree.setNodeChild(0b000, 1)
