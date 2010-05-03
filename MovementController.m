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
#import "CombatController.h"
#import "OffsetController.h"
#import "PlayerDataController.h"
#import "AuraController.h"
#import "MacroController.h"
#import "BlacklistController.h"
#import "WaypointController.h"
#import "MobController.h"
#import "StatisticsController.h"
#import "CombatProfileEditor.h"
#import "BindingsController.h"
#import "InventoryController.h"
#import "Profile.h"
#import "ProfileController.h"
#import "MailActionProfile.h"

#import "Action.h"
#import "Rule.h"

#import "Offsets.h"

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

@interface MovementController ()
@property (readwrite, retain) WoWObject *moveToObject;
@property (readwrite, retain) Position *moveToPosition;
@property (readwrite, retain) Waypoint *destinationWaypoint;
@property (readwrite, retain) NSString *currentRouteKey;
@property (readwrite, retain) Route *currentRoute;
@property (readwrite, retain) Route *currentRouteHoldForFollow;

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

- (void)moveToWaypoint: (Waypoint*)waypoint;

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
	MovementState_MovingToObject	= 0,
	MovementState_Patrolling		= 1,
	MovementState_Stuck				= 1,
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

		_stuckDictionary = [[NSMutableDictionary dictionary] retain];

		_currentRouteSet = nil;
		_currentRouteKey = nil;

		_moveToObject = nil;
		_moveToPosition = nil;
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
		_lastCorrectionLeft = NO;
		_performingActions = NO;
		_checkingPosition = NO;

		self.isFollowing = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasRevived:) name: PlayerHasRevivedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachedFollowUnit:) name: ReachedFollowUnitNotification object: nil];

    }
    return self;
}

- (void) dealloc{
	[_stuckDictionary release];
	
    [super dealloc];
}

- (void)awakeFromNib {
   //self.shouldJump = [[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue];
}

@synthesize currentRouteSet = _currentRouteSet;
@synthesize currentRouteKey = _currentRouteKey;
@synthesize currentRoute = _currentRoute;
@synthesize currentRouteHoldForFollow = _currentRouteHoldForFollow;
@synthesize moveToObject = _moveToObject;
@synthesize moveToPosition = _moveToPosition;
@synthesize destinationWaypoint = _destinationWaypoint;
@synthesize lastAttemptedPosition = _lastAttemptedPosition;
@synthesize lastAttemptedPositionTime = _lastAttemptedPositionTime;
@synthesize lastPlayerPosition = _lastPlayerPosition;
@synthesize unstickifyTarget = _unstickifyTarget;
@synthesize lastDirectionCorrection = _lastDirectionCorrection;
@synthesize movementExpiration = _movementExpiration;
@synthesize jumpCooldown = _jumpCooldown;
@synthesize lastJumpTime = _lastJumpTime;
@synthesize performingActions = _performingActions;
@synthesize checkingPosition = _checkingPosition;
@synthesize isFollowing;

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
	
	log(LOG_DEV, @"isMoving: Not moving!");
	
	return NO;
}

- (BOOL)moveToObject: (WoWObject*)object{
	
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return NO;
	}	
	
	if ( !object || ![object isValid] ) {
		[_moveToObject release];
		_moveToObject = nil;
		return NO;
	}

	// reset our timer
	[self resetMovementTimer];
	
	// save and move!
	self.moveToObject = object;

	// If this is a Node then let's change the position to one just above it and overshooting it a tad
	if ( [(Unit*)object isKindOfClass: [Node class]] && ![playerData isOnGround] ) {
		float distance = [[playerData position] distanceToPosition: [object position]];
		if (distance > 8.0f) {

			log(LOG_MOVEMENT, @"Over shooting the node for a nice drop in!");
			
			// We over shoot to adjust to give us a lil stop ahead distance
			float newX = 0.0;
			// If it's north of me
			if ( [[self.moveToObject position] xPosition] > [[playerData position] xPosition]) newX = [[self.moveToObject position] xPosition]+0.5f;
			else newX = [[self.moveToObject position] xPosition]-0.5f;
			
			float newY = 0.0;
			// If it's west of me
			if ( [[self.moveToObject position] yPosition] > [[playerData position] yPosition]) newY = [[self.moveToObject position] yPosition]+0.5f;
			else newY = [[self.moveToObject position] yPosition]-0.5f;

			// Just Above it for a sweet drop in
			float newZ = [[self.moveToObject position] zPosition]+2.5f;

			self.moveToPosition = [[Position alloc] initWithX:newX Y:newY Z:newZ];
			
		} else {
			self.moveToPosition =[object position];
		}
	} else {

	  self.moveToPosition =[object position];
	}
	
	[self moveToPosition: self.moveToPosition];	

	if ( [object isKindOfClass:[Mob class]] || [object isKindOfClass:[Player class]] )
		[self performSelector:@selector(stayWithObject:) withObject: _moveToObject afterDelay:0.1f];

	return YES;
}

// in case the object moves
- (void)stayWithObject:(WoWObject*)obj{
	
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}	
	
	// to ensure we don't do this when we shouldn't!
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

- (BOOL)resetMoveToObject {
	if ( _moveToObject ) return NO;
	self.moveToObject = nil;
	return YES;	
}

// set our patrolling routeset
- (void)setPatrolRouteSet: (RouteSet*)route{
	log(LOG_MOVEMENT, @"Switching from route %@ to %@", _currentRouteSet, route);
	
	self.currentRouteSet = route;
	
	// player is dead
	if ( ( [playerData isGhost] || [playerData isDead] ) && ![botController isPvPing] ){
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	}
	// normal route
	else{
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
		
	}

	// reset destination waypoint to make sure we re-evaluate where to go
	self.destinationWaypoint = nil;
	
	// set our jump time
	self.lastJumpTime = [NSDate date];
}

- (void)stopMovement {

	log(LOG_MOVEMENT, @"Stop Movement.");

	[self resetMovementTimer];

	// check to make sure we are even moving!
	UInt32 movementFlags = [playerData movementFlags];

	

	// player is moving
	if ( movementFlags & MovementFlag_Forward || movementFlags & MovementFlag_Backward ){
		log(LOG_MOVEMENT, @"Player is moving, stopping movement");
		[self moveForwardStop];
	} else 

	if ( movementFlags & MovementFlag_FlyUp || movementFlags & MovementFlag_FlyDown ){
		log(LOG_MOVEMENT, @"Player is flying, stopping movment");
		[self moveUpStop];
	} else {
		log(LOG_MOVEMENT, @"Player is not moving! No reason to stop!? Flags: 0x%X", movementFlags);
	}

}

- (void)resumeMovement{
		
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}	

	log(LOG_MOVEMENT, @"resumeMovement:");

