//
//  MPStack.h
//  TaskParser
//
//  Created by Coding Monkey on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableArray (MPStack)
	- (void)push:(id)inObject;
	- (id)pop;
@end

