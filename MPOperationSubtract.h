//
//  MPOperationSubtract.h
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"
#import "MPOperation.h"

/*!
 * @class MPOperationSubtract
 * @abstract An MPValue object that represents a subtraction operation.
 * @discussion 
 *	An MPOperationSubtract is used when there is a subtraction of two values in an equation.  For example, 
 *  <pre>
 *	Par 
 *  {
 *		$MinLevel = $MyLevel - 2;
 *	}
 *  </pre>
 *
 *  In the definition of $MinLevel, an MPOperationSubtract would return the difference of the two values.
 */
@interface MPOperationSubtract : MPOperation {

}


/*!
 * @function value
 * @abstract Return the actual value of this operation.
 *
 */
- (NSInteger) value;


/*!
 * @function operation
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPOperationSubtract *) operation;

@end
