extends Node2D

var tree:SparseDimensionalDAG

func _ready():
	tree = SparseDimensionalDAG.new(3)
	tree.addData(0b000)
	tree.addData(0b010)
	tree.addData(0b001)
	tree.addData(0b011)
	print(tree.readLeaf(0b011))
