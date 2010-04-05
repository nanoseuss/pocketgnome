//
//  MPUntilTask.h
//  TaskParser
//
//  Created by codingMonkey on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTaskConditional.h"


/*!
 * @class      MPUntilTask
 * @abstract   Execute single child until the condition is true
 * @discussion 
 * (following is from PPather wiki documentation)
 * UntilTask will execute it's single child as long as it's condition is false. As soon as it's condition
 * becomes true, Until will stop executing it's child.
 *
 * This is a valuable tool in QuestGoal tasks for example, where you need to pull mobs and loot them until 
 * you have a certain amount of items from them. It may also be used to do something specific until you have 
 * reached a certain level.
 *
 * The following example will illustrate the use of Until in conjunction with a PScript function ($ItemCount) 
 * to farm specific mobs until 8 or more Lynx Collars are present in your inventory.
 * <code>
 *	Until
 *	{
 *	  $cond = $ItemCount{"Lynx Collar"} >= 8;
 *	  Pull { $Names = ["Springpaw Lynx", "Springpaw Cub"]; } 
 *	}
 * </code>
 *		
 */
@interface MPTaskUntil : MPTaskConditional {

}



#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