//	[self stopMovement];

	// we're moving!
//	if ( [self isMoving] ){
		
//		log(LOG_MOVEMENT, @"We're already moving! Stopping before resume.");
	
//		[self stopMovement];
		
//		usleep( [controller refreshDelay] );
//	}

	if ( _moveToObject ) {
		log(LOG_MOVEMENT, @"Moving to object.");
		_movementState = MovementState_MovingToObject;
		[self moveToPosition:[self.moveToObject position]];
	} else 
	if ( _currentRouteSet || self.isFollowing ) {
		
		// Refresh the route if we're in follow
		if (self.isFollowing) self.currentRoute = botController.followRoute;

		_movementState = MovementState_Patrolling;

		// previous waypoint to move to
		if ( self.destinationWaypoint ) {
			log(LOG_MOVEMENT, @"Moving to WP: %@", self.destinationWaypoint);
			[self moveToPosition:[self.destinationWaypoint position]];
		} else {
		// find the closest waypoint
			
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
			} else {
				// find the closest waypoint in our primary route!
				newWP = [self.currentRoute waypointClosestToPosition:playerPosition];
			}
			
			// we have a waypoint to move to!
			if ( newWP ) {
				log(LOG_MOVEMENT, @"Found waypoint %@ to move to", newWP);
				
				[self turnTowardPosition: [newWP position]];

				usleep([controller refreshDelay]*2);
				
				[self moveToWaypoint:newWP];
			} else {
				log(LOG_ERROR, @"Unable to find a position to resume movement to!");
			}
		}	
	} else {
		log(LOG_ERROR, @"We have no route or unit to move to!");
	}
}

- (void)resumeMovementToClosestWaypoint {

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}
	
	log(LOG_MOVEMENT, @"resumeMovementToClosestWaypoint:");
	
	// reset our timer
	[self resetMovementTimer];
/*
	// we're moving!
	if ( [self isMoving] ) {

		log(LOG_MOVEMENT, @"We're already moving! Stopping before resume.");

		[self stopMovement];

		usleep( [controller refreshDelay] );
	}
	[self establishPlayerPosition];
 */

	if ( !_currentRouteSet ) {
		log(LOG_ERROR, @"We have no route or unit to move to!");
		return;
	}

	_movementState = MovementState_Patrolling;

	log(LOG_MOVEMENT, @"Finding the closest waypoint");

	Position *playerPosition = [playerData position];
	Waypoint *newWaypoint;

	NSArray *waypoints = [self.currentRoute waypoints];

	// find the closest waypoint in our primary route!
	newWaypoint = [self.currentRoute waypointClosestToPosition:playerPosition];

	float distanceToWaypoint = [[playerData position] distanceToPosition: [newWaypoint position]];

	if ( distanceToWaypoint > 100.0f  && botController.theRouteCollection.routes.count > 1) {
		log(LOG_WAYPOINT, @"Looks like the next waypoint is very far, checking to see if we have a closer route.");

		float closestDistance = 0.0f;
		Waypoint *thisWaypoint = nil;
		Route *route = nil;
		RouteSet *routeSetFound = [RouteSet retain];

		for (RouteSet *routeSet in [botController.theRouteCollection routes] ) {
 
			// Set the route to test against
			if ( [playerData isGhost] || [playerData isDead] ) route = [routeSet routeForKey:CorpseRunRoute];
				else route = [routeSet routeForKey:PrimaryRoute];

			if ( !route || route == nil) continue;
 
			if ( closestDistance == 0.0f ) {
				thisWaypoint = [route waypointClosestToPosition:playerPosition];
				closestDistance = [playerPosition distanceToPosition: [thisWaypoint position]];
				routeSetFound = routeSet;
				continue;
			}
 
			// We have one to compare
			thisWaypoint = [route waypointClosestToPosition:playerPosition];
			distanceToWaypoint = [playerPosition distanceToPosition: [thisWaypoint position]];
			if (distanceToWaypoint < closestDistance) {
				closestDistance = distanceToWaypoint;
				routeSetFound = routeSet;
			}
		}

		if ( routeSetFound && [routeSetFound UUID] != [self.currentRouteSet UUID]) {
			log(LOG_WAYPOINT, @"Found a closer route, switching!");
			[self setPatrolRouteSet: routeSetFound];
			routeSetFound = nil;
			[routeSetFound release];
			[self performSelector: _cmd withObject: nil afterDelay:0.3f];
			return;
		}
	}

	// If the waypoint is too close, grab the next
	if (![newWaypoint actions] && distanceToWaypoint < ( [playerData speedMax] / 2.0f) ) {
		int index = [waypoints indexOfObject: newWaypoint];
		index++;
		newWaypoint = [waypoints objectAtIndex: index];
	}

	// If we already have a waypoint we check it
	if ( self.destinationWaypoint ) {


		int indexNext = [waypoints indexOfObject:self.destinationWaypoint];
		int indexClosest = [waypoints indexOfObject: newWaypoint];

		// If the closest waypoint is further back than the current one then don't use it.
		if ( indexClosest < indexNext) {
			newWaypoint = self.destinationWaypoint;
		} else

		// Don't skip more than...
		if ( (indexClosest-indexNext) > 10 ) {
			newWaypoint = self.destinationWaypoint;
		} else {

			Waypoint *thisWaypoint;
			NSArray *actions;
			int i;

			for ( i=indexNext; i<indexClosest; i++ ) {

				thisWaypoint = [[self.currentRoute waypoints] objectAtIndex: i];

				actions = [thisWaypoint actions];

				// If there are no actions
				if ( !actions || [actions count] <= 0 ) continue;

				// If there are actions to be taken at the current waypoint we don't skip it.
				newWaypoint = thisWaypoint;
			}
		}
	}

	// Check to see if we're air mounted and this is a long distance waypoint.  If so we wait to start our descent.
	if ( ![playerData isOnGround] && [[playerData player] isMounted] ) {

		distanceToWaypoint = [[playerData position] distanceToPosition: [newWaypoint position]];

		float horizontalDistanceToWaypoint = [[playerData position] distanceToPosition2D: [newWaypoint position]];
		float verticalDistanceToWaypoint = [[playerData position] zPosition]-[[newWaypoint position] zPosition];
		Position *positionAboveWaypoint = [[Position alloc] initWithX:[[newWaypoint position] xPosition] Y:[[newWaypoint position] yPosition] Z:[[playerData position] zPosition]];

		// Only consider this if it's a far off distance
		if ( distanceToWaypoint > 100.0f && 
			distanceToWaypoint > ( verticalDistanceToWaypoint/2.0f ) && 
			verticalDistanceToWaypoint < horizontalDistanceToWaypoint &&
			verticalDistanceToWaypoint > 30.0f
			) {

			log(LOG_MOVEMENT, @"Waypoint is far off so we won't descend until we're closer. hDist: %0.2f, vDist: %0.2f", horizontalDistanceToWaypoint, verticalDistanceToWaypoint);

			Position *positionToDescend = [[playerData position] positionAtDistance:verticalDistanceToWaypoint withDestination:positionAboveWaypoint];
			
			[self turnTowardPosition: positionToDescend];

			usleep([controller refreshDelay]*2);

			[self moveToPosition: positionToDescend];
			return;
		}
	}

	// we have a waypoint to move to!
	if ( newWaypoint ) {

		log(LOG_MOVEMENT, @"Found waypoint %@ to move to", newWaypoint);

		[self turnTowardPosition: [newWaypoint position]];

		usleep([controller refreshDelay]*2);

		[self moveToWaypoint:newWaypoint];

	} else {
		log(LOG_ERROR, @"Unable to find a position to resume movement to!");
	}
}

