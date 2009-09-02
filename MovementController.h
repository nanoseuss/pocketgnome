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

#define MobReachedNotification      @"MobReachedNotification"
//#define RouteFinishedNotification   @"RouteFinishedNotification"

@interface MovementController : NSObject {
    IBOutlet id controller;
    IBOutlet id mobController;
    IBOutlet id botController;
    IBOutlet id chatController;
    IBOutlet id combatController;
    IBOutlet PlayerDataController *playerData;
    
	IBOutlet NSPopUpButton *movementType;

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
	NSTimer *_movementTimer2;
}

@property BOOL isMoving;
@property BOOL isPatrolling;
@property BOOL shouldJump;

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

- (void)moveToObject: (WoWObject*)unit andNotify: (BOOL)notifyBotController;
- (void)moveToWaypoint: (Waypoint*)waypoint;

- (void)turnTowardObject: (WoWObject*)unit;

- (void)moveForwardStart;
- (void)moveForwardStop;

- (BOOL)useSmoothTurning;

- (IBAction)prefsChanged: (id)sender;
@end
