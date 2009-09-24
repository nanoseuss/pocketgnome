//
//  OffsetController.m
//  Pocket Gnome
//
//  Created by Josh on 9/1/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "OffsetController.h"
#import "MemoryAccess.h"
#import "Controller.h"

#define TEXT_SEGMENT_MAX_ADDRESS				0x824DC0


#define SERVER_NAME_STATIC						"\xB8\x00\x44\x55\x01\x89\xD3\x0F\x45\xD8\xA1\x0C\x86\x5F\x01\x89\x44\x24\x04\x8D\x45\xF4\x89\x04\x24\xE8\x66\xFF\x29\x00\xC7\x44\x24\x08\x58\x00\x00\x00\xC7\x44\x24\x04\x00\x00\x00\x00\xC7\x04\x24\xA0\x43\x55\x01"
#define SERVER_NAME_STATIC_MASK					"x????xxxxxx????xxxxxxxxxxx????xxxxxxxxxxxxxxxxxxx????"

#define PLAYER_NAME_STATIC						"\x55\x89\xE5\x31\xC0\x80\x3D\x28\x3D\x55\x01\x00\xBA\x28\x3D\x55\x01\x0F\x45\xC2\x5D\xC3"
#define PLAYER_NAME_STATIC_MASK					"xxxxxxx????xx????xxxxx"

#define ACCOUNT_NAME_STATIC						"\xC7\x44\x24\x08\x00\x05\x00\x00\x8B\x45\x08\x89\x44\x24\x04\xC7\x04\x24\x80\x41\xC3\x00"
#define ACCOUNT_NAME_STATIC_MASK				"xxxxxxxxxxxxxxxxxx????"

#define PLAYER_GUID_STATIC						"\x8B\x75\x10\x8B\x7D\x14\x8B\x15\xE0\xBE\xB9\x00\x8D\x42\x01\xA3\xE0\xBE\xB9\x00"
#define PLAYER_GUID_STATIC_MASK					"xxxxxxxx????xxxx????"

#define OBJECT_LIST_LL_PTR						"\x55\x89\xE5\x57\x56\x53\x83\xEC\x1C\x8B\x0D\x6C\x5A\x25\x01\x8D\x91\xA4\x00\x00\x00\x8B\x42\x08\xA8\x01\x0F\x85\xE6\x00\x00\x00\x85\xC0\x0F\x84\xDE\x00\x00\x00"
#define OBJECT_LIST_LL_PTR_MASK					"xxxxxxxxxxx????xxxxxxxxxxxxx????xxxx????"

#define	COMBO_POINTS_STATIC						"\x0F\xB6\x05\xAC\xD8\xB9\x00\x5B\x5D\xC3"
#define COMBO_POINTS_STATIC_MASK				"xxx????xxx"

#define TARGET_TABLE_STATIC						"\x55\x89\xE5\x56\x53\x83\xEC\x20\x8B\x75\x08\x8B\x0D\x90\xD9\xB9\x00"
#define TARGET_TABLE_STATIC_MASK				"xxxxxxxxxxxxx????"

#define KNOWN_SPELLS_STATIC						"\x83\xC0\x04\x3D\xA0\x55\x59\x01\x75\xEE"
#define KNOWN_SPELLS_STATIC_MASK				"xxxx????xx"

#define HOTBAR_BASE_STATIC						"\x8B\x45\x08\x8B\x14\x85\x00\x85\x58\x01\x85\xD2\x74\x3B"
#define HOTBAR_BASE_STATIC_MASK					"xxxxxx????xxxx"

#define PLAYER_IN_BUILDING_STATIC				"\x0F\xB6\xD0\x8B\x0D\x80\x60\x23\x01\x89\x15\x80\x60\x23\x01\x84\xC0"
#define PLAYER_IN_BUILDING_STATIC_MASK			"xxxxx????xx????xx"

#define LAST_SPELL_THAT_DIDNT_CAST_STATIC		"\x89\xC2\x8B\x85\xE0\xF2\xFF\xFF\x3B\x05\x54\xEA\x25\x01"
#define	LAST_SPELL_THAT_DIDNT_CAST_STATIC_MASK	"xxxxxxxxxx????"

#define CHAT_BOX_OPEN_STATIC					"\xA1\x20\x2B\xC2\x00\x85\xC0\x74\x3A"
#define CHAT_BOX_OPEN_STATIC_MASK				"x????xxxx"

