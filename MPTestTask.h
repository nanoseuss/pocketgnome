//
//  MPTestTask.h
//  TaskParser
//
//  Created by admin on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
@class MPTimer;
//@class MPActivityWait;
@class TestActivity;
@class MPActivityTest;


typedef enum TestTaskState { 
    TestTaskStateBegin = 1, 
    TestTaskStateUp	= 2, 
    TestTaskStateDown	= 3
} MPTestTaskState; 


@interface MPTestTask : MPTask {
	NSInteger upTime;
	NSInteger downTime;
	MPTimer *timerUpTime;
	MPTimer *timerDownTime;
	MPTestTaskState state;
	
	NSArray *locations;
	
	NSString *action, *targetName;
	
	
//	MPActivityWait *myActivity;
	TestActivity *myActivity;
	MPActivityTest *testActivity;
}
@property (retain) NSString *action, *targetName;
@property (readonly, retain) MPTimer *timerUpTime, *timerDownTime;
//@property (retain) MPActivityWait *myActivity;
@property (retain) TestActivity *myActivity;
@property (retain) MPActivityTest *testActivity;
@property (retain) NSArray* locations;




#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