- (int)movementType {
	return [movementTypePopUp selectedTag];
}

#pragma mark Waypoints
- (void)moveToWaypoint: (Waypoint*)waypoint {

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// reset our timer
	[self resetMovementTimer];

	int index = [[_currentRoute waypoints] indexOfObject: waypoint];
	[waypointController selectCurrentWaypoint:index];

	log(LOG_WAYPOINT, @"Moving to a waypoint: %@", waypoint);

	self.destinationWaypoint = waypoint;

	[self moveToPosition:[waypoint position]];
}

- (void)moveToWaypointFromUI:(Waypoint*)wp {
	_destinationWaypointUI = [wp retain];
	[self moveToPosition:[wp position]];
}

- (void)startFollow {
	
	log(LOG_WAYPOINT, @"Starting movement controller for follow");
	
	if ( [playerData targetID] != [[botController followUnit] GUID]) {
		log(LOG_DEV, @"Targeting follow unit.");
		[playerData targetGuid:[[botController followUnit] GUID]];
	}

	// Check to see if we need to mount or dismount
	if ( [botController followMountCheck] ) {
		// Just kill the follow and mounts will be checked before follow begins again
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;
	}
	
	self.isFollowing = YES;
	self.currentRouteHoldForFollow = self.currentRoute;
	self.currentRoute = botController.followRoute;
	

	// Set us to the 1st waypoint!
	NSArray *waypoints = [self.currentRoute waypoints];
	self.destinationWaypoint = [waypoints objectAtIndex:0];
	
	[self resumeMovement];
}

