//
//  MPItem.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/24/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @class      MPItem
 * @abstract   Represents a useable item.
 * @discussion 
 * 
 *		
 */
@interface MPItem : NSObject {

	UInt32 actionID;
	int currentID;  // for items that can scale: like "Drink"
	NSString *name;
//	Spell *mySpell;
//	NSMutableArray *listIDs, *listBuffIDs;
	
	BotController *botController;
	SpellController *spellController;
	

}
@property (readwrite,retain) NSString *name;

@end
