/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class OffsetController;
@class PlayerDataController;
@class AuraController;
@class MacroController;
@class BlacklistController;
@class WaypointController;
@class MobController;
@class StatisticsController;
@class CombatProfileEditor;

@class Route;
@class Waypoint;
@class RouteSet;
@class WoWObject;
@class Position;

#define ReachedObjectNotification      @"ReachedObjectNotification"

// How close do we need to be to a node before we dismount?
#define DistanceUntilDismountByNode	4.5f

// how close do we need to be to a school to fish?
#define NODE_DISTANCE_UNTIL_FISH		17.0f

typedef enum MovementType {
	MovementType_Mouse		= 0,
	MovementType_Keyboard	= 1,
	MovementType_CTM		= 2,
} MovementType;

@interface MovementController : NSObject {
	
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet PlayerDataController	*playerData;
	IBOutlet AuraController			*auraController;
	IBOutlet MacroController		*macroController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet WaypointController		*waypointController;
	IBOutlet MobController			*mobController;
	IBOutlet StatisticsController	*statisticsController;
	IBOutlet CombatProfileEditor	*combatProfileEditor;
	
	IBOutlet NSTextField	*logOutStuckAttemptsTextField;
	IBOutlet NSPopUpButton	*movementTypePopUp;

	NSMutableDictionary *_stuckDictionary;
	
	NSString *_currentRouteKey;
	RouteSet *_currentRouteSet;			// current route set
	Waypoint *_destinationWaypoint;
	Route *_currentRoute;				// current route we're running
	
	int _movementState;
	
	WoWObject *_moveToObject;			// current object we're moving to
	
	BOOL _isMovingFromKeyboard;
	
	NSTimer *_movementTimer;			// this just checks to see if we reached our position!
	
	// stuck checking
	Position	*_lastAttemptedPosition;
	NSDate		*_lastAttemptedPositionTime;
	NSDate		*_lastDirectionCorrection;
	Position	*_lastPlayerPosition;
	int			_positionCheck;
	float		_lastDistanceToDestination;
	int			_stuckCounter;
	id			_unstickifyTarget;
	int			_unstickifyTry;
	
	NSDate *_movementExpiration;
	NSDate *_lastJumpTime;
	
	int _jumpCooldown;
	
	BOOL _movingUp;
	BOOL _afkPressForward;
	BOOL _lastCorrectionForward;
}

@property (readwrite, retain) RouteSet *currentRouteSet;

// move to an object (takes priority over a route)
- (BOOL)moveToObject: (WoWObject*)object;

// move to a position (I'd prefer we don't do this often, but it is sometimes needed :()
- (void)moveToPosition: (Position*)position;

// the object we're moving to
- (WoWObject*)moveToObject;

// reset the move to object and returns true on success
- (BOOL)resetMoveToObject;

// begin patrolling with this routeset
- (void)setPatrolRouteSet: (RouteSet*)route;

// stop all movement
- (void)stopMovement;

// resume movement if we stopped
- (void)resumeMovement;

// what type of movement are we operating in?  
- (int)movementType;

// turn toward the object
- (void)turnTowardObject:(WoWObject*)obj;

// dismount the player
- (BOOL)dismount;

// is the player currently moving?
- (BOOL)isMoving;

// jump
- (void)jump;

// are we currently patrolling?
- (BOOL)isPatrolling;

// reset our movement state
- (void)resetMovementState;

// just presses forward or backward
- (void)antiAFK;

// establish the player's position
- (void)establishPlayerPosition;

// for now
- (float)averageSpeed;
- (float)averageDistance;
- (BOOL)shouldJump;

@end
