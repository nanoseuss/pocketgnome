//
//  MovementController2.m
//  Pocket Gnome
//
//  Created by Josh on 2/16/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MovementController.h"

#import "Player.h"
#import "Node.h"
#import "Unit.h"
#import "Route.h"
#import "RouteSet.h"
#import "RouteCollection.h"
#import "Mob.h"

#import "Controller.h"
#import "BotController.h"
#import "OffsetController.h"
#import "PlayerDataController.h"
#import "AuraController.h"
#import "MacroController.h"
#import "BlacklistController.h"
#import "WaypointController.h"
#import "MobController.h"
#import "StatisticsController.h"
#import "CombatProfileEditor.h"

#import "Action.h"
#import "Rule.h"

#import "Offsets.h"

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

@interface MovementController ()
@property (readwrite, retain) WoWObject *moveToObject;
@property (readwrite, retain) Waypoint *destinationWaypoint;
@property (readwrite, retain) NSString *currentRouteKey;
@property (readwrite, retain) Route *currentRoute;

@property (readwrite, retain) Position *lastAttemptedPosition;
@property (readwrite, retain) NSDate *lastAttemptedPositionTime;
@property (readwrite, retain) Position *lastPlayerPosition;

@property (readwrite, retain) NSDate *movementExpiration;
@property (readwrite, retain) NSDate *lastJumpTime;

@property (readwrite, retain) id unstickifyTarget;

@property (readwrite, retain) NSDate *lastDirectionCorrection;

@property (readwrite, assign) int jumpCooldown;
@end

@interface MovementController (Internal)

- (void)setClickToMove:(Position*)position andType:(UInt32)type andGUID:(UInt64)guid;

- (void)turnLeft: (BOOL)go;
- (void)turnRight: (BOOL)go;
- (void)moveForwardStart;
- (void)moveForwardStop;
- (void)moveUpStop;
- (void)moveUpStart;
- (void)backEstablishPosition;
- (void)establishPosition;

- (void)correctDirection: (BOOL)force;
- (void)turnToward: (Position*)position;

- (void)routeEnded;
- (void)performActions:(NSDictionary*)dict;

- (void)realMoveToNextWaypoint;

- (void)resetMovementTimer;

- (BOOL)isCTMActive;

- (void)turnTowardPosition: (Position*)position;

- (void)unStickify;

@end

@implementation MovementController

typedef enum MovementState{
	MovementState_Unit			= 0,
	MovementState_Backtrack		= 1,
	MovementState_Patrol		= 2,
}MovementState;

+ (void)initialize {
   
	/*NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool: YES],  @"MovementShouldJump",
                                   [NSNumber numberWithInt: 2],     @"MovementMinJumpTime",
                                   [NSNumber numberWithInt: 6],     @"MovementMaxJumpTime",
                                   nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];*/
}

- (id) init{
    self = [super init];
    if ( self != nil ) {
		
		_backtrack = [[NSMutableArray array] retain];
		_stuckDictionary = [[NSMutableDictionary dictionary] retain];
		
		_currentRouteSet = nil;
		_currentRouteKey = nil;
		
		_moveToObject = nil;
		_lastAttemptedPosition = nil;
		_destinationWaypoint = nil;
		_lastAttemptedPositionTime = nil;
		_lastPlayerPosition = nil;
		_movementTimer = nil;
		
		_movementState = -1;
		
		_isMovingFromKeyboard = NO;
		_positionCheck = 0;
		_lastDistanceToDestination = 0.0f;
		_stuckCounter = 0;
		_unstickifyTry = 0;
		_unstickifyTarget = nil;
		_jumpCooldown = 3;
		
		self.lastJumpTime = [NSDate distantPast];
		self.lastDirectionCorrection = [NSDate distantPast];
		
		_movingUp = NO;
		_afkPressForward = NO;
		_lastCorrectionForward = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
    }
    return self;
}

- (void) dealloc{
	[_backtrack release];
	[_stuckDictionary release];
	
    [super dealloc];
}

- (void)awakeFromNib {
   //self.shouldJump = [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue];
}

@synthesize currentRouteSet = _currentRouteSet;
@synthesize currentRouteKey = _currentRouteKey;
@synthesize currentRoute = _currentRoute;
@synthesize moveToObject = _moveToObject;
@synthesize destinationWaypoint = _destinationWaypoint;
@synthesize lastAttemptedPosition = _lastAttemptedPosition;
@synthesize lastAttemptedPositionTime = _lastAttemptedPositionTime;
@synthesize lastPlayerPosition = _lastPlayerPosition;
@synthesize unstickifyTarget = _unstickifyTarget;
@synthesize lastDirectionCorrection = _lastDirectionCorrection;
@synthesize movementExpiration = _movementExpiration;
@synthesize jumpCooldown = _jumpCooldown;
@synthesize lastJumpTime = _lastJumpTime;

// checks to see if the player is moving - duh!
- (BOOL)isMoving{
	
	UInt32 movementFlags = [playerData movementFlags];
	
	// moving forward or backward
	if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
		log(LOG_MOVEMENT, @"isMoving: Moving forward/backward");
		return YES;
	}
	
	// moving up or down
	else if ( movementFlags & MovementFlag_FlyUp || movementFlags & MovementFlag_FlyDown ){
		log(LOG_DEV, @"isMoving: Moving up/down");
		return YES;
	}
	
	// CTM active
	else if ( [self movementType] == MovementType_CTM  && [self isCTMActive] ){
		log(LOG_DEV, @"isMoving: CTM Active");
		return YES;
	}
	
	else if ( [playerData speed] > 0 ){
		log(LOG_DEV, @"isMoving: Speed > 0");
		return YES;
	}
	
	return NO;
}

- (BOOL)moveToObject: (WoWObject*)object{
	
	if ( !object || ![object isValid] ){
		[_moveToObject release]; _moveToObject = nil;
		return NO;
	}
	
	// save and move!
	self.moveToObject = object;
	[self moveToPosition:[object position]];
	
	if ( [self.moveToObject isKindOfClass:[Mob class]] || [self.moveToObject isKindOfClass:[Player class]] ){
		[self performSelector:@selector(stayWithObject:) withObject:self.moveToObject afterDelay:0.1f];
	}
	
	return YES;
}

// in case the object moves
- (void)stayWithObject:(WoWObject*)obj{
	
	if ( ![obj isValid] || obj != self.moveToObject ){
		return;
	}
	
	float distance = [self.lastAttemptedPosition distanceToPosition:[obj position]];
	
	if ( distance > 2.5f ){
		log(LOG_MOVEMENT, @"%@ moved away, re-positioning %0.2f", obj, distance);
		[self moveToObject:obj];
		return;
	}
	
	[self performSelector:@selector(stayWithObject:) withObject:self.moveToObject afterDelay:0.1f];
}

- (WoWObject*)moveToObject{
	return [[_moveToObject retain] autorelease];
}

- (BOOL)resetMoveToObject{
	if ( _moveToObject )
		return NO;
	
	self.moveToObject = nil;
	
	return YES;	
}

