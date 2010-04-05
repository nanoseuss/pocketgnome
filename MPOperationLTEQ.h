//
//  MPOperationLTEQ.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPOperation.h"


/*!
 * @class MPOperationLTEQ
 * @abstract An MPValue object that represents an conditional <= operation.
 * @discussion 
 *	An MPOperationLTEQ is used when there is an <= comparison of two values in an equation.  For example, 
 *  <pre>
 *	When 
 *  {
 *		$Cond = $MyLevel <= 22;
 *	}
 *  </pre>
 *
 *  In this $Cond, an MPOperationLTEQ would return the boolean result of this comparison.
 */
@interface MPOperationLTEQ : MPOperation {

}


/*!
 * @function value
 * @abstract Return the actual value of this operation.
 *
 */
- (BOOL) value;


/*!
 * @function operation
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPOperationLTEQ *) operation;

@end
