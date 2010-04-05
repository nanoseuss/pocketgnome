//
//  MPValue.m
//  TaskParser
//
//  Created by Coding Monkey on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "MPValueInt.h"
#import "MPMyLevelValue.h"
#import "MPMyClassValue.h"
#import "MPParser.h"
#import "MPStack.h"
#import "MPValue.h"
#import "MPOperation.h"
#import "MPValueInt.h"
#import "MPValueFloat.h"
#import "MPValueString.h"
#import "MPMyLevelValue.h"
#import "MPOperation.h"
#import "MPOperationAdd.h"
#import "MPOperationSubtract.h"
#import "MPOperationMultiply.h"
#import "MPOperationEQ.h"
#import "MPOperationGT.h"
#import "MPOperationLT.h"
#import "MPOperationGTEQ.h"
#import "MPOperationLTEQ.h"
#import "MPOperationNEQ.h"
#import "MPConditionAND.h"
#import "MPConditionOR.h"
#import "PatherController.h"


@implementation MPValue
@synthesize isString;
@synthesize patherController;

-(id) init {
	return [self initWithPather:nil];
}

- (id) initWithPather:(PatherController *)controller {
	if ((self = [super init])) {
		self.patherController = controller;
		isString = NO;
	}
	return self;
}

#pragma mark -


+ (MPValue*) parseEquation: (PKTokenizer *)parser withDesiredType:(NSString*)type withPather:(PatherController*)controller  {
	
	NSMutableArray* equationStack = [NSMutableArray array];
	MPValue *currentValue, *rightValue,  *leftValue;
	MPOperation* operation;
	
	do {
		currentValue = [MPValue nextValueWithParser:parser withDesiredType:type withPather:controller];
		
		if ( currentValue != nil) {
				
			// push currentValue
			[equationStack push:currentValue];
			
			// if stackCount = 3
			if ([equationStack count] == 3) {
				
				// stack objects should be: right, op, left
				rightValue = [equationStack pop];
				operation = [equationStack pop];
				leftValue = [equationStack pop];
				
				// combine values into the operation
				[operation setLeft: leftValue];
				[operation setRight: rightValue];
				
				// store the operation back on the stack
				[equationStack push: operation];
				
			} // end if
			
		}
		
	} while( currentValue != nil);  // while curr != nil
	
	if ([equationStack count] > 1) {
		PGLog(@" Error in MPValue::parseEquation: Ended up with >1 values on the stack!");
	}
	
	return [equationStack pop];
}


+ (MPValue*) nextValueWithParser: (PKTokenizer *)parser withDesiredType:(NSString *) type withPather:(PatherController*)controller{
	
	NSString *current;
	NSString *name;
	MPValue *value;
	
	// curr = [nextToken]
	current = [[parser nextToken] stringValue];
	
	//if a valid value was returned
	if (current != nil) {
		
//	if ([current isEqualToString:@"["]) {
//		value = [MPValue parseArray:parser];
//		return value;
//	}
	
	// if curr == $
	if ([current isEqualToString: @"$"]) {
		
		// name = [nextToken]
		name = [[parser nextToken] stringValue];
		
		// value = [MPValue functionValueByKey: name]
		value = [MPValue functionValueByKey:name withPather:controller];
		
		// if value == nil  => error Message
		if (value == nil) {
			PGLog(@"Error: MPValue:nextValueWithParser: functionValueByKey returned nil for key[(@%)]", name);
		}
		
		// return value
		return value;
		
	} // end if
	
	
	// if curr == "+", "-", "/", "*", "==", ">=", "<=", ">", "<", "!=", "&&", "||"
	if ([current isEqualToString:@"+"]  || 
		[current isEqualToString:@"-"]  ||
		[current isEqualToString:@"/"]  ||
		[current isEqualToString:@"*"]  ||
		[current isEqualToString:@"="] ||
		[current isEqualToString:@"=="] ||
		[current isEqualToString:@">="] ||
		[current isEqualToString:@"<="] ||
		[current isEqualToString:@">"]  ||
		[current isEqualToString:@"<"]  ||
		[current isEqualToString:@"!="] ||
		[current isEqualToString:@"&&"] ||
		[current isEqualToString:@"||"]) {
		
		// value = [MPValue operationValueByKey:curr];		
		// return value
		return [MPValue operationValueByKey:current];
		
	} // end if
	
	
	// if curr = "("
	if ([current isEqualToString:@"("] ) {
		
		// return [MPValue parseEquation:parser];
		return [MPValue parseEquation:parser withDesiredType:type withPather:controller];
		
	}// end if
	
	// if curr = ")" or ";"
	if ([current isEqualToString:@")"] || [current isEqualToString:@";"]) {
		
		// return nil
		return nil;
		
	} // end if
	
	// if we get to here ... it's a scalar
	//return [MPValue scalarValue: curr byType:scalarType];
	return [MPValue scalarValueFromData:current withDesiredType:type];
		
	}
	
	// current was nil so return that
	return nil;
	
}