// being patrol
- (void)setPatrolRouteSet: (RouteSet*)route{
	log(LOG_MOVEMENT, @"Switching from route %@ to %@", _currentRouteSet, route);
	
	self.currentRouteSet = route;
	
	// player is dead
	if ( [playerData isGhost] || [playerData isDead] ){
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	}
	// normal route
	else{
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
	}
	
	// set our jump time
	self.lastJumpTime = [NSDate date];
}

- (void)stopMovement{
	
	log(LOG_MOVEMENT, @"Stop Movement...");
	
	// check to make sure we are even moving!
	UInt32 movementFlags = [playerData movementFlags];
	
	// player is moving
	if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
		log(LOG_MOVEMENT, @"Player is moving, stopping movement");
		[self resetMovementTimer];
		[self moveForwardStop];
	}
	
	else if ( movementFlags & MovementFlag_FlyUp || movementFlags & MovementFlag_FlyDown ){
		log(LOG_MOVEMENT, @"Player is flying, stopping movment");
		[self resetMovementTimer];
		[self moveUpStop];
	}
	else{
		log(LOG_MOVEMENT, @"Player is not moving! No reason to stop!? Flags: 0x%X", movementFlags);
	}
}

- (void)resumeMovement{
	
	log(LOG_MOVEMENT, @"resumeMovement:");
	
	// we're moving!
	if ( [self isMoving] ){
		
		log(LOG_MOVEMENT, @"We're already moving! Stopping before resume.");
	
		[self stopMovement];
		
		usleep( [controller refreshDelay] );
	}
	
	// moving to an object
	if ( _moveToObject ) {
		log(LOG_MOVEMENT, @"Moving to object.");
		[self moveToPosition:[self.moveToObject position]];
	}
	else if ( _currentRouteSet ){
		
		// we need to backtrack (we probably chased down a unit or something)
		if ( [_backtrack count] ){
			log(LOG_MOVEMENT, @"Backtracking to our route!");
		}
		// previous waypoint to move to
		else if ( self.destinationWaypoint ){
			
			// check for patrol procedure before we move (thanks slipknot)
			if ( ![botController performPatrolProcedure] ) {
				log(LOG_MOVEMENT, @"Performing patrol procedure before resuming.");
				return;
			}
			
			log(LOG_MOVEMENT, @"Moving to WP: %@", self.destinationWaypoint);
			[self moveToPosition:[self.destinationWaypoint position]];
		}
		// find the closest waypoint
		else{
			
			log(LOG_MOVEMENT, @"Finding the closest waypoint");
			
			Position *playerPosition = [playerData position];
			
			Waypoint *newWP = nil;
			
			// if the player is dead, find the closest WP based on both routes
			if ( [playerData isDead] ){
				
				// we switched to a corpse route on death
				if ( [[self.currentRoute waypoints] count] == 0 ){
					log(LOG_GHOST, @"Unable to resume, we're dead and there is no corpse route!");
					return;
				}
				
				Waypoint *closestWaypointCorpseRoute	= [[self.currentRouteSet routeForKey:CorpseRunRoute] waypointClosestToPosition:playerPosition];
				Waypoint *closestWaypointPrimaryRoute	= [[self.currentRouteSet routeForKey:PrimaryRoute] waypointClosestToPosition:playerPosition];
				
				float corpseDistance = [playerPosition distanceToPosition:[closestWaypointCorpseRoute position]];
				float primaryDistance = [playerPosition distanceToPosition:[closestWaypointPrimaryRoute position]];
				
				// use corpse route
				if ( corpseDistance < primaryDistance ){
					self.currentRouteKey = CorpseRunRoute;
					self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
					newWP = closestWaypointCorpseRoute;
				}
				// use primary route
				else {
					self.currentRouteKey = PrimaryRoute;
					self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
					newWP = closestWaypointPrimaryRoute;
				}
			}
			else{
				// find the closest waypoint in our primary route!
				newWP = [self.currentRoute waypointClosestToPosition:playerPosition];
			}
			
			// we have a waypoint to move to!
			if ( newWP ) {
				log(LOG_MOVEMENT, @"Found waypoint %@ to move to", newWP);
				self.destinationWaypoint = newWP;
				
				// check for patrol procedure before we move (thanks slipknot)
				if ( ![botController performPatrolProcedure] ){
					log(LOG_MOVEMENT, @"Performing patrol procedure before resuming.");
					return;
				}
				
				[self moveToPosition:[newWP position]];
			}
			else{
				log(LOG_ERROR, @"Unable to find a position to resume movement to!");
			}
		}
	}
	else{
		log(LOG_ERROR, @"We have no route or unit to move to!");
	}
}

- (int)movementType{
	return [movementTypePopUp selectedTag];
}

#pragma mark Waypoints

- (void)moveToWaypoint: (Waypoint*)waypoint {
	
	log(LOG_WAYPOINT, @"Moving to a waypoint: %@", waypoint);
	
	[_destinationWaypoint release];
	_destinationWaypoint = [waypoint retain];
	
	[self moveToPosition:[waypoint position]];
	
}

- (void)moveToNextWaypoint{
	
	// do we have an action for the destination we just reached?
	NSArray *actions = [self.destinationWaypoint actions];
	if ( actions && [actions count] > 0 ) {

		// check if conditions are met
		Rule *rule = [self.destinationWaypoint rule];
		if ( rule == nil || [botController evaluateRule: rule withTarget: TargetNone asTest: NO] ){
			
			// reset our timer
			[self resetMovementTimer];
			
			log(LOG_WAYPOINT, @"Performing %d actions", [actions count] );
			
			// time to perform actions!
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  actions,						@"Actions",
								  [NSNumber numberWithInt:0],	@"CurrentAction",
								  nil];
			
			[self performActions:dict];
			
			return;
		}
	}
	
	[self realMoveToNextWaypoint];	
}

- (void)realMoveToNextWaypoint{
	
	log(LOG_WAYPOINT, @"Moving to the next waypoint!");
	
	NSArray *waypoints = [self.currentRoute waypoints];
	int index = [waypoints indexOfObject:self.destinationWaypoint];
	
	// we have an index! yay!
	if ( index != NSNotFound ){
		
		// at the end of the route
		if ( index == [waypoints count] - 1 ){
			log(LOG_WAYPOINT, @"We've reached the end of the route!");

			[self routeEnded];
			return;
		}
		
		// move to the next WP
		else if ( index < [waypoints count] - 1 ){
			index++;
		}
		
		// increment something here to keep track of how many waypoints we've moved to?
		
		self.destinationWaypoint = [waypoints objectAtIndex:index];
		log(LOG_WAYPOINT, @"Moving to next waypoint of %@ with index %d", self.destinationWaypoint, index);
		[self moveToPosition:[self.destinationWaypoint position]];
	}
	else{
		log(LOG_ERROR, @"There are no waypoints for the current route!");
	}
}

