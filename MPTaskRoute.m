//
//  MPRouteTask.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskRoute.h"
#import "MPTask.h"
#import "Route.h"
#import "Waypoint.h"

#import "MPActivityWalk.h"
#import "PatherController.h"
#import "BotController.h"
#import "MPTaskController.h"


@interface MPTaskRoute (Internal)

/*!
 * @function clearWalkActivity
 * @abstract Properly shuts down the Walk Activity.
 * @discussion
 */
- (void) clearWalkActivity;


@end



@implementation MPTaskRoute
@synthesize walkActivity;
@synthesize taskController;
@synthesize locations;
@synthesize route;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Route";
		walkActivity = nil;
		self.locations = nil;
		self.route = nil;
		done = NO;
		
		self.taskController = [controller taskController];
		
	}
	return self;
}

- (void) setup {

	self.locations = [self locationsFromVariable:@"locations"];
	repeat  = [self boolFromVariable:@"repeat" orReturnDefault:NO];
	inOrder = [[[self stringFromVariable:@"order" orReturnDefault:@"order"] lowercaseString] isEqualToString:@"order"];

	
	if (!inOrder) {
		// oops, we want these in reverse.  Let's switch them:
		NSMutableArray *reversedLocations = [NSMutableArray arrayWithCapacity:[locations count]];
		NSEnumerator *enumerator = [locations reverseObjectEnumerator];
		for (id location in enumerator) {
			[reversedLocations addObject:location];
		}
		self.locations = [reversedLocations copy];
	}
	
	// now create a route out of these locations:
	self.route = [Route route];
	for( MPLocation *location in locations) {
		[route addWaypoint:[Waypoint waypointWithPosition:location]];
	}
	
}


- (void) dealloc
{
	PGLog(@"[Route dealloc]");
    [locations release];
	[walkActivity release];
	[route release];
	[taskController release];
	
    [super dealloc];
}

#pragma mark -



- (BOOL) isFinished {
	return done;
}



- (MPLocation *) location {

	// ok, should probably return the next Waypoint
	return nil;
}


- (void) restart {
	done = NO;
 }


- (BOOL) wantToDoSomething {
	PGLog(@"[Route wtds]");
	// as long as we are not done, we do want To Do something
	// also make sure we are not still "inCombat"
	return ((!done) && (![taskController inCombat]));
}



- (MPActivity *) activity {
	PGLog(@"[Route activity]");
	// create (or recreate) our activity if it isn't already created
	if (walkActivity == nil)	{
		PGLog(@"[Rout activity] --> creating New Activity" );
		BOOL useMount = NO; // [[[patherController botController] mountCheckbox] state];
		[self setWalkActivity:[MPActivityWalk walkRoute:route forTask:self useMount:useMount]];
	}
	
	// return the activity to work on
	return walkActivity;
}



- (BOOL) activityDone: (MPActivity*)activity {
PGLog(@"[Route activityDone]");
	// that activity is done so release it 
	if (activity == walkActivity) {
		[self clearWalkActivity];
		if (!repeat) {
			done = YES;  // activity is done, then so are we.
		}
	}
	
	return YES; // ??
}



- (void) clearWalkActivity {
	[walkActivity stop];
	[walkActivity autorelease];
	self.walkActivity = nil;
}



- (NSString *) description {
	
	NSMutableString *text = [NSMutableString stringWithFormat:@" Route \n  %i points in route ", [[route waypoints] count]];
	return text;
}

#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskRoute alloc] initWithPather:controller] autorelease];
}


@end
