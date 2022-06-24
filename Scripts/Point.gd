extends Node

class_name Point

var position = Vector2();
var prevPosition = Vector2();
var locked = bool();

func _init():
	position = Vector2(0,0);
	prevPosition = Vector2(0,0);
	locked = false;
	
func InitPoint(newPosition):
	position = newPosition;
	prevPosition = newPosition;
	
func ChangeLock(isLocked):
	locked = isLocked;
	
func Update(delta, downDir):
	if !locked:
		var positionBeforeUpdate = position;
		position += position - prevPosition;
		position += downDir * Player.GRAVITY * pow(delta, 2);
		prevPosition = positionBeforeUpdate;
