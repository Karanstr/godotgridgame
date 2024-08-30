extends Polygon2D

var textureSize = Vector2i(2, 2) # In pixels

func setUp(polygonShape:PackedVector2Array, textureRef, blockSize:Vector2):
	polygon = polygonShape;
	texture = textureRef
	texture_scale = Vector2(1,1)/(blockSize/Vector2(textureSize))
