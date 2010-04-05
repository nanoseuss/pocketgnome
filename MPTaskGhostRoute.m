//
//  MPTaskGhostRoute.m
//  Pocket Gnome
//
//  Created by admin on 10/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskGhostRoute.h"
#import "MPTask.h"

#import "MPTimer.h"
#import "MPActivityWait.h"
#import "MPActivityWalk.h"
#import "Waypoint.h"
#import "MPLocation.h"
#import "Position.h"
#import "Route.h"
#import "PatherController.h"
#import "MacroController.h"
#import "PlayerDataController.h"



@interface MPTaskGhostRoute (Internal)

- (BOOL) isDead;
- (BOOL) isGhost;

- (void) rePop;
- (void) revive;

- (void) clearWalkToWaypoint;
- (void) clearWalkToPosition;
- (void) clearWaitActivity;

@end


@implementation MPTaskGhostRoute
@synthesize waitActivity, walkToWaypointActivity, walkToPositionActivity, timerRetry, route, closestWaypoint, corpseLocation;
@synthesize locations;

- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"GhostRoute";
		self.waitActivity = nil;
		self.walkToWaypointActivity = nil;
		self.walkToPositionActivity = nil;
		self.corpseLocation = nil;
		self.closestWaypoint = nil;
		
		timerRetry = [MPTimer timer:5000];
		
		self.locations = nil;
		self.route = nil;

		state = GhostRouteWaitForRePop;
	}
	return self;
}

- (void) setup {
	
	self.locations = [self locationsFromVariable:@"locations"];

	
	// now create a route out of these locations:
	self.route = [Route route];
	for( MPLocation *location in locations) {
		[route addWaypoint:[Waypoint waypointWithPosition:location]];
	}
	
}


- (void) dealloc
{
	PGLog(@"[GhostRoute dealloc]");
	[waitActivity release];
	[walkToWaypointActivity release];
	[walkToPositionActivity release];
	[corpseLocation release];
	[closestWaypoint release];
	
	[timerRetry release];
	
	[route release];
	[locations release];
	
    [super dealloc];
}

#pragma mark -




- (BOOL) isFinished {
	return NO;
}


- (MPLocation *) location {
	
	// ok, should probably return the next Waypoint
	return nil;
}


- (void) restart {
	state = GhostRouteWaitForRePop;
}


- (BOOL) wantToDoSomething {
	PGLog(@"[GhostRoute wtds]");
	
	// if !isDead 
	if( ![self isDead] ) {
		state = GhostRouteWaitForRePop;
		self.corpseLocation = nil;
		return NO;
	} 
	
	// switch state
	switch (state) {
		case GhostRouteWaitForRePop:
			// if isDead && !isGhost
			if ([self isDead] && ![self isGhost]) {
				
				PGLog(@"I'm dead but not a ghost ... try to Repop. myPosition[%@]", [self myPosition]);
				[self rePop];
				state = GhostRouteWaitForGraveYard;
				[timerRetry start];
			}
			
			// if isGhost
			if ([self isGhost] ) {
				PGLog(@" I'm dead, and a ghost, must be at graveyard...myPosition[%@]", [self myPosition]);
				state = GhostRouteWaitForGraveYard;
			}
			break;
			
		case GhostRouteWaitForGraveYard:
			// if timerRetry ready
			if ([timerRetry ready] ) {
				
				PGLog(@"timerRetry expired waiting for repop ... trying again.");
				state = GhostRouteWaitForRePop;
			}
			
			// if isGhost 
			if ([self isGhost] ) {
				[timerRetry reset]; // don't want this going off while we wait for proper exiting state ... 
				PGLog(@"We are now a Ghost.  Find WP closest to corpse and run to there. myPosition[%@]", [self myPosition]);
				
				// find closestWaypoint
				self.corpseLocation = (MPLocation *)[[patherController playerData] corpsePosition];
				if (corpseLocation != nil) {
					
					if (([corpseLocation xPosition] == 0) && ([corpseLocation yPosition] == 0) && ([corpseLocation zPosition] == 0)) {
						PGLog (@"   ---> corpseLocation returned [0,0,0] .... waiting " );
					} else {
					
						self.closestWaypoint = [route waypointClosestToPosition:corpseLocation];
						state = GhostRouteGhostWalkToClosestWaypoint;
						PGLog(@"   --> corpseLocation [%@]  closestWaypoint [%@]", corpseLocation, closestWaypoint);
					}
				} else {
					PGLog(@"corpseLocation was nil ... waiting here.");
				}
			} 
			break;
			
		case GhostRouteGhostWalkToClosestWaypoint:
			// if at closestWaypoint
			if ( [self myDistanceToPosition:[closestWaypoint position]] < 5.0 ) {
				PGLog (@"within 5 yards of closest Waypoint [%@], begin move to Corpse. myPosition[%@]", closestWaypoint, [self myPosition]);
				state = GhostRouteMoveToRezPoint;
			} // end if
			break;
			
		case GhostRouteMoveToRezPoint:
			// if near CorpsePosition
			if ([self myDistanceToPosition:corpseLocation] < 26.0f ) {
				PGLog (@"Moved within 26yds of corpse. Attempt to Rez...");
				[self revive];				
				state = GhostRouteVerifyRez;
			}
			break;
			
		case GhostRouteVerifyRez:
			// if !isDead
			if (![self isDead] ) {
				
				state = GhostRouteWaitForRePop;
				self.corpseLocation = nil;
				return NO;
			}
			break;
		default:
			break;
	}

	
	return YES;
}




