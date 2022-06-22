extends Node2D;

class_name Chain
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var linkObj = preload("res://Objects/Link.tscn");
var points = [Point.new()];
var links = [Link.new()];
const maxLength = 8;
const hookSpeed = 10;
var hookDir = Vector2(1,0);

onready var player = get_parent();
onready var hookNode = $Hook;
const playerPos = Vector2(15, 0);
const readyPos  = Vector2(32, 0);
var grabPos = Vector2(0,0);

var currentState = ChainState.Ready;

enum ChainState \
{
	Ready,
	Firing,
	Deployed,
	Retracting,
	Hooked,
}

var states = \
{
	ChainState.Ready : true,
	ChainState.Firing : false,
	ChainState.Deployed : false,
	ChainState.Retracting : false,
	ChainState.Hooked : false
}	

# Called when the node enters the scene tree for the first time.
func _ready():
	InitHook();

func InitHook():
	hookNode.pointA.InitPoint(readyPos);
	hookNode.pointB.InitPoint(playerPos);
	hookNode.rotation = 0;
	hookNode.position = readyPos;
	points = [hookNode.pointA, hookNode.pointB];
	#points = [];
	links = [hookNode];
	ReleaseHook();
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateChain(delta);
	SimulateMotion(delta);

func UpdateChain(delta):
	match currentState:
		ChainState.Firing:
			FireChainStep();
		ChainState.Retracting:
			PullChainStep(delta);
	if (states[ChainState.Hooked]):
		UpdateHook();
			
func UpdateHook():
	links.front().global_position = grabPos;
	GetHookPoint().position = links.front().position;

func PullTrigger(mousePos, global):
	if (currentState == ChainState.Ready):
		grabPos = global; # collision should be in FireChainStep() 
		hookDir = (mousePos - playerPos).normalized();
		SetShootState();
	elif (currentState == ChainState.Deployed):
		SetRetractState();
	
func SetReadyState():
	states[ChainState.Retracting] = false;
	states[ChainState.Ready] = true;
	currentState = ChainState.Ready;
	InitHook();
func SetShootState():
	states[ChainState.Ready] = false;
	states[ChainState.Firing] = true;
	currentState = ChainState.Firing;
	GetHandPoint().ChangeLock(false);
func SetDeployedState():
	states[ChainState.Firing] = false;
	states[ChainState.Deployed] = true;	
	currentState = ChainState.Deployed;	
	GetHandPoint().ChangeLock(true);
	GetHandPoint().position = playerPos;
func SetRetractState():
	states[ChainState.Deployed] = false;
	states[ChainState.Retracting] = true;
	currentState = ChainState.Retracting;

func FireChainStep():
	# TODO: Add collision logic
	if(links.size() < maxLength):
		InsertLink();
		MoveHook();
	else:
		SetHooked();
		SetDeployedState();

func PullChainStep(delta):
	if(links.size() != 1):
			RetractLink();
			if (states[ChainState.Hooked]):
				print (GetChainDirection());
			player.move_and_slide(player.pullForce * hookDir, GetChainDirection());
			
	else:
		#SetHangingState();
		SetReadyState();

func MoveHook():
	GetHookPoint().position += hookDir * hookSpeed;

func SetHooked():
	states[ChainState.Hooked] = true;
	states[ChainState.Firing] = false;
	states[ChainState.Deployed] = true;	
	currentState = ChainState.Deployed;	
	GetHandPoint().ChangeLock(true);
	GetHookPoint().ChangeLock(true);
	GetHandPoint().position = playerPos;

func ReleaseHook():
	states[ChainState.Hooked] = false;
	GetHookPoint().ChangeLock(false);
	pass;

func RetractLink():
	var retractDir = GetChainDirection();
	var prevPointPos = readyPos;
	for point in points:
		var current = point.position;
		point.position = prevPointPos
		prevPointPos = current;
	RemoveLink();

func SimulateMotion(delta):
	if(currentState == ChainState.Ready):
		return;
	UpdatePoints(delta);
	for i in range(100):
		UpdateLinks();

func UpdatePoints(delta):
	for point in points:
		point.Update(delta);

func UpdateLinks():
	for link in links:
		link.Update();

func GetChainDirection():
	return (GetHookPoint().position - GetHandPoint().position).normalized();
	
func InsertLink():
	var newPoint = Point.new();
	#newPoint.ChangeLock(true);
	newPoint.InitPoint(playerPos);
	var link = linkObj.instance();
	link.SetLink(points.back(), newPoint);
	add_child(link)
	links.push_back(link);
	points.push_back(newPoint);
	
func RemoveLink():
	var isHandLocked = GetHandPoint().locked;
	if(links.size() > 1):
		remove_child(links.back());
		links.pop_back();
		points.pop_back();
	GetHandPoint().ChangeLock(isHandLocked);

func GetHandPoint():
	return links[links.size() - 1].pointB;

func GetHookPoint():
	return links[0].pointA;