- (void)moveToNextWaypoint{

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}

	// reset our timer
	[self resetMovementTimer];

	if (self.isFollowing) {
		
		// Check to see if we need to mount or dismount
		if ( [botController followMountCheck] ) {
			// Just kill the follow and mounts will be checked before follow begins again
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
			return;
		}
		
		// Refresh our follow route
		self.currentRoute = botController.followRoute;
		[self realMoveToNextWaypoint];

		// Return here since we're skipping waypoint actions in follow mode
		return;
	}

	// do we have an action for the destination we just reached?
	NSArray *actions = [self.destinationWaypoint actions];
	if ( actions && [actions count] > 0 ) {
		
		log(LOG_WAYPOINT, @"Actions to take? %d", [actions count]);

		// check if conditions are met
		Rule *rule = [self.destinationWaypoint rule];
		if ( rule == nil || [botController evaluateRule: rule withTarget: TargetNone asTest: NO] ){

			

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

- (void)realMoveToNextWaypoint {

	if ( !botController.isBotting && !_destinationWaypointUI ) {
		[self resetMovementState];
		return;
	}

	log(LOG_WAYPOINT, @"Moving to the next waypoint!");
	
	NSArray *waypoints = [self.currentRoute waypoints];
	int index = [waypoints indexOfObject:self.destinationWaypoint];
	
	// we have an index! yay!
	if ( index != NSNotFound ){
		
		// at the end of the route
		if ( index == [waypoints count] - 1 ){
			log(LOG_WAYPOINT, @"We've reached the end of the route!");
			
			// TO DO: keep a dictionary w/the route collection (or set) to remember how many times we've run a route
			
			[self routeEnded];
			return;
		}
		
		// move to the next WP
		else if ( index < [waypoints count] - 1 ){
			index++;
		}
		
		// increment something here to keep track of how many waypoints we've moved to?
		
		log(LOG_WAYPOINT, @"Moving to next waypoint of %@ with index %d", self.destinationWaypoint, index);
		[self moveToWaypoint:[waypoints objectAtIndex:index]];
	} else {
		if (self.isFollowing) {
			[self routeEnded];
			return;
		} else {
			log(LOG_ERROR, @"There are no waypoints for the current route!");
		}
	}
}

- (void)routeEnded{
	
	// Pop the notification if we're following
	if (self.isFollowing) {
		log(LOG_WAYPOINT, @"Ending follow with notification.");
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;
	}

	// player is currently on the primary route and is dead, if they've finished, then we ran the entire route and didn't find our body :(
	if ( self.currentRouteKey == PrimaryRoute && [playerData isGhost] ){
		[botController stopBot:nil];
		[controller setCurrentStatus:@"Bot: Unable to find body, stopping bot"];
		log(LOG_GHOST, @"Unable to find your body after running the full route, stopping bot");
		return;
	}
	
	// we've reached the end of our corpse route, lets switch to our main route
	if ( self.currentRouteKey == CorpseRunRoute ){
		
		log(LOG_GHOST, @"Switching from corpse to primary route!");
		
		self.currentRouteKey = PrimaryRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
		
		// find the closest WP
		self.destinationWaypoint = [self.currentRoute waypointClosestToPosition:[playerData position]];
	}

	// Use the first waypoint
	else{
		self.destinationWaypoint = [[self.currentRoute waypoints] objectAtIndex:0];
	}
	
	[self resumeMovement];
}

#pragma mark Actual Movement Shit - Scary

- (void)moveToPosition: (Position*)position {
	if ( !botController.isBotting && !_destinationWaypointUI ) {
		[self resetMovementState];
		return;
	}

	// reset our timer (that checks if we're at the position)
	[self resetMovementTimer];

	[botController jumpIfAirMountOnGround];

    Position *playerPosition = [playerData position];
    float distance = [playerPosition distanceToPosition: position];

	log(LOG_DEV, @"moveToPosition called (distance: %f).", distance)

	// sanity check
    if ( !position || distance == INFINITY ) {
        log(LOG_MOVEMENT, @"Invalid waypoint (distance: %f). Ending patrol.", distance);
		botController.evaluationInProgress=nil;
		[botController evaluateSituation];
        return;
    }

	// no object, no actions, just trying to move to the next WP!
	if ( !_moveToObject && ![_destinationWaypoint actions] && distance < ( [playerData speedMax] / 2.0f) ) {
		log(LOG_MOVEMENT, @"Waypoint is too close %0.2f < %0.2f. Moving to the next one.", distance, ([playerData speedMax] / 2.0f));
		[self moveToNextWaypoint];
		return;
	}

	// we're moving to a new position!
	if ( ![_lastAttemptedPosition isEqual:position] ) 
		log(LOG_MOVEMENT, @"Moving to a new position! From %@ to %@ Timer will expire in %0.2f", _lastPlayerPosition, position, (distance/[playerData speedMax]) + 4.0);

	// only reset the stuck counter if we're going to a new position
	if ( ![position isEqual:self.lastAttemptedPosition] ) {
		log(LOG_DEV, @"Resetting stuck counter");
		_stuckCounter = 0;
	}

	self.lastAttemptedPosition		= position;
	self.lastAttemptedPositionTime	= [NSDate date];
	self.lastPlayerPosition			= playerPosition;
	_positionCheck					= 0;
	_lastDistanceToDestination		= 0.0f;

    self.movementExpiration = [NSDate dateWithTimeIntervalSinceNow: (distance/[playerData speedMax]) + 4.0f];

	// actually move!
	if ( self.isFollowing && [[playerData player] isFlyingMounted] && [self movementType] != MovementType_CTM) {
		log(LOG_MOVEMENT, @"Forcing CTM for follow if we're flying!");
		// Force CTM for party follow.
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}
	else if ( [self movementType] == MovementType_Keyboard ) {
		log(LOG_MOVEMENT, @"moveToPosition: with Keyboard");
		UInt32 movementFlags = [playerData movementFlags];

		// If we don't have the bit for forward motion let's stop
		if ( !(movementFlags & MovementFlag_Forward) ) [self moveForwardStop];
        [self correctDirection: YES];
        if ( !(movementFlags & MovementFlag_Forward) )  [self moveForwardStart];

	}
	else if ( [self movementType] == MovementType_Mouse ) {
		log(LOG_MOVEMENT, @"moveToPosition: with Mouse");

		[self moveForwardStop];
		[self correctDirection: YES];
		[self moveForwardStart];

	}
	else if ( [self movementType] == MovementType_CTM ) {
		log(LOG_MOVEMENT, @"moveToPosition: with CTM");
		[self setClickToMove:position andType:ctmWalkTo andGUID:0];
	}

	_movementTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1f target: self selector: @selector(checkCurrentPosition:) userInfo: nil repeats: YES];
}

- (void)checkCurrentPosition: (NSTimer*)timer {

	// stopped botting?  end!
	if ( !botController.isBotting && !_destinationWaypointUI ) {
		log(LOG_MOVEMENT, @"We're not botting, stop the timer!");
		[self resetMovementState];
		return;
	}

	if ( self.isFollowing ) {
		// Check to see if we're close enough to stop.

		if ( botController.followUnit && [botController.followUnit isValid] ) {
			log(LOG_DEV, @"Checking to see if we're close enough to stop.");
			
			Position *positionFollowUnit = [botController.followUnit position];
			float distanceToFollowUnit = [[playerData position] distanceToPosition: positionFollowUnit];

			// If we're close enough let's check to see if we need to stop
			if ( distanceToFollowUnit <=  botController.theCombatProfile.yardsBehindTargetStop ) {
				log(LOG_DEV, @"Setting a random stopping distance");

				// Establish a random stopping distance
				int randomStoppingValue = SSRandomIntBetween(botController.theCombatProfile.yardsBehindTargetStart, botController.theCombatProfile.yardsBehindTargetStop);
				int randomStoppingDistance=randomStoppingValue+botController.theCombatProfile.yardsBehindTargetStart;

				if ( distanceToFollowUnit <= randomStoppingDistance ) {
					// We're close enough to stop!
					[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
					return;
				}
			}
		}
		// Check to see if we need to mount or dismount
		if ( [botController followMountCheck] ) {
			log(LOG_DEV, @"Need to mount in follow mode from checkCurrentPosition.");
			// Just kill the follow and mounts will be checked before follow begins again
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
			_checkingPosition = NO;
			return;
		}
	}

	_positionCheck++;

	if (_stuckCounter > 0) log(LOG_MOVEMENT, @"[%d] Check current position.  Stuck counter: %d", _positionCheck, _stuckCounter);

	Position *playerPosition = [playerData position];
	float playerSpeed = [playerData speed];
	BOOL isNode = [_moveToObject isKindOfClass: [Node class]];

    Position *destPosition = ( _moveToObject ) ? [_moveToObject position] : [_destinationWaypoint position];
	if (isNode) destPosition = 	_moveToPosition;	// Pass it our overshoot position instead of the real object position

	float distanceToDestination = [playerPosition distanceToPosition: destPosition];

    // sanity check, incase something happens
    if ( distanceToDestination == INFINITY && !self.isFollowing) {
        log(LOG_MOVEMENT, @"Player distance == infinity. Stopping.");
		self.isFollowing = NO;
		[self resetMovementTimer];
		[botController evaluateSituation];
		_checkingPosition = NO;
        return;
    }

	// check to see if we're near our target
	float stopingDistance = ([playerData speedMax]/2.5f);
	if ( stopingDistance < 5.0f) stopingDistance = 5.0f;
//	float distanceToObject = 5.0f;			// this used to be (playerSpeed/2.0)
											//	when on mount:	7.0
											//  when on ground: 3.78

	// If this is a node that we're flying to we'll adjust the distance value
	if ( isNode && [[playerData player] isFlyingMounted] ) stopingDistance = DistanceUntilDismountByNode;

	// we've reached our position!
	if ( distanceToDestination <= stopingDistance ) {

		// request from UI!
		if ( _destinationWaypointUI ) {
			[_destinationWaypointUI release];
			_destinationWaypointUI = nil;
			// stop movement
			[self stopMovement];
			return;
		}

		log(LOG_MOVEMENT, @"Reached our destination! %0.2f < %0.2f", distanceToDestination, stopingDistance);

		// we've reached our position for follow mode
		if ( self.isFollowing ) {
			log(LOG_MOVEMENT, @"Reached follow waypoint.");
			[self moveToNextWaypoint];
			_checkingPosition = NO;
			return;
		} else

		// moving to a unit
		if ( self.moveToObject ) {
			id object = [self.moveToObject retain];
	
			// get rid of our move to object!
			self.moveToObject = nil;
			// stop this timer
			[self resetMovementTimer];
			// stop movement
			[self stopMovement];

			if ( isNode ) { 
				log(LOG_MOVEMENT, @"Reached our node hover spot %@", object);
			} else {
				log(LOG_MOVEMENT, @"Reached our object %@", object);
			}
			// we've reached the unit! Send a notification
			[[NSNotificationCenter defaultCenter] postNotificationName: ReachedObjectNotification object: object];
			return;
		} else

		// moving to a waypoint
		if ( self.destinationWaypoint ) {
			log(LOG_MOVEMENT, @"Reached waypoint %@", self.destinationWaypoint);
			BOOL continueRoute = YES;

			if ( ![botController isBotting] ){
				continueRoute = NO;
				log(LOG_MOVEMENT, @"Not continuing route! We're not botting anymore!");
			}

			if ( continueRoute ){
				[self moveToNextWaypoint];
				return;
			}

		} else {
			log(LOG_ERROR, @"Somehow we're not able to get to our waypoint!?");
		}
	}

	// Check evaluation to see if we need to do anything
//	if ( !self.moveToObject && [botController evaluateSituation] ) {
	if ( [botController evaluateSituation] ) {
		log(LOG_DEV, @"Action taken, not checking movement, checking evaluation.");
//		if ( [self isMoving] ) [self stopMovement];
//		[botController evaluateSituation];
		return;
	}

	// should we jump?
	if (	[self isMoving] && distanceToDestination > ([playerData speedMax]/1.1f) &&
			playerSpeed >= ([playerData speedMax]/1.1f) && 
			[[[NSUserDefaults standardUserDefaults] objectForKey: @"MovementShouldJump"] boolValue] &&
			![[playerData player] isFlyingMounted]
		) {

		if ( ([[NSDate date] timeIntervalSinceDate: self.lastJumpTime] > self.jumpCooldown ) ) [self jump];

	} 

	// *******************************************************
	// if we we get here, we're not close enough :(
	// *******************************************************

	// make sure we're still moving
	if ( _positionCheck > 3 && _stuckCounter < 3 && ![self isMoving] ) {
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
	if ( _stuckCounter > 3 ) {
		// stop this timer
		[self resetMovementTimer];
		[controller setCurrentStatus: @"Bot: Stuck, entering anti-stuck routine"];
		log(LOG_MOVEMENT, @"Player is stuck, trying anti-stuck routine.");
		[self unStickify];
		_checkingPosition = NO;
		return;
	}

	// check to see if we are stuck
	if ( _positionCheck > 5 ) {
		float maxSpeed = [playerData speedMax];
		float distanceTraveled = [self.lastPlayerPosition distanceToPosition:playerPosition];
		
//		log(LOG_DEV, @" Checking speed: %0.2f <= %.02f  (max: %0.2f)", playerSpeed, (maxSpeed/10.0f), maxSpeed );
//		log(LOG_DEV, @" Checking distance: %0.2f <= %0.2f", distanceTraveled, (maxSpeed/10.0f)/5.0f);

		// distance + speed check
		if ( distanceTraveled <= (maxSpeed/10.0f)/5.0f || playerSpeed <= maxSpeed/10.0f ) {
			log(LOG_DEV, @"Incrementing the stuck counter! (playerSpeed: %0.2f)", playerSpeed);
			_stuckCounter++;
		}

		self.lastPlayerPosition = playerPosition;
	}

	// reset if stuck didn't change!
	if ( _positionCheck > 13 && oldStuckCounter == _stuckCounter ) _stuckCounter = 0;

	// are we stuck moving up?
	UInt32 movementFlags = [playerData movementFlags];
	if ( movementFlags & MovementFlag_FlyUp && !_movingUp ){
		log(LOG_MOVEMENT, @"We're stuck moving up! Fixing!");
		[self moveUpStop];

		[self resumeMovement];
		_checkingPosition = NO;
		return;
	}

	if( [controller currentStatus] == @"Bot: Stuck, entering anti-stuck routine" ) {
		if ( self.isFollowing ) [controller setCurrentStatus: @"Bot: Following"];
		else if ( self.moveToObject ) [controller setCurrentStatus: @"Bot: Moving to object"];
		else [controller setCurrentStatus: @"Bot: Patrolling"];
	}

	_checkingPosition = NO;
	// TO DO: moving in the wrong direction check? (can sometimes happen when doing mouse movements based on the speed of the machine)
}

- (void)unStickify{

	if ( !botController.isBotting ) {
		[self resetMovementState];
		return;
	}	

	_movementState = MovementState_Stuck;

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

		if ( _unstickifyTry > stuckTries ) {
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
	if ( self.moveToObject ) self.unstickifyTarget = self.moveToObject;
		else self.unstickifyTarget = self.destinationWaypoint;

	// reset our counter
	if ( self.unstickifyTarget != lastTarget ) _unstickifyTry = 0;

	_unstickifyTry++;
	[lastTarget release];

	log(LOG_MOVEMENT, @"Entering anti-stuck procedure! Try %d", _unstickifyTry);

	[botController jumpIfAirMountOnGround];

	// anti-stuck for follow!
	if ( self.isFollowing && _unstickifyTry > 5) {

		log(LOG_MOVEMENT, @"Got stuck while following, cancelling follow!");
		[[NSNotificationCenter defaultCenter] postNotificationName: ReachedFollowUnitNotification object: nil];
		return;

	}

	// anti-stuck for moving to an object!
	if ( self.moveToObject ) {

		// If it's a Node we'll adhere to the UI blacklist setting
		if ( [self.moveToObject isKindOfClass: [Node class]] ) {
			// have we exceeded the amount of attempts to move to the node?

			int blacklistTriggerNodeFailedToReach = [[[NSUserDefaults standardUserDefaults] objectForKey: @"BlacklistTriggerNodeFailedToReach"] intValue];
			if ( _unstickifyTry > blacklistTriggerNodeFailedToReach ) {

				log(LOG_NODE, @"Unable to reach %@ after %d attempts, blacklisting.", _moveToObject, blacklistTriggerNodeFailedToReach);

				[blacklistController blacklistObject:self.moveToObject withReason:Reason_CantReachObject];
				self.moveToObject = nil;

				[self resumeMovement];

				return;			

			}
		} else

		// blacklist unit after 5 tries!
		if ( _unstickifyTry > 5 && _unstickifyTry < 10 ) {
			
			log(LOG_MOVEMENT, @"Unable to reach %@, blacklisting", self.moveToObject);
			
			[blacklistController blacklistObject:self.moveToObject withReason:Reason_CantReachObject];
			
			self.moveToObject = nil;
			
			[self resumeMovement];
			
			return;			
		}

		// player is flying and is stuck :(  makes me sad, lets move up a bit
		if ( [[playerData player] isFlyingMounted] ) {

			log(LOG_MOVEMENT, @"Moving up since we're flying mounted!");

			if ( _unstickifyTry < 3 ) {
				// Bump to the right
				[bindingsController executeBindingForKey:BindingStrafeRight];
			} else {
				// Bump to the left
				[bindingsController executeBindingForKey:BindingStrafeLeft];
			}

			// move up for 1 second!

			[self moveUpStop];
			[self moveUpStart];

			if ( _unstickifyTry < 3 ) {
				// Bump to the right
				[bindingsController executeBindingForKey:BindingStrafeRight];
			} else {
				// Bump to the left
				[bindingsController executeBindingForKey:BindingStrafeLeft];
			}

			[self performSelector:@selector(moveUpStop) withObject:nil afterDelay:1.4f];
			[self performSelector:@selector(resumeMovement) withObject:nil afterDelay:1.5f];
			return;
		}

		log(LOG_MOVEMENT, @"Stuck, trying to jump over object.");

		// Stop n back up a lil
		[self stopMovement];
		// Jump Back
		[self jumpBack];
		usleep( [controller refreshDelay]*2 );

		// Move forward
		[self moveForwardStart];
		usleep( [controller refreshDelay]*2 );

		// Jump
		[self jumpRaw];

		if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
		else [bindingsController executeBindingForKey:BindingStrafeLeft];

		usleep( [controller refreshDelay]*2 );
//		[self moveForwardStop];

		if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
		else [bindingsController executeBindingForKey:BindingStrafeLeft];

		[self resumeMovement];
		return;
	}

	// can't reach a waypoint :(
	else if ( self.destinationWaypoint ) {

		// player is flying and is stuck :(  makes me sad, lets move up a bit
		if ( [[playerData player] isFlyingMounted] && _unstickifyTry < 5 ) {
			
			log(LOG_MOVEMENT, @"Moving up since we're flying mounted!");
			
			if ( _unstickifyTry < 2 ) {
				// Bump to the right
				[bindingsController executeBindingForKey:BindingStrafeRight];
			} else {
				// Bump to the left
				[bindingsController executeBindingForKey:BindingStrafeLeft];
			}

			// move up for 1 second!
			[self moveUpStop];
			[self moveUpStart];

			if ( _unstickifyTry < 2 ) {
				// Bump to the right
				[bindingsController executeBindingForKey:BindingStrafeRight];
			} else {
				// Bump to the left
				[bindingsController executeBindingForKey:BindingStrafeLeft];
			}
			
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
		
		else if ( _unstickifyTry > 10 ) {
			// Move to the closest waypoint
			self.destinationWaypoint = [self.currentRoute waypointClosestToPosition:[playerData position]];
			
		}

		log(LOG_MOVEMENT, @"Stuck moving to waypoint, trying to jump over object.");

		// Stop n back up a lil
		[self stopMovement];
		// Jump Back
		[self jumpBack];
		usleep( [controller refreshDelay]*2 );
		
		// Move forward
		[self moveForwardStart];
		usleep( [controller refreshDelay]*2 );
	
		// Jump
		[self jumpRaw];

		if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
		else [bindingsController executeBindingForKey:BindingStrafeLeft];

		usleep( [controller refreshDelay]*2 );
//		[self moveForwardStop];

		if ( _unstickifyTry < 2 ) [bindingsController executeBindingForKey:BindingStrafeRight];
		else [bindingsController executeBindingForKey:BindingStrafeLeft];

		[self resumeMovement];
	}

}

- (BOOL)checkUnitOutOfRange: (Unit*)target {
	
	if ( !botController.isBotting ) {
		[self resetMovementState];
		return NO;
	}

	// This is intended for issues like runners, a chance to correct vs blacklist
	// Hopefully this will help to avoid bad blacklisting which comes AFTER the cast
	// returns true if the mob is good to go

	if (!target || target == nil) return YES;

	// only do this for hostiles
	if (![playerData isHostileWithFaction: [target factionTemplate]]) return YES;

	// If the mob is in our attack range return true
	float distanceToTarget = [[(PlayerDataController*)playerData position] distanceToPosition: [target position]];
	if ( distanceToTarget <= [botController.theCombatProfile attackRange]) return YES;

	log(LOG_COMBAT, @"%@ has gone out of range: %0.2f", target, distanceToTarget);

	// If they're just a lil out of range lets inch up
	if ( distanceToTarget < ([botController.theCombatProfile attackRange] + 10.0f) ) {

		log(LOG_COMBAT, @"Unit is still close, jumping forward.");

		if ( [self jumpTowardsPosition: [target position]] ) {
	
			// Now check again to see if they're in range
			float distanceToTarget = [[(PlayerDataController*)playerData position] distanceToPosition: [target position]];

			if ( distanceToTarget > botController.theCombatProfile.attackRange ) {
				log(LOG_COMBAT, @"Still out of range: %@, giving up.", target);
				return NO;
			} else {
				log(LOG_COMBAT, @"Back in range: %@.", target);
				return YES;
			}
		}
	}

	// They're running and they're nothing we can do about it
	log(LOG_COMBAT, @"Target: %@ has gone out of range: %0.2f", target, distanceToTarget);
    return NO;
}

- (void)resetRoutes{
	// to be safe
	[self resetMovementState];

	// dump the routes!
	self.currentRouteSet = nil;
	self.currentRouteKey = nil;
	self.currentRoute = nil;
}

- (void)resetMovementState {

	log(LOG_MOVEMENT, @"Resetting movement state");
	[self resetMovementTimer];

	if ( [self isMoving] ) {
		log(LOG_MOVEMENT, @"Stopping movement!");
		[self stopMovement];
		[self setClickToMove:nil andType:ctmIdle andGUID:0x0];
	}

	self.moveToObject				= nil;
	self.destinationWaypoint		= nil;
	self.lastAttemptedPosition		= nil;
	self.lastAttemptedPositionTime	= nil;
	self.lastPlayerPosition			= nil;
	_isMovingFromKeyboard			= NO;
	[_stuckDictionary removeAllObjects];
	
	_checkingPosition = NO;
	_unstickifyTry = 0;
	_stuckCounter = 0;
	_performingActions = NO;

	if (self.isFollowing && self.currentRouteHoldForFollow) {
		// Switch back to what ever was the old route
		self.currentRoute =	self.currentRouteHoldForFollow;
		self.currentRouteHoldForFollow =  nil;
	}

	self.isFollowing = NO;

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
			[self turnTowardPosition: position];
            usleep([controller refreshDelay]*2);
        }
    } else {
        if(printTurnInfo) log(LOG_MOVEMENT, @"Skipping turn because right mouse button is down.");
    }
    
}


#pragma mark Notifications

- (void)reachedFollowUnit: (NSNotification*)notification {
	if ( !botController.isBotting ) return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: _cmd object: nil];

	log(LOG_FUNCTION, @"Reached Follow Unit called in the movementController.");
	
	// Reset the movement controller.
	[self resetMovementState];

}

- (void)playerHasDied:(NSNotification *)aNotification {
	if ( !botController.isBotting ) return;

	// reset our movement state!
	[self resetMovementState];

	// We're not set to use a route so do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ) return;

	// do nothing if PvPing and in a BG
	if ( botController.isPvPing && [playerData isInBG:[playerData zone]] ) {
		log(LOG_MOVEMENT, @"Ignoring corpse route because we're PvPing!");
		return;
	}

	// switch back to starting route?
	if ( [botController.theRouteCollection startRouteOnDeath] ) {

		// normal route if PvPing
		if ( [botController isPvPing] ){
			self.currentRouteKey = PrimaryRoute;
			self.currentRouteSet = [botController.theRouteCollection startingRoute];
			self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];
		}
		else{
			self.currentRouteKey = CorpseRunRoute;
			self.currentRouteSet = [botController.theRouteCollection startingRoute];
			self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
		}
		log(LOG_MOVEMENT, @"Player Died, switching to main starting route! %@", self.currentRoute);
	}
	// be normal!
	else{
		log(LOG_MOVEMENT, @"Player Died, switching to corpse route");
		self.currentRouteKey = CorpseRunRoute;
		self.currentRoute = [self.currentRouteSet routeForKey:CorpseRunRoute];
	}
	
	if ( self.currentRoute && [[self.currentRoute waypoints] count] == 0  ){
		log(LOG_MOVEMENT, @"No corpse route! Ending movement");
		[self stopMovement];
	}
}

- (void)playerHasRevived:(NSNotification *)aNotification {
	if ( !botController.isBotting ) return;

	// reset movement state
	[self resetMovementState];

	// We're not set to use a route so do nothing
	if ( ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"UseRoute"] boolValue] ) return;

	// do nothing if PvPing and in a BG
	if ( botController.isPvPing && [playerData isInBG:[playerData zone]] ) {
		log(LOG_MOVEMENT, @"Ignoring corpse route because we're PvPing!");
		return;
	}
	
	// switch our route!
	self.currentRouteKey = PrimaryRoute;
	self.currentRoute = [self.currentRouteSet routeForKey:PrimaryRoute];

	log(LOG_MOVEMENT, @"Player revived, switching to %@", self.currentRoute);

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

