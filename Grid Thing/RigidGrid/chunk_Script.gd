extends Node2D

var grid:Grid; 
var blockTypes; #Make blockType class and store types in there 
# ^^^^ Maybe move inside of Grid?
var uniqueBlockData; #NBT Data, Store things like rotation, power level, etc..
# ^^^^ Maybe move inside of Grid?

func init(gridSize:Vector2, uniqueBlocks:int, gridDimensions:Vector2i = Vector2i(64,64)):
	grid = Grid.create(gridSize, uniqueBlocks, gridDimensions)
	grid.reCacheMeshes([0]); #Initial meshing for initial value
	#_addPhysicsMeshes() #Initial value probably doesn't have physics mesh?
	_addRenderMeshes(0)
	pass

func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var keys:Array[int] = grid.pointToKey(get_local_mouse_position())
		var key:int = keys[0]
		if key != -1:
			var oldVal:int = grid.read(key)
			var newVal:int = 1 if oldVal == 0 else 0;
			grid.assign(key, newVal)
			_updateMeshes([oldVal, newVal])

func _updateMeshes(changedVals:Array[int]):
	for change in changedVals:
		_removeRenderMeshes(change)
		_removePhysicsMeshes(change)
	grid.reCacheMeshes(changedVals);
	for change in changedVals:
		_addRenderMeshes(change)
		_addPhysicsMeshes(change)

func _addRenderMeshes(blockType):
	var color;
	match blockType: #Eventually reference block datas
		0:
			color = "blue"
		1:
			color = "yellow"
	for meshNum in grid.cachedMeshes[blockType].size():
		var mesh = grid.cachedMeshes[blockType][meshNum]
		var polygon = _makeRenderPolygon(mesh, color)
		polygon.name = encodeMeshName(meshNum, blockType)
		add_child(polygon)

func _removeRenderMeshes(blockType): 
	for meshNum in grid.cachedMeshes[blockType].size():
		get_node(encodeMeshName(meshNum, blockType)).free()

func _addPhysicsMeshes(blockType:int):
	if (blockType != 0): #If blockType has a collision mesh, reference block datas?
		for meshNum in grid.cachedMeshes[blockType].size():
			var mesh = grid.cachedMeshes[blockType][meshNum]
			var colBox:CollisionShape2D = _makeColBox(mesh);
			colBox.name = encodeMeshName(meshNum, blockType)
			get_node("../../").add_child(colBox)

func _removePhysicsMeshes(blockType:int):
	if (blockType != 0): #If blockType has a collision mesh, reference block datas?
		for meshNum in grid.cachedMeshes[blockType].size():
			get_node("../../" + encodeMeshName(meshNum, blockType)).free()

func encodeMeshName(meshNum, blockType):
	#Chunk Name, followed by encoded mesh name
	#Chunk Name only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((meshNum << grid.blocks.packSize) + blockType)

func _makeRenderPolygon(mesh, color):
	var rect = _meshToLocalRect(mesh);
	var polygon = Polygon2D.new();
	var data:PackedVector2Array = PackedVector2Array();
	data.push_back(rect.position);
	data.push_back(Vector2(rect.position.x, rect.position.y + rect.size.y));
	data.push_back(rect.position + rect.size);
	data.push_back(Vector2(rect.position.x + rect.size.x, rect.position.y));
	polygon.color = color;
	polygon.polygon = data;
	return polygon

func _makeColBox(mesh:Rect2i):
	var rectMesh = _meshToLocalRect(mesh);
	var colShape = CollisionShape2D.new();
	colShape.shape = RectangleShape2D.new();
	colShape.position = rectMesh.position + rectMesh.size/2;
	colShape.shape.size = rectMesh.size;
	return colShape

func _meshToLocalRect(mesh:Rect2i):
	var alignedRect:Rect2 = Rect2(mesh)
	alignedRect.position *= grid.blockLength
	alignedRect.size *= grid.blockLength
	return alignedRect
