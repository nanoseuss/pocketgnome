//
//  MPValue.h
//  TaskParser
//
//  Created by Coding Monkey on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPParser.h"
@class PatherController;

/*!
 * @class MPValue
 * @abstract An object to help us simplify equation evaluation and task file parsing of values.
 * @discussion 
 *	MPValue is used to represent a Value that is used by our task.  A value can represent a scalar value 
 *  (like an int '4' or float '4.0') or it can also represent a MPPather function like $MyLevel.
 *
 *
 * A MPValue can return it's value with the method [self value];  This returned value is a scalar that can 
 * be used in operations/evaluations.
 */
@interface MPValue : NSObject {
	BOOL isString;
	PatherController *patherController;
}
@property (readonly) BOOL isString;
@property (retain) PatherController* patherController;

- (id) init;
- (id) initWithPather:(PatherController*)controller;


/*!
 * @function parseEquation
 * @abstract Compiles variables data into a value or an equation.
 * @discussion
 *	NOTE: MPFunctionValues need a reference to the patherController in order to work their mojo.
 */
+ (MPValue *) parseEquation: (PKTokenizer *)parser withDesiredType:(NSString*)type withPather:(PatherController*)controller;



/*!
 * @function nextValueWithParser
 * @abstract Parses the next MPValue object of the parser.
 * @discussion
 *	In the process of parsing an Equation, this method gets called numerous times to return an MPValue 
 * object to be used in the equation.
 */
+ (MPValue*) nextValueWithParser: (PKTokenizer *)parser withDesiredType:(NSString *) type withPather:(PatherController*)controller;



/*!
 * @function parseArray
 * @abstract Parses the next Array off of the parser.
 * @discussion
 *	This method will pull the next full array off of the parser.  It is possible to parse 
 * nested arrays with this method.  But the non array values will be returned as strings.
 */
+ (NSMutableArray*) parseArray: (PKTokenizer *)parser;



/*!
 * @function functionValueByKey
 * @abstract Return the function value corresponding to the given key.
 * @discussion
 *	Function values are specific MPvalues that have to read their values from PocketGnome classes.
 *
 *  Some examples would be: $MyLevel, $InventoryCount, etc...
 */
+ (MPValue *) functionValueByKey: (NSString *)key withPather:(PatherController*)controller;


/*!
 * @function operationValueByKey
 * @abstract Return the operation value corresponding to the given key.
 * @discussion
 *	Operation values are specific MPvalues that perform operations on other MPValues.
 *
 */
+ (MPValue *) operationValueByKey: (NSString *)key;


/*!
 * @function scalarValueFromData:withDesiredType:
 * @abstract Return a scalar value type according to the given key/Type
 * @discussion
 *	Returns one of the basic Scalar Value types (Integer or Float).
 *
 */
+ (MPValue *) scalarValueFromData: (NSString *)data withDesiredType:(NSString*)type;

@end