- (void)moveBackwardStart {
    _isMovingFromKeyboard = YES;
	
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_DownArrow, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
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

- (void)strafeRightStart {
/*
	_isMovingFromKeyboard = YES;
	_movingUp = YES;

    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)kVK_Space, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
*/
}

- (void)strafeRightStop {
/*
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
*/
}

- (void)turnTowardObject:(WoWObject*)obj{
	if ( obj ){
		[self turnTowardPosition:[obj position]];
	}
}

- (BOOL)isPatrolling {

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

- (void)correctDirectionByTurning {

	if ( _lastCorrectionLeft ){
		log(LOG_MOVEMENT, @"Turning right!");
		[bindingsController executeBindingForKey:BindingTurnRight];
		usleep([controller refreshDelay]);
		[bindingsController executeBindingForKey:BindingTurnLeft];
		_lastCorrectionLeft = NO;
	}
	else{
		log(LOG_MOVEMENT, @"Turning left!");
		[bindingsController executeBindingForKey:BindingTurnLeft];
		usleep([controller refreshDelay]);
		[bindingsController executeBindingForKey:BindingTurnRight];
		_lastCorrectionLeft = YES;
	}
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
			
		// mouse movement or CTM
        }
		else{

			// what are we facing now?
			float playerDirection = [playerData directionFacing];
			float theAngle = [playerPosition angleTo: position];

			log(LOG_MOVEMENT, @"%0.2f %0.2f Difference: %0.2f > %0.2f", playerDirection, theAngle, fabsf( theAngle - playerDirection ), M_PI);

			// face the other location!
			[playerData faceToward: position];

			// compensate for the 2pi --> 0 crossover
			if ( fabsf( theAngle - playerDirection ) > M_PI ) {
				if(theAngle < playerDirection)  theAngle        += (M_PI*2);
				else                            playerDirection += (M_PI*2);
			}

			// find the difference between the angles
			float angleTo = fabsf(theAngle - playerDirection);

			// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
			if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
				[self correctDirectionByTurning];
				[self establishPlayerPosition];
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
	if ( ![[playerData player] isOnGround] ) {
		log(LOG_MOVEMENT, @"[Movement] Unable to dismount player! In theory we should never be here! Mount ID: %d", mountID);
    }
	
	return NO;	
}

- (void)jump{

	// If we're air mounted and not on the ground then let's not jump
	if ([[playerData player] isFlyingMounted] && ![[playerData player] isOnGround] ) return;
	
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

- (void)jumpRaw {

	// If we're air mounted and not on the ground then let's not jump
	if ([[playerData player] isFlyingMounted] && ![[playerData player] isOnGround] ) return;

	log(LOG_MOVEMENT, @"Jumping!");
	[self moveUpStart];
	usleep( [controller refreshDelay] );
    [self moveUpStop];
}

- (BOOL)jumpTowardsPosition: (Position*)position {
	log(LOG_MOVEMENT, @"Jumping towards position.");

	if ( [self isMoving] ) [self stopMovement];

	// Face the target
	[self turnTowardPosition: position];
	usleep( [controller refreshDelay]*2 );
	[self establishPosition];

	// Move forward
	[self moveForwardStart];
	usleep( [controller refreshDelay]*2 );

	// Jump
	[self jumpRaw];
	sleep(1);

	// Stop
	[self moveForwardStop];

	return YES;
}

- (BOOL)jumpForward {
	log(LOG_MOVEMENT, @"Jumping forward.");
	
	// Move backward
	[self moveForwardStart];
	usleep(100000);
	
	// Jump
	[self jumpRaw];
	
	// Stop
	[self moveForwardStop];
	usleep([controller refreshDelay]*2);
	
	return YES;
	
}

- (BOOL)jumpBack {
	log(LOG_MOVEMENT, @"Jumping back.");
	
	// Move backward
	[self moveBackwardStart];
	usleep(100000);
	
	// Jump
	[self jumpRaw];

	// Stop
	[self moveBackwardStop];
	usleep([controller refreshDelay]*2);
	
	return YES;
	
}

#pragma mark Waypoint Actions

#define INTERACT_RANGE		8.0f

- (void)performActions:(NSDictionary*)dict{
	
	// player cast?  try again shortly
	if ( [playerData isCasting] ) {
		_performingActions = NO;
		float delayTime = [playerData castTimeRemaining];
        if ( delayTime < 0.2f) delayTime = 0.2f;
        log(LOG_WAYPOINT, @"Player casting. Waiting %.2f to perform next action.", delayTime);

        [self performSelector: _cmd
                   withObject: dict 
                   afterDelay: delayTime];

		return;
	}

	// If we're being called after delaying lets cancel the evaluations we started
	if ( _performingActions ) {
		[botController cancelCurrentEvaluation];
		_performingActions = NO;
	}

	int actionToExecute = [[dict objectForKey:@"CurrentAction"] intValue];
	NSArray *actions = [dict objectForKey:@"Actions"];
	float delay = 0.0f;

	// are we done?
	if ( actionToExecute >= [actions count] ){
		log(LOG_WAYPOINT, @"Action complete, resuming route");
		[self realMoveToNextWaypoint];
		return;
	}

	// execute our action
	else {

		log(LOG_WAYPOINT, @"Executing action %d", actionToExecute);

		Action *action = [actions objectAtIndex:actionToExecute];

		// spell
		if ( [action type] == ActionType_Spell ){
			
			UInt32 spell = [[[action value] objectForKey:@"SpellID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			log(LOG_WAYPOINT, @"Casting spell %d", spell);

			// only pause movement if we have to!
			if ( !instant ) [self stopMovement];

			[botController performAction:spell];
		}
		
		// item
		else if ( [action type] == ActionType_Item ){
			
			UInt32 itemID = [[[action value] objectForKey:@"ItemID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_ITEM_MASK + itemID);
			
			log(LOG_WAYPOINT, @"Using item %d", itemID);
			
			// only pause movement if we have to!
			if ( !instant )	[self stopMovement];

			[botController performAction:actionID];
		}

		// macro
		else if ( [action type] == ActionType_Macro ) {

			UInt32 macroID = [[[action value] objectForKey:@"MacroID"] unsignedIntValue];
			BOOL instant = [[[action value] objectForKey:@"Instant"] boolValue];
			UInt32 actionID = (USE_MACRO_MASK + macroID);
			
			log(LOG_WAYPOINT, @"Using macro %d", macroID);
			
			// only pause movement if we have to!
			if ( !instant )
				[self stopMovement];
			
			[botController performAction:actionID];
		}
		
		// delay
		else if ( [action type] == ActionType_Delay ){
			
			delay = [[action value] floatValue];
			
			[self stopMovement];
			
			log(LOG_WAYPOINT, @"Delaying for %0.2f seconds", delay);
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
				log(LOG_WAYPOINT, @"Unable to find route %@ to switch to!", UUID);
				
			}
			else{
				log(LOG_WAYPOINT, @"Switching route to %@ with %d waypoints", route, [[route routeForKey: PrimaryRoute] waypointCount]);
				
				// switch the botController's route!
				[botController setTheRouteSet:route];
				
				[self setPatrolRouteSet:route];
				
				[self resumeMovement];
				
				// after we switch routes, we don't want to continue any other actions!
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
					
					log(LOG_WAYPOINT, @"Turning in/grabbing quests to/from %@", questNPC);
					
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
			log(LOG_WAYPOINT, @"Interacting with mob %@", entryID);
			
			// moving bad, lets pause!
			[self stopMovement];
			
			// interact
			[botController interactWithMob:[entryID unsignedIntValue]];
		}

		// interact with object
		else if ( [action type] == ActionType_InteractObject ) {

			NSNumber *entryID = [action value];
			log(LOG_WAYPOINT, @"Interacting with node %@", entryID);

			// moving bad, lets pause!
			[self stopMovement];

			// interact
			[botController interactWithNode:[entryID unsignedIntValue]];
		}

		// repair
		else if ( [action type] == ActionType_Repair ) {

			// get all nearby mobs
			NSArray *nearbyMobs = [mobController mobsWithinDistance:INTERACT_RANGE levelRange:NSMakeRange(0,255) includeElite:YES includeFriendly:YES includeNeutral:YES includeHostile:NO];
			Mob *repairNPC = nil;
			for ( repairNPC in nearbyMobs ) {
				if ( [repairNPC canRepair] ) {
					log(LOG_WAYPOINT, @"Repairing with %@", repairNPC);
					break;
				}
			}

			// repair
			if ( repairNPC ) {
				[self stopMovement];
				if ( [botController interactWithMouseoverGUID:[repairNPC GUID]] ){
					
					// sleep some to allow the window to open!
					usleep(500000);
					
					// now send the repair macro
					[macroController useMacro:@"RepairAll"];	
					
					log(LOG_WAYPOINT, @"All items repaired");
				}
			}
			else{
				log(LOG_WAYPOINT, @"Unable to repair, no repair NPC found!");
			}
		}
		
		// switch combat profile
		else if ( [action type] == ActionType_CombatProfile ) {
			log(LOG_WAYPOINT, @"Switching from combat profile %@", botController.theCombatProfile);

			CombatProfile *profile = nil;
			NSString *UUID = [action value];
			for ( CombatProfile *otherProfile in [combatProfileEditor combatProfiles] ){
				if ( [UUID isEqualToString:[otherProfile UUID]] ) {
					profile = otherProfile;
					break;
				}
			}

			[botController changeCombatProfile:profile];
		}

		// jump to waypoint
		else if ( [action type] == ActionType_JumpToWaypoint ) {

			int waypointIndex = [[action value] intValue] - 1;
			NSArray *waypoints = [self.currentRoute waypoints];

			if ( waypointIndex >= 0 && waypointIndex < [waypoints count] ){
				self.destinationWaypoint = [waypoints objectAtIndex:waypointIndex];
				log(LOG_WAYPOINT, @"Jumping to waypoint %@", self.destinationWaypoint);
				[self resumeMovement];
			}
			else{
				log(LOG_WAYPOINT, @"Error, unable to move to waypoint index %d, out of range!", waypointIndex);
			}
		}
		
		// mail
		else if ( [action type] == ActionType_Mail ){

			MailActionProfile *profile = (MailActionProfile*)[profileController profileForUUID:[action value]];
			log(LOG_WAYPOINT, @"Initiating mailing profile: %@", profile);
			[itemController mailItemsWithProfile:profile];
		}

	}

	log(LOG_WAYPOINT, @"Action %d complete, checking for more!", actionToExecute);

	if (delay > 0.0f) {
		_performingActions = YES;
		[botController evaluateSituation];	// Lets run evaluation while we're waiting, it will not move while performingActions
		[self performSelector: _cmd
			   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
							actions,									@"Actions",
							[NSNumber numberWithInt:++actionToExecute],	@"CurrentAction",
							nil]
				afterDelay: delay];
	} else {
		[self performSelector: _cmd
				   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
								actions,									@"Actions",
								[NSNumber numberWithInt:++actionToExecute],	@"CurrentAction",
								nil]
				   afterDelay: delay];
		
	}
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
