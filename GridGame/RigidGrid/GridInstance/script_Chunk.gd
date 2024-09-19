extends Node2D

@export var editable:bool = true

var grid:packedGrid
var gridDims:Vector2i
var blockDims:Vector2
var chunkCOM:Vector2
var chunkMass:int = 0

var cachedRects:Dictionary = {}
var pointMasses:Dictionary = {}

var lastEditKey:Vector2i = Vector2i(-1, -1)
var editValue:int = 1

func initialize(blockDimensions:Vector2, gridDimensions:Vector2i = Vector2i(64,64)):
	gridDims = gridDimensions
	blockDims = blockDimensions
	grid = packedGrid.new(gridDims.y, gridDims.x)

func _input(event):
	if event is InputEventKey && event.pressed:
		match event.keycode:
			KEY_0: editValue = 0
			KEY_1: editValue = 1
			KEY_2: editValue = 2

func _process(_delta):
	if (editable):
		if Input.is_action_pressed("click"):
			var cell:Vector2i = pointToCell(get_local_mouse_position())
			if (cell != lastEditKey && cell != Vector2i(-1, -1)):
				lastEditKey = cell
				var oldVal:int = grid.accessCell(cell)
				grid.accessCell(cell, editValue)
				grid.zeroRow(3)
				updateChunk({editValue: null, oldVal:null})
				var _groups:Array = grid.identifySubGroups()
				modifyRow(1, grid.Row.new([546], 15, 3), true)
		elif Input.is_action_just_released("click"): lastEditKey = Vector2i(-1, -1)

#row of type grid.Row
func modifyRow(rowNum:int, row, nullAs0:bool = false):
	grid.modifyRow(rowNum, row, nullAs0)
	updateChunk(BlockTypes.blocks)

#We do not update 0. 0 isn't real.
func updateChunk(changedVals:Dictionary):
	changedVals.erase(0)
	for change in changedVals:
		_removeRenderBoxes(change)
		_removePhysicsBoxes(change)
		cachedRects.erase(change)
		pointMasses.erase(change)
		if grid.binGrids.has(change):
			cachedRects[change] = BinUtil.greedyRect(grid.binGrids[change])
			_addRenderBoxes(change)
			_addPhysicsBoxes(change)
	_updateCOM(changedVals)

func pointToCell(point:Vector2) -> Vector2i:
	var cell:Vector2i = point/blockDims
	if (point.x < 0 || cell.x >= gridDims.x || point.y < 0 || cell.y >= gridDims.y):
		return Vector2i(-1, -1)
	return cell

#region Mass Management

func _updateCOM(changedVals:Dictionary):
	var centerOfMass = Vector2(0,0);
	chunkMass = 0;
	for blockType in cachedRects.keys():
		if (changedVals.has(blockType)): pointMasses[blockType] = _reduceToPointMasses(blockType);
		for point in pointMasses[blockType]:
			centerOfMass += Vector2(point.x * point.z, point.y * point.z)
			chunkMass += point.z
	centerOfMass /= Vector2(chunkMass, chunkMass)
	get_node("../").updateMass(chunkMass, centerOfMass)
	return centerOfMass

func _reduceToPointMasses(blockType:int):
	var blockPointMasses:Array = [];
	for recti in cachedRects[blockType]:
		var blockWeight = BlockTypes.blocks[blockType].weight
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
	var image = BlockTypes.blocks[blockType].texture;
	for rectNum in cachedRects.get(blockType, []).size():
		var rect = cachedRects[blockType][rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = _encodeName(rectNum, blockType)
		add_child(polygon)

func _removeRenderBoxes(blockType): 
	for rectNum in cachedRects.get(blockType, []).size():
		get_node(_encodeName(rectNum, blockType)).free()

func _addPhysicsBoxes(blockType:int):
	if (BlockTypes.blocks[blockType].collision == true):
		for rectNum in cachedRects.get(blockType, []).size():
			var rect = cachedRects[blockType][rectNum]
			var colBox:CollisionShape2D = _makeColBox(rect);
			colBox.name = _encodeName(rectNum, blockType)
			add_sibling(colBox)

func _removePhysicsBoxes(blockType:int):
	if (BlockTypes.blocks[blockType].collision == true):
		for rectNum in cachedRects.get(blockType, []).size():
			get_node("../" + _encodeName(rectNum, blockType)).free()

func _encodeName(number, blockType) -> String:
	#Chunk Name, followed by encoded name
	#Only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((number << grid.bitsPerBlock) + blockType)

func _makeRenderPolygon(recti, texture) -> Polygon2D:
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

func _makeColBox(recti:Rect2i) -> CollisionShape2D:
	var rect = _rectiToRect(recti);
	var colShape = CollisionShape2D.new();
	colShape.shape = RectangleShape2D.new();
	colShape.position = rect.position + rect.size/2;
	colShape.shape.size = rect.size;
	return colShape

func _rectiToRect(recti:Rect2i) -> Rect2:
	var rect:Rect2 = Rect2(recti)
	rect.position *= blockDims
	rect.size *= blockDims
	return rect

#endregion

#
