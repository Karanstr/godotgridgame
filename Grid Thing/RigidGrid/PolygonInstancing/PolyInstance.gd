extends Polygon2D

func _ready():
	setUp(
		PackedVector2Array([Vector2(0,0), Vector2(8,0), Vector2(8,8), Vector2(0,8)]),
		"res://RigidGrid/PolygonInstancing/Colors/green.png",
		Vector2(1, 1)
		)

#Add function to set up all the stuff
func setUp(polygonShape:PackedVector2Array, textureName:String, blockSize:Vector2):
	polygon = polygonShape;
	texture = load(textureName) #Stupid way to do it, be better pls
	scale = blockSize
	pass
