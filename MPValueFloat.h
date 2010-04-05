//
//  MPFloatValue.h
//  TaskParser
//
//  Created by Coding Monkey on 9/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"




/*!
 * @class MPFloatValue
 * @abstract An MPValue object that represents a simple double/float value.
 * @discussion 
 *	An MPFloatValue is used when the number it represents was given in an equation.  For example, 
 *  <pre>
 *	Par 
 *  {
 *		$MaxDistance =  30.0;  // could also work for 30
 *	}
 *  </pre>
 *
 *  In the definition of $MaxDistance, an MPFloatValue would be used to represent the 30.0.
 */
@interface MPValueFloat : MPValue {
	
	float floatValue;
}

@property (readwrite) float floatValue;


/*!
 * @function value
 * @abstract Return the actual value of this object.
 *
 */
- (float) value;


/*!
 * @function initWithData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPValueFloat *) initWithString: (NSString *) data;
+ (MPValueFloat *) floatFromString: (NSString *) data;

+ (MPValueFloat *) initWithFloat: (float) data;

@end
