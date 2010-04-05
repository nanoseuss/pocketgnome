//
//  MPIntValue.h
//  TaskParser
//
//  Created by Coding Monkey on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"




/*!
 * @class MPIntValue
 * @abstract An MPValue object that represents a simple integer value.
 * @discussion 
 *	An MPIntValue is used when the number it represents was given in an equation.  For example, 
 *  <pre>
 *	Par 
 *  {
 *		$MaxLevel = $MyLevel + 2;
 *	}
 *  </pre>
 *
 *  In the definition of $MaxLevel, an MPIntValue would be used to represent the 2.
 */
@interface MPValueInt : MPValue {

	NSInteger integerValue;
}

@property (readwrite) NSInteger integerValue;


/*!
 * @function value
 * @abstract Return the actual value of this object.
 *
 */
- (NSInteger) value;


/*!
 * @function intFromString
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPValueInt *) intFromString: (NSString *) data;



/*!
 * @function initWithData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPValueInt *) intFromData: (NSInteger) data;

@end
