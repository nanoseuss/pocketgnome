//
//  MPLocation.h
//  TaskParser
//
//  Created by codingMonkey on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Position.h"
@class Mob;

@interface MPLocation : Position {


}


/*!
 * @function inFrontOfUsingHeading:andDistance:
 * @abstract Returns a MPLocation in front of the given point.
 * @discussion
 *	Attempts to give a location (distance) away from current location, in direction of heading.
 */
- (MPLocation *) locationAtHeading: (float) heading andDistance:(float) distance;


#pragma mark -

/*!
 * @function locationAtX
 * @abstract Returns a MPLocation with the given XYZ coordinates.
 * @discussion
 */
+ (id) locationAtX: (float)xLoc Y: (float)yLoc Z:(float)zLoc;

/*!
 * @function locationFromVariableData
 * @abstract Returns a MPLocation from the contents of the given array.
 * @discussion
 *	This array is expected to have come from a task file (or maybe a mesh file).  the format 
 *  should be:  array[string(x),string(y),string(z)]
 */
+ (MPLocation*) locationFromVariableData: (NSArray *)locationData;

+ (id) locationFromPosition: (Position *) position;

/*!
 * @function locationInFrontOfTarget:atDistance
 * @abstract Returns a location in front of the given target.
 * @discussion
 *	
 */
+ (id) locationInFrontOfTarget:(Mob *)mob atDistance:(float) distance;
+ (id) locationBehindTarget:(Mob *)mob atDistance:(float) distance;
@end
