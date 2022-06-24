extends Node2D;

class_name Chain
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var linkObj = preload("res://Objects/Link.tscn");
var points = [Point.new()];
var links = [Link.new()];
export var maxLength = 10;
export var deployDuration = .5;
var timeSinceFired = 0;

onready var player = get_parent();
onready var hook = $Hook;
const playerPos = Vector2(15, 0);
const readyPos  = Vector2(32, 0);

var currentState = ChainState.Ready;

enum ChainState \
{
	Ready,
	Firing,
	Deployed,
	Retracting,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	SetReadyState();
	hook.hookSpeed = GetMaxChainLength() / deployDuration;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateChain(delta);
	SimulateMotion(delta);
	LateUpdate(delta);

func UpdateChain(delta):
	match currentState:
		ChainState.Firing:
			FireChainStep(delta);
		ChainState.Deployed:
			if (!hook.isHooked):
				SetRetractState();
		ChainState.Retracting:
			PullChainStep(delta);
			
func LateUpdate(delta):
	hook.CheckHookCollision();
	if(currentState == ChainState.Ready):
		rotation = (get_global_mouse_position() - global_position).angle();
	elif(hook.isHooked):
		rotation = GetHookAngle(); 
		ClampPlayer(delta);

func PullTrigger():
	timeSinceFired = 0;
	if (currentState == ChainState.Ready):
		SetShootState();
	else:
		SetRetractState();

func FireChainStep(delta):
	timeSinceFired += delta;
	hook.ShootHook(delta);
	if(timeSinceFired >= (deployDuration / maxLength) * (links.size() - 1)):
		if(links.size() <= maxLength):
			InsertLink();
		else:
			SetDeployedState();

func PullChainStep(delta):
	timeSinceFired += delta;
	
	if (!hook.isHooked):
#		player.move_and_slide(pullForce * Vector2(cos(rotation), sin(rotation)), GetChainDirection());
#		player.move_and_slide(CalcPullForce() * Vector2(cos(rotation), sin(rotation)).normalized(), Vector2(0, -1));
#	else:
		ReleaseHook();
	
	if(timeSinceFired >= (deployDuration / maxLength) * (maxLength - links.size())):
		if(links.size() != 1):
			RetractLink();
		else:
			SetReadyState();
	
func ClampPlayer(delta):
	var distFromAnchor = player.global_position - hook.anchorPos;
	#d=
	var mDist = Link.maxHeight * links.size();
	distFromAnchor = distFromAnchor.clamped(mDist);
	player.global_position = distFromAnchor + hook.anchorPos;
	#player.global_position = points.back().global_position;
#	var anchorAngle = Vector2(cos(rotation), sin(rotation)).normalized();
#	if (distFromAnchor > GetMaxChainLength()):
#		player.move_and_slide(distFromAnchor  * anchorAngle * 10, Vector2(0, -1));
#	var newHeight = (distFromAnchor.length()/mDist) * Link.maxHeight;
#	if(newHeight > Link.maxHeight):
#		newHeight = Link.maxHeight;
#	for link in links:
#		link.height = newHeight;

func RetractLink():
	var retractDir = GetChainDirection();
	var prevPointPos = readyPos;
	for point in points:
		var current = point.position;
		point.position = prevPointPos
		prevPointPos = current;
	RemoveLink();

func InsertLink():
	points.back().ChangeLock(false);
	var newPoint = Point.new();
	newPoint.InitPoint(playerPos);
	var link = linkObj.instance();
#	link.z_index = maxLength - links.size();
	link.SetLink(points.back(), newPoint);
	add_child(link)
	links.push_back(link);
	points.push_back(newPoint);
	points.back().ChangeLock(true);
	
func RemoveLink():
	if(links.size() > 1):
		remove_child(links.back());
		links.pop_back();
		points.pop_back();
	points.back().ChangeLock(true);

func GetChainDirection():
	return (points.front().position - points.back().position).normalized();

func GetMaxChainLength():
	return Link.maxHeight * maxLength;

func GetHookAngle():
	return (hook.global_position - global_position).angle()

func SetReadyState():
	currentState = ChainState.Ready;
	hook.ptHead.InitPoint(readyPos);
	hook.ptFeet.InitPoint(playerPos);
#	hook.ptFeet.ChangeLock(true);
	hook.rotation = 0;
	hook.position = readyPos;
	points = [hook.ptHead, hook.ptFeet];
	links = [hook];
#	hook.z_index = maxLength;
	hook.Release();

func SetShootState():
	currentState = ChainState.Firing;

func SetDeployedState():
	currentState = ChainState.Deployed;

func SetRetractState():
	currentState = ChainState.Retracting;

func ReleaseHook():
	hook.Release();
	
func SimulateMotion(delta):
	if(currentState == ChainState.Ready):
		return;
	UpdatePoints(delta);
	for i in range(100):
		UpdateLinks();

func UpdatePoints(delta):
	var downDir = Vector2(sin(rotation), cos(rotation)).normalized();
	for point in points:
		point.Update(delta, downDir);

func UpdateLinks():
	for link in links:
		link.Update();