- (void)routeEnded{
	
	//NSArray *currentWaypoints = [self.currentRoute waypoints];
	//Waypoint *curWP = [currentWaypoints indexOfObject:self.destinationWaypoint];
	
	// we've reached the end of our corpse route, lets switch to our main route
	if ( self.currentRouteKey == CorpseRunRoute ){
		
		log(LOG_GHOST, @"Switching from corpse to primary route!");
		
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
		
		// find the closest WP
	}
	
	//[self.currentRoute waypointClosestToPosition:playerPosition]

	// use the first WP	
	self.destinationWaypoint = [[self.currentRoute waypoints] objectAtIndex:0];
	
	[self resumeMovement];
}

#pragma mark Actual Movement Shit - Scary

- (void)moveToPosition: (Position*)position {
	
	[botController jumpIfAirMountOnGround];

	// reset our timer (that checks if we're at the position)
	[self resetMovementTimer];
	
    Position *playerPosition = [playerData position];
    float distance = [playerPosition distanceToPosition: position];
	
	// sanity check
    if ( !position || distance == INFINITY ) {
        log(LOG_MOVEMENT, @"Invalid waypoint (distance: %f). Ending patrol.", distance);

		// we should do sometihng here! finish route!
        return;
    }
	
	// no object, no actions, just trying to move to the next WP!
	if ( !_moveToObject && ![_destinationWaypoint actions] && distance < [playerData speedMax] / 2.0f ){
		log(LOG_MOVEMENT, @"Waypoint is too close %0.2f < %0.2f. Moving to the next one.", distance, [playerData speedMax] / 2.0f );
        [self moveToNextWaypoint];
        return;
	}
	
	// we're moving to a new position!
	if ( ![_lastAttemptedPosition isEqual:position] ) {
		log(LOG_MOVEMENT, @"Moving to a new position! From %@ to %@ Timer will expire in %0.2f", _lastPlayerPosition, position, (distance/[playerData speedMax]) + 4.0);
	}
	
	// only reset the stuck counter if we're going to a new position
	if ( ![position isEqual:self.lastAttemptedPosition] ) {
//		log(LOG_MOVEMENT, @"Resetting stuck counter");
		_stuckCounter					= 0;
	}
	
	self.lastAttemptedPosition		= position;
	self.lastAttemptedPositionTime	= [NSDate date];
	self.lastPlayerPosition			= playerPosition;
	_positionCheck					= 0;
	_lastDistanceToDestination		= 0.0f;
	
	//self.lastSavedPosition = playerPosition;
	//self.lastDirectionCorrection = [NSDate date];
    self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: (distance/[playerData speedMax]) + 4.0];
	
	// actually move!
	if ( [self movementType] == MovementType_Keyboard ){
		UInt32 movementFlags = [playerData movementFlags];
		if ( !(movementFlags & MovementFlag_Forward) ) [self moveForwardStop];
        [self correctDirection: YES];
        if ( !(movementFlags & MovementFlag_Forward) )  [self moveForwardStart];
	}
	else if ( [self movementType] == MovementType_Mouse ){
		[self moveForwardStop];
		[self correctDirection: YES];
		[self moveForwardStart];
	}
	else if ( [self movementType] == MovementType_CTM ) {
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}
	
	_movementTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(checkCurrentPosition:) userInfo: nil repeats: YES];
}

- (void)checkCurrentPosition: (NSTimer*)timer {
	
	// stopped botting?  end!
	if ( ![botController isBotting] ) {
		log(LOG_MOVEMENT, @"We're not botting, stop the timer!");
		[self resetMovementState];
		return;
	}
	
	_positionCheck++;

	if (_stuckCounter > 0) log(LOG_MOVEMENT, @"[%d] Check current position.  Stuck counter: %d", _positionCheck, _stuckCounter);

	BOOL isPlayerOnGround = [playerData isOnGround];
	Position *playerPosition = [playerData position];
	float playerSpeed = [playerData speed];
    Position *destPosition = ( _moveToObject ) ? [_moveToObject position] : [_destinationWaypoint position];
	
	float distanceToDestination = [playerPosition distanceToPosition: destPosition];
	//float distanceToDestination2D = [playerPosition distanceToPosition2D: destPosition];
	
    // sanity check, incase something happens
    if ( distanceToDestination == INFINITY ) {
        log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
		
		[self resetMovementTimer];

		// do something here
        return;
    }
	
	// evaluate situation - should we do something?
	if ( [botController isBotting] && !self.moveToObject ){
		if ( [botController evaluateSituation] ){
			// don't need to reset our movement timer b/c it will be done when we're told to move somewhere else!
			log(LOG_MOVEMENT, @"Action taken, not checking movement");
			return;
		}
	}
	
	// check to see if we're near our target
	float distanceToObject = 5.0f;			// this used to be (playerSpeed/2.0)
											//	when on mount:	7.0
											//  when on ground: 3.78
	
	BOOL isNode = [self.moveToObject isKindOfClass: [Node class]];
	if ( isNode && !isPlayerOnGround ){
		distanceToObject = DistanceUntilDismountByNode;
	}
	
	// we've reached our position!
	if ( distanceToDestination <= distanceToObject ){
		
		log(LOG_MOVEMENT, @"Reached our destination! %0.2f < %0.2f", distanceToDestination, distanceToObject);
		
		// moving to a unit
		if ( self.moveToObject ){
			
			id object = [self.moveToObject retain];
			
			// get rid of our move to object!
			self.moveToObject = nil;
			
			// stop this timer
			[self resetMovementTimer];
			
			// stop movement
			[self stopMovement];
			
			log(LOG_MOVEMENT, @"Reached our object %@", object);
			
			// we've reached the unit! Send a notification
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedObjectNotification object: object];
			
			return;
		}
		
		// moving to a waypoint
		else if ( self.destinationWaypoint ){
			
			log(LOG_MOVEMENT, @"Reached waypoint %@", self.destinationWaypoint);
			
			BOOL continueRoute = YES;
			
			// we could be told to move by a UI click, so make sure we're botting to perform a patrol proc
			if ( ![botController isBotting] || ![botController performPatrolProcedure] ){
				continueRoute = NO;
				log(LOG_MOVEMENT, @"Not continuing route! We have to do something or we're not botting anymore!");
			}
			
			if ( continueRoute ){
				[self moveToNextWaypoint];
				return;
			}	
		}
		// umm wut?
		else{
			log(LOG_ERROR, @"Somehow we're not able to get to our waypoint!?");
		}
	}
	
	// should we jump?
	//log(LOG_MOVEMENT, @" %0.2f > %0.2f %d", distanceToDestination, (playerSpeed * 1.5f), [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue]);
	if ( ( distanceToDestination > (playerSpeed * 1.5f) ) && [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue] ){
		
		if ( ([[NSDate date] timeIntervalSinceDate: self.lastJumpTime] > self.jumpCooldown ) ){
			[self jump];
		}
	}
	else {
		[self correctDirection: NO];
	}
	
	// *******************************************************
	// if we we get here, we're not close enough :(
	// *******************************************************
	
	// make sure we're still moving
	if ( _positionCheck > 3 && _stuckCounter < 3 && ![self isMoving] ){
		log(LOG_MOVEMENT, @"For some reason we're not moving! Let's start moving again!");
		
		[self resumeMovement];
		
		_stuckCounter++;
		return;
	}
	
	// *******************************************************
	// stuck checking
	// *******************************************************
	
	// copy the old stuck counter
	int oldStuckCounter = _stuckCounter;
	
	// we're stuck?
	if ( _stuckCounter > 3 ){
		// stop this timer
		[self resetMovementTimer];
		
		[controller setCurrentStatus: @"Bot: Stuck, entering anti-stuck routine"];
		
		log(LOG_MOVEMENT, @"Player is stuck, trying anti-stuck routine");
		
		[self unStickify];
		
		return;
	}
	
	// check to see if we are stuck
	if ( _positionCheck > 5 ) {
		float maxSpeed = [playerData speedMax];
		float distanceTraveled = [self.lastPlayerPosition distanceToPosition:playerPosition];
		
		log(LOG_DEV, @" Checking speed: %0.2f <= %.02f  (max: %0.2f)", playerSpeed, (maxSpeed/10.0f), maxSpeed );
		log(LOG_DEV, @" Checking distance: %0.2f <= %0.2f", distanceTraveled, (maxSpeed/10.0f)/5.0f);
		
		// distance + speed check
		if ( distanceTraveled <= (maxSpeed/10.0f)/5.0f || playerSpeed <= maxSpeed/10.0f ){
			_stuckCounter++;
		}
		
		self.lastPlayerPosition = playerPosition;
	}
	
	// reset if stuck didn't change!
	if ( _positionCheck > 13 && oldStuckCounter == _stuckCounter ){
		_stuckCounter = 0;
	}
	
	// are we stuck moving up?
	UInt32 movementFlags = [playerData movementFlags];
	if ( movementFlags & MovementFlag_FlyUp && !_movingUp ){
		log(LOG_MOVEMENT, @"We're stuck moving up! Fixing!");
		[self moveUpStop];
		
		[self resumeMovement];
		return;
	}
	
	// TO DO: moving in the wrong direction check? (can sometimes happen when doing mouse movements based on the speed of the machine)
}

