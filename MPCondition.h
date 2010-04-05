//
//  MPCondition.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"
#import "MPValueBool.h"


/*!
 * @class MPCondition
 * @abstract A value object that performs operations on other conditions (&& or ||)
 * @discussion 
 *	When a [value] method is called on an MPCondition object, it returns the BOOL condition of 
 *  it's operation.
 */@interface MPCondition : MPValue {
	 MPValueBool *left, *right;
}
@property (readwrite,retain) MPValueBool* left;
@property (readwrite,retain) MPValueBool* right;


- (BOOL) value;
@end
