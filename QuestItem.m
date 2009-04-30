//
//  QuestItem.m
//  Pocket Gnome
//
//  Created by Josh on 4/23/09.
//	Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "QuestItem.h"


@implementation QuestItem

@synthesize item;
@synthesize quantity;

- (void) dealloc {
	[item release];
	[quantity release];
	
	[super dealloc];
}

@end
