//
//  MPOperationNEQ.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPOperationEQ.h"


/*!
 * @class MPOperationNEQ
 * @abstract An MPValue object that represents an conditional != operation.
 * @discussion 
 *	An MPOperationNEQ is used when there is an != comparison of two values in an equation.  For example, 
 *  <pre>
 *	When 
 *  {
 *		$Cond = $MyLevel != 22;
 *	}
 *  </pre>
 *
 *  In this $Cond, an MPOperationNEQ would return the boolean result of this comparison.
 */
@interface MPOperationNEQ : MPOperationEQ {

}




/*!
 * @function operation
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPOperationNEQ *) operation;

@end
