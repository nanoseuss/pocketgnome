//
//  MPOperation.h
//  TaskParser
//
//  Created by Coding Monkey on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"



/*!
 * @class MPOperation
 * @abstract A value object that performs operations (mathmatical or conditional)
 * @discussion 
 *	When a [value] method is called on an MPOperation object, it returns the value of it's operation.
 */
@interface MPOperation : MPValue {

	MPValue *left, *right;
}
@property (readwrite,retain) MPValue* left;
@property (readwrite,retain) MPValue* right;


- (NSInteger) value;

@end
