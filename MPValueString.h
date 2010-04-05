//
//  MPStringValue.h
//  TaskParser
//
//  Created by codingMonkey on 9/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPValue.h"




/*!
 * @class MPStringValue
 * @abstract An MPValue object that represents a string value.
 * @discussion 
 *	An MPStringValue is used when an equation needs to do a string comparison.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$Cond = $MyClass = "Mage";
 *	}
 *  </pre>
 *
 *  In the definition of $Cond, both $MyClass and "Mage" are MPStringValues.
 *
 *  NOTE: the MPOperationEQ class will do specific tests for string values and perform the comparison
 *  using [[left value] isEqualToString: [right value]];
 */
@interface MPValueString : MPValue {
	NSString * stringValue;
}
@property (readwrite, retain) NSString *stringValue;


/*!
 * @function value
 * @abstract Return the actual value of this object.
 *
 */
- (NSString *) value;


/*!
 * @function stringFromData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPValueString *) stringFromData: (NSString *) data;


@end
