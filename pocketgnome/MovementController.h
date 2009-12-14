//
//  MovementController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/16/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "Position.h"
//#import "Route.h"
//#import "Waypoint.h"
//#import "Mob.h"

@class Mob;
@class Unit;
@class Route;
@class WoWObject;
@class Waypoint;
@class Position;

@class PlayerDataController;
@class OffsetController;
@class AuraController;
@class MacroController;
@class BlacklistController;

#define MobReachedNotification      @"MobReachedNotification"
//#define RouteFinishedNotification   @"RouteFinishedNotification"
// How close do we need to be to a node before we dismount?
#define NODE_DISTANCE_UNTIL_DISMOUNT	4.5f
// how close do we need to be to a school to fish?
#define NODE_DISTANCE_UNTIL_FISH		17.0f

@interface MovementController : NSObject {
    IBOutlet id controller;
    IBOutlet id mobController;
    IBOutlet id botController;
    IBOutlet id chatController;
    IBOutlet id combatController;
	IBOutlet AuraController			*auraController;
    IBOutlet PlayerDataController	*playerData;
	IBOutlet OffsetController		*offsetController;
    IBOutlet MacroController		*macroController;
	IBOutlet BlacklistController	*blacklistController;
	
	IBOutlet NSTextField	*logOutStuckAttemptsTextField;
	IBOutlet NSPopUpButton	*movementType;

    BOOL _shouldAttack;
    BOOL _shouldJump;
    BOOL _isMoving;
    BOOL _isPaused;
    BOOL _isPatrolling;
    BOOL _stopAtEnd;
    BOOL _notifyForObjectMove;
    int _patrolCount, _jumpCooldown, _waypointDoneCount;
	int _lastInteraction;
    NSDate *_lastJumpTime, *_lastDirectionCorrection, *movementExpiration;
    Position *lastSavedPosition;
    NSTimer *_movementTimer;
    Waypoint *_destination;
    Unit *_unit;
    Route *_route;
	
	// New error correction stuff
	int _movementChecks;							// This keeps track of the number of movement checks we have (every 0.1 second) to the same position (while attempting to moveToPosition)
													//	if this number gets too high (it tracks the number of attempts to hit one position), we can be sure we're stuck!
													//	for safe measure checkSpeedDistance checks the average speed and average distance traveled as well
	float _totalMovementSpeed, _totalDistance;
	Position *lastAttemptedPosition;				// Keeps track of the last position we tried to go to
	Position *lastPlayerPosition;					// Stores the last known player position (used in checkSpeedDistance to determine the average distance traveled)
	int _isStuck;									// Every time we're stuck this is incremented by 1
	int _unstickAttempt;							// Tracks how many times we've tried to "unstick" ourselves from the same spot!
	int _successfulMoves;							// How many times are we moving through our route correctly?
	Waypoint * _lastTriedWaypoint;
	float _averageSpeed;
	float _averageDistance;
	NSDate *_lastResumeCorrection;					// this is for when we start to fly too far away from our WP!
}

@property BOOL isMoving;
@property BOOL isPatrolling;
@property BOOL shouldJump;
@property (readonly) int movementType;
@property float averageSpeed;
@property float averageDistance;

- (void)resetMovementState;     // reset ALL movement state, completely
- (void)resetUnit;				// just sets the unit to nil

- (void)pauseMovement;
- (void)resumeMovement;
- (void)resumeMovementToNearestWaypoint;

- (WoWObject*)moveToObject;
- (void)finishMovingToObject: (WoWObject*)unit;

- (Route*)patrolRoute;
- (void)setPatrolRoute: (Route*)route;
- (void)beginPatrol: (unsigned)count andAttack: (BOOL)attack;
- (void)beginPatrolAndStopAtLastPoint;
- (void)establishPosition;
- (void)backEstablishPosition;

- (void)moveNearPosition: (Position*)position andCloseness: (float)closeness;
- (void)moveToObject: (WoWObject*)unit andNotify: (BOOL)notifyBotController;
- (void)moveToWaypoint: (Waypoint*)waypoint;

- (void)turnTowardObject: (WoWObject*)unit;

- (void)followObject: (WoWObject*)unit;

- (void)moveBackwardStop;
- (void)moveForwardStart;
- (void)moveForwardStop;

- (BOOL)useSmoothTurning;
- (BOOL)useClickToMove;

- (BOOL)dismount;		// dismount the player

// CTM
- (void)setClickToMove:(Position*)position andType:(UInt32)type andGUID:(UInt64)guid;

- (IBAction)prefsChanged: (id)sender;
@end
