//
//  MPMyLevelValue.h
//  MacPather
//
//  Created by Coding Monkey on 9/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"
@class PatherController;

/*!
 * @class MPMyLevelValue
 * @abstract An MPValue object that represents the current level of the toon.
 * @discussion 
 *	An MPMyLevelValue is used when the in place of the pather $MyLevel variable.  For example, 
 *  <pre>
 *	Par 
 *  {
 *		$MaxLevel =  $MyLevel + 2;  
 *	}
 *  </pre>
 *
 *  In the definition of $MaxDistance, an MPMyLevelValue would be used to represent $MyLevel.
 */
@interface MPMyLevelValue : MPValue {
}


/*!
 * @function value
 * @abstract Return the actual level of this toon.
 *
 */
- (NSInteger) value;


/*!
 * @function initWithData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPMyLevelValue *) initWithPather: (PatherController *) controller;

@end
