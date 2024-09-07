extends Node2D

var blocks:BlockTypes;
@export var editable:bool = true;

var gridData:packedGrid;
var gridDims:Vector2i;
var blockDims:Vector2;
var chunkDims:Vector2;
var chunkCOM:Vector2;
var chunkMass:int = 0;

var pointMasses:Array = [];
var cachedRects:Array = [];

var lastEditKey:int = -1;

func init(chunkDimensions:Vector2, blockTypes:BlockTypes, gridDimensions:Vector2i = Vector2i(64,64)):
	blocks = blockTypes
	gridDims = gridDimensions
	chunkDims = chunkDimensions
	blockDims = chunkDims/Vector2(gridDims)
	gridData = packedGrid.new(gridDims, blocks.array.size())
	for block in blockTypes.array.size():
		pointMasses.push_back([])
		cachedRects.push_back([])
	cachedRects[0] = Util.greedyRect(gridData.binArrays[0])
	_addRenderBoxes(0)

func _process(_delta):
	if (editable):
		if Input.is_action_pressed("click"):
			var key:int = pointToKey(get_local_mouse_position())[0]
			if key != -1 && key != lastEditKey:
				lastEditKey = key
				var oldVal:int = gridData.read(key)[0]
				var newVal:int = 1 if oldVal == 0 else 0;
				gridData.modify(key, newVal)
				updateChunk([oldVal, newVal])
				var groups = Util.findGroups(gridData.mergeStrings(blocks.solidBlocks.keys()), gridDims)
				print(groups.size())
		elif Input.is_action_just_released("click"): lastEditKey = -1

func updateChunk(changedVals:Array[int]):
	for change in changedVals: #Remove Old Boxes
		_removeRenderBoxes(change)
		_removePhysicsBoxes(change)
	for change in changedVals: #Add Current Boxes
		cachedRects[change] = Util.greedyRect(gridData.binArrays[change])
		_addRenderBoxes(change)
		_addPhysicsBoxes(change)
	_updateCOM(changedVals)

#region Stuff Unsorted

func pointToKey(point:Vector2) -> Array[int]:
	var offset:Vector2 = Vector2(.01,.01)
	var keys:Array[int] = [];
	for x in range(0, 2):
		for y in range(0, 2):
			var woint:Vector2 = offset - 2*offset*Vector2(x,y) + point
			if woint.x > 0 && woint.x < chunkDims.x && woint.y > 0 && woint.y < chunkDims.y:
				keys.append(Util.encode(woint/blockDims, gridDims.x))
			else:
				keys.append(-1)
	return keys

#endregion

#region Mass Management

func _updateCOM(changedVals:Array[int]):
	var centerOfMass = Vector2(0,0);
	var _oldMass:int = chunkMass;
	chunkMass = 0;
	for blockType in changedVals:
		pointMasses[blockType] = _reduceToPointMasses(blockType);
		for point in pointMasses[blockType]:
			centerOfMass += Vector2(point.x * point.z, point.y * point.z)
			chunkMass += point.z
	centerOfMass /= Vector2(chunkMass, chunkMass)
	#broadCast [oldMass, chunkMass] to chunkManager to update total mass?

	var node = get_node("../")
	node.updateRigidGrid(centerOfMass, chunkMass)
	return centerOfMass

func _reduceToPointMasses(blockType:int):
	var blockPointMasses:Array = [];
	for recti in cachedRects[blockType]:
		var blockWeight = blocks.array[blockType].weight
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
	var image = blocks.array[blockType].texture;
	for rectNum in cachedRects[blockType].size():
		var rect = cachedRects[blockType][rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = _encodeName(rectNum, blockType)
		add_child(polygon)

func _removeRenderBoxes(blockType): 
	for rectNum in cachedRects[blockType].size():
		get_node(_encodeName(rectNum, blockType)).free()

func _addPhysicsBoxes(blockType:int):
	if (blocks.array[blockType].collision == true):
		for rectNum in cachedRects[blockType].size():
			var rect = cachedRects[blockType][rectNum]
			var colBox:CollisionShape2D = _makeColBox(rect);
			colBox.name = _encodeName(rectNum, blockType)
			get_node("../../").add_child(colBox)

func _removePhysicsBoxes(blockType:int):
	if (blocks.array[blockType].collision == true):
		for rectNum in cachedRects[blockType].size():
			get_node("../../" + _encodeName(rectNum, blockType)).free()

func _encodeName(number, blockType):
	#Chunk Name, followed by encoded name
	#Only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((number << gridData.packedData.packSize) + blockType)

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
	polygon.texture_scale = texture.get_size()/blockDims
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
	rect.position *= blockDims
	rect.size *= blockDims
	return rect

#endregion

#
