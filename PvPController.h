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
#import "SaveData.h"

@class WaypointController;

@class PvPBehavior;

@interface PvPController : SaveData {
	
	IBOutlet WaypointController *waypointController;

	IBOutlet NSPanel *renamePanel;
	IBOutlet NSView *view;
	
    NSSize minSectionSize, maxSectionSize;
	
	PvPBehavior *_currentBehavior;
	
	NSString *_nameBeforeRename;
}

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;

@property (readonly) BOOL validBehavior;
@property (readwrite, retain) PvPBehavior *currentBehavior;
@property (readonly, retain) NSArray *behaviors;

- (void)importBehaviorAtPath: (NSString*)path;

- (IBAction)createBehavior: (id)sender;
- (IBAction)renameBehavior: (id)sender;
- (IBAction)closeRename: (id)sender;
- (IBAction)duplicateBehavior: (id)sender;
- (IBAction)deleteBehavior: (id)sender;
- (IBAction)importBehavior: (id)sender;
- (IBAction)exportBehavior: (id)sender;

- (IBAction)test: (id)sender;

@end
