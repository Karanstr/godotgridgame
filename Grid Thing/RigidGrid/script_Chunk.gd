extends Node2D

var grid:Grid; 
var thisblockTypes:BlockTypes;
@export var editable:bool = true;
var chunkCOM:Vector2;
var pointMasses:Array = []
var chunkMass:int = 0

var lastEditKey:int = -1;

func init(gridSize:Vector2, blockTypes:BlockTypes, gridDimensions:Vector2i = Vector2i(64,64)):
	thisblockTypes = blockTypes
	for block in blockTypes.array.size():
		pointMasses.push_back([])
	grid = Grid.create(gridSize, blockTypes.array.size(), gridDimensions)
	updateChunk([0], true)

func _process(_delta):
	if (editable):
		if Input.is_action_pressed("click"):
			var key:int = grid.pointToKey(get_local_mouse_position())[0]
			if key != -1 && key != lastEditKey:
				lastEditKey = key
				var oldVal:int = grid.read(key)
				var newVal:int = 1 if oldVal == 0 else 0;
				grid.assign(key, newVal)
				updateChunk([oldVal, newVal])
		if Input.is_action_just_released("click"):
			lastEditKey = -1

func updateChunk(changedVals:Array[int], firstCall:bool = false):
	if (!firstCall):
		for change in changedVals: #Remove Old Boxes
			_removeRenderBoxes(change)
			_removePhysicsBoxes(change)
	grid.reCacheRects(changedVals);
	if (!firstCall):
		_updateCOM(changedVals)
	for change in changedVals: #Add Current Boxes
		_addRenderBoxes(change)
		_addPhysicsBoxes(change)

#region Mass Management

func _updateCOM(changedVals:Array[int]):
	var centerOfMass = Vector2(0,0);
	var oldMass:int = chunkMass;
	chunkMass = 0;
	for blockType in changedVals:
		pointMasses[blockType] = _reduceToPointMasses(blockType);
		for point in pointMasses[blockType]:
			centerOfMass += Vector2(point.x * point.z, point.y * point.z)
			chunkMass += point.z
	centerOfMass /= Vector2(chunkMass, chunkMass)
	#broadCast [oldMass, chunkMass] to chunkManager to update total mass?

	var node = get_node("../")
	node.updateCOM(centerOfMass)
	return centerOfMass

func _reduceToPointMasses(blockType:int):
	var blockPointMasses:Array = [];
	for recti in grid.cachedRects[blockType]:
		var blockWeight = thisblockTypes.array[blockType].weight
		if (blockWeight != 0):
			blockPointMasses.push_back(_rectToPointMass(recti, blockWeight))
	return blockPointMasses

func _rectToPointMass(recti:Rect2i, weightPerBlock:int):
	var numOfBlocks:int = recti.size.x * recti.size.y
	var summedWeight:int = numOfBlocks * weightPerBlock
	var rect = _rectiToRect(recti)
	var center = rect.position + rect.size/2
	return Vector3(center.x, center.y, summedWeight)

#endregion

#region Render&Physics Management

func _addRenderBoxes(blockType):
	var image = thisblockTypes.array[blockType].texture;
	for rectNum in grid.cachedRects[blockType].size():
		var rect = grid.cachedRects[blockType][rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = _encodeName(rectNum, blockType)
		add_child(polygon)

func _removeRenderBoxes(blockType): 
	for rectNum in grid.cachedRects[blockType].size():
		get_node(_encodeName(rectNum, blockType)).free()

func _addPhysicsBoxes(blockType:int):
	if (thisblockTypes.array[blockType].collision == true):
		for rectNum in grid.cachedRects[blockType].size():
			var rect = grid.cachedRects[blockType][rectNum]
			var colBox:CollisionShape2D = _makeColBox(rect);
			colBox.name = _encodeName(rectNum, blockType)
			get_node("../../").add_child(colBox)

func _removePhysicsBoxes(blockType:int):
	if (thisblockTypes.array[blockType].collision == true):
		for rectNum in grid.cachedRects[blockType].size():
			get_node("../../" + _encodeName(rectNum, blockType)).free()

func _encodeName(number, blockType):
	#Chunk Name, followed by encoded name
	#Only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((number << grid.blocks.packSize) + blockType)

func _makeRenderPolygon(recti, texture):
	var rect = _rectiToRect(recti);
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

func _makeColBox(recti:Rect2i):
	var rect = _rectiToRect(recti);
	var colShape = CollisionShape2D.new();
	colShape.shape = RectangleShape2D.new();
	colShape.position = rect.position + rect.size/2;
	colShape.shape.size = rect.size;
	return colShape

func _rectiToRect(recti:Rect2i):
	var rect:Rect2 = Rect2(recti)
	rect.position *= grid.blockLength
	rect.size *= grid.blockLength
	return rect

#endregion

#
