//
//  MPRangedTreeNode.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 11/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTreeNode.h"

@interface MPRangedTreeNode : MPTreeNode {
	
	NSRange range;
	float minValue, maxValue;
}
@property (readwrite) NSRange range;
@property (readwrite) float minValue, maxValue;

+ (id) nodeWithObject: (id) object forRange: (NSRange) range;
+ (id) nodeWithObject: (id) object withMinVal: (float)minVal MaxVal: (float) maxVal;
@end
