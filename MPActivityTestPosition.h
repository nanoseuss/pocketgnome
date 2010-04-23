//
//  MPActivityTestPosition.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 4/9/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"
@class MPMover;
@class MPSpell;
@class MPTask;



// ok, this is a single Activity that I will use for various testing 
// actions.  It will 
@interface MPActivityTest : MPActivity {
	NSString *key, *targetName;
	MPSpell *mySpell;
	
}
@property (readwrite, assign) NSString *key, *targetName;
@property (retain) MPSpell *mySpell;


- (id) init;
- (id) initWithTask:(MPTask*)aTask;


+ (id) activityForTask: (MPTask*) aTask andDict:(NSDictionary *)dict;

@end
