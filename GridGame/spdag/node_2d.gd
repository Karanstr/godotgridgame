extends Node2D

var tree:SparseDimensionalDAG
var pot = Nodes.pot

var blockTypeRects:Dictionary = {}
var blockDims = Vector2(1, 1)

func _ready():
	tree = SparseDimensionalDAG.new(3)
	tree.setNodeChild(0b100, 1)
	var oneBinGrid = tree.DFSGraphToBin()
	var zeroBinGrid = ~oneBinGrid & BinUtil.genMask(2**(tree.rootAddress[0] + 1))
	blockTypeRects[0] = BinUtil.greedyRect([zeroBinGrid])
	blockTypeRects[1] = BinUtil.greedyRect([oneBinGrid])
	_addRenderBoxes(0)
	_addRenderBoxes(1)

#region Render&Physics Management  

func _encodeName(number, blockType = 0) -> String:
	#Chunk Name, only matters with collision boxes
	return String.num_int64((number << 1) + blockType)

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

func _makeColBox(recti:Rect2i) -> CollisionShape2D:
	var rect = _rectiToRect(recti)
	var colShape = CollisionShape2D.new()
	colShape.shape = RectangleShape2D.new()
	colShape.position = rect.position + rect.size/2
	colShape.shape.size = rect.size
	return colShape

func _addRenderBoxes(blockType):
	var image = BlockTypes.blocks[blockType+1].texture
	for rectNum in blockTypeRects.get(blockType, []).size():
		var rect = blockTypeRects[blockType][rectNum]
		var polygon = _makeRenderPolygon(rect, image)
		polygon.name = _encodeName(rectNum, blockType)
		add_child(polygon)

func _removeRenderBoxes(blockType): 
	for rectNum in blockTypeRects.get(blockType, []).size():
		get_node(_encodeName(rectNum, blockType)).free()

#func _addPhysicsBoxes():
	#for rectNum in collisionRects.size():
		#var rect = collisionRects[rectNum]
		#var colBox:CollisionShape2D = _makeColBox(rect)
		#colBox.name = _encodeName(rectNum)
		#add_sibling(colBox)
#
#func _removePhysicsBoxes():
	#for rectNum in collisionRects.size():
		#get_node("../" + _encodeName(rectNum)).free()

#endregion
