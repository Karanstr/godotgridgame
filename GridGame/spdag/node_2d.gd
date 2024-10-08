extends Node2D

var tree:SparseDimensionalDAG

func _ready():
	tree = SparseDimensionalDAG.new(3)
	tree.fillLeaf(0b000)
	tree.fillLeaf(0b001)
	tree.fillLeaf(0b010)
	tree.fillLeaf(0b011)
	tree.fillLeaf(0b100)
	tree.fillLeaf(0b101)
	tree.fillLeaf(0b110)
	tree.fillLeaf(0b111)
	tree.removeLeaf(0b000)
	tree.removeLeaf(0b001)
	tree.removeLeaf(0b010) #This causes the floating reference :(
	tree.removeLeaf(0b011)
	tree.removeLeaf(0b100)
	tree.removeLeaf(0b101)
	tree.removeLeaf(0b110)
	tree.removeLeaf(0b111)
