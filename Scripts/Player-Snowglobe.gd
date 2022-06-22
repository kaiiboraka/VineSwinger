extends KinematicBody2D

class_name Player

var velocity = Vector2();

var moveSpeed = 300;
var pullForce = 1000;

var GRAVITY = 1000;
var jumpForce = 500;

const maxJumpHeight = 10;
const minJumpHeight = 5;
const timeTilJumpApex = .5;

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

func _init():
	jumpForce = (2 * maxJumpHeight) / timeTilJumpApex;
	#GRAVITY = -(2 * maxJumpHeight) / pow(timeTilJumpApex, 2);
	GRAVITY = -jumpForce / timeTilJumpApex;

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
	PlayerStateUpdate();
	
func PlayerStateUpdate():
	MoveState();
	GroundState();
	JumpState();
	HangState();
	#print(PlayerState.keys()[currentState])

func HangState():
	if (Input.is_action_just_pressed("player_hook")):
		chain.PullTrigger(get_local_mouse_position(), get_global_mouse_position());
	if (Input.is_action_just_pressed("player_releaseHook")):
		chain.ReleaseHook();
	states[PlayerState.Hanging] = true if (chain.states[chain.ChainState.Hooked]) else false;

func JumpState():
	if (!states[PlayerState.Grounded]):
		 pass;
	else :
		states[PlayerState.Jumping] = Input.is_action_just_pressed("player_jump");
		if(states[PlayerState.Jumping]):
			velocity.y -= jumpForce;
			print("jump");
		currentState = PlayerState.Jumping if states[PlayerState.Jumping] else currentState;
	
func MoveState():
	states[PlayerState.Moving] = moveDir != 0;
	currentState = PlayerState.Moving if states[PlayerState.Moving] else PlayerState.Idle;
	
func CalculateMove(delta):
	velocity.y += delta * GRAVITY;
	velocity.x = moveSpeed * moveDir;
	move_and_slide(velocity, Vector2(0, -1));

func GroundState():
	states[PlayerState.Grounded] = is_on_floor();
	if (is_on_ceiling() && states[PlayerState.Jumping]):
		velocity.y = 0;
	if(states[PlayerState.Grounded]):
		velocity.y = 0;
	
func FallState():
	if (states[PlayerState.Grounded]):
		states[PlayerState.Falling] = false;
		return
	states[PlayerState.Falling] = velocity.y < 0;
	
func GetMoveDir():
	if Input.is_action_pressed("player_move_left"):
		moveDir = -1 
	elif Input.is_action_pressed("player_move_right"):
		moveDir = 1
	else: 
		if (states[PlayerState.Grounded]):
			moveDir = 0
	return moveDir
