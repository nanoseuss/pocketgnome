//
//  MPTaskRest.h
//  Pocket Gnome
//
//  Created by admin on 10/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class Route;
@class MPActivityRest;

/*!
 * @class      MPTaskRest
 * @abstract   Restores Health and Mana according to set parameters.
 * @discussion 
 * (from http://wiki.ppather.net )
 * Character will rest with this task. Just set the min health/mana your character needs to have before initiating the rest procedure.
 * <code>
 *	 Rest
 *	 {
 *		 $Prio = 2;
 *		 $MinHealth = 25; // % value
 *		 $MinMana = 25; // % value
 *	 }
 * </code>
 *		
 */

@interface MPTaskRest : MPTask {
	NSInteger minHealth, minMana;
	MPActivityRest *restActivity;
	BOOL ignoreMana;
}
@property (retain) MPActivityRest *restActivity;




#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
