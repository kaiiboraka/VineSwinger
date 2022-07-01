extends KinematicBody2D

var isHooked = false;
var anchorPos = Vector2(0, 0);
var hookSpeed = 300;
var height;
var pullSpeed = 200;
var velocity = Vector2(0,0);
onready var collider = $CollisionShape2D;

func _ready():
	height = 3;#scale.x * texture.get_width();
	Disable(true);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(isHooked):
		global_position = anchorPos;
	else:
		move_and_slide(velocity, Vector2(0, -1));
		if(!collider.disabled):
			CheckHookCollision();

func MoveHook(speed, dir):
	velocity += speed * Vector2(cos(rotation),sin(rotation)) * dir;
		
func CheckHookCollision():
	var collision = get_last_slide_collision();
	if(collision):
		isHooked = true;
		anchorPos = collision.position;
		Disable(true);
		velocity = Vector2.ZERO;
		GameController.DebugPrint("chain bumped into something");
	
func Reset(playerPos):
	var hookPos = Vector2(playerPos.x + height, playerPos.y);
	position = hookPos;
	rotation = 0;
	Release();

func Release():
	velocity = Vector2.ZERO;
	isHooked = false;
	Disable(true);

func Disable(toggle):
	collider = $CollisionShape2D;
#	collider.set_disabled(toggle);
	collider.set_deferred("disabled", toggle);
