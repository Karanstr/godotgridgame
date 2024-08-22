extends Node2D

var grid:Grid; 
var blockTypes; #Make blockType class and store types in there 
# ^^^^ Maybe move inside of Grid?
var uniqueBlockData; #NBT Data, Store things like rotation, power level, etc..
# ^^^^ Maybe move inside of Grid?

func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointToKey(get_local_mouse_position())
		var key:int = keys[0]
		if key != -1:
			var oldVal:int = grid.read(key)
			var newVal:int = 1 if oldVal == 0 else 0;
			grid.assign(key, newVal)
			_updateMeshes([oldVal, newVal])
			queue_redraw()

func _updateMeshes(changedVals:Array[int]):
	for change in changedVals:
		if (change != 0):
			_removePhysicsMeshes(change)
	grid.reCacheMeshes(changedVals);
	for change in changedVals:
		if (change != 0):
			_addPhysicsMeshes(change)

func _addPhysicsMeshes(blockType:int):
	for meshNum in grid.cachedMeshes[blockType].size():
		var mesh = grid.cachedMeshes[blockType][meshNum]
		var colBox:CollisionShape2D = _makeColBox(alignMesh(mesh));
		colBox.name = encodeMeshName(meshNum, blockType)
		get_node("../../").add_child(colBox)

func _removePhysicsMeshes(blockType:int):
	for meshNum in grid.cachedMeshes[blockType].size():
		get_node("../../" + encodeMeshName(meshNum, blockType)).free()

func encodeMeshName(meshNum, blockType):
	return name + " " + String.num_int64((meshNum << grid.blocks.packSize) + blockType)

func _makeColBox(rectMesh:Rect2):
	var colShape = CollisionShape2D.new();
	colShape.shape = RectangleShape2D.new();
	colShape.position = rectMesh.position + rectMesh.size/2;
	colShape.shape.size = rectMesh.size;
	return colShape

func init(gridSize:Vector2, uniqueBlocks:int, gridDimensions:Vector2i = Vector2i(64,64)):
	grid = Grid.create(gridSize, uniqueBlocks, gridDimensions)
	grid.reCacheMeshes([0]); #Initial meshing for initial value
	#_addPhysicsMeshes() #Initial value probably doesn't have physics mesh?
	_addRenderMeshes(0)
	pass

func _addRenderMeshes(blockType):
	pass

#Get rid of _draw calls and instead use polygons 2d
#This will prevent the entire chunk from being recached whenever one blocktype
#Needs recaching
func _draw():
	for blockMeshes in grid.cachedMeshes.size():
		if (blockMeshes != 0):
			var color:Color;
			match blockMeshes:
				1: color = "Yellow"
			for rect in grid.cachedMeshes[blockMeshes].size():
				var alignedRect:Rect2 = alignMesh(grid.cachedMeshes[blockMeshes][rect])
				draw_rect(alignedRect, color)
				draw_rect(alignedRect, "black", false, grid.blockLength.x/10)
	#draw_rect(Rect2(Vector2(0,0), grid.length/50), 'blue', true) #Display COM
	print("Draw complete")

func alignMesh(mesh:Rect2i):
	var alignedRect:Rect2 = Rect2(mesh)
	alignedRect.position *= grid.blockLength
	alignedRect.size *= grid.blockLength
	return alignedRect
