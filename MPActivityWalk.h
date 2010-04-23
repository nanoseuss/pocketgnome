//
//  MPActivityWalk.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPCustomClass;
@class MPMover;
@class MovementController;
@class Route;


/*!
 * @class      MPActivityWalk
 * @abstract   This activity moves you around the world.
 * @discussion 
 * Need to get from one location to another?  This is the activity to use.  
 *
 * This activity is about walking longer distances.  Use this activity to walk a route, or walk to 
 * locations that are "farther" away.  
 *
 * This activity can be created several ways:
 * - [MPActivityWalk walkRoute: forTask: useMount:] : A route is given, so this is easy.  Just pass this onto the MC.
 *
 * - [MPActivityWait walkToLocation: forTask: useMount:] : given a location we will have to generate a 
 *   route. (this is what Pathing is all about isn't it).  
 *
 * - [MPActivityWalk walkToUnit: forTask: useMount:] : given an in game unit, generate a route to get there.
 *
 */
@interface MPActivityWalk : MPActivity {
	
	NSArray *listLocations;
	MPMover *mover;
	int currentIndex;
	BOOL useMount;
	MovementController *movementController;
	MPCustomClass *customClass;
}
@property (retain) NSArray *listLocations;
@property (retain) MPCustomClass *customClass;
@property (retain) MPMover *mover;
@property (retain) MovementController *movementController;


- (id) initWithRoute: (Route*)aRoute andTask:(MPTask*)aTask usingMount:(BOOL)mount;


 
#pragma mark -



/*!
 * @function walkRoute:forTask:useMount:
 * @abstract Walk this defined Route.
 * @discussion
 *	Returns a walk activity to run the current route.
 */
+ (id) walkRoute: (Route *) aRoute forTask:(MPTask *)aTask useMount:(BOOL)mount;



/*!
 * @function walkToLocation:forTask:useMount:
 * @abstract Walk to this location.
 * @discussion
 *	Will generate a route that takes you to the desired location. (eventually)
 */
+ (id) walkToLocation:(MPLocation*)aLocation forTask:(MPTask*) aTask useMount:(BOOL)mount;

@end
