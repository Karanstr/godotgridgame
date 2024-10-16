extends Node2D

var world:FixedDimensionDAG
var root:FixedDimensionDAG.NodeAddress

var rectData:Array = []
var blockDims = Vector2(.66,.66)

func _ready():
	get_node("Highlight").polygon[1].y = blockDims.y
	get_node("Highlight").polygon[2].y = blockDims.y
	get_node("Highlight").polygon[2].x = blockDims.x * 2
	get_node("Highlight").polygon[3].x = blockDims.x * 2
	
	world = FixedDimensionDAG.new(1)
	var startLayer = 3
	world.ensureDepth(startLayer)
	root = world.NodeAddress.new(startLayer, 0)

func posToCell(mousePos:Vector2) -> Vector2i:
	var cell = Vector2i(floor(mousePos/blockDims))
	return cell

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var cell = posToCell(get_local_mouse_position())
		#var data = tree.growToContain(cell)
		#cell = data[0]
		#position += Vector2(data[1]) * blockDims
		var newValue = 0
		if cell.x >= 0 && cell.x < 2 ** (root.layer + 1):
			if world.readLeaf(root, cell.x) == 0:
				newValue = 1
			root = world.setNodeChild(root, cell.x, newValue)
		#position.x += tree.shrinkToFit() * blockDims.x
		#position.x += tree.compactRoot() * blockDims.x

func _process(_delta):
	updateRender()

#Stupid bad rendering

#region Render Management

func updateRender():
	_removeRenderBoxes()
	rectData = BinUtil.greedyRect([world.DFSGraphToBin(root)])
	_addRenderBoxes()
	get_node("Highlight").polygon[2].x = 2**(root.layer + 1) * blockDims.x
	get_node("Highlight").polygon[3].x = 2**(root.layer + 1) * blockDims.x

func _rectiToRect(recti:Rect2i) -> Rect2:
	var rect:Rect2 = Rect2(recti)
	rect.position *= blockDims
	rect.size *= blockDims
	return rect

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

func _addRenderBoxes():
	var image = BlockTypes.blocks[1].texture
	for rectNum in rectData.size():
		var rect = rectData[rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = String.num(rectNum)
		add_child(polygon)

func _removeRenderBoxes():
	for rectNum in rectData.size():
		get_node(String.num(rectNum)).free()

#endregion
