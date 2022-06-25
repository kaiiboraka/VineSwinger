import sys

playerSpeed, jumpHeight, jumpDist, jumpDistAtApex, jumpForce, timeTilApex, gravity = 0,0,0,0,0,0,0;

def GetHeight(g, t): # h
    return -.5 * g * pow(t, 2);

def GetGravity(h, t): # g
    return (-2 * h) / pow(t, 2);

def GetInitialVelocity(h, t): # v0
    return (2 * h) / t;

def GetTimeTilApex(Vx, Xh): # th
    return Xh / Vx;

#Tries to read in an input, or assigns it to the default otherwise
def GetValidInput(prompt, defaultVal):
    userInput = input("Enter the " + prompt + " (Press ENTER to skip): ");
    if(userInput != ""):
        return float(userInput);
    else:
        return defaultVal;

def PrintValues():
    print();
    print(f"playerSpeed:{playerSpeed}");
    print(f"jumpHeight:{jumpHeight}");
    print(f"jumpDist:{jumpDist}");
    print();
    print(f"To reach maximum height of {jumpHeight} and distance of {jumpDist}:");
    print(f"The force must be {jumpForce:.2f} with {gravity:.2f} gravity,");
    print(f"and will take {timeTilApex:.2f} seconds.");

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    defaultSpeed = 3;
    defaultHeight = 8;
    defaultDist = 5;
    try:
        playerSpeed = float(sys.argv[1]);
    except:
        playerSpeed = GetValidInput("moveSpeed", defaultSpeed);
    try:
        jumpHeight = float(sys.argv[2]);
    except:
        jumpHeight = GetValidInput("jumpHeight", defaultHeight);
    try:
        jumpDist = float(sys.argv[3]);
    except:
        jumpDist = GetValidInput("jumpDist", defaultDist);

    jumpDistAtApex = jumpDist / 2;
    timeTilApex = GetTimeTilApex(playerSpeed, jumpDistAtApex);
    gravity = GetGravity(jumpHeight, timeTilApex);
    jumpForce = GetInitialVelocity(jumpHeight, timeTilApex);

    PrintValues();
