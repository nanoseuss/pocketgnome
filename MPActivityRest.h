//
//  MPActivityRest.h
//  Pocket Gnome
//
//  Created by admin on 10/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPTimer;


/*!
 * @class      MPActivityRest
 * @abstract   This activity passes control to the [CustomClass rest] method.
 * @discussion 
 * This activity is used to pass control to the CustomClass' rest method.  
 */
@interface MPActivityRest : MPActivity {
	NSInteger lowHealth, lowMana, timeOutSeconds;
	BOOL restHealth, restMana;
	MPTimer *restingTimeOut;
}
@property (readwrite) NSInteger lowHealth, lowMana, timeOutSeconds;
@property (readonly, retain) MPTimer *restingTimeOut;

- (id) init;
- (id) initWithTask:(MPTask*)aTask;


#pragma mark -


/*!
 * @function restForLowHealth:orLowMana:forAtMost:forTask:
 * @abstract Initiate a rest state.
 * @discussion
 *	Returns an activity that will rest until the problematic attribute (health/mana) has been restored to it's max value.  You can set a 
 *  maximum amount of time in seconds that this task will rest.
 */
+ (id) restForLowHealth: (NSInteger) minHealth orLowMana: (NSInteger) minMana forAtMost: (NSInteger) seconds  forTask:(MPTask *)aTask;

@end
