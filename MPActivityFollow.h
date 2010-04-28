//
//  MPActivityFollow.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/19/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPCustomClass;
@class MPMover;
@class Position;
@class Unit;


typedef enum FollowState { 
    FollowStateInRange		= 1,	// Within desired distance range
	FollowStateApproaching	= 2,	// Need to Approach to Follow target
	FollowStateLastKnownPosition = 3  // Moving to last known position
} MPFollowState; 



/*!
 * @class      MPActivityFollow
 * @abstract   This activity follows an in game unit.
 * @discussion 
 * Tired of being a loner?  Then use this activity to follow a unit around in the world.
 *
 */
@interface MPActivityFollow : MPActivity {

	Unit *followUnit;
	float approachTo, maxDistance;
	
	float lastHeading;
	Position *lastPosition;
	NSMutableArray *targetRoute;
	
	MPCustomClass *customClass;
	MPMover *mover;
	MPFollowState state;
}
@property (retain) Unit *followUnit;
@property (retain) MPCustomClass *customClass;
@property (retain) MPMover *mover;
@property (retain) NSMutableArray *targetRoute;
@property (retain) Position *lastPosition;



+ (id) follow:(Unit *) unit howClose:(float)howClose howFar:(float) howFar forTask:(MPTask *) task ; 

@end
