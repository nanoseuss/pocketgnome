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

#import "QuestController.h"

#import "Controller.h"
#import "PlayerDataController.h"
#import "MobController.h"
#import "OffsetController.h"
#import "MacroController.h"
#import "BotController.h"

#import "MemoryAccess.h"
#import "Player.h"
#import "Quest.h"
#import "QuestItem.h"

// 3.1.1 valid
// #define QUEST_START_STATIC			((IS_X86) ? 0x14125F0 : 0x0)

// Using QUEST_START_STATIC
/* This quest list is a bit confusing... here is an example:
 0x0		7905			<-- quest id
 0x4		12				<-- unknown  (this seems to be a counter... starts at 1 and goes up to the total number of quests)
 0x8		0				<-- unknown
 0xC		0				<-- unknown
 0x10	38				<-- Zone ID
 0x14	0
 0x18	1
 0x1C	0
 0x20	256				<-- quest id
 0x24	9
 0x28	0
 0x2C	0
 0x30	44				<-- Zone ID
 0x34	0
 0x38	1
 0x3C	0
 0x40	125				<-- quest id
 0x44	3
 0x48	0
 0x4C	0
 0x50	145				<-- quest id
 0x54	7
 0x58	0
 0x5C	0
 */

@implementation QuestController

- (id) init {
    self = [super init];
    if (self != nil) {
		_playerQuests = [[NSMutableArray array] retain];
    }
    return self;
}

- (void) dealloc
{
    [_playerQuests release];
    [super dealloc];
}


- (NSArray*)playerQuests {
    return [[_playerQuests retain] autorelease];
}


typedef struct QuestInfo {
    UInt32  questID;
    UInt32  bytes;
    UInt32  bytes1;
    UInt32  bytes2;
} QuestInfo;

- (void) reloadPlayerQuests{
	
	// Get access to memory
	MemoryAccess *wowMemory = [controller wowMemoryAccess];
	UInt32 playerAddress = [playerController baselineAddress];
	
	// Add the player's current quests to the array pls
	int i;
	for ( i = 0; i < 25; i++ ){
		QuestInfo quest;
		if([wowMemory loadDataForObject: self atAddress: (playerAddress + PlayerField_QuestStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
			if ( quest.questID > 0 ){
				[_playerQuests addObject: [Quest questWithID: [NSNumber numberWithInt: quest.questID]]];
			}
			else{
				break;
			}
		}
	}
	
	// Get the data for each quest from WoWHead
    for(Quest *quest in _playerQuests) {
        [quest reloadQuestData];
    }
	
	/*
	 // No real point in using the below unless you want to find the Title IDs (faction)...  The below bytes simply go from 1 up to the max quest number... (bytes... bytes1 and bytes2 are always 0)
	 if(wowMemory) {
	 // Shouldn't be more than 50 (25 quests + 25 potential headings)
	 for(i = 0; i< 50; i++)
	 {
	 UInt32 questStart = QUEST_START_STATIC;
	 
	 QuestInfo quest;
	 if([wowMemory loadDataForObject: self atAddress: (questStart) + i*sizeof(quest) Buffer:(Byte*)&quest BufLength: sizeof(quest)]) {
	 //PGLog(@"ID: %d, 1:%d, 2:%d, 3:%d", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
	 
	 if ( quest.questID == 0 ) continue;
	 
	 // Check to see if this object exists (if it does then it's not a heading)
	 NSEnumerator *enumerator = [_playerQuests objectEnumerator];
	 Quest *obj;
	 
	 while ((obj = [enumerator nextObject]) != nil)
	 {
	 // Found a valid quest ID... lets save the extra data
	 if ( [[obj ID] intValue] == quest.questID )
	 {
	 PGLog(@"Found quest %d (%d, %d, %D)", quest.questID, quest.bytes, quest.bytes1, quest.bytes2);
	 
	 obj._bytes1 = [NSNumber numberWithInt:quest.bytes];
	 obj._bytes2 = [NSNumber numberWithInt:quest.bytes1];
	 obj._bytes3 = [NSNumber numberWithInt:quest.bytes2];
	 
	 break;
	 } 
	 }
	 }
	 }
	 }*/
	
	/*
	 // For when i don't have the ability to start wow...
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:19]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:91]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:122]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:125]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:126]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:127]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:128]]];
	 [_playerQuests addObject:[[Quest alloc] initWithQuestID:[NSNumber numberWithInt:145]]];
	 
	 
	 // Get the data for each quest from WoWHead
	 int k;
	 for(k = 0; k < [_playerQuests count]; k++ ){
	 [[_playerQuests objectAtIndex:k] reloadQuestData];
	 }*/
}

- (void) dumpQuests{
	if ( !_playerQuests || ![_playerQuests count] ){
		return;
	}
	
	NSLog(@"Total quests: %i", [_playerQuests count] );
	for(Quest *quest in _playerQuests) {
		
		PGLog(@"Quest: %@ %@", [quest questID], [quest name]);
		
        for(QuestItem *questItem in quest.itemRequirements){
            PGLog(@"  Required Item: %@ Quantity: %@", [questItem item], [questItem quantity]);
        }
	}
}

#pragma mark NPC

#define Type_Available	0
#define Type_Active		1


typedef struct QuestStruct {
    UInt32 questID;
    UInt32 level;		// not level requirement, but rather the quest level
    UInt32 unknown;
    UInt32 unknown2;
	UInt32 flag;		// if 3 or 4, player has the quest
	char   name[128];	// not sure the limit, but this should be enough
} QuestStruct;

- (GUID)questGiverGUID{
	GUID targetGUID = [playerController targetID];
	Mob *mob = [mobController mobWithGUID:targetGUID];
	if ( !mob || ![mob isQuestGiver] ){
		return 0x0;
	}
	
	return targetGUID;	
}

- (int)getNumQuestsForType:(int)type{
	
	GUID questGiver = [self questGiverGUID];
	if ( questGiver == 0x0 ){
		PGLog(@"[Quest] Selected mob is either invalid or not a questgiver!");
		return 0;
	}
	
	// we have to interact first, or the memory space won't be updated!
	[botController interactWithMouseoverGUID:questGiver];
	
	UInt32 offset = [offsetController offset:@"Lua_GetNumGossipAvailableQuests"];
	int total = 0;
	
	if ( offset ){
		MemoryAccess *memory = [controller wowMemoryAccess];
		if ( memory && [memory isValid] ){
			
			UInt32 address = offset;
			UInt32 maxAddress = offset + 0x4280;
			
			do{
				QuestStruct quest;
				if ( [memory loadDataForObject: self atAddress: address Buffer:(Byte*)&quest BufLength: sizeof(quest)] && quest.questID ){
					PGLog(@"[%d] %d %s", quest.questID, quest.flag, quest.name);	
					
					// current available quests
					if ( type == Type_Available && quest.flag != 3 && quest.flag != 4 )
						total++;
					else if ( type == Type_Active && ( quest.flag == 3 || quest.flag == 4 ) )
						total++;
				}
				address += 0x214;
			} while ( address < maxAddress );
		}		
	}
							 
	return total;
}

- (int)GetNumAvailableQuests{
	return [self getNumQuestsForType:Type_Available];
}

// quests you already have with the quest giver
- (int)GetNumActiveQuests{
	return [self getNumQuestsForType:Type_Active];
}

- (void)turnInAllQuests{
	
}

- (BOOL)getAvailableQuests{
	
	GUID questGiver = [self questGiverGUID];
	if ( questGiver == 0x0 ){
		PGLog(@"[Quest] Selected NPC is not a quest giver, unable to retrieve quests");
		return NO;
	}
	
	int totalAvailable = [self GetNumAvailableQuests], i = 0;
	GUID target = [playerController targetID];
	
	// loop through and get quests!
	for ( ; i < totalAvailable; i++ ){
		
		if ( [botController interactWithMouseoverGUID:target] ){
			usleep(300000);
			
			// select the available quest!
			[macroController useMacroOrSendCmd:[NSString stringWithFormat:@"/script SelectGossipAvailableQuest(1);"]];
			usleep(10000);
			
			// click "continue" (not all quests need this)
			[macroController useMacro:@"QuestContinue"];
			usleep(10000);
			
			// click "Accept" (this is ONLY needed if we're accepting a quest)
			[macroController useMacro:@"QuestAccept"];
			usleep(300000);
		}
		else{
			PGLog(@"[Quest] Unable to interact with the quest giver! Aborting");
			return NO;
		}
	}
	
	return YES;
}

typedef struct PlayerQuest {
    UInt32 questID;
    UInt32 state;		// not level requirement, but rather the quest level
    UInt8  ObjectiveRequiredCounts[4];
	UInt32 time;
} PlayerQuest;

- (BOOL)isQuestComplete: (int)index{
	
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( memory && [memory isValid] ){
	
		UInt32 questStart = [[playerController player] infoAddress] + 0x278;
		/*UInt32 questPointer = [[playerController player] baseAddress] + 0xFF4, questStart = 0;
		[memory loadDataForObject: self atAddress: questPointer Buffer:(Byte*)&questStart BufLength: sizeof(questStart)];
		questStart += 0x28;*/
		PGLog(@"Start: 0x%X", questStart);
		
		int i = 0;
		for ( ; i < 25; i++ ){
			
			PlayerQuest quest;
			if ( [memory loadDataForObject: self atAddress: questStart + (i*0x14) Buffer:(Byte*)&quest BufLength: sizeof(quest)] && quest.questID ){
				PGLog(@"[%i] %i %i", quest.questID, quest.state, quest.time);
				int k = 0;
				for ( ; k < 4; k++ ){
					PGLog(@" %i", quest.ObjectiveRequiredCounts[k]);
				}
			}
			else{
				PGLog(@"ending after %d searches...", i);
				break;
			}
		}
	}

	/*
	[StructLayout(LayoutKind.Sequential)]
    public struct PlayerQuest
    {
        public int ID;
        public StateFlag State;
        [MarshalAs(UnmanagedType.ByValArray,SizeConst = 4)]
        public short[] ObjectiveRequiredCounts;
        public int Time;
		
        public enum StateFlag : uint
        {
            None = 0,
            Complete = 1,
            Failed = 2
        }
    }
	*/
	
	
	
	/*
	
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( memory && [memory isValid] ){

		UInt32 itemsInQuestLog = 0x0;
		if ( [memory loadDataForObject: self atAddress: 0xC8DB48 Buffer:(Byte*)&itemsInQuestLog BufLength: sizeof(itemsInQuestLog)] ){
			PGLog(@"[Quest] Items in log: %d", itemsInQuestLog);

				for ( ; index < itemsInQuestLog; index++ ){
					Byte unknown1 = 0x0, unknown2 = 0x0;
					UInt32 questID = 0x0;
					
					[memory loadDataForObject: self atAddress: 0xDB9BE8 + (16*index) Buffer:(Byte*)&unknown1 BufLength: sizeof(unknown1)];
					[memory loadDataForObject: self atAddress: 0xDB9BEC + (16*index) Buffer:(Byte*)&unknown2 BufLength: sizeof(unknown2)];
					[memory loadDataForObject: self atAddress: 0xDB9BF0 + (16*index) Buffer:(Byte*)&questID BufLength: sizeof(questID)];
					
					
					// if unknown1 is 1, the quest is NOT complete!
					
					PGLog(@"[%d] %d:%d - %u", index, unknown1, unknown2, questID);
					
					// this means the quest is NOT complete!!
					if ( !unknown1 && unknown2 ){
						PGLog(@" complete!");
					}
					else{
						
					}
					
				}
		}
				
	
	}
	return NO;
	*/
	//if ( v9 && !DB9BE8[4 * v1] && DB9BEC[4 * v1] )
	
	
}

/*
 
 So much is changing here!!!
 For Lua_GetNumGossipAvailableQuests
	0x0:	Quest ID
	0x4:	Quest Level (not required level)
	0x10:	If this is 3 or 4, you already have the quest! (it's active)
 
 // next quest is at 0x214
 
 
 while < 0x4280
 
 
 
 
 // number of quests including the titles within the quest log: C8DB48
 */

@end