- (MPActivity *) activity {
	PGLog(@"[Route activity]");

	
	// switch state
	switch (state) {
		case GhostRouteWaitForRePop:
		case GhostRouteWaitForGraveYard:
		case GhostRouteVerifyRez:
		default:
			// if walkToWaypointActivity != nil
			if (walkToWaypointActivity != nil) {
				[self clearWalkToWaypoint];
			}
			
			// if walkToPosition != nil
			if (walkToPositionActivity != nil) {
				[self clearWalkToPosition];
			}
			
			// if waitActivity == nil
			if (waitActivity == nil ) {
				// waitActivity = new MPActivityWait
				self.waitActivity = [MPActivityWait waitIndefinatelyForTask:self];
			}
			return waitActivity;
			break;
			
			
		case GhostRouteGhostWalkToClosestWaypoint:
			
			// if waitActivity != nil
			if (waitActivity != nil) {
				[self clearWaitActivity];
			}
			
			// if walkToPosition != nil
			if (walkToPositionActivity != nil) {
				[self clearWalkToPosition];
			}
			
			// if walkToWaypointActivity == nil
			if (walkToWaypointActivity == nil) {
				// walkToWaypointActivity = new MPActivityWalk Route
				self.walkToWaypointActivity = [MPActivityWalk walkRoute:route forTask:self useMount:NO];
			}
			
			return walkToWaypointActivity;
			break;
			
			
		case GhostRouteMoveToRezPoint:
			// if waitActivity != nil
			if (waitActivity != nil) {
				[self clearWaitActivity];
			}
			
			// if walkToWaypointActivity != nil
			if (walkToWaypointActivity != nil) {
				[self clearWalkToWaypoint];
			}
			
			// if walkToPosition == nil
			if (walkToPositionActivity == nil) {
				// walkToPosition = new MPActivityWalk CorpsePosition
				self.walkToPositionActivity = [MPActivityWalk walkToLocation:corpseLocation forTask:self useMount:NO];
			}
			return walkToPositionActivity;
			break;
	}
		
}



- (BOOL) activityDone: (MPActivity*)activity {
	PGLog(@"[Route activityDone]");
	// that activity is done so release it 

	
	return YES; // ??
}








- (NSString *) description {
	
	NSMutableString *text = [NSMutableString stringWithFormat:@" GhostRoute \n  %i points in route ", [[route waypoints] count]];
	return text;
}

#pragma mark -
#pragma mark Internal Helpers


- (BOOL) isDead {
	return [[patherController playerData] isDead];
}

- (BOOL) isGhost {
	return [[patherController playerData] isGhost];
}

- (void) rePop {
	[[patherController macroController] useMacroOrSendCmd:@"ReleaseCorpse"];
}

- (void) revive {
	[[patherController macroController] useMacroOrSendCmd:@"Resurrect"];
//	[macroController useMacroOrSendCmd:@"Resurrect"];
}


- (void) clearWalkToWaypoint {
	[walkToWaypointActivity stop];
	[walkToWaypointActivity autorelease];
	self.walkToWaypointActivity = nil;
}


- (void) clearWalkToPosition {
	[walkToPositionActivity stop];
	[walkToPositionActivity autorelease];
	self.walkToPositionActivity = nil;
}


- (void) clearWaitActivity {
	[waitActivity stop];
	[waitActivity autorelease];
	self.waitActivity = nil;
}



#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskGhostRoute alloc] initWithPather:controller] autorelease];
}


@end
