extends KinematicBody2D

class_name Player

var velocity = Vector2();

var moveSpeed = 200;
const maxJumpHeight = 120;
const timeTilJumpApex = .5;
const jumpDist = 150;

const hangTime = .2;
var currHangTime = hangTime;

const jumpForce = -(2 * maxJumpHeight) / timeTilJumpApex;
const GRAVITY = -jumpForce / timeTilJumpApex;

var tanAngle;
var distToHook;
var launchRight;
var launchLeft;

var moveDir = 1;
var currentState = PlayerState.Idle;
var inputVector;

onready var camera = $Camera2D;
onready var collider = $CollisionShape2D;
onready var chain = $Chain;
onready var sprite = $Sprite;

enum PlayerState \
{
	FacingRight,
	Grounded,
	Idle,
	Moving,
	Jumping,
	Falling,
	Hanging
}

var states = \
{
	PlayerState.FacingRight : true,
	PlayerState.Grounded : true,
	PlayerState.Idle : true,
	PlayerState.Moving : false,
	PlayerState.Jumping : false,
	PlayerState.Falling : false,
	PlayerState.Hanging : false,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true); # Replace with function body.
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED);

func _input(event):
	if Input.is_action_pressed("ui_scroll_up"):
		camera.zoom.x -= .1;
		camera.zoom.y -= .1;
	if Input.is_action_pressed("ui_scroll_down"):
		camera.zoom.x += .1;
		camera.zoom.y += .1;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	GetMoveDir();
	#velocity = lerp(velocity, moveDir * moveSpeed, acceleration)
	#position.x += velocity * delta
	#if Input.is_action_just_released("player_move_left"):
	#	print("stopped left");
	#if Input.is_action_just_released("player_move_right"):
	#	print("stopped right");

func _physics_process(delta):
	tanAngle = deg2rad((chain.hook.anchorPos.y - global_position.y) / (chain.hook.anchorPos.x - global_position.x));
	distToHook = global_position.distance_to(chain.hook.anchorPos);
	var circleNormal = chain.hook.anchorPos - global_position;
	#Obtain vector Center of circle - point P1. Let's call this vector v1.
	#Tangent vector 't' is perpendicular to v1. If v1=(vx, vy) then t=(-vy,vx).
	launchRight = Vector2(-circleNormal.y, circleNormal.x);
	launchLeft  = Vector2(circleNormal.y, -circleNormal.x);
	CalculateMove(delta);
	PlayerStateUpdate(delta);
	update();
	
func _draw():
	if(chain.hook.isHooked):
		var newPos = chain.hook.global_position - position;
		draw_arc(newPos, distToHook, 0, 2 * PI, 36, Color.chocolate, 1.0, true);
		draw_line(global_position - position,launchRight, Color.webpurple, 1.0, true);
		draw_line(global_position - position,launchLeft, Color.violet, 1.0, true);
	
func PlayerStateUpdate(delta):
	MoveState();
	HangState();
	GroundState(delta);
	JumpState();
	#print(PlayerState.keys()[currentState])

func HangState():
	if (Input.is_action_just_pressed("player_hook")):
		chain.PullTrigger();
	if (Input.is_action_just_pressed("player_releaseHook")):
		chain.ReleaseHook();
	states[PlayerState.Hanging] = chain.hook.isHooked;
	if(states[PlayerState.Hanging]):
		states[PlayerState.Jumping] = false;
		states[PlayerState.Falling] = true;
		velocity.y = min(velocity.y, GRAVITY);

func JumpState():
#	if (states[PlayerState.Jumping]):
#		return;
	if (currHangTime > 0 || (states[PlayerState.Hanging])):
		states[PlayerState.Jumping] = Input.is_action_just_pressed("player_jump");
		if(states[PlayerState.Jumping]):
			velocity.y += jumpForce;
			#GameController.DebugPrint("jumped, hangtime 0'd");
			currentState = PlayerState.Jumping if states[PlayerState.Jumping] else currentState;
			currHangTime = 0;
			if(states[PlayerState.Hanging]):
				chain.ReleaseHook();
				velocity = launchRight;


func MoveState():
	states[PlayerState.Moving] = (moveDir != 0);
	currentState = PlayerState.Moving if states[PlayerState.Moving] else PlayerState.Idle;
	
func CalculateMove(delta):
	velocity.y += GRAVITY * delta;
	velocity.x = lerp(velocity.x, moveSpeed * moveDir, .25);
#	if (!states[PlayerState.Grounded] && moveDir == 0):
#		velocity.x /= 2;
	move_and_slide(velocity, Vector2(0, -1));

func GroundState(delta):
	states[PlayerState.Grounded] = is_on_floor();
	if (is_on_ceiling() && !states[PlayerState.Grounded]):
		velocity.y = 0;
	if(states[PlayerState.Grounded]):
		velocity.y = 0;
		currHangTime = hangTime;
	else:
		currHangTime -= delta;
	
func FallState():
	if (states[PlayerState.Grounded]):
		states[PlayerState.Falling] = false;
		return
	states[PlayerState.Falling] = velocity.y < 0;
	
func GetMoveDir():
	var tempMoveDir = moveDir;
	if Input.is_action_pressed("player_move_left"):
		moveDir = -1
	elif Input.is_action_pressed("player_move_right"):
		moveDir = 1
	else: 
		moveDir = 0
#	if (tempMoveDir != moveDir):
#		GameController.DebugPrint("moveDir changed to: " + str(moveDir));
	if (moveDir != 0):
		sprite.scale.x = moveDir;
	return moveDir