- (void)unStickify{
	
	// *************************************************
	// Check for alarm/log out
	// *************************************************
	
	// should we play an alarm?
	if ( [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnStuck"] boolValue] ){
		int stuckThreshold = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"AlarmOnStuckAttempts"] intValue];
		if ( _unstickifyTry > stuckThreshold ){
			log(LOG_MOVEMENT, @"We're stuck, playing an alarm!");
			[[NSSound soundNamed: @"alarm"] play];
		}
	}
	
	// check to see if we should log out!
	if ( [[botController logOutAfterStuckCheckbox] state] ){
		int stuckTries = [logOutStuckAttemptsTextField intValue];
		
		if ( _unstickifyTry > stuckTries ){
			log(LOG_MOVEMENT, @"We're stuck, closing wow!");
			[botController logOut];
			[controller setCurrentStatus: @"Bot: Logged out due to being stuck"];
			return;
		}
	}
	
	// set our stuck counter to 0!
	_stuckCounter = 0;
	
	// is this a new attempt?
	id lastTarget = [self.unstickifyTarget retain];
	
	// what is our new "target" we are trying to reach?
	if ( self.moveToObject )
		self.unstickifyTarget = self.moveToObject;
	else
		self.unstickifyTarget = self.destinationWaypoint;
	
	// reset our counter
	if ( self.unstickifyTarget != lastTarget ){
		_unstickifyTry = 0;
	}
	_unstickifyTry++;
	[lastTarget release];
	
	log(LOG_MOVEMENT, @"Entering anti-stuck procedure! Try %d", _unstickifyTry);
	
	// anti-stuck for moving to an object!
	if ( self.moveToObject ){
		
		// blacklist unit after 5 tries!
		if ( _unstickifyTry > 5 ){
			
			log(LOG_MOVEMENT, @"Unable to reach %@, blacklisting", self.moveToObject);
			
			[blacklistController blacklistObject:self.moveToObject withReason:Reason_CantReachObject];
			
			self.moveToObject = nil;
			
			[self resumeMovement];
			
			return;			
		}
		
		// player is flying and is stuck :(  makes me sad, lets move up a bit
		if ( [[playerData player] isFlyingMounted] ){
			
			log(LOG_MOVEMENT, @"Moving up since we're flying mounted!");
			
			// move up for 1 second!
			[self moveUpStop];
			[self moveUpStart];
			[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:1.0f];
			[self performSelector:@selector(resumeMovement) withObject:nil afterDelay:1.1f];
			return;
		}
		
		log(LOG_MOVEMENT, @"Moving to an object + stuck and not flying?  shux");
		[self resumeMovement];
	}
	
	// can't reach a waypoint :(
	else if ( self.destinationWaypoint ){
		
		// player is flying and is stuck :(  makes me sad, lets move up a bit
		if ( [[playerData player] isFlyingMounted] && _unstickifyTry < 5 ) {
			
			log(LOG_MOVEMENT, @"Moving up since we're flying mounted!");
			
			// move up for 1 second!
			[self moveUpStop];
			[self moveUpStart];
			[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:1.0f];
			[self performSelector:@selector(resumeMovement) withObject:nil afterDelay:1.1f];
			return;
		}
		
		if ( _unstickifyTry > 5 ){
			
			// move to the previous waypoint and try this again
			NSArray *waypoints = [[self currentRoute] waypoints];
			int index = [waypoints indexOfObject: [self destinationWaypoint]];
			if ( index != NSNotFound ){
				if ( index == 0 ) {
					index = [waypoints count];
				}
				log(LOG_MOVEMENT, @"Moving to prevous waypoint.");
				[self moveToWaypoint: [waypoints objectAtIndex: index-1]];
			}
			else{
				log(LOG_MOVEMENT, @"Trying to move to a previous WP, previously we would finish the route");
			}
			
		}
		
		[self resumeMovement];
	}
}

