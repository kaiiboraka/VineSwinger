extends Sprite

class_name Link

export var overlapRatio = .3;

var linkHead;
var linkFeet;
var height # it's 25
var idx;

func _init():
	#height = texture.get_width();
	linkHead = Point.new();
	linkFeet = Point.new();

func _draw():
	if(GameController.debug):
		Render();

func SetLink(newA, newB, newIdx):
	linkHead = newA;
	linkFeet = newB;
	idx = newIdx;
	position = GetCenter();
	rotation = GetDirection().angle();
	height = scale.x * texture.get_height() * (1-overlapRatio);

func GetCenter():
	return (linkHead.position + linkFeet.position) / 2.0;

func GetDirection():
	return (linkHead.position - linkFeet.position).normalized();

func Update():
	var linkCenter = GetCenter();
	var linkDirection = GetDirection();
	position = linkCenter;
	rotation = linkDirection.angle();
	if(!linkHead.locked):
		linkHead.position = linkCenter + linkDirection * height / 2;
	if(!linkFeet.locked):
		linkFeet.position = linkCenter - linkDirection * height / 2;

func Render():
	var headColor = Color().from_hsv(0,           1, 1 - idx * 0.0625, 1);
	var footColor = Color().from_hsv(156.0/256.0, 1, 1 - idx * 0.0625, 1);
	
	draw_circle((linkFeet.position - position) / scale, 2.5, footColor); #
	draw_circle((linkHead.position - position) / scale, 2, headColor); #
	draw_circle(Vector2.ZERO, 1, Color.purple);
	draw_line(linkFeet.position - position, linkHead.position - position, Color.white, .5, true);