#define CORPSE_STATIC							"\xA1\x80\x0B\x54\x01\x89\x03\xA1\x84\x0B\x54\x01\x89\x43\x04\xA1\x88\x0B\x54\x01\x89\x43\x08"
#define CORPSE_STATIC_MASK						"x????xxx????xxxx????xxx"

#define ITEM_IN_LOOT_WINDOW						"\x83\xFA\x11\x77\x0B\xC1\xE2\x05\x8B\x82\xE4\xE0\x57\x01\x5D\xC3"
#define ITEM_IN_LOOT_WINDOW_MASK				"xxxxxxxxxx????xx"

#define PLAYER_CURRENT_ZONE						"\x8B\x10\x89\x15\xF8\x80\xB9\x00\x8B\x0D\x00\x81\xB9\x00\x85\xC9"
#define PLAYER_CURRENT_ZONE_MASK				"xxxx????xx????xx"

#define CD_OBJ_LIST_STATIC						"\x89\x5C\x24\x08\x8B\x84\x88\x00\x01\x00\x00\x89\x44\x24\x04\xC7\x04\x24\x40\xE9\x25\x01"
#define CD_OBJ_LIST_STATIC_MASK					"xxxxxxxxxxxxxxxxxx????"

#define CTM_POS									"\x8D\x45\xD8\x8B\x55\x0C\x89\x54\x24\x08\xC7\x44\x24\x04\xFC\x08\x27\x01\x89\x04\x24"
#define CTM_POS_MASK							"xxxxxxxxxxxxxx????xxx"

#define CTM_ACTION								"\x55\x89\xE5\x53\x8B\x1D\xD4\x09\x27\x01\x83\xFB\x0D"
#define CTM_ACTION_MASK							"xxxxxx????xxx"

#define CTM_GUID								"\x8B\x4D\x10\x8B\x01\x8B\x51\x04\xA3\xF0\x09\x27\x01"
#define CTM_GUID_MASK							"xxxxxxxxx????"

#define CTM_SCALE								"\xC7\x05\xE8\x09\x27\x01\x00\x00\x34\x43\x0F\x2E\x15\xB8\x2A\xB9\x00\x76\x09"
#define CTM_SCALE_MASK							"xx????xxxxxxx????xx"

#define CTM_DISTANCE							"\x8B\x45\xC8\x89\x03\x8B\x45\xCC\x89\x43\x04\x8B\x45\xD0\x89\x43\x08\xF3\x0F\x10\x05\xE4\x09\x27\x01"
#define CTM_DISTANCE_MASK						"xxxxxxxxxxxxxxxxxxxxx????"

#define LAST_RED_ERROR_MESSAGE					"\xC7\x44\x24\x08\xB8\x0B\x00\x00\x89\x5C\x24\x04\xC7\x04\x24\xE0\x0B\x54\x01"
#define LAST_RED_ERROR_MESSAGE_MASK				"xxxxxxxxxxxxxxx????"

#define MOUNT_LIST_POINTER						"\x55\x89\xE5\x53\x83\xEC\x14\xBB\xD4\x84\x5A\x01"
#define MOUNT_LIST_POINTER_MASK					"xxxxxxxx????"

@interface OffsetController (Internal)

//- (unsigned int) findPatternWithByteMask: (unsigned char*)byteMask withStringMask:(unsigned char*)stringMask;
/*- (BOOL) bDataCompare: (const char *)pData byteMask:(const char*)byteMask stringMask:(const char*)stringMask;
- (unsigned long) findPatternWithByteMask: (char*)byteMask 
						   withStringMask: (char*)stringMask 
								 withData: (Byte *)data
								  withLen: (vm_size_t)dwLen;*/
- (void)memoryChunk;

- (void)findAllOffsets: (Byte*)data Len:(unsigned long)len StartAddress:(unsigned long)startAddress;

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask);
unsigned long dwFindPattern( unsigned char *bMask,char * szMask, Byte* dw_Address, unsigned long dw_Len, unsigned long startAddressOffset, long minOffset );

/*
BOOL bDataCompare(const Byte* pData, const Byte* bMask, const char* szMask);
uint32_t dwFindPattern(Byte * dwAddress,uint32_t dwLen,Byte *bMask,char * szMask);
*/
@end

@implementation OffsetController

- (id)init{
    self = [super init];
    if (self != nil) {
		offsets = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
    }
    return self;
}

