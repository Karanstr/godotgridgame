extends Node2D

var grid:Grid; 
var blockTypes; #Make blockType class and store types in there 
var uniqueBlockData; #Store things like rotation, power level, etc..
# ^^^^ Maybe move inside of Grid?


func init(gridSize:Vector2, uniqueBlocks:int):
	grid = Grid.create(gridSize, uniqueBlocks)
	grid.reCacheMeshes([0]);
	#_addPhysicsMeshes()
	_addRenderMeshes(0)
	pass

func _addPhysicsMeshes(blockType):
	pass

func _addRenderMeshes(blockType):
	pass
