//
//  MPAVLRangedTree.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPAVLTree.h"

@interface MPAVLRangedTree : MPAVLTree {

}

- (void) addObject: (id) object forRange: (NSRange) range;
- (void) addObject: (id) object withMinValue:(float)minValue maxValue:(float)maxValue;

@end

