//
//  MPBoolValue.h
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"

/*!
 * @class MPBoolValue
 * @abstract An MPValue object that represents a simple BOOL value.
 * @discussion 
 *	An MPBoolValue is used when representing conditional statements. For example, 
 *  <pre>
 *	If 
 *  {
 *		$Cond =  $MyLevel <= 10; 
 *		Par {
 *			...
 *		}
 *	}
 *  </pre>
 *
 * Your task should retrieve the $Cond value by using 
 */
@interface MPValueBool : MPValue {
	BOOL boolValue;
}
@property (readwrite) BOOL boolValue;


/*!
 * @function value
 * @abstract Return the actual value of this object.
 */
- (BOOL) value;


/*!
 * @function initWithData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPValueBool *) initWithData: (BOOL) data;


@end
