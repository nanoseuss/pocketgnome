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

#import <Cocoa/Cocoa.h>


@interface SaveData : NSObject {

	NSMutableArray *_objects;
}

// should not be implemented by the subclass, only called!
- (void)deleteObject:(id)object;				// delete an object
- (void)deleteObjectWithName:(NSString*)name;	// delete an object (needed for renames)
- (void)saveObject: (id)object;					// save an object
- (NSArray*)loadAllObjects;						// return an array w/all objects found in the app support folder
- (void)deleteAllObjects;

// UI
- (IBAction)showInFinder: (id)sender;
- (IBAction)saveAllObjects: (id)sender;

// should be implemented by the subclass
- (NSString*)objectExtension;
- (NSString*)objectName:(id)object;

// for backwards compatibility
- (NSArray*)loadAllDataForKey: (NSString*)key withClass:(id)objClass;

@end
