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
#import "WoWObject.h"
#import "Position.h"

@class Position;

enum eCorpseBaseFields {
    CorpseField_OwnerGUID                 = 0x18,  // 3.1.2	
	
	CorpseField_XLocation                 = 0xE0,
    CorpseField_YLocation                 = 0xE4,
    CorpseField_ZLocation                 = 0xE8,
	CorpseField_Rotation				  = 0xEC,
	
};

/*
// OLD CONSTANTS
enum eCorpseFields {
   CORPSE_FIELD_OWNER                            = 0x18 , // Type: Guid , Size: 2
   CORPSE_FIELD_FACING                           = 0x20 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_X                            = 0x24 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_Y                            = 0x28 , // Type: Float, Size: 1
   CORPSE_FIELD_POS_Z                            = 0x2C , // Type: Float, Size: 1
   CORPSE_FIELD_DISPLAY_ID                       = 0x30 , // Type: Int32, Size: 1
   CORPSE_FIELD_ITEM                             = 0x34 , // Type: Int32, Size: 19
   CORPSE_FIELD_BYTES_1                          = 0x80 , // Type: Chars, Size: 1
   CORPSE_FIELD_BYTES_2                          = 0x84 , // Type: Chars, Size: 1
   CORPSE_FIELD_GUILD                            = 0x88 , // Type: Int32, Size: 1
   CORPSE_FIELD_FLAGS                            = 0x8C , // Type: Int32, Size: 1
   CORPSE_FIELD_DYNAMIC_FLAGS                    = 0x90 , // Type: Int32, Size: 1
   CORPSE_FIELD_PAD                              = 0x94 , // Type: Int32, Size: 1
};
*/

@interface Corpse : WoWObject <UnitPosition> {

}

+ (id)corpseWithAddress: (NSNumber*)address inMemory: (MemoryAccess*)memory;

- (UInt32) parentLowGUID;

@end
