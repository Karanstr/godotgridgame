extends Node2D

var tree:SparseDimensionalDAG
var pot = Nodes.pot

var rectData:Array = []
var blockDims = Vector2(1, 1)

func _ready():
	tree = SparseDimensionalDAG.new(2)
	tree.setNodeChild(0b000, 1)
	tree.setNodeChild(0b110, 1)
	tree.setNodeChild(0b111, 1)

#Stupid bad rendering. Problem is this data type was designed for raymarching, not greedymeshing
func _process(_delta):
	_removeRenderBoxes()
	rectData = BinUtil.greedyRect([tree.DFSGraphToBin()])
	_addRenderBoxes()

#region Render Management

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
