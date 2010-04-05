//
//  MPParser.h
//  TaskParser
//
//  Created by Coding Monkey on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ParseKit/ParseKit.h"


/*!
 * @class MPParser
 * @abstract A simplified interface to the PKTokenizer when parsing Pather Task Files
 * @discussion 
 *	MPParser has 2 main goals to it's design:
 *		1. Internally keep track of file line numbers when parsing files
 *		2. Internally handle the PreProcessing directives and make the resulting token stream 
 *		   like a single file even when they are #included  from multiple files.
 *
 * 
 *  The basic operation of this class would be like:
 *  <pre>
 *		MPParser* parser = [MPParser initWithFile: @"FileName.psc"];
 *		NSString* token;
 *		while( token = [parser nextToken] ) {
 *			NSLog(@" token: %@", token);
 *      }
 *	</pre>
 */

@interface MPParser : NSObject {
	
	/*! @var fileContentsStack A Stack containing all our previously active File Contents. */
	NSMutableArray* fileContentsStack;
	
	/*! @var fileNameStack A Stack containing all our previously opened files. */
	NSMutableArray* fileNameStack;
	
	/*! @var filePositionStack A Stack containing our positions in our previously opened files. */
	NSMutableArray* filePositionStack;
	
	/*! @var tokenizerStack A Stack containing our previous tokenizers for each of our previously opened files. */
	NSMutableArray* tokenizerStack;
	
	
	
	/*! @var listStrings The current contents of our task file broken up by lines. */
	NSArray* listStrings;
	
	/*! @var currentFileName Name of our currently active file. */
	NSString* currentFileName;
	
	/*! @var currentLineNumber Line Position in our currently active file. */
	NSInteger currentLineNumber;
	
	/*! @var tokenizer A PKTokenizer that is processing our current line in our currently active file. */
	PKTokenizer* tokenizer;
	
	
	
	/*! @var eof A token reference for the end of a file (or line in our case). */
	PKToken *eof;
	
	
	
	/*! @var processingEnabled A flag indicating whether or not the current lines should be processed.  */
	NSInteger processingEnabled;
	
	/*! @var flagStack A Stack of our previous processingEnabled flags. */
	NSMutableArray* flagStack;
	
}

@property (retain) NSMutableArray *flagStack;
@property (retain) PKToken *eof;
@property (retain) PKTokenizer *tokenizer;
@property (retain) NSString *currentFileName;
@property (retain) NSArray *listStrings;
@property (retain) NSMutableArray *tokenizerStack, *filePositionStack, *fileNameStack, *fileContentsStack;


/*!
 * @function init
 * @abstract Our base initializer
 */
- (id) init;



/*!
 * @function loadFile
 * @abstract Loads a new file into our parser
 * @discussion
 *	This method loads a file into our parser for processing.  If a file was currently being 
 *  processed (like when you encounter a #import <file.psc>  preprocessing directive), then 
 *  the current file data is stored on our Stacks, and the new file takes over.
 */
- (id) loadFile: (NSString*)fileName;



/*!
 * @function nextToken
 * @abstract Return the next valid token in the file
 * @discussion
 *	Returns the next valid token in the task file.  
 *
 *
 * This method interprets the preprocessor directives and prevents them from being passed on.
 */
- (NSString*) nextToken;



/*!
 * @function nextRawToken
 * @abstract Return the next token in the file
 * @discussion
 *	Returns the next token in the task file (even if the current preprocessing state is false). 
 *
 */
- (NSString*) nextRawToken;


/*!
 * @function nextValue
 * @abstract Returns the next few tokens as a value
 * @discussion
 *	This method will attempt to return the next "Value" it encounters as a single token. For 
 * values it is most likely the next token.  But on complex values, it will compile all the 
 * tokens into one string.
 */
- (NSString*) nextValue;



/*!
 * @function nextArrayValue
 * @abstract Returns the next few tokens as an array value
 * @discussion
 *	Similar to nextValue, this method will attempt to make sure the different array values 
 *  get compiled into a single token.
 */
- (NSString*) nextArrayValue;



/*!
 * @function pathFromValue
 * @abstract Return a file path from the given value.
 * @discussion
 *	This method cleans up file paths from values returned by newValue.
 */
- (NSString*) pathFromValue: (NSString*) aValue;



/*!
 * @function pathFromValue:relativeToPath
 * @abstract Return a relative file path from the given value.
 * @discussion
 *	This method attempts to combine the newPath given with the relativePath to form a new path.
 */
- (NSString*) pathFromValue: (NSString*) aValue  relativeToPath:(NSString*) relativePath;



/*!
 * @function pathFromValue:relativeToPath
 * @abstract Return a relative file path from the given value.
 * @discussion
 *	This method attempts to combine the newPath given with the relativePath to form a new path.
 */
- (NSInteger) evaluateCommand: (NSString*) command  withData:(NSString*) conditionData;



/*!
 * @function lineNumber
 * @abstract Return the current line number of the currently active file.
 * @discussion
 *	Returns the current line position in the currently active file.
 */
- (NSInteger) lineNumber;



/*!
 * @function fileName
 * @abstract Return the current name of the currently active file.
 * @discussion
 *	Returns the current name of the currently active file.
 */
- (NSString *) fileName;





/*!
 * @function initWithFile
 * @abstract Convienience method for creating a new parser.
 * @discussion
 *	It sure beats typing <pre> MPParser *parser = [[[self alloc] init] loadFile:fileName]; </pre> over and over.
 */
+ (id) initWithFile: (NSString*)fileName;



/*!
 * @function tokenizerWithString
 * @abstract Return a new tokenizer
 * @discussion
 *	Convienience method for returning a new ParseKit tokenizer configured with our settings and loaded with the given string data.
 */
+ (id) tokenizerWithString: (NSString*)s;


/*!
 * @function equationTokenizerWithString
 * @abstract Return a new tokenizer that is configured for equation parsing
 * @discussion
 *	Equations many times have subtraction operations in them: $MyLevel - 3.  The standard [tokenizerWithString]
 * will return ($MyLevel) and (-3).  But we need ($MyLevel) (-) (3).  This will do that.
 */
+ (id) equationTokenizerWithString: (NSString*)s;

@end