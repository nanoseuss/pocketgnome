//
//  MovementController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

#import "MovementController.h"
#import "Controller.h"
#import "PlayerDataController.h"
#import "Position.h"
#import "MobController.h"
#import "BotController.h"
#import "CombatController.h"
#import "ChatController.h"

#import "WoWObject.h";

#import "Route.h"
#import "RouteSet.h"
#import "Waypoint.h"
#import "Action.h"

@interface MovementController ()
@property (readwrite, retain) Waypoint *destination;
@property (readwrite, retain) WoWObject *unit;
@property (readwrite, retain) NSDate *lastJumpTime;
@property (readwrite, retain) NSDate *lastDirectionCorrection;
@property (readwrite, retain) NSDate *movementExpiration;
@property (readwrite, retain) Position *lastSavedPosition;
@property (readwrite, assign) int jumpCooldown;
@property BOOL shouldAttack;
@property BOOL isPaused;
@property BOOL stopAtEnd;
@property BOOL shouldNotify;
@property int waypointDoneCount;
@end

@interface MovementController (Internal)
- (void)moveToPosition: (Position*)position;

- (void)finishAlt;
- (void)finishRoute;
- (void)resetMovementTimer;
- (void)moveToNextWaypoint;

- (void)moveForwardStart;
- (void)moveForwardStop;

- (void)moveBackwardStart;
- (void)moveBackwardStop;

- (void)correctDirection: (BOOL)force;
@end

@implementation MovementController

+ (void)initialize {
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool: YES],  @"MovementShouldJump",
                                   [NSNumber numberWithInt: 2],     @"MovementMinJumpTime",
                                   [NSNumber numberWithInt: 6],     @"MovementMaxJumpTime",
                                   nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.isMoving = NO;
        self.isPaused = NO;
        _route = nil;
        self.jumpCooldown = 3;
        self.lastJumpTime = [NSDate distantPast];
        self.lastDirectionCorrection = [NSDate distantPast];
        self.lastSavedPosition = nil;

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
    }
    return self;
}

- (void)awakeFromNib {
    self.shouldJump = [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue];
}

@synthesize isMoving = _isMoving;
@synthesize isPatrolling = _isPatrolling;
@synthesize destination = _destination;
@synthesize unit = _unit;

@synthesize shouldJump = _shouldJump;
@synthesize lastJumpTime = _lastJumpTime;
@synthesize jumpCooldown = _jumpCooldown;

@synthesize lastDirectionCorrection = _lastDirectionCorrection;
@synthesize shouldAttack = _shouldAttack;
@synthesize isPaused = _isPaused;
@synthesize lastSavedPosition;
@synthesize movementExpiration;
@synthesize waypointDoneCount = _waypointDoneCount;
@synthesize stopAtEnd = _stopAtEnd;

@synthesize shouldNotify = _notifyForObjectMove;


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if( [playerData playerIsValid] ) {
        [self resetMovementState];
    }
}

- (void)pauseMovement {
    
    // stop timers
    [self resetMovementTimer];
    
    if(!self.isPaused || (([playerData movementFlags] & 0x1) == 0x1)) {
        // stop movement if we haven't already
        PGLog(@"[Move] Pause movement.");
        [self moveForwardStop];
        
        self.isPaused = YES;
        usleep(100000);
    }
}

- (BOOL)shouldResume {
    
    if(self.isPaused || (([playerData movementFlags] & 0x1) == 0x0)) {
        if(self.unit)
            PGLog(@"[Move] Resume unit movement: %@", self.unit);
        else
            PGLog(@"[Move] Resume waypoint movement: %@", self.destination);
        
        self.isPaused = NO;
        return YES;
    }
    return NO;
}

- (void)resumeMovement {
    if([self shouldResume]) {
        // if we were moving to a unit, go there
        // otherwise, resume to the next waypoint
        [self moveToPosition: (self.unit ? [self.unit position] : [[self destination] position])];
    }
}

- (void)resumeMovementToNearestWaypoint {
    if([self shouldResume]) {
        Position *playerPosition = [playerData position];
        Waypoint *waypoint = [[self patrolRoute] waypointClosestToPosition: playerPosition];
        
        int newIndex = [[[self patrolRoute] waypoints] indexOfObject: waypoint];
        int oldIndex = [[[self patrolRoute] waypoints] indexOfObject: [self destination]];
        
        if(newIndex > oldIndex && (newIndex < (oldIndex + 10))) {
            // PGLog(@"[Move] Found new, closer waypoint.");
            [self moveToWaypoint: waypoint];
        } else {
            [self moveToWaypoint: [self destination]];
        }
    }
}

- (WoWObject*)moveToObject {
    return self.unit;
}

- (void)finishMovingToObject:(WoWObject*)unit {
    if(self.unit == unit) {
        self.unit = nil;
        self.shouldNotify = NO;
        PGLog(@"[Move] Finishing movement to %@", unit);
    }
}


#pragma mark -

- (void)beginPatrol: (unsigned)count andAttack: (BOOL)attack {
    Route *route = [self patrolRoute];
    if( !route ) return;

    if( [route waypointCount] > 0 ) {
        [combatController setCombatEnabled: attack];
        [self setIsPatrolling: YES];
        _patrolCount = count;
        self.shouldAttack = attack;
        
        // determine at which waypoint to start the patrol
        Waypoint *startWaypoint = nil;
        Position *playerPosition = [playerData position];
        float minDist = INFINITY, tempDist;
        for(Waypoint *waypoint in [route waypoints]) {
            tempDist = [playerPosition distanceToPosition: [waypoint position]];
            if( (tempDist < minDist) && (tempDist >= 0.0f)) {
                minDist = tempDist;
                startWaypoint = waypoint;
            }
        }
        
        // reset jump timer and head to the WP
        if(startWaypoint) {
            PGLog(@"[Move] Doing route: %@.", route);
            self.lastJumpTime = [NSDate date];
            [self moveToWaypoint: startWaypoint];
        } else {
            PGLog(@"[Move] StartWaypoint was nil. Ending route %@", route);
            [self resetMovementState];
            return;
        }
    } else {
        PGLog(@"[Move] %@ has no waypoints. Ending route.", route);
        [self resetMovementState];
        return;
    }
}

- (void)beginPatrolAndStopAtLastPoint {
    self.stopAtEnd = YES;
    [self beginPatrol: 1 andAttack: NO];
}

- (Route*)patrolRoute {
    return [[_route retain] autorelease];
}

- (void)setPatrolRoute: (Route*)route {
    [self resetMovementState];
    [_route autorelease];
    _route = [route retain];
    
    if(!_route) [combatController setCombatEnabled: NO];
}

- (void)moveToPosition: (Position*)position {
    [self resetMovementTimer];
    Position *playerPosition = [playerData position];
    float distance = [playerPosition distanceToPosition: position];

    if(!position || distance == INFINITY) { // sanity check
        PGLog(@"[Move] Invalid waypoint (distance: %f). Ending patrol.", distance);
        if(self.unit)   [self finishAlt];
        else            [self finishRoute];
        return;
    }
    
    if(!self.unit && (distance < ([playerData speedMax]/2.0f))) {
        //PGLog(@"[Move] Waypoint is too close. Moving to the next one.");
        [self moveToNextWaypoint];
        return;
    }
    
    self.lastSavedPosition = playerPosition;
    self.lastDirectionCorrection = [NSDate date];
    self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: (distance/[playerData speedMax]) + 4.0];
    
    if([useSmoothTurning state]) {
        if(!self.isMoving)  [self moveForwardStop];
        [self correctDirection: YES];
        if(!self.isMoving)  [self moveForwardStart];
    } else {
        [self moveForwardStop];
        [self correctDirection: YES];
        [self moveForwardStart];
    }
    
    _movementTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(checkCurrentPosition:) userInfo: nil repeats: YES];
}

- (void)moveToWaypoint: (Waypoint*)waypoint {
    [self setDestination: waypoint];
    [self moveToPosition: [waypoint position]];
}

- (void)moveToObject: (WoWObject*)unit andNotify: (BOOL)notify {
    //if(self.unit == unit) {
    //    return;
    //}
    
    if(unit && [unit isValid] && [unit conformsToProtocol: @protocol(UnitPosition)]) {
        if( ![self.unit isEqualToObject: unit]) {
            PGLog(@"[Move] Moving to: %@", unit);
            Position *position = [unit position];
            self.unit = unit;
            self.shouldNotify = notify;
            [self moveToPosition: position];
        } else {
            [self resumeMovement];
        }
    } else {
        // PGLog(@"Cannot move to invalid unit.");
        self.unit = nil;
        self.shouldNotify = NO;
    }
}

- (void)establishPosition {
    [self moveForwardStart];
    usleep(100000);
    [self moveForwardStop];
    usleep(30000);
}

- (void)backEstablishPosition {
    [self moveBackwardStart];
    usleep(100000);
    [self moveBackwardStop];
    usleep(30000);
}

#pragma mark -
#pragma mark Internal

- (void)finishAlt {
    id unit = self.unit;
    BOOL notify = self.shouldNotify;
    [self moveForwardStop];
    [self resetMovementTimer];
    [self finishMovingToObject: unit];
    
    PGLog(@"finishAlt: %@", unit);
    
    if(notify)
        [botController reachedUnit: unit];
}

- (void)finishRoute {
    Route *finishedRoute = [self patrolRoute];
    // stop our movement
    [self resetMovementState];
    
    PGLog(@"[Move] Finished Route: %@", finishedRoute);
    
    // send route finished notification
    [botController finishedRoute: finishedRoute];
}


- (void)realMoveToNextWaypoint {
    NSArray *waypoints = [[self patrolRoute] waypoints];
    if([self isPatrolling] && [self patrolRoute] && [waypoints count]) {
        
        int index = [waypoints indexOfObject: [self destination]];
        if(index != NSNotFound) {
            
            if(index == [waypoints count]-1) {   // if we're at the end, loop around
                if(self.stopAtEnd) {
                    [self finishRoute];
                    return;
                }
                index = 0;
            } else if(index < [[[self patrolRoute] waypoints] count]-1)
                index++;
            
            self.waypointDoneCount++;
            // check to see if we've hit our max WP
            if(_patrolCount && (self.waypointDoneCount > _patrolCount*[waypoints count]))   {
                PGLog(@"[Move] Patrol count expired. Ending patrol.");
                [self finishRoute];
            } else {
                // PGLog(@"moveToNextWaypoint");
                [self moveToWaypoint: [waypoints objectAtIndex: index]];
            }
        } else {
            PGLog(@"[Move] Waypoint not found. Ending route.");
            [self finishRoute];
        }
    } else {
        // otherwise just cancel all movement
        PGLog(@"[Move] Patrol route or waypoints invalid. Ending patrol.");
        [self finishRoute];
    }

}

- (void)moveToNextWaypoint {
    // check for waypoint-initiated actions
    if( [[self destination] action].type == ActionType_Delay ) {
        PGLog(@"[Move] Performing %.2f second delay at waypoint %d.", [[self destination] action].delay, [[[self patrolRoute] waypoints] indexOfObject: [self destination]]);
        [self pauseMovement];
        [self performSelector: @selector(realMoveToNextWaypoint)
                   withObject: nil
                   afterDelay: [[[self destination] action] delay]];
        return;
    } else {
        [self realMoveToNextWaypoint];
    }
}

- (void)jump {
    // correct direction
    [self correctDirection: YES];
    
    // update variables
    self.lastJumpTime = [NSDate date];
    int min = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMinJumpTime"] intValue];
    int max = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMaxJumpTime"] intValue];
    self.jumpCooldown = SSRandomIntBetween(min, max);
    //PGLog(@"Set jump cooldown to %d (between %d, and %d)", self.jumpCooldown, min, max);
    
    // jump!
    if(![controller isWoWChatBoxOpen]) {
        [chatController jump];
    }
}


- (void)checkCurrentPosition: (NSTimer*)timer {
    
    Position *playerPosition = [playerData position];
    Position *destPosition = (self.unit) ? [self.unit position] : [[self destination] position];

    float distance = [playerPosition distanceToPosition: destPosition];
    float distance2d = [playerPosition distanceToPosition2D: destPosition];
    
    // sanity check, incase something happens
    if(distance == INFINITY) {
        PGLog(@"[Move] Player distance == infinity. Stopping.");
        if(self.unit)   [self finishAlt];
        else            [self finishRoute];
        return;
    }
    
    // poll the bot controller
    if([botController isBotting]) {
        if( [self isPatrolling] && [botController evaluateSituation]) {
            // there was an action taken
            return;
        }
    }

// if we're near our target, move to the next
    float playerSpeed = [playerData speed];
    if(distance2d < playerSpeed/2.0)  {
        if(!self.unit) {
            if([botController isBotting]) {
                if([botController shouldProceedFromWaypoint: [self destination]]) {
                    [self moveToNextWaypoint];
                }
            } else {
                [self moveToNextWaypoint];
            }
        } else {
            // PGLog(@"We're close to the unit. Stopping movement.");
            [self finishAlt];
        }
        return;
    } else {
        // if we're far enough away from our target, see if we should jump
        if( (distance > playerSpeed) && (!self.unit)) {
            if( self.shouldJump && ([[NSDate date] timeIntervalSinceDate: self.lastJumpTime] > self.jumpCooldown) ) {
                [self jump];
            }
        } else {
            [self correctDirection: NO];
        }
    }
    
    // if we're not moving forward for some reason, start moving again
    if(!self.isPaused && (([playerData movementFlags] & 0x1) != 0x1)) {   // [self isPatrolling] && 
        // PGLog(@"We are stopped for some reason... starting again.");
        [self moveForwardStop];
        [self moveToPosition: (self.unit ? [self.unit position] : [[self destination] position])];
        return;
    }
    
}

#pragma mark -

- (void)resetMovementTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [_movementTimer invalidate]; _movementTimer = nil;
}

- (void)resetMovementState {
    [self moveForwardStop];
    [self resetMovementTimer];
    [self setDestination: nil];
    [self setIsPatrolling: NO];
    self.unit = nil;
    self.shouldNotify = NO;
    self.isPaused = NO;
    self.stopAtEnd = NO;
    _patrolCount = 0;
    self.waypointDoneCount = 0;
    self.shouldAttack = NO;
    self.lastSavedPosition = nil;
    self.movementExpiration = nil;
}

- (void)moveForwardStart {
    [self setIsMoving: YES];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveBackwardStart {
    [self setIsMoving: YES];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveForwardStop {
    [self setIsMoving: NO];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)moveBackwardStop {
    [self setIsMoving: NO];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)turnLeft: (BOOL)go {
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    if(go) {
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, TRUE);
        if(keyStroke) {
        CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    } else {
        // post another key down
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
            
            // then post key up, twice
            keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_LeftArrow, FALSE);
            if(keyStroke) {
                CGEventPostToPSN(&wowPSN, keyStroke);
                CGEventPostToPSN(&wowPSN, keyStroke);
                CFRelease(keyStroke);
            }
        }
    }
}

- (void)turnRight: (BOOL)go {
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    if(go) {
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    } else { 
        // post another key down
        CGEventRef keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, TRUE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
        
        // then post key up, twice
        keyStroke = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_RightArrow, FALSE);
        if(keyStroke) {
            CGEventPostToPSN(&wowPSN, keyStroke);
            CGEventPostToPSN(&wowPSN, keyStroke);
            CFRelease(keyStroke);
        }
    }
}

//#define StillTurnRadianPerSec   3.5f
//#define MovingTurnRadianPerSec  2.25f

#define OneDegree   0.0174532925