- (void)dealloc {
	[offsets release];
	[super dealloc];
}

- (void)memoryIsValid: (NSNotification*)notification {
    [self memoryChunk];
}

- (void)dumpOffsets{
	[self memoryChunk];
}

- (void)memoryChunk{
	
    // get the WoW PID
    pid_t wowPID = 0;
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    OSStatus err = GetProcessPID(&wowPSN, &wowPID);
    
    if((err == noErr) && (wowPID > 0)) {
        
        // now we need a Task for this PID
        mach_port_t MySlaveTask;
        kern_return_t KernelResult = task_for_pid(current_task(), wowPID, &MySlaveTask);
        if(KernelResult == KERN_SUCCESS) {
			//PGLog(@"We have a task!");
            // Cool! we have a task...
            // Now we need to start grabbing blocks of memory from our slave task and copying it into our memory space for analysis
            vm_address_t SourceAddress = 0;
            vm_size_t SourceSize = 0;
            vm_region_basic_info_data_t SourceInfo;
            mach_msg_type_number_t SourceInfoSize = VM_REGION_BASIC_INFO_COUNT;
            mach_port_t ObjectName = MACH_PORT_NULL;
            
            vm_size_t ReturnedBufferContentSize;
            Byte *ReturnedBuffer = nil;
            
            while(KERN_SUCCESS == (KernelResult = vm_region(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO,(vm_region_info_t) &SourceInfo,&SourceInfoSize,&ObjectName))) {
                // If we get here then we have a block of memory and we know how big it is... let's copy writable blocks and see what we've got!
				//PGLog(@"we have a block of memory!");
				
                // ensure we have access to this block
                if ((SourceInfo.protection & VM_PROT_READ)) {
                    NS_DURING {
                        ReturnedBuffer = malloc(SourceSize);
                        ReturnedBufferContentSize = SourceSize;
                        if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                            (ReturnedBufferContentSize > 0) )
                        {
							
							if ( ReturnedBufferContentSize > TEXT_SEGMENT_MAX_ADDRESS ){
								ReturnedBufferContentSize = TEXT_SEGMENT_MAX_ADDRESS;
								
							}
							
							// Lets grab all our offsets!
							[self findAllOffsets: ReturnedBuffer Len:SourceSize StartAddress: SourceAddress];
						}
                    } NS_HANDLER {
                    } NS_ENDHANDLER
                    
                    if (ReturnedBuffer != nil)
                    {
                        free(ReturnedBuffer);
                        ReturnedBuffer = nil;
                    }
                }
               
                // reset some values to search some more
                SourceAddress += SourceSize;
				
				// If it's past the .text segment
				if ( SourceAddress > TEXT_SEGMENT_MAX_ADDRESS ){
					break;
				}
            }
        }
    }
}

