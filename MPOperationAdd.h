//
//  MPOperationAdd.h
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"
#import "MPOperation.h"


/*!
 * @class MPOperationAdd
 * @abstract An MPValue object that represents an addition operation.
 * @discussion 
 *	An MPOperationAdd is used when there is an addition of two values in an equation.  For example, 
 *  <pre>
 *	Par 
 *  {
 *		$MaxLevel = $MyLevel + 2;
 *	}
 *  </pre>
 *
 *  In the definition of $MaxLevel, an MPOperationAdd would return the sum of the two values.
 */
@interface MPOperationAdd : MPOperation {

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
+ (MPOperationAdd *) operation;

@end
