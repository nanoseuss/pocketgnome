//
//  MPTaskWait.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class MPActivityWait;

@interface MPTaskWait : MPTask {
	MPActivityWait *myActivity;
}
@property (retain) MPActivityWait *myActivity;


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
