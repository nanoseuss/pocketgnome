//
//  MPOperationEQ.h
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPOperation.h"


/*!
 * @class MPOperationEQ
 * @abstract An MPValue object that represents an conditional == operation.
 * @discussion 
 *	An MPOperationEQ is used when there is an == comparison of two values in an equation.  For example, 
 *  <pre>
 *	When 
 *  {
 *		$Cond = $MyLevel == 22;
 *	}
 *  </pre>
 *
 *  In this $Cond, an MPOperationEQ would return the boolean result of this comparison.
 */
@interface MPOperationEQ : MPOperation {

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
+ (MPOperationEQ *) operation;

@end
