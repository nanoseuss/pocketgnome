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
 * $Id: FileManager.h 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

// this is my version "2" of the file manager, realizing the original SaveData didn't have enough flexibility for my liking!
//      What assumptions do we need? Objects that are passed MUST have the following:
//              - a property called name
//              - a string called objectExtension

#import <Cocoa/Cocoa.h>

@class SaveDataObject;

@interface FileManager : NSObject {
	
}

// we shouldn't really use this
+ (FileManager*)sharedFileManager;

// save all objects in the array
- (BOOL)saveObjects:(NSArray*)objects;

// save one object
- (BOOL)saveObject:(SaveDataObject*)obj;

// get all objects with the extension
- (NSArray*)getObjectsWithClass:(Class)class;

// delete the object with this file name
- (BOOL)deleteObjectWithFilename:(NSString*)filename;

// delete an object
- (BOOL)deleteObject:(SaveDataObject*)obj;

// gets the filename (not path) for an object
- (NSString*)filenameForObject:(SaveDataObject*)obj;

// old method
- (NSArray*)dataForKey: (NSString*)key withClass:(Class)class;

@end