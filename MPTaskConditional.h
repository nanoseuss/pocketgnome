//
//  MPConditionalTask.h
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTask.h"
#import "MPValueBool.h"

@interface MPTaskConditional : MPTask {
	MPValueBool *condition;
	MPTask *child;	// conditional tasks only have 1 child
}

@property (readwrite,retain) MPValue *condition;
@property (readwrite,retain) MPTask *child;

@end
