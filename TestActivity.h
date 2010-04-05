//
//  TestActivity.h
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPTimer;

@interface TestActivity : MPActivity {
MPTimer *timerWaitTime;		 // how long to wait.
}
@property (retain) MPTimer *timerWaitTime;


- (id) init;
- (id) initWithTask:(MPTask*)aTask;

/*!
 * @function waitIndefinately
 * @abstract Just keep waiting.
 * @discussion
 *	Returns a wait activity that just keeps on waiting.  No done will be reported.  It is useful as a 
 *  filler task waiting for other higher priority tasks to become active.
 */
+ (id) waitIndefinatelyForTask: (MPTask*) aTask;

@end
