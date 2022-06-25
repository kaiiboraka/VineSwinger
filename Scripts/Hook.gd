extends Link

var isHooked = false;
var anchorPos = Vector2(0, 0);
var hookSpeed = 10;

onready var kb2d = $KinematicBody2D
onready var collider = $KinematicBody2D/CollisionShape2D

func _ready():
	height = 6;#scale.x * texture.get_width();
	Disable(true);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(isHooked):
		global_position = anchorPos;
		linkHead.position = position;
		linkFeet.position = position;
		linkFeet.position.x -= height;

func ShootHook(delta):
	linkHead.ChangeLock(true);
	if (!isHooked):
		Disable(false);
#		linkHead.position.x += hookSpeed * delta;

func CheckHookCollision():
	var collision = kb2d.move_and_collide(Vector2(0,0), true, true, true);
	if(collision):
		isHooked = true;
		anchorPos = collision.position;
		linkFeet.ChangeLock(true);
		Disable(true);
		if(GameController.debug):
			print("chain bumped into something");
	
func Release():
	isHooked = false;
#	linkHead.ChangeLock(false);
	Disable(true);

func Disable(toggle):
	collider.set_deferred("disabled", toggle);