- (BOOL)checkUnitOutOfRange: (Unit*)target {
	// This is intended for issues like runners, a chance to correct vs blacklist
	// Hopefully this will help to avoid bad blacklisting which comes AFTER the cast
	// returns true if the mob is good to go
	
	if (!target || target == nil) return YES;

	// only do this for hostiles
	if (![playerData isHostileWithFaction: [target factionTemplate]]) return YES;

	// If the mob is in our attack range return true
	float distanceToTarget = [[(PlayerDataController*)playerData position] distanceToPosition: [target position]];
	if ( distanceToTarget <= botController.theCombatProfile.attackRange) return YES;

	log(LOG_MOVEMENT, @"%@ has gone out of range: %@", target, distanceToTarget);
		
	// If they're just a lil out of range lets inch up
	float moveForwardRange = 5.0;
	if ( distanceToTarget < (botController.theCombatProfile.attackRange + moveForwardRange) && ![self isMoving]) {
		log(LOG_MOVEMENT, @"Unit is still close, inching forward.");
		// Face the target
		[playerData faceToward: [target position]];
		usleep([controller refreshDelay]);
		// Move, Jump, Stop
		[self moveForwardStart];
		usleep(10000);
		[self jump];
		[self moveForwardStop];
			
		// Now check again to see if they're in range
        usleep(100000);
		float distanceToTarget = [[(PlayerDataController*)playerData position] distanceToPosition: [target position]];
		if ( distanceToTarget > botController.theCombatProfile.attackRange) {
			log(LOG_MOVEMENT, @"Still out of range: %@, giving up.", target, distanceToTarget);
			return NO;
		}
	}
	// They're running and they're nothing we can do about it
	log(LOG_MOVEMENT, @"Target: %@ has gone out of range: %@", target, distanceToTarget);
    return NO;
}
- (void)resetMovementState{
	
	log(LOG_MOVEMENT, @"Resetting movement state");
	
	if ( [self isMoving] ){
		log(LOG_MOVEMENT, @"Stopping movement!");
		[self stopMovement];
		[self setClickToMove:nil andType:ctmIdle andGUID:0x0];
	}
	
	/*self.currentRoute				= nil;
	self.currentRouteSet			= nil;
	self.currentRouteKey			= nil;*/
	self.moveToObject				= nil;
	self.destinationWaypoint		= nil;
	self.lastAttemptedPosition		= nil;
	self.lastAttemptedPositionTime	= nil;
	self.lastPlayerPosition			= nil;
	_isMovingFromKeyboard			= NO;
	[_stuckDictionary removeAllObjects];
	
	_unstickifyTry = 0;
	_stuckCounter = 0;
	
	[self resetMovementTimer];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
}

#pragma mark -

- (void)resetMovementTimer{
	
	//[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(realMoveToNextWaypoint) object: nil];
    [_movementTimer invalidate]; _movementTimer = nil;
}

- (void)correctDirection: (BOOL)force{
	
	if ( self.moveToObject ){
		[self turnTowardObject:self.moveToObject];
	}
	else{
		[self turnToward: [self.destinationWaypoint position]];
	}
	
	return;
	/*
	
    if ( force ){
		
        // every 2 seconds, we should cover around [playerData speedMax]*2
        // check to ensure that we've moved 1/4 of that
        // log(LOG_MOVEMENT, @"Expiration in: %.2f seconds (%@).", [self.movementExpiration timeIntervalSinceNow], self.movementExpiration);
        if( self.movementExpiration && ([self.movementExpiration compare: [NSDate date]] == NSOrderedAscending) ) {
            log(LOG_MOVEMENT, @"[Move] **** Movement timer expired!! ****");
            
			// if we can't reach the unit, just bail it
            if ( self.moveToObject ){ 
                log(LOG_MOVEMENT, @"[Move] ... Unable to reach unit %@; cancelling.", self.unit);
  
				//TO DO: BLACKLIST THE UNIT??? FIRE A NOTIFICATION?
				self.moveToObject = nil;
				[self resumeMovement];
				return;
            }
			// trying to get to
			else {
                // move to the previous waypoint and try this again
                NSArray *waypoints = [[self patrolRoute] waypoints];
                int index = [waypoints indexOfObject: [self destination]];
                if(index != NSNotFound) {
                    if(index == 0) {
                        index = [waypoints count];
                    }
                    log(LOG_MOVEMENT, @"[Move] ... Moving to prevous waypoint.");
                    [self moveToWaypoint: [waypoints objectAtIndex: index-1]];
                } else {
                    [self finishRoute];
                }
            }
            return;
        }
        
        // float timeSpan = [[NSDate date] timeIntervalSinceDate: self.lastDirectionCorrection];
        // if(distanceMoved > 0.01)
        //    log(LOG_MOVEMENT, @"Moved %.2f yards in %.2f seconds.", distanceMoved, timeSpan);
        
        // update the direction we're facing
		Position *position = self.moveToObject ? [self.moveToObject position] : [self.destination position];
		if ( self.moveToObject ){
			[self turnTowardObject:self.moveToObject];
		}
		else{
			[self turnToward: position];
		}
		
        // find distance moved since last check
        Position *playerPosition = [playerData position];
        float distanceMoved = [playerPosition distanceToPosition2D: self.lastSavedPosition];
        self.lastSavedPosition = playerPosition;
        self.lastDirectionCorrection = [NSDate date];
        
        // update movement expiration if we are actually moving
        if(self.lastSavedPosition && (distanceMoved > ([playerData speedMax]/2.0)) ) {
            float secondsFromNow = ([playerPosition distanceToPosition: position]/[playerData speedMax]) + 4.0;
            self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: secondsFromNow];
            //log(LOG_MOVEMENT, @"Movement expiration in %.2f seconds for %.2f yards.", secondsFromNow, [playerPosition distanceToPosition: position]);
        }
    } else {
        if( [[NSDate date] timeIntervalSinceDate: self.lastDirectionCorrection] > 2.0) {
            [self correctDirection: YES];
        }
    }*/
}

- (void)turnToward: (Position*)position{
	
	/*if ( [movementType selectedTag] == MOVE_CTM ){
	 log(LOG_MOVEMENT, @"[Move] In theory we should never be here!");
	 return;
	 }*/
	
    BOOL printTurnInfo = NO;
	
	// don't change position if the right mouse button is down
    if ( ![controller isWoWFront] || ( ( GetCurrentButtonState() & 0x2 ) != 0x2 ) ) {
        Position *playerPosition = [playerData position];
        if ( [self movementType] == MovementType_Keyboard ){
			
            // check player facing vs. unit position
            float playerDirection, savedDirection;
            playerDirection = savedDirection = [playerData directionFacing];
            float theAngle = [playerPosition angleTo: position];
			
            if ( fabsf(theAngle - playerDirection) > M_PI ){
                if ( theAngle < playerDirection )	theAngle += (M_PI*2);
                else								playerDirection += (M_PI*2);
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
                
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] ------");
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad turn with %.2f error (lim %.2f) for distance %.2f.", absAngleTo, errorStart, errorLimit, startDistance);
                
                NSDate *date = [NSDate date];
                ( angleTo > 0) ? [self turnLeft: YES] : [self turnRight: YES];
                
                int delayCount = 0;
                float errorPrev = errorStart, errorNow;
                float lastDiff = angleTo, currDiff;
                
                
                while ( delayCount < 2500 ) { // && (signbit(lastDiff) == signbit(currDiff))
                    
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
                        if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Range is Good] %.2f < %.2f", errorNow, errorLimit);
                        //log(LOG_MOVEMENT, @"Expected additional movement: %.2f", currentDistance * sinf(0.035*2.25));
                        break;
                    }
                    
                    if( (delayCount > 250) ) {
                        if( (signbit(lastDiff) != signbit(currDiff)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Sign Diff] %.3f vs. %.3f (Error: %.2f vs. %.2f)", lastDiff, currDiff, errorNow, errorPrev);
                            break;
                        }
                        if( (errorNow > (errorPrev + errorLimit)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Error Growing] %.2f > %.2f", errorNow, errorPrev);
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
				 log(LOG_MOVEMENT, @"[Turn] Stabalized at ~%d ms (wow delay: %d) with %.3f diff --> %.2f yards.", j*2, [controller refreshDelay], diff, currentDistance * sinf(diff) );
				 break;
				 }
				 }*/
                
                // [playerData setDirectionFacing: newPlayerDirection];
                
                if(fabsf(finalFacing - savedDirection) > M_PI) {
                    if(finalFacing < savedDirection)    finalFacing += (M_PI*2);
                    else                                savedDirection += (M_PI*2);
                }
                float interval = -1*[date timeIntervalSinceNow], turnRad = fabsf(savedDirection - finalFacing);
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad/sec (%.2f/%.2f) at pSpeed %.2f.", turnRad/interval, turnRad, interval, [playerData speed] );
                
            }
        }
		else{
            if ( printTurnInfo ) log(LOG_MOVEMENT, @"DOING SHARP TURN to %.2f", [playerPosition angleTo: position]);
            [playerData faceToward: position];
            usleep([controller refreshDelay]*2);
        }
    } else {
        if(printTurnInfo) log(LOG_MOVEMENT, @"Skipping turn because right mouse button is down.");
    }
    
}


