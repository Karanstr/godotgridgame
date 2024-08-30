extends Node2D

var grid:Grid; 
var thisblockTypes:BlockTypes;
@export var editable:bool = true;

var lastEditKey:int;

func init(gridSize:Vector2, blockTypes:BlockTypes, gridDimensions:Vector2i = Vector2i(64,64)):
	thisblockTypes = blockTypes
	grid = Grid.create(gridSize, blockTypes, gridDimensions)
	grid.reCacheMeshes([0]); #Initial meshing for initial value
	#_addPhysicsMeshes() #Initial value probably doesn't have physics mesh?
	_addRenderMeshes(0)
	pass

func _process(_delta):
	if (editable):
		if Input.is_action_pressed("click"):
			var keys:Array[int] = grid.pointToKey(get_local_mouse_position())
			var key:int = keys[0]
			if key != -1 && key != lastEditKey:
				lastEditKey = key
				var oldVal:int = grid.read(key)
				var newVal:int = 1 if oldVal == 0 else 0;
				grid.assign(key, newVal)
				_updateMeshes([oldVal, newVal])
		if Input.is_action_just_released("click"):
			lastEditKey = -1

#region Meshing

func _updateMeshes(changedVals:Array[int]):
	for change in changedVals:
		_removeRenderMeshes(change)
		_removePhysicsMeshes(change)
	grid.reCacheMeshes(changedVals);
	for change in changedVals:
		_addRenderMeshes(change)
		_addPhysicsMeshes(change)

func _addRenderMeshes(blockType):
	var meshImage = thisblockTypes.array[blockType].texture;
	for meshNum in grid.cachedMeshes[blockType].size():
		var mesh = grid.cachedMeshes[blockType][meshNum]
		var polygon = _makeRenderPolygon(mesh, meshImage)
		polygon.name = encodeMeshName(meshNum, blockType)
		add_child(polygon)

func _removeRenderMeshes(blockType): 
	for meshNum in grid.cachedMeshes[blockType].size():
		get_node(encodeMeshName(meshNum, blockType)).free()

func _addPhysicsMeshes(blockType:int):
	if (thisblockTypes.array[blockType].collision == true):
		for meshNum in grid.cachedMeshes[blockType].size():
			var mesh = grid.cachedMeshes[blockType][meshNum]
			var colBox:CollisionShape2D = _makeColBox(mesh);
			colBox.name = encodeMeshName(meshNum, blockType)
			get_node("../../").add_child(colBox)

func _removePhysicsMeshes(blockType:int):
	if (thisblockTypes.array[blockType].collision == true):
		for meshNum in grid.cachedMeshes[blockType].size():
			get_node("../../" + encodeMeshName(meshNum, blockType)).free()

func encodeMeshName(meshNum, blockType):
	#Chunk Name, followed by encoded mesh name
	#Chunk Name only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((meshNum << grid.blocks.packSize) + blockType)

func _makeRenderPolygon(points, texture):
	var rect = _meshToLocalRect(points);
	var data:PackedVector2Array = PackedVector2Array();
	data.push_back(rect.position);
	data.push_back(Vector2(rect.position.x, rect.position.y + rect.size.y));
	data.push_back(rect.position + rect.size);
	data.push_back(Vector2(rect.position.x + rect.size.x, rect.position.y));
	
	var polygon = Polygon2D.new();
	polygon.texture = texture
	polygon.texture_scale = Vector2(1,1)/(grid.blockLength/texture.get_size())
	polygon.texture_filter = 1
	polygon.texture_repeat = 2
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
#endregion

#
