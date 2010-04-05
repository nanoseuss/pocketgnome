//
//  MPMyClassValue.h
//  TaskParser
//
//  Created by codingMonkey on 9/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPValue.h"

/*!
 * @class MPMyClassValue
 * @abstract An MPValue object that class name of the toon.
 * @discussion 
 *	An MPMyClassValue is used when the in place of the pather $MyClass variable.  For example, 
 *  <pre>
 *	If 
 *  {
 *		$Cond =  $MyClass = "Mage";  
 *	}
 *  </pre>
 *
 *  In the definition of $Cond, an MPMyClassValue would be used to represent $MyClass.
 */
@interface MPMyClassValue : MPValue {

}


/*!
 * @function value
 * @abstract Return the actual level of this toon.
 *
 */
- (NSString *) value;


/*!
 * @function initWithData
 * @abstract Convienience method to return an initialized object.
 *
 */
+ (MPMyClassValue *) initWithPather: (PatherController *) controller;

@end