#pragma mark Notifications

- (void)playerHasDied:(NSNotification *)aNotification{
	
	// reset our movement state!
	[self resetMovementState];
	
	// do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ){
		return;
	}
	
	// do nothing if they're PvPing
	if ( [botController isPvPing] || [playerData isInBG:[playerData zone]] ){
		log(LOG_MOVEMENT, @"[Move] Ignoring corpse route because we're PvPing!");
		return;
	}
	
	// switch back to starting route?
	if ( [botController.theRouteCollection startRouteOnDeath] ){
		self.currentRouteKey = CorpseRunRoute;
		self.currentRouteSet = [botController.theRouteCollection startingRoute];
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
		log(LOG_MOVEMENT, @"[Move] Died, switching to main starting route! %@", self.currentRoute);
	}
	// be normal!
	else{
		log(LOG_MOVEMENT, @"[Move] Died, switching to corpse route");
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	}
	
	if ( self.currentRoute && [[self.currentRoute waypoints] count] == 0  ){
		log(LOG_MOVEMENT, @"[Move] No corpse route! Ending movement");
		[self stopMovement];
	}
}

- (void)playerHasRevived:(NSNotification *)aNotification{
	
	// do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ){
		return;
	}
	
	// reset movement state
	[self resetMovementState];
	
	// switch our route!
	self.currentRouteKey = PrimaryRoute;
	self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
	
	log(LOG_MOVEMENT, @"[Move] Player revived, switching to %@", self.currentRoute);
	
	if ( self.currentRoute ){
		[self resumeMovement];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    /*if( [playerData playerIsValid:self] ) {
        [self resetMovementState];
    }*/
}

#pragma mark Keyboard Movements

- (void)moveForwardStart{
    _isMovingFromKeyboard = YES;
	
	log(LOG_MOVEMENT, @"moveForwardStart");
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_UpArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveBackwardStart {
    _isMovingFromKeyboard = YES;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveUpStart {
	_isMovingFromKeyboard = YES;
	_movingUp = YES;

    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}

- (void)moveForwardStop {
	_isMovingFromKeyboard = NO;
	
	log(LOG_MOVEMENT, @"moveForwardStop");
	
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
    _isMovingFromKeyboard = NO;
	
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

- (void)moveUpStop {
	 _isMovingFromKeyboard = NO;
	_movingUp = NO;

    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    // post another key down
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
    
    // then post key up, twice
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

- (void)turnLeft: (BOOL)go{
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

- (void)turnRight: (BOOL)go{
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

- (void)turnTowardObject:(WoWObject*)obj{
	if ( obj ){
		[self turnTowardPosition:[obj position]];
	}
}

- (BOOL)isPatrolling{

	// we have a destination + our movement timer is going!
	if ( self.destinationWaypoint && _movementTimer )
		return YES;
		
	return NO;
}

- (void)antiAFK{
	
	if ( _afkPressForward ){
		[self moveForwardStop];
		_afkPressForward = NO;
	}
	else{
		[self moveBackwardStop];
		_afkPressForward = YES;
	}
}

- (void)establishPlayerPosition{
		
	if ( _lastCorrectionForward ){
	
		[self backEstablishPosition];
		_lastCorrectionForward = NO;
	}
	else{
		[self establishPosition];
		_lastCorrectionForward = YES;
	}
}

#pragma mark Helpers

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

- (void)turnTowardPosition: (Position*)position {
	
    BOOL printTurnInfo = NO;
	
	// don't change position if the right mouse button is down
    if ( ((GetCurrentButtonState() & 0x2) != 0x2) ){
		
        Position *playerPosition = [playerData position];
		
		// keyboard turning
        if ( [self movementType] == MovementType_Keyboard ){
			
            // check player facing vs. unit position
            float playerDirection, savedDirection;
            playerDirection = savedDirection = [playerData directionFacing];
            float theAngle = [playerPosition angleTo: position];
			
            if ( fabsf( theAngle - playerDirection ) > M_PI ){
                if ( theAngle < playerDirection )	theAngle += (M_PI*2);
                else								playerDirection += (M_PI*2);
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
                
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] ------");
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad turn with %.2f error (lim %.2f) for distance %.2f.", absAngleTo, errorStart, errorLimit, startDistance);
                
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
                        if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Range is Good] %.2f < %.2f", errorNow, errorLimit);
                        //log(LOG_MOVEMENT, @"Expected additional movement: %.2f", currentDistance * sinf(0.035*2.25));
                        break;
                    }
                    
                    if( (delayCount > 250) ) {
                        if( (signbit(lastDiff) != signbit(currDiff)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Sign Diff] %.3f vs. %.3f (Error: %.2f vs. %.2f)", lastDiff, currDiff, errorNow, errorPrev);
                            break;
                        }
                        if( (errorNow > (errorPrev + errorLimit)) ) {
                            if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] [Error Growing] %.2f > %.2f", errorNow, errorPrev);
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
				 log(LOG_MOVEMENT, @"[Turn] Stabalized at ~%d ms (wow delay: %d) with %.3f diff --> %.2f yards.", j*2, [controller refreshDelay], diff, currentDistance * sinf(diff) );
				 break;
				 }
				 }*/
                
                // [playerData setDirectionFacing: newPlayerDirection];
                
                if(fabsf(finalFacing - savedDirection) > M_PI) {
                    if(finalFacing < savedDirection)    finalFacing += (M_PI*2);
                    else                                savedDirection += (M_PI*2);
                }
                float interval = -1*[date timeIntervalSinceNow], turnRad = fabsf(savedDirection - finalFacing);
                if(printTurnInfo) log(LOG_MOVEMENT, @"[Turn] %.3f rad/sec (%.2f/%.2f) at pSpeed %.2f.", turnRad/interval, turnRad, interval, [playerData speed] );
            }
			
		// mouse turning or CTM
        }
		else{

            [playerData faceToward: position];
			
			float playerDirection = [playerData directionFacing];
			float theAngle = [playerPosition angleTo: position];
			
			// compensate for the 2pi --> 0 crossover
			if ( fabsf( theAngle - playerDirection ) > M_PI ) {
				if(theAngle < playerDirection)  theAngle        += (M_PI*2);
				else                            playerDirection += (M_PI*2);
			}
			
			// find the difference between the angles
			float angleTo = fabsf(theAngle - playerDirection);
			
			// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
			if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
				[self establishPosition];
			}
			
			if ( printTurnInfo ) log(LOG_MOVEMENT, @"Doing sharp turn to %.2f", theAngle );

            usleep( [controller refreshDelay] );
        }
    }
	else {
        if(printTurnInfo) log(LOG_MOVEMENT, @"Skipping turn because right mouse button is down.");
    }
}

#pragma mark Click To Move

- (void)setClickToMove:(Position*)position andType:(UInt32)type andGUID:(UInt64)guid{
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory ){
		return;
	}
	
	// Set our position!
	if ( position != nil ){
		float pos[3] = {0.0f, 0.0f, 0.0f};
		pos[0] = [position xPosition];
		pos[1] = [position yPosition];
		pos[2] = [position zPosition];
		[memory saveDataForAddress: [offsetController offset:@"CTM_POS"] Buffer: (Byte *)&pos BufLength: sizeof(float)*3];
	}
	
	// Set the GUID of who to interact with!
	if ( guid > 0 ){
		[memory saveDataForAddress: [offsetController offset:@"CTM_GUID"] Buffer: (Byte *)&guid BufLength: sizeof(guid)];
	}
	
	// Set our scale!
	float scale = 13.962634f;
	[memory saveDataForAddress: [offsetController offset:@"CTM_SCALE"] Buffer: (Byte *)&scale BufLength: sizeof(scale)];
	
	// Set our distance to the target until we stop moving
	float distance = 0.5f;	// Default for just move to position
	if ( type == ctmAttackGuid ){
		distance = 3.66f;
	}
	else if ( type == ctmInteractNpc ){
		distance = 2.75f;
	}
	else if ( type == ctmInteractObject ){
		distance = 4.5f;
	}
	[memory saveDataForAddress: [offsetController offset:@"CTM_DISTANCE"] Buffer: (Byte *)&distance BufLength: sizeof(distance)];
	
	// take action!
	[memory saveDataForAddress: [offsetController offset:@"CTM_ACTION"] Buffer: (Byte *)&type BufLength: sizeof(type)];
}

