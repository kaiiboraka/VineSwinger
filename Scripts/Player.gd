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
	CalculateMove(delta);
	PlayerStateUpdate(delta);
	
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
		velocity.y = GRAVITY;

func JumpState():
	if (currHangTime > 0):
		states[PlayerState.Jumping] = Input.is_action_just_pressed("player_jump");
		if(states[PlayerState.Jumping]):
			velocity.y += jumpForce;
			#GameController.DebugPrint("jumped, hangtime 0'd");
			currentState = PlayerState.Jumping if states[PlayerState.Jumping] else currentState;
			currHangTime = 0;
	
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
	if (is_on_ceiling() && states[PlayerState.Jumping]):
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
