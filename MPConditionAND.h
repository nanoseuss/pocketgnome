//
//  MPOperationAND.h
//  TaskParser
//
//  Created by Coding Monkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCondition.h"


/*!
 * @class MPConditionAND
 * @abstract An MPValue object that represents an conditional && operation.
 * @discussion 
 *	An MPConditionAND is used when there is an && comparison of two values in an equation.  For example, 
 *  <pre>
 *	When 
 *  {
 *		$Cond = ($MyLevel >= 18) && ( $MyLevel <= 22);
 *	}
 *  </pre>
 *
 *  In this $Cond, an MPConditionAND would return the boolean result of these two comparison.
 */
@interface MPConditionAND : MPCondition	{

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
+ (MPConditionAND *) operation;


@end