+ (NSMutableArray*) parseArray: (PKTokenizer *)parser {

	NSMutableArray *newArray = [NSMutableArray array];
	NSString *current;
	
	// current = [nextToken]
	current = [[parser nextToken] stringValue];
	
	do {

		// if (current != ',') {
		if (![current isEqualToString:@","]) {
		
			// if (current == '[') 
			if ([current isEqualToString:@"["] ) {
			
				// value = [parseArray:parser];
				[newArray addObject:[MPValue parseArray:parser]];
				
			} else {
			
				// newArray[] = Current
				[newArray addObject:current];
				
			} 
			
			
		} // end if
		
		// current = [nextToken]
		current = [[parser nextToken] stringValue];
		
	} while (![current isEqualToString:@"]"]); // while (current != ']')
	
	return [[newArray retain] autorelease];
}


+ (MPValue *) functionValueByKey: (NSString *)key withPather:(PatherController*)controller {
	
	// prevent typos related to capitalization ... 
	NSString *lcKey = [key lowercaseString];
	
	// if $MyLevel
	if ([lcKey isEqualToString:@"mylevel"]) {
		return [MPMyLevelValue initWithPather:controller];
	}
	
	if ([lcKey isEqualToString:@"myclass"]) {
		return [MPMyClassValue initWithPather:controller];
	}
	
	
	return [MPMyLevelValue initWithPather:controller]; // if nothing else then ... 

}


+ (MPValue *) operationValueByKey: (NSString *)key {
		
	// if +
	if ([key isEqualToString:@"+"]) {
		return [MPOperationAdd operation];
	}
	
	// if -
	if ([key isEqualToString:@"-"]) {
		return [MPOperationSubtract operation];
	}
	
	// if *
	if ([key isEqualToString:@"*"]) {
		return [MPOperationMultiply operation];
	}
	
	
	// if ==
	if ([key isEqualToString:@"=="] || [key isEqualToString:@"="]) {
		return [MPOperationEQ operation];
	}
	
	
	// if >
	if ([key isEqualToString:@">"]) {
		return [MPOperationGT operation];
	}
	
	
	// if <
	if ([key isEqualToString:@"<"]) {
		return [MPOperationLT operation];
	}
	
	
	// if >=
	if ([key isEqualToString:@">="]) {
		return [MPOperationGTEQ operation];
	}
	
	
	// if <=
	if ([key isEqualToString:@"<="]) {
		return [MPOperationLTEQ operation];
	}
	
	
	// if !=
	if ([key isEqualToString:@"!="]) {
		return [MPOperationNEQ operation];
	}
	
	
	// if &&
	if ([key isEqualToString:@"&&"]) {
		return [MPConditionAND operation];
	}
	
	
	// if ||
	if ([key isEqualToString:@"||"]) {
		return [MPConditionOR operation];
	}
	
	
	return [MPOperationAdd operation]; // if nothing else then ... 
	
	
}



+ (MPValue *) scalarValueFromData: (NSString *)data withDesiredType:(NSString*)type{

	// if data contains " then we return a string value 
	NSRange range = [data rangeOfString:@"\"" options:0];
    
	if (range.length > 0) {
		return [MPValueString stringFromData:data];
	}
	
	// else
	if ([type isEqualToString:@"int"] ) {
		
		return [MPValueInt intFromString:data];
	} else {
	
		return [MPValueFloat floatFromString:data];
	}
}
@end