- (void)turnToward: (Position*)position {
    BOOL printTurnInfo = NO;
    if( ![controller isWoWFront] || ((GetCurrentButtonState() & 0x2) != 0x2) ) {  // don't change position if the right mouse button is down
        Position *playerPosition = [playerData position];
        if( [useSmoothTurning state] ) {
            // check player facing vs. unit position
            float playerDirection, savedDirection;
            playerDirection = savedDirection = [playerData directionFacing];
            float theAngle = [playerPosition angleTo: position];
    
            if(fabsf(theAngle - playerDirection) > M_PI) {
                if(theAngle < playerDirection)  theAngle += (M_PI*2);
                else                            playerDirection += (M_PI*2);
            }
            
            // find the difference between the angles
            float angleTo = (theAngle - playerDirection), absAngleTo = fabsf(angleTo);
            
            // tan(angle) = error / distance; error = distance * tan(angle);
            float speedMax = [playerData speedMax];
            float startDistance = [playerPosition distanceToPosition2D: position];
            float errorLimit = (startDistance < speedMax) ?  1.0f : (1.0f + ((startDistance-speedMax)/12.5f)); // (speedMax/3.0f);
            //([playerData speed] > 0) ? ([playerData speedMax]/4.0f) : ((startDistance < [playerData speedMax]) ? 1.0f : 2.0f);
            float errorStart = (absAngleTo < M_PI_2) ? (startDistance * sinf(absAngleTo)) : INFINITY;
            
            
            if( errorStart > (errorLimit) ) { // (fabsf(angleTo) > OneDegree*5) 
            
                // compensate for time taken for WoW to process keystrokes.
                // response time is directly proportional to WoW's refresh rate (FPS)
                // 2.25 rad/sec is an approximate turning speed
                float compensationFactor = ([controller refreshDelay]/2000000.0f) * 2.25f;
                
                if(printTurnInfo) PGLog(@"[Turn] ------");
                if(printTurnInfo) PGLog(@"[Turn] %.3f rad turn with %.2f error (lim %.2f) for distance %.2f.", absAngleTo, errorStart, errorLimit, startDistance);
                
                NSDate *date = [NSDate date];
                ( angleTo > 0) ? [self turnLeft: YES] : [self turnRight: YES];
                
                int delayCount = 0;
                float errorPrev = errorStart, errorNow;
                float lastDiff = angleTo, currDiff;
                
                
                while( delayCount < 2500 ) { // && (signbit(lastDiff) == signbit(currDiff))
                    
                    // get current values
                    Position *currPlayerPosition = [playerData position];
                    float currAngle = [currPlayerPosition angleTo: position];
                    float currPlayerDirection = [playerData directionFacing];
                    
                    // correct for looping around the circle
                    if(fabsf(currAngle - currPlayerDirection) > M_PI) {
                        if(currAngle < currPlayerDirection) currAngle += (M_PI*2);
                        else                                currPlayerDirection += (M_PI*2);
                    }
                    currDiff = (currAngle - currPlayerDirection);
                    
                    // get current diff and apply compensation factor
                    float modifiedDiff = fabsf(currDiff);
                    if(modifiedDiff > compensationFactor) modifiedDiff -= compensationFactor;
                    
                    float currentDistance = [currPlayerPosition distanceToPosition2D: position];
                    errorNow = (fabsf(currDiff) < M_PI_2) ? (currentDistance * sinf(modifiedDiff)) : INFINITY;
                    
                    if( (errorNow < errorLimit) ) {
                        if(printTurnInfo) PGLog(@"[Turn] [Range is Good] %.2f < %.2f", errorNow, errorLimit);
                        //PGLog(@"Expected additional movement: %.2f", currentDistance * sinf(0.035*2.25));
                        break;
                    }
                    
                    if( (delayCount > 250) ) {
                        if( (signbit(lastDiff) != signbit(currDiff)) ) {
                            if(printTurnInfo) PGLog(@"[Turn] [Sign Diff] %.3f vs. %.3f (Error: %.2f vs. %.2f)", lastDiff, currDiff, errorNow, errorPrev);
                            break;
                        }
                        if( (errorNow > (errorPrev + errorLimit)) ) {
                            if(printTurnInfo) PGLog(@"[Turn] [Error Growing] %.2f > %.2f", errorNow, errorPrev);
                            break;
                        }
                    }
                    
                    if(errorNow < errorPrev)
                        errorPrev = errorNow;
                        
                    lastDiff = currDiff;
                    
                    delayCount++;
                    usleep(1000);
                }
                
                ( angleTo > 0) ? [self turnLeft: NO] : [self turnRight: NO];
                
                float finalFacing = [playerData directionFacing];

                /*int j = 0;
                while(1) {
                    j++;
                    usleep(2000);
                    if(finalFacing != [playerData directionFacing]) {
                        float currentDistance = [[playerData position] distanceToPosition2D: position];
                        float diff = fabsf([playerData directionFacing] - finalFacing);
                        PGLog(@"[Turn] Stabalized at ~%d ms (wow delay: %d) with %.3f diff --> %.2f yards.", j*2, [controller refreshDelay], diff, currentDistance * sinf(diff) );
                        break;
                    }
                }*/
                
                // [playerData setDirectionFacing: newPlayerDirection];
                
                if(fabsf(finalFacing - savedDirection) > M_PI) {
                    if(finalFacing < savedDirection)    finalFacing += (M_PI*2);
                    else                                savedDirection += (M_PI*2);
                }
                float interval = -1*[date timeIntervalSinceNow], turnRad = fabsf(savedDirection - finalFacing);
                if(printTurnInfo) PGLog(@"[Turn] %.3f rad/sec (%.2f/%.2f) at pSpeed %.2f.", turnRad/interval, turnRad, interval, [playerData speed] );
                
            }
        } else {
            if(printTurnInfo) PGLog(@"Doing sharp turn to %.2f", [playerPosition angleTo: position]);
            [playerData faceToward: position];
            usleep([controller refreshDelay]);
        }
    } else {
        if(printTurnInfo) PGLog(@"Skipping turn because right mouse button is down.");
    }
    
}