- (BOOL)isCTMActive{
	UInt32 value = 0;
    [[controller wowMemoryAccess] loadDataForObject: self atAddress: [offsetController offset:@"CTM_ACTION"] Buffer: (Byte*)&value BufLength: sizeof(value)];
    return ((value == ctmWalkTo) || (value == ctmLoot) || (value == ctmInteractNpc) || (value == ctmInteractObject));
}

// Party Version of follow
- (void)followObject: (WoWObject*)unit{
	
	// not moving directly to the unit's position! Within a range from it
	float start = botController.theCombatProfile.yardsBehindTargetStart;
	float stop = botController.theCombatProfile.yardsBehindTargetStop;
	float randomDistance = SSRandomFloatBetween( start, stop );
	
	Position *positionToMove = [[unit position] positionAtDistance:randomDistance withDestination:[playerData position]];
	log(LOG_MOVEMENT, @"[Follow] Moving to %@", positionToMove);
	[self moveToPosition:positionToMove];
	//[self setClickToMove: positionToMove andType:ctmWalkTo andGUID:0x0];
}

#pragma mark Miscellaneous

- (BOOL)dismount{
	
	// do they have a standard mount?
	UInt32 mountID = [[playerData player] mountID];
	
	// check for druids
	if ( mountID == 0 ){
		
		// swift flight form
		if ( [auraController unit: [playerData player] hasAuraNamed: @"Swift Flight Form"] ){
			[macroController useMacroOrSendCmd:@"CancelSwiftFlightForm"];
			return YES;
		}
		
		// flight form
		else if ( [auraController unit: [playerData player] hasAuraNamed: @"Flight Form"] ){
			[macroController useMacroOrSendCmd:@"CancelFlightForm"];
			return YES;
		}
	}
	
	// normal mount
	else{
		[macroController useMacroOrSendCmd:@"Dismount"];
		return YES;
	}
	
	// just in case people have problems, we'll print something to their log file
	if ( ![playerData isOnGround] ) {
		log(LOG_MOVEMENT, @"[Movement] Unable to dismount player! In theory we should never be here! Mount ID: %d", mountID);
    }
	
	return NO;	
}

- (void)jump{

	log(LOG_MOVEMENT, @"Jumping!");
    // correct direction
    [self correctDirection: YES];
    
    // update variables
    self.lastJumpTime = [NSDate date];
    int min = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMinJumpTime"] intValue];
    int max = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementMaxJumpTime"] intValue];
    self.jumpCooldown = SSRandomIntBetween(min, max);
	
	[self moveUpStart];
    usleep(100000);
    [self moveUpStop];
    usleep(30000);
}

#pragma mark Waypoint Actions

#define INTERACT_RANGE		8.0f

