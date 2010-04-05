//
//  MPIfTask.h
//  TaskParser
//
//  Created by admin on 9/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPTaskConditional.h"



/*!
 * @class      MPIfTask
 * @abstract   The If task runs it's child task only if the given condition is true.
 * @discussion 
 * "IfTask will allow it's child to execute only while it's condition ($cond) is true. 
 * That means that if $cond becomes true and the child starts to execute, but then $cond 
 * becomes false again, the child has to stop executing." (PPather Wiki Definition)
 *
 * The following example will use one of Pather's predefined variables ($MyClass) to find 
 * the class of the current toon. If the class equals "Mage", then the nested QuestPickup 
 * task will be allowed to run. If the toon has a different class, it will never run.:
 * <code>
 *	 If
 *	 {
 *		 $cond = $MyClass == "Mage"; 
 *		 QuestPickup
 *		 {
 *			 $NPC = "Arcanist Vandril";
 *			 $Name = "A Simple Robe";
 *			 $ID = 9488;
 *		 }
 *	 }
 * </code>
 *		
 */
@interface MPTaskIf : MPTaskConditional {

}



#pragma mark -


/*!
 * @function initWithPather
 * @abstract Convienience method to return a new initialized task.
 * @discussion
 */
+ (id) initWithPather: (PatherController*)controller;

@end