- (void)correctDirection: (BOOL)force {
    if(force) {
        // every 2 seconds, we should cover around [playerData speedMax]*2
        // check to ensure that we've moved 1/4 of that
        // PGLog(@"Expiration in: %.2f seconds (%@).", [self.movementExpiration timeIntervalSinceNow], self.movementExpiration);
        if( self.movementExpiration && ([self.movementExpiration compare: [NSDate date]] == NSOrderedAscending) ) {
            PGLog(@"[Move] **** Movement timer expired!! ****");
            // if we can't reach the unit, just bail it
            if (self.unit) { 
                PGLog(@"[Move] ... Unable to reach unit %@; cancelling.", self.unit);
                [self finishAlt];
            } else {
                // move to the previous waypoint and try this again
                NSArray *waypoints = [[self patrolRoute] waypoints];
                int index = [waypoints indexOfObject: [self destination]];
                if(index != NSNotFound) {
                    if(index == 0) {
                        index = [waypoints count];
                    }
                    PGLog(@"[Move] ... Moving to prevous waypoint.");
                    [self moveToWaypoint: [waypoints objectAtIndex: index-1]];
                } else {
                    [self finishRoute];
                }
            }
            return;
        }
        
        // float timeSpan = [[NSDate date] timeIntervalSinceDate: self.lastDirectionCorrection];
        // if(distanceMoved > 0.01)
        //    PGLog(@"Moved %.2f yards in %.2f seconds.", distanceMoved, timeSpan);
        
        // update the direction we're facing
        Position *position = self.unit ? [self.unit position] : [self.destination position];
        [self turnToward: position];
                
        // find distance moved since last check
        Position *playerPosition = [playerData position];
        float distanceMoved = [playerPosition distanceToPosition2D: self.lastSavedPosition];
        self.lastSavedPosition = playerPosition;
        self.lastDirectionCorrection = [NSDate date];
        
        // update movement expiration if we are actually moving
        if(self.lastSavedPosition && (distanceMoved > ([playerData speedMax]/2.0)) ) {
            float secondsFromNow = ([playerPosition distanceToPosition: position]/[playerData speedMax]) + 4.0;
            self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: secondsFromNow];
            // PGLog(@"Movement expiration in %.2f seconds for %.2f yards.", secondsFromNow, [playerPosition distanceToPosition: position]);
        }
    } else {
        if( [[NSDate date] timeIntervalSinceDate: self.lastDirectionCorrection] > 2.0) {
            [self correctDirection: YES];
        }
    }
}

#pragma mark IB Actions

- (IBAction)prefsChanged: (id)sender {
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: self.shouldJump] forKey: @"MovementShouldJump"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

@end