- (void)performActions:(NSDictionary*)dict{
	
	// player cast?  try again shortly
	if ( [playerData isCasting] ){
		float delayTime = [playerData castTimeRemaining];
        if ( delayTime < 0.2f) delayTime = 0.2f;
        log(LOG_MOVEMENT, @"  Player casting. Waiting %.2f to perform next action.", delayTime);
        
        [self performSelector: _cmd
                   withObject: dict 
                   afterDelay: delayTime];
		
		return;
	}
	
	int actionToExecute = [[dict objectForKey:@"CurrentAction"] intValue];
	NSArray *actions = [dict objectForKey:@"Actions"];
	float delay = 0.1f;
	
	// are we done?
	if ( actionToExecute >= [actions count] ){
		log(LOG_MOVEMENT, @"[Waypoint] Action complete, resuming route");
		[self realMoveToNextWaypoint];
		return;
	}
	
	// execute our action
	else {
		
		log(LOG_MOVEMENT, @"[Waypoint] Executing action %d", actionToExecute);
		
		Action *action = [actions objectAtIndex:actionToExecute];
		
		// spell
		if ( [action type] == ActionType_Spell ){
			
			UInt32 spell = [[[action value] objectForKey:@"SpellID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			log(LOG_MOVEMENT, @"[Waypoint] Casting spell %d", spell);
			
			// only pause movement if we have to!
			if ( !instant )
				[self stopMovement];
			
			[botController performAction:spell];
		}
		
		// item
		else if ( [action type] == ActionType_Item ){
			
			UInt32 itemID = [[[action value] objectForKey:@"ItemID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_ITEM_MASK + itemID);
			
			log(LOG_MOVEMENT, @"[Waypoint] Using item %d", itemID);
			
			// only pause movement if we have to!
			if ( !instant )
				[self stopMovement];
			
			[botController performAction:actionID];
		}
		
		// macro
		else if ( [action type] == ActionType_Macro ){
			
			UInt32 macroID = [[[action value] objectForKey:@"MacroID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_MACRO_MASK + macroID);
			
			log(LOG_MOVEMENT, @"[Waypoint] Using macro %d", macroID);
			
			// only pause movement if we have to!
			if ( !instant )
				[self stopMovement];
			
			[botController performAction:actionID];
		}
		
		// delay
		else if ( [action type] == ActionType_Delay ){
			
			delay = [[action value] floatValue];
			
			[self stopMovement];
			
			log(LOG_MOVEMENT, @"[Waypoint] Delaying for %0.2f seconds", delay);
		}
		
		// jump
		else if ( [action type] == ActionType_Jump ){
			
			[self jump];
			
		}
		
		// switch route
		else if ( [action type] == ActionType_SwitchRoute ){
			
			RouteSet *route = nil;
			NSString *UUID = [action value];
			for ( RouteSet *otherRoute in [waypointController routes] ){
				if ( [UUID isEqualToString:[otherRoute UUID]] ){
					route = otherRoute;
					break;
				}
			}
			
			if ( route == nil ){
				log(LOG_MOVEMENT, @"[Waypoint] Unable to find route %@ to switch to!", UUID);
				
			}
			else{
				log(LOG_WAYPOINT, @"Switching route to %@ with %d waypoints", route, [[route routeForKey: PrimaryRoute] waypointCount]);
				
				// switch the botController's route!
				[botController setTheRouteSet:route];
/*
I uncommented this because it's calling a non existent method.  Not sure if this is old er broken er?
				// start patrolling!

				[self patrolWithRouteSet:route];
*/
				return;
			}
		}
		
		else if ( [action type] == ActionType_QuestGrab || [action type] == ActionType_QuestTurnIn ){
			
			// reset mob counts
			if ( [action type] == ActionType_QuestTurnIn ){
				[statisticsController resetQuestMobCount];
			}
			
			// get all nearby mobs
			NSArray *nearbyMobs = [mobController mobsWithinDistance:INTERACT_RANGE levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];				
			Mob *questNPC = nil;
			for ( questNPC in nearbyMobs ){
				
				if ( [questNPC isQuestGiver] ){
					
					[self stopMovement];
					
					// might want to make k 3 (but will take longer)
					
					log(LOG_MOVEMENT, @"[Waypoint] Turning in/grabbing quests to/from %@", questNPC);
					
					int i = 0, k = 1;
					for ( ; i < 3; i++ ){
						for ( k = 1; k < 5; k++ ){
							
							// interact
							if ( [botController interactWithMouseoverGUID:[questNPC GUID]] ){
								usleep(300000);
								
								// click the gossip button
								[macroController useMacroWithKey:@"QuestClickGossip" andInt:k];
								usleep(10000);
								
								// click "continue" (not all quests need this)
								[macroController useMacro:@"QuestContinue"];
								usleep(10000);
								
								// click "Accept" (this is ONLY needed if we're accepting a quest)
								[macroController useMacro:@"QuestAccept"];
								usleep(10000);
								
								// click "complete quest"
								[macroController useMacro:@"QuestComplete"];
								usleep(10000);
								
								// click "cancel" (sometimes we have to in case we just went into a quest we already have!)
								[macroController useMacro:@"QuestCancel"];
								usleep(10000);
							}
						}
					}
				}
			}
		}
		
		// interact with NPC
		else if ( [action type] == ActionType_InteractNPC ){
			
			NSNumber *entryID = [action value];
			log(LOG_MOVEMENT, @"[Waypoint] Interacting with mob %@", entryID);
			
			// moving bad, lets pause!
			[self stopMovement];
			
			// interact
			[botController interactWithMob:[entryID unsignedIntValue]];
		}
		
		// interact with object
		else if ( [action type] == ActionType_InteractObject ){
			
			NSNumber *entryID = [action value];
			log(LOG_MOVEMENT, @"[Waypoint] Interacting with node %@", entryID);
			
			// moving bad, lets pause!
			[self stopMovement];
			
			// interact
			[botController interactWithNode:[entryID unsignedIntValue]];	
		}
		
		// repair
		else if ( [action type] == ActionType_Repair ){
			
			// get all nearby mobs
			NSArray *nearbyMobs = [mobController mobsWithinDistance:INTERACT_RANGE levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];				
			Mob *repairNPC = nil;
			for ( repairNPC in nearbyMobs ){
				if ( [repairNPC canRepair] ){
					log(LOG_MOVEMENT, @"[Waypoint] Repairing with %@", repairNPC);
					break;
				}
			}
			
			// repair
			if ( repairNPC ){
				[self stopMovement];
				if ( [botController interactWithMouseoverGUID:[repairNPC GUID]] ){
					
					// sleep some to allow the window to open!
					usleep(500000);
					
					// now send the repair macro
					[macroController useMacro:@"RepairAll"];	
					
					log(LOG_MOVEMENT, @"[Waypoint] All items repaired");
				}
			}
			else{
				log(LOG_MOVEMENT, @"[Waypoint] Unable to repair, no repair NPC found!");
			}
		}
		
		// switch combat profile
		else if ( [action type] == ActionType_CombatProfile ){
			log(LOG_MOVEMENT, @"[Waypoint] Switching from combat profile %@", botController.theCombatProfile);
			
			CombatProfile *profile = nil;
			NSString *UUID = [action value];
			for ( CombatProfile *otherProfile in [combatProfileEditor combatProfiles] ){
				if ( [UUID isEqualToString:[otherProfile UUID]] ){
					profile = otherProfile;
					break;
				}
			}
			
			[botController changeCombatProfile:profile];
		}
		
		// jump to waypoint
		else if ( [action type] == ActionType_JumpToWaypoint ){
			
			int waypointIndex = [[action value] intValue] - 1;
			NSArray *waypoints = [self.currentRoute waypoints];
			
			if ( waypointIndex >= 1 && waypointIndex < [waypoints count] ){
				self.destinationWaypoint = [waypoints objectAtIndex:waypointIndex];
				log(LOG_MOVEMENT, @"[Waypoint] Jumping to waypoint %@", self.destinationWaypoint);
				[self resumeMovement];
			}
			else{
				log(LOG_MOVEMENT, @"[Waypoint] Error, unable to move to waypoint index %d, out of range!", waypointIndex);
			}
		}
	}
	
	log(LOG_MOVEMENT, @"[Waypoint] Action %d complete, checking for more!", actionToExecute);
	
	[self performSelector: _cmd
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
							actions,									@"Actions",
							[NSNumber numberWithInt:++actionToExecute],	@"CurrentAction",
							nil]
			   afterDelay: delay];
}

#pragma mark Temporary

- (float)averageSpeed{
	return 0.0f;
}
- (float)averageDistance{
	return 0.0f;
}
- (BOOL)shouldJump{
	return NO;
}

@end
