extends Link

var isHooked = false;
var anchorPos = Vector2(0, 0);
var hookSpeed = 10;

onready var kb2d = $KinematicBody2D
onready var collider = $KinematicBody2D/CollisionShape2D

func _ready():
	Disable(true);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(isHooked):
		global_position = anchorPos;
		ptHead.position = position;
		ptFeet.position = position;
		ptFeet.position.x -= 6;

func ShootHook(delta):
	ptHead.ChangeLock(true);
	if (!isHooked):
		Disable(false);
		ptHead.position.x += hookSpeed * delta;

func CheckHookCollision():
	var collision = kb2d.move_and_collide(Vector2(0,0), true, true, true);
	if(collision):
		isHooked = true;
		anchorPos = collision.position;
		ptFeet.ChangeLock(true);
		Disable(true);
		print("chain bumped into something");
	
func Release():
	isHooked = false;
#	ptHead.ChangeLock(false);
	Disable(true);

func Disable(toggle):
	collider.set_deferred("disabled", toggle);
