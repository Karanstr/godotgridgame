extends Node2D

var grid:Grid; 
var thisblockTypes:BlockTypes;
@export var editable:bool = true;
var chunkCOM:Vector2;

var lastEditKey:int;

func init(gridSize:Vector2, blockTypes:BlockTypes, gridDimensions:Vector2i = Vector2i(64,64)):
	thisblockTypes = blockTypes
	grid = Grid.create(gridSize, blockTypes.array.size(), gridDimensions)
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
				updateChunk([oldVal, newVal])
		if Input.is_action_just_released("click"):
			lastEditKey = -1

func updateChunk(changedVals:Array[int]):
	_updateMeshes(changedVals)
	_updateCOM(changedVals)
	pass

#region Mass Juggling

#Only based on changed vals rn, implement all vals
func _updateCOM(changedVals:Array[int]):
	var pointMasses = reduceToPointMasses(changedVals)
	var centerOfMass = Vector2(0,0);
	var totalMass = 0
	for point in pointMasses:
		centerOfMass += Vector2(point.x, point.y) * Vector2(point.z, point.z)
		totalMass += point.z
	centerOfMass /= Vector2(totalMass, totalMass)
	return centerOfMass


func reduceToPointMasses(changedVals:Array[int]):
	var reducedPointMasses:Array = [];
	for blockType in changedVals:
		for mesh in grid.cachedMeshes[blockType]:
			var blockWeight = thisblockTypes.array[blockType].weight
			if (blockWeight != 0):
				reducedPointMasses.push_back(meshToPointMass(mesh, blockWeight))
	return reducedPointMasses

func meshToPointMass(mesh, weightPerBlock):
	var numOfBlocks:int = mesh.size.x * mesh.size.y
	var summedWeight:int = numOfBlocks * weightPerBlock
	var meshInWorld = _meshToLocalRect(mesh)
	var center = meshInWorld.position + meshInWorld.size/2
	return Vector3(center.x, center.y, summedWeight)


#endregion

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
	polygon.polygon = data;
	polygon.texture = texture;
	polygon.texture_scale = texture.get_size()/grid.blockLength
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
