//
//  MPOperationGT.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPOperation.h"

/*!
 * @class MPOperationGT
 * @abstract An MPValue object that represents an conditional > operation.
 * @discussion 
 *	An MPOperationGT is used when there is an > comparison of two values in an equation.  For example, 
 *  <pre>
 *	When 
 *  {
 *		$Cond = $MyLevel > 22;
 *	}
 *  </pre>
 *
 *  In this $Cond, an MPOperationGT would return the boolean result of this comparison.
 */
@interface MPOperationGT : MPOperation {

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
+ (MPOperationGT *) operation;

@end