//[offsetController offset:@"OBJECT_LIST_LL_PTR"]
- (void)findAllOffsets: (Byte*)data Len:(unsigned long)len StartAddress:(unsigned long)startAddress{
	
	
	
	unsigned long offset = dwFindPattern( (Byte*)PLAYER_GUID_STATIC, PLAYER_GUID_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"PLAYER_GUID_STATIC"];
	PGLog(@"PLAYER_GUID_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)OBJECT_LIST_LL_PTR, OBJECT_LIST_LL_PTR_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"OBJECT_LIST_LL_PTR"];
	PGLog(@"OBJECT_LIST_LL_PTR: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)SERVER_NAME_STATIC, SERVER_NAME_STATIC_MASK, data, len, startAddress, 0x0 ) + 0x6;
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"SERVER_NAME_STATIC"];
	PGLog(@"SERVER_NAME_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)ACCOUNT_NAME_STATIC, ACCOUNT_NAME_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"ACCOUNT_NAME_STATIC"];
	PGLog(@"ACCOUNT_NAME_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)PLAYER_NAME_STATIC, PLAYER_NAME_STATIC_MASK, data, len, startAddress, 0x1500000 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"PLAYER_NAME_STATIC"];
	PGLog(@"PLAYER_NAME_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)COMBO_POINTS_STATIC, COMBO_POINTS_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"COMBO_POINTS_STATIC"];
	PGLog(@"COMBO_POINTS_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)TARGET_TABLE_STATIC, TARGET_TABLE_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"TARGET_TABLE_STATIC"];
	PGLog(@"TARGET_TABLE_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)KNOWN_SPELLS_STATIC, KNOWN_SPELLS_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"KNOWN_SPELLS_STATIC"];
	PGLog(@"KNOWN_SPELLS_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)HOTBAR_BASE_STATIC, HOTBAR_BASE_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"HOTBAR_BASE_STATIC"];
	PGLog(@"HOTBAR_BASE_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)PLAYER_IN_BUILDING_STATIC, PLAYER_IN_BUILDING_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"PLAYER_IN_BUILDING_STATIC"];
	PGLog(@"PLAYER_IN_BUILDING_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)LAST_SPELL_THAT_DIDNT_CAST_STATIC, LAST_SPELL_THAT_DIDNT_CAST_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"LAST_SPELL_THAT_DIDNT_CAST_STATIC"];
	PGLog(@"LAST_SPELL_THAT_DIDNT_CAST_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CHAT_BOX_OPEN_STATIC, CHAT_BOX_OPEN_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CHAT_BOX_OPEN_STATIC"];
	PGLog(@"CHAT_BOX_OPEN_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CORPSE_STATIC, CORPSE_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CORPSE_STATIC"];
	PGLog(@"CORPSE_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)ITEM_IN_LOOT_WINDOW, ITEM_IN_LOOT_WINDOW_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"ITEM_IN_LOOT_WINDOW"];
	PGLog(@"ITEM_IN_LOOT_WINDOW: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)PLAYER_CURRENT_ZONE, PLAYER_CURRENT_ZONE_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"PLAYER_CURRENT_ZONE"];
	PGLog(@"PLAYER_CURRENT_ZONE: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CD_OBJ_LIST_STATIC, CD_OBJ_LIST_STATIC_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CD_OBJ_LIST_STATIC"];
	PGLog(@"CD_OBJ_LIST_STATIC: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CTM_POS, CTM_POS_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CTM_POS"];
	PGLog(@"CTM_POS: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CTM_ACTION, CTM_ACTION_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CTM_ACTION"];
	PGLog(@"CTM_ACTION: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CTM_GUID, CTM_GUID_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CTM_GUID"];
	PGLog(@"CTM_GUID: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CTM_SCALE, CTM_SCALE_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CTM_SCALE"];
	PGLog(@"CTM_SCALE: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)CTM_DISTANCE, CTM_DISTANCE_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"CTM_DISTANCE"];
	PGLog(@"CTM_DISTANCE: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)LAST_RED_ERROR_MESSAGE, LAST_RED_ERROR_MESSAGE_MASK, data, len, startAddress, 0x0 );
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"LAST_RED_ERROR_MESSAGE"];
	PGLog(@"LAST_RED_ERROR_MESSAGE: 0x%X", offset);
	
	offset = dwFindPattern( (Byte*)MOUNT_LIST_POINTER, MOUNT_LIST_POINTER_MASK, data, len, startAddress, 0x15A0000 ) + 0x4;
	[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:@"MOUNT_LIST_POINTER"];
	PGLog(@"MOUNT_LIST_POINTER: 0x%X", offset);
}

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask){
	for(;*szMask;++szMask,++pData,++bMask){
		if(*szMask=='x' && *pData!=*bMask ){
			return false;
		}
	}
	return true;
}

unsigned long dwFindPattern( unsigned char *bMask,char * szMask, Byte*dw_Address, unsigned long dw_Len, unsigned long startAddressOffset, long minOffset ){
	unsigned long i;
	for(i=0; i < dw_Len; i++){
	
		if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){

			const unsigned char* pData = (unsigned char*)( dw_Address+i );
			char *mask = szMask;
			unsigned long j = 0;
			for ( ;*mask;++mask,++pData){
				if ( j && *mask == 'x' ){
					break;
				}
				if ( *mask == '?' ){
					j++;
				}
			}
				
			unsigned long offset = 0, k;
			for (k=0;j>0;j--,k++){
				--pData;
				offset <<= 8;  
				offset ^= (long)*pData & 0xFF;   
			}
			
			if ( offset >= minOffset ){
				return offset;
			}
			else if ( offset > 0x0 ){
				PGLog(@"[Offset] Found 0x%X < 0x%X at 0x%X, ignoring...", offset, minOffset, i);
			}
		}
	}
	
	return 0;
}

- (unsigned long) offset: (NSString*)key{
	NSNumber *offset = [offsets objectForKey: key];
	if ( offset ){
		return [offset unsignedLongValue];
	}
	return 0;
}
@end
