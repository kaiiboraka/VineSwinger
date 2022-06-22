extends Sprite

class_name Link

var pointA;
var pointB;
var isHook = false;
var linkSize = 12;

func _init():
	pointA = Point.new();
	pointB = Point.new();

func SetLink(newA, newB):
	pointA = newA;
	pointB = newB;

func _input_event(viewport, event, shape_idx):
	#dragging = (event is InputEventMouseButton);
	pass

func GetCenter():
	return (pointA.position + pointB.position) / 2.0;

func GetDirection():
	return (pointA.position - pointB.position).normalized();

func Update():
	var linkCenter = GetCenter();
	var linkDirection = GetDirection();
	position = linkCenter;
	rotation = linkDirection.angle();
	if(!pointA.locked):
		pointA.position = linkCenter + linkDirection * linkSize / 2;
	if(!pointB.locked):
		pointB.position = linkCenter - linkDirection * linkSize / 2;
	if (false):#dragging):
		var mousePos = get_local_mouse_position();
		pointA.InitPoint(mousePos);
		pointB.InitPoint(mousePos);
	
