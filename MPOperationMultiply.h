//
//  MPOperationMultiply.h
//  TaskParser
//
//  Created by Coding Monkey on 9/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"
#import "MPOperation.h"


/*!
 * @class MPOperationMultiply
 * @abstract An MPValue object that represents a multiplication operation.
 * @discussion 
 *	An MPOperationMultiply is used when there is a multiplication of two values in an equation.  For example, 
 *  <pre>
 *	Auction 
 *  {
 *		$MinAmount = $BaseAmount("Item") * 2;
 *	}
 *  </pre>
 *
 *  In the definition of $MinAmount, an MPOperationMultiply would return the multiplication of the two values.
 */
@interface MPOperationMultiply : MPOperation {

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
+ (MPOperationMultiply *) operation;

@end
