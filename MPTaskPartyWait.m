//
//  MPTaskPartyWait.m
//  Pocket Gnome
//
//  Created by codingMonkey on 4/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPTaskPartyWait.h"

#import "MPActivityWait.h"
#import "MPLocation.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "Player.h"
#import "PlayerDataController.h"
#import "Position.h"



@interface MPTaskPartyWait (Internal)


@end




@implementation MPTaskPartyWait
@synthesize listParty, activityWait, timerRefreshListParty;



- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		
		name = @"PartyWait";
		
		maxDistance = 20.0f;
		
		self.activityWait = nil;
		self.listParty = nil;
		self.timerRefreshListParty = [MPTimer timer:30000]; // 30 seconds
		[timerRefreshListParty forceReady];
		
	}
	return self;
}



- (void) setup {
	
	maxDistance = [[self stringFromVariable:@"maxdistance" orReturnDefault:@"20.0"] floatValue];

}



- (void) dealloc
{
    [activityWait release];
    [listParty release];
	[timerRefreshListParty release];
	
    [super dealloc];
}



#pragma mark -



- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {
	
	return (MPLocation *)[[PlayerDataController sharedController] position];
}



- (void) restart {
	
}



- (BOOL) wantToDoSomething {

	if ([timerRefreshListParty ready]) {
	
		self.listParty = nil;
		self.listParty = [[PlayerDataController sharedController] partyMembers];
	
		[timerRefreshListParty start];
	}
	
	
	PlayerDataController *me = [PlayerDataController sharedController];
	
	// if we are in combat, : NO
	if ([me isInCombat]) return NO;
	
	
	// if we have no party member, we don't want to do anything:
	if ([listParty count] == 0) {
		return NO;
	}
	
	
	// find the farthest member away
	Position *myPosition = [me position];
	
	float distance = 0.0f;
	float currentDistance = 0.0f;
	for( Player *member in listParty) {
	
		currentDistance = [myPosition distanceToPosition:[member position]];
		if (currentDistance > distance) {
			distance = currentDistance;
		}
	}
	
	
	// if we found a member farther than maxDistance away.
	return (distance >= maxDistance);
}



- (MPActivity *) activity {
	
	
	if ( activityWait == nil) {
		self.activityWait = [MPActivityWait waitIndefinatelyForTask:self];
	}
	
	return (MPActivity *)activityWait;
	
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// let's keep our activity around so we don't keep recreating it
	
	return YES; // ??
}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	if ([listParty count]> 0) {
	
		Position *myPosition = [[PlayerDataController sharedController] position];
		
		float currentDistance = 0.0f;
		for( Player *member in listParty) {
		
			currentDistance = [myPosition distanceToPosition:[member position]];
			if (currentDistance > maxDistance) {
				
				[text appendFormat:@"   %@ : %0.2f  / %0.2f", [member name], currentDistance, maxDistance];
				
			}
		}
	
		
	} else {
		[text appendFormat:@"   no party members"];
	}
	
	return text;
}



#pragma mark -



+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskPartyWait alloc] initWithPather:controller] autorelease];
}

@end
