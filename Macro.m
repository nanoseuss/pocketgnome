/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "Macro.h"


@implementation Macro

+ (id)macroWithName: (NSString*)name number: (NSNumber*)number body: (NSString*)body isCharacter: (BOOL)isChar {
    Macro *newMacro = [[Macro alloc] init];
    if(newMacro) {
        newMacro.name = name;
        newMacro.body = body;
        newMacro.number = number;
        newMacro.isCharacter = isChar;
    }
    return [newMacro autorelease];
}

- (void) dealloc
{
    self.name = nil;
    self.body = nil;
    self.number = nil;
    [super dealloc];
}


@synthesize name;
@synthesize body;
@synthesize number;
@synthesize isCharacter;

- (NSString*)nameWithType{
	
	if ( self.isCharacter ){
		return [NSString stringWithFormat:@"Character - %@", self.name];
	}
	else{
		return [NSString stringWithFormat:@"Account - %@", self.name];
	}
}

@end
