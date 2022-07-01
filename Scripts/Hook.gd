extends Link

var isHooked = false;
var anchorPos = Vector2(0, 0);
var hookSpeed = 5;
var pullSpeed = 5;

onready var kb2d = $KinematicBody2D
onready var collider = $KinematicBody2D/CollisionShape2D

func _ready():
	height = 3;#scale.x * texture.get_width();
	Disable(true);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(isHooked):
		global_position = anchorPos;
		linkHead.position = position;
		linkFeet.position = position;
		linkFeet.position.x -= height;

func MoveHook(delta, dir):
#	linkFeet.ChangeLock(true);
#	linkHead.position.x += hookSpeed * delta * dir;
	linkHead.position.x += delta * dir;
	linkFeet.position = Vector2(linkHead.position.x + height, 0);
	

func CheckHookCollision():
	var collision = kb2d.move_and_collide(Vector2(0,0), true, true, true);
	if(collision):
		isHooked = true;
		anchorPos = collision.position;
		Disable(true);
		GameController.DebugPrint("chain bumped into something");
	
func Reset(playerPos):
	var hookPos = Vector2(playerPos.x + height, playerPos.y);
	linkHead.InitPoint(hookPos);
	linkFeet.InitPoint(playerPos);
	idx = 0;
	rotation = 0;
	position = GetCenter();
	Release();

func Release():
	isHooked = false;
	Disable(true);

func Disable(toggle):
	collider.set_deferred("disabled", toggle);
