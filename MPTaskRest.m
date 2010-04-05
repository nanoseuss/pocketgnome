//
//  MPTaskRest.m
//  Pocket Gnome
//
//  Created by admin on 10/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPTaskRest.h"
#import "MPTask.h"
#import "MPActivityRest.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "Player.h"

@implementation MPTaskRest
@synthesize restActivity;


- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Rest";
		restActivity = nil;
		minHealth=-1;
		minMana=-1;
		ignoreMana=NO;
	}
	return self;
}

- (void) setup {
	
	minHealth = (NSInteger) [[self integerFromVariable:@"minhealth" orReturnDefault:-1] value];
	PGLog(@"Rest setup: minHealth=%d", minHealth);
	
	minMana  = (NSInteger) [[self integerFromVariable:@"minmana" orReturnDefault:-1] value];
	PGLog(@"Rest setup: minMana=%d", minMana );
	
	Player *player = [[patherController playerData] player];
	
	ignoreMana = [@"Warrior" isEqualToString:[Unit stringForClass: [player unitClass]]] 
				 || [@"Rogue" isEqualToString:[Unit stringForClass: [player unitClass]]];
}


- (void) dealloc
{
	PGLog(@"[Rest dealloc]");
    [restActivity release];
	
    [super dealloc];
}

#pragma mark -




- (BOOL) isFinished {
	return NO;
}



- (MPLocation *) location {
	
	return nil;
}


- (void) restart {

}


- (BOOL) wantToDoSomething {
	PGLog(@"[Rest wtds]");
	// as long as we are not done, we do want To Do something
	
	PlayerDataController *player = [patherController playerData];
	
	if ([player isDead] ||
		[player isGhost] ||
		[player isInCombat] )
		return NO;
	
	
	if ((int)[player percentHealth] <= (int) minHealth) {  
		PGLog(@"   Rest:  pH[%d] <= mH[%d] (currentH[%d])", [player percentHealth], minHealth,[player health]);
		return YES;
	}
	
	
	if (((int)[player percentMana] <= (int) minMana) && (!ignoreMana)) {
		PGLog(@"   Rest:  pM[%d] <= mM[%d] (currentM[%d])", [player percentMana], minMana, [player mana]);
		return YES;
	}
	
	if (restActivity != nil) return YES; // we are currently resting ... continue to want to do something until it reports done.
	
	return NO;
}



- (MPActivity *) activity {
	PGLog(@"[Rest activity]");
	// create (or recreate) our activity if it isn't already created
	if (restActivity == nil)	{
		[self setRestActivity:[MPActivityRest  restForLowHealth:minHealth orLowMana:minMana forAtMost: 28  forTask:self]];
	}
	
	// return the activity to work on
	return restActivity;
}



- (BOOL) activityDone: (MPActivity*)activity {
	PGLog(@"[Rest activityDone]");
	// that activity is done so release it 
	if (activity == restActivity) {
		[restActivity autorelease];
		[self setRestActivity:nil];
	}
	
	return NO; // ??
}





- (NSString *) description {
	
	NSMutableString *text = [NSMutableString stringWithString:@" Rest \n"];
	if (minHealth > 0) {
		[text appendFormat:@"\t Health: min[%d]/ %d / 100\n", minHealth, [[patherController playerData] percentHealth]];
	}
	if (minMana > 0) {
		[text appendFormat:@"\t Mana: min[%d]/ %d / 100\n", minMana, [[patherController playerData] percentMana]];
	}
	return text;
}

#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskRest alloc] initWithPather:controller] autorelease];
}




@end
