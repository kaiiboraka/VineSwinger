extends Sprite

class_name Link

var ptHead;
var ptFeet;
const maxHeight = 12;
var height = 0;

func _init():
	ptHead = Point.new();
	ptFeet = Point.new();

func SetLink(newA, newB):
	ptHead = newA;
	ptFeet = newB;

func GetCenter():
	return (ptHead.position + ptFeet.position) / 2.0;

func GetDirection():
	return (ptHead.position - ptFeet.position).normalized();

func Update():
	var linkCenter = GetCenter();
	var linkDirection = GetDirection();
	position = linkCenter;
	rotation = linkDirection.angle();
	if(!ptHead.locked):
		ptHead.position = linkCenter + linkDirection * height / 2;
	if(!ptFeet.locked):
		ptFeet.position = linkCenter - linkDirection * height / 2;
	if (false):
		var mousePos = get_local_mouse_position();
		ptHead.InitPoint(mousePos);
		ptFeet.InitPoint(mousePos);
	
