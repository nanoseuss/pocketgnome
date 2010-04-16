//
//  MPActivityTestPosition.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MPActivityTestPosition.h"
#import "MPActivity.h"
#import "MPTask.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "BotController.h"
#import "MobController.h"
#import "Mob.h"
#import "Waypoint.h"
#import "Position.h"
#import "Offsets.h"

#import "MPMover.h"
#import "MPSpell.h"

#import "SpellController.h"
#import "Spell.h"

@implementation MPActivityTest
@synthesize key, targetName;


- (id) init {
	return [self initWithTask:nil];
}

- (id) initWithTask:(MPTask*)aTask {
	
	if ((self = [super initWithName:@"Test Task" andTask:aTask])) {
		
		
		key = nil;
		targetName = nil;
		
//		self.timerWaitTime =  [MPTimer randomTimerFrom:20 To:80];
		
		
	}
	return self;
}


- (void) dealloc
{
 //   [timerWaitTime release];
    [super dealloc];
}


#pragma mark -



- (void) start {
	MPMover *mover = [MPMover sharedMPMover];
	[mover resetMovementState];
}


- (BOOL) work {
	
	if ((key == nil) || ([key isEqualToString:@"positioncheck"])) {
		
		
		
//		Position *myPosition = [[[task patherController] playerData] position];
		Mob *targetMob = nil;
		NSArray *mobList = [[[task patherController] mobController] allMobs];
		for (Mob *mob in mobList) {
//			PGLog(@" checking mob[%@]",[mob name]);
			if ([targetName isEqualToString:[mob name]]) {
				targetMob = mob;
			}
		}
		
		
		if (targetMob != nil) {
			
			/*
			PlayerDataController *player = [PlayerDataController sharedController];
			Position *myPosition = [player position];
			float angle = [myPosition angleTo:[targetMob position]];
			float myDirection = [player directionFacing];
			
			if ( fabsf(angle - myDirection) > M_PI ){
                if ( angle < myDirection )	angle += (M_PI*2);
                else								myDirection += (M_PI*2);
            }
            
            // find the difference between the angles
            float angleTo = (angle - myDirection), absAngleTo = fabsf(angleTo);
			
			PGLog(@"checking direction angle[%0.3f] my directionFacing[%0.3f]", angle, [player directionFacing]);
			PGLog(@"  angleTo[%0.3f]  absAngleTo[%0.3f]", angleTo, absAngleTo);
			
			if ( (angleTo < M_PI_4) && (angleTo > -M_PI_4)) {
				PGLog(@"   ---> Front");
			}
			if ( (angleTo <= -M_PI_4) && (angleTo > -3*M_PI_4)) {
				PGLog(@"   ---> Right");
			}
			if ( (angleTo <= -3*M_PI_4) || (angleTo >= 3*M_PI_4) ) {
				PGLog(@"   ---> Back");
			}
			if ( (angleTo >= M_PI_4) && (angleTo < 3*M_PI_4)) {
				PGLog(@"   ---> Left");
			}
			*/
			
			MPMover *mover = [MPMover sharedMPMover];
			int direction = [mover directionOfPosition:[targetMob position]];
			PGLog(@" ---> mover directionOfPosition: %d  angleTowards[%0.4f]", direction, [mover angleTurnTowards:[targetMob position]]);
			
			MPLocation *testLoc = [MPLocation locationBehindTarget:targetMob atDistance:5.0f];
			
//			[mover moveTowards:(MPLocation *)[targetMob position] within:3.0f facing:(MPLocation *)[targetMob position]];
			[mover moveTowards:testLoc within:1.0f facing:(MPLocation *)[targetMob position]];
			[mover action];
			
			
			/*
			
			//// let's try grabbing some Spell Info
			SpellController *spellController = [SpellController sharedSpells];
			Spell *spell = [spellController playerSpellForName:@"Thorns"];
			if (spell) {
				PGLog(@"   ===> spell [%@] [%d]", [spell name], [[spell ID] intValue]);
			}else {
				PGLog(@"   ===> spell [Thorns] not found ... ");
			}
			
			PlayerDataController *me = [PlayerDataController sharedController];
			if (![spellController isSpellOnCooldown:[[spell ID] intValue]]) {
				
				if ([me percentMana] > 50) {
					
					[[[task patherController] botController] performAction:[[spell ID] intValue]];
				}

			}
			
			Spell *innervate = [spellController playerSpellForName:@"Innervate"];
			if (![spellController isSpellOnCooldown:[[innervate ID] intValue]]) {
				[[[task patherController] botController] performAction:[[innervate ID] intValue]];
			} else {
				PGLog(@"    ====> spell Innervate is on Cooldown. ");
			}
			*/
			
			MPSpell *thorns = [MPSpell thorns];
			PlayerDataController *me = [PlayerDataController sharedController];
			if ([me percentMana] > 50) {
				if (![thorns unitHasBuff:(Unit *)[me player]]) {
					[thorns cast];
				} else {
					PGLog(@"   ---> Already have Thorns!");
				}
			}
			
			
			/*
			 
			 Design:
			 
			 MPSpell
			 MPBuff
			 MPDebuff
			 
			 [DruidSpell rejuvination] 
			 {
				MPSpell *spell = [MPSpell spell];
				[spell setName:@"Rejuvination"]
				[spell addID: 100] // Rank 1
				[spell addID: 200] // Rank 2
				...
				[spell setTimer: 12000]; // 12 sec duration  (like for rejuvination)
				[spell scanActionBar]; // look to find actionbar location & grab current ID
				return spell;
			 }
			 
			 MPSpell *wrath = [DruidSpell wrath];
			 if ([wrath canCast]) {
			 
				int error = [wrath cast];
			 }
			 
			 MPSpell *rejuv = [DruidSpell rejuvination];
			 if ((![rejuv unitHasBuff:[player guid]) || ([rejuv isReadyForUnit: [player guid]]) ) {
				[rejuv castOnUnit:[player guid]];
			 }
			 
			 MPSpell *thorns = [DruidSpell thorns];
			 if (![thorns unitHasBuff:[player guid]]) {
				[thorns castOnUnit:[player guid];
			 }
			 
			 
			 
			 */
			
		} else {
			PGLog(@" Position Check: mob[%@] not found", targetName);
		}
		
	}
//	NSInteger testVal = [[task patherController] getMyLevel];
//	PGLog(@" the patherController's test value[%d]", testVal );
	
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}


- (void) stop{}


#pragma mark -

+ (id) activityForTask: (MPTask*) aTask andDict:(NSDictionary *)dict{
	
	MPActivityTest *newActivity = [[MPActivityTest alloc] initWithTask: aTask];
	newActivity.key = [dict objectForKey:@"actionKey"];
	newActivity.targetName = [dict objectForKey:@"targetName"];
	return newActivity;
}

@end
