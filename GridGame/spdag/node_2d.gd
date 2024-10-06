extends Node2D

var tree:SparseDimensionalDAG

func _ready():
	tree = SparseDimensionalDAG.new(3)
	#tree.addData(0b000)
	#tree.addData(0b001)
	#tree.addData(0b010)
	#tree.addData(0b011)
	tree.addData(0b100)
	tree.addData(0b101)
	tree.addData(0b110)
	tree.addData(0b111)
	
