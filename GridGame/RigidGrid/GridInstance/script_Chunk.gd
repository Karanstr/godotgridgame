extends Node2D

@export var editable:bool = false

var grid:packedGrid
var blockDims:Vector2

var blockTypeRects:Dictionary = {}
var collisionRects:Array = []
var pointMasses:Dictionary = {}

var lastEditKey:Vector2i = Vector2i(-1, -1)
var editValue:int = 0
var exile = false

func initialize(blockDimensions:Vector2, gridDimensions:Vector2i, hasData = false, gridData:Array = []):
	blockDims = blockDimensions
	grid = packedGrid.new(gridDimensions.y, gridDimensions.x, hasData, gridData)
	if get_parent().name == "World": editable = true
	updateChunk(grid.bitBinRows)

func _input(event):
	if event is InputEventKey && event.pressed && editable:
		match event.keycode:
			KEY_1: editValue = 0
			KEY_2: editValue = 1
			KEY_3: editValue = 2
			KEY_5: exile = true

func _process(_delta):
	if (editable):
		if Input.is_action_pressed("click"):
			var cell:Vector2i = pointToCell(get_local_mouse_position())
			if (cell != lastEditKey && cell != Vector2i(-1, -1)):
				lastEditKey = cell
				grid.accessCell(cell, editValue)
		elif Input.is_action_just_released("click"): lastEditKey = Vector2i(-1, -1)
	#After all frame actions, calculate updates
	if exile:
		findAndExileGroups()
		exile = false
	if grid.changedBGrids.is_empty() == false:
		updateChunk(grid.changedBGrids) #Removes updates meshes/phys objects

#We do not update 0. 0 isn't real.
func updateChunk(changedBlocks:Dictionary):
	for change in changedBlocks:
		_removeRenderBoxes(change)
		blockTypeRects.erase(change)
		pointMasses.erase(change)
		if grid.bitBinRows.has(change): #If value still exists in binRows
			var renderGrid:Array[int] = grid.mergeBinGrids({change:null})
			blockTypeRects[change] = BinUtil.greedyRect(renderGrid)
			_addRenderBoxes(change)
	_removePhysicsBoxes()
	var collisionGrid:Array[int] = grid.mergeBinGrids(grid.bitBinRows)
	collisionRects = BinUtil.greedyRect(collisionGrid)
	_addPhysicsBoxes()
	_updateCOM(grid.bitBinRows)
	grid.changedBGrids.clear()

func findAndExileGroups():
	var parent = get_parent()
	var groups:Array = grid.identifySubGroups()
	for group in groups.size()-1: #Keep the bottom grid bc I need to decide somehow and this lets things fall
		var curGroup = groups[group]
		curGroup.copyGridToGroup(grid.rows)
		grid.subtractGrid(curGroup.grid)
		parent.exileGroup(curGroup.fittedGrid, Vector2(curGroup.topLeftCell) * blockDims)

func pointToCell(point:Vector2) -> Vector2i:
	var cell:Vector2i = point/blockDims
	if point.x < 0:
		cell.x -= 1
	if point.y < 0:
		cell.y -= 1 
	return cell

func cellToPoint(cell:Vector2i):
	return Vector2(cell)*blockDims

#region Mass Management

func _updateCOM(changedVals:Dictionary):
	var centerOfMass = Vector2(0,0)
	var chunkMass:int = 0
	for blockType in blockTypeRects:
		if (changedVals.has(blockType)): pointMasses[blockType] = _reduceToPointMasses(blockType)
		for point in pointMasses.get(blockType, []):
			centerOfMass += Vector2(point.x * point.z, point.y * point.z)
			chunkMass += point.z
	centerOfMass /= Vector2(chunkMass, chunkMass)
	get_parent().updateMass(chunkMass, centerOfMass)
	return centerOfMass

func _reduceToPointMasses(blockType:int):
	var blockPointMasses:Array = []
	for recti in blockTypeRects[blockType]:
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
	var image = BlockTypes.blocks[blockType].texture
	for rectNum in blockTypeRects.get(blockType, []).size():
		var rect = blockTypeRects[blockType][rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = _encodeName(rectNum, blockType)
		add_child(polygon)

func _removeRenderBoxes(blockType): 
	for rectNum in blockTypeRects.get(blockType, []).size():
		get_node(_encodeName(rectNum, blockType)).free()

func _addPhysicsBoxes():
	for rectNum in collisionRects.size():
		var rect = collisionRects[rectNum]
		var colBox:CollisionShape2D = _makeColBox(rect)
		colBox.name = _encodeName(rectNum, 0)
		add_sibling(colBox)

func _removePhysicsBoxes():
	for rectNum in collisionRects.size():
		get_node("../" + _encodeName(rectNum, 0)).free()

func _encodeName(number, blockType) -> String:
	#Chunk Name, followed by encoded name
	#Only matters with collision boxes, but I don't care enough to remove it from the render polygons
	return name + " " + String.num_int64((number << grid.bitsPerBlock) + blockType)

func _makeRenderPolygon(recti, texture) -> Polygon2D:
	var rect = _rectiToRect(recti)
	var data:PackedVector2Array = PackedVector2Array()
	data.push_back(rect.position)
	data.push_back(Vector2(rect.position.x, rect.position.y + rect.size.y))
	data.push_back(rect.position + rect.size)
	data.push_back(Vector2(rect.position.x + rect.size.x, rect.position.y))
	var polygon = Polygon2D.new()
	polygon.polygon = data
	polygon.texture = texture
	polygon.texture_scale = texture.get_size()/blockDims
	return polygon

func _makeColBox(recti:Rect2i) -> CollisionShape2D:
	var rect = _rectiToRect(recti)
	var colShape = CollisionShape2D.new()
	colShape.shape = RectangleShape2D.new()
	colShape.position = rect.position + rect.size/2
	colShape.shape.size = rect.size
	return colShape

func _rectiToRect(recti:Rect2i) -> Rect2:
	var rect:Rect2 = Rect2(recti)
	rect.position *= blockDims
	rect.size *= blockDims
	return rect

#endregion

#
