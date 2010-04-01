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

#import "OffsetController.h"
#import "MemoryAccess.h"
#import "Controller.h"


// Rough estimate of where the text segment ends (0x8291E0 for 3.2.2a)
#define TEXT_SEGMENT_MAX_ADDRESS				0x830000

@interface OffsetController (Internal)

- (void)memoryChunk;
- (void)findAllOffsets: (Byte*)data Len:(unsigned long)len StartAddress:(unsigned long)startAddress;

- (unsigned long) dwFindPattern: (unsigned char*)bMask 
				 withStringMask:(char*)szMask 
					   withData:(Byte*)dw_Address 
						withLen:(unsigned long)dw_Len 
			   withStartAddress:(unsigned long)startAddressOffset 
				  withMinOffset:(long)minOffset 
					  withCount:(int)count;

- (unsigned long) dwFindPatternPPC: (unsigned char*)bMask 
					withStringMask:(char*)szMask 
						  withData:(Byte*)dw_Address 
						   withLen:(unsigned long)dw_Len 
				  withStartAddress:(unsigned long)startAddressOffset 
					 withMinOffset:(long)minOffset 
						 withCount:(int)count;

- (void)findPPCOffsets: (Byte*)data Len:(unsigned long)len StartAddress:(unsigned long)startAddress;
BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask);


// new scans
- (NSArray*) findPatternPPC: (unsigned char*)bMask 
			 withStringMask:(char*)szMask 
				   withData:(Byte*)dw_Address 
					withLen:(unsigned long)dw_Len 
			  withMinOffset:(long)minOffset;
- (NSArray*) findPattern: (unsigned char*)bMask 
		  withStringMask:(char*)szMask 
				withData:(Byte*)dw_Address 
				 withLen:(unsigned long)dw_Len 
		   withMinOffset:(long)minOffset ;
@end

@implementation OffsetController

- (id)init{
    self = [super init];
    if (self != nil) {
		offsets = [[NSMutableDictionary alloc] init];
		_offsetsLoaded = NO;
		
		_offsetDictionary = [[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"OffsetSignatures" ofType: @"plist"]] retain];
		if ( !_offsetDictionary ){
			PGLog(@"[Offsets] Error, offset dictionary not found!");
		}
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(memoryIsValid:) name: MemoryAccessValidNotification object: nil];
    }
    return self;
}

- (void)dealloc {
	[offsets release];
	[_offsetDictionary release];
	[super dealloc];
}

- (void)memoryIsValid: (NSNotification*)notification {
    [self memoryChunk];
}

// new and improved offset finder, will loop through our plist file to get the signatures! yay! Easier to store PPC/Intel
- (void)findOffsets: (Byte*)data Len:(unsigned long)len StartAddress:(unsigned long)startAddress{

	// should only be set to yes during testing!
	BOOL emulatePPC = NO;
	
	if ( _offsetDictionary ){
		
		NSArray *allKeys = [_offsetDictionary allKeys];
		
		// Intel or PPC?
		NSString *arch = (IS_X86) ? @"Intel" : @"ppc";
		NSRange range;
		
		if ( emulatePPC )
			arch = @"ppc";

		// this will be a key, such as PLAYER_NAME_STATIC
		for ( NSString *key in allKeys ){

			// grab our offset masks for our appropriate instruction set
			NSDictionary *offsetData = [[_offsetDictionary valueForKey:key] valueForKey:arch];
			
			// Keys within offsetData:
			//	Mask
			//	Signature
			//	StartOffset
			//	Count	(which pattern # is the correct offset? Sadly we have to use this if there isn't a unique function using an offset)

			// lets get the raw data from our objects!
			NSString *dictMask					= [offsetData objectForKey: @"Mask"];
			NSString *dictSignature				= [offsetData objectForKey: @"Signature"];
			NSString *dictStartScanAddress		= [offsetData objectForKey: @"StartScanAddress"];
			NSString *dictCount					= [offsetData objectForKey: @"Count"];
			NSString *dictAdditionalOffset		= [offsetData objectForKey: @"AdditionalOffset"];
			NSString *dictSubtractOffset		= [offsetData objectForKey: @"SubtractOffset"];
			
			// no offset data found, move on to the next one!
			if ( [dictMask length] == 0 || [dictSignature length] == 0 )
				continue;
			
			// what is the count #?
			unsigned int count = 1;
			if ( dictCount != nil ){
				count = [dictCount intValue];
			}

			// start offset specified?
			unsigned long startScanAddress = 0x0;
			if ( [dictStartScanAddress length] > 0 ){
				range.location = 2;
				range.length = [dictStartScanAddress length]-range.location;
				
				const char *szStartScanAddressInHex = [[dictStartScanAddress substringWithRange:range] UTF8String];
				startScanAddress = strtol(szStartScanAddressInHex, NULL, 16);
			}
			
			unsigned long additionalOffset = 0x0;
			if ( [dictAdditionalOffset length] > 0 ){
				range.location = 2;
				range.length = [dictAdditionalOffset length]-range.location;
				
				const char *szAdditionalOffsetInHex = [[dictAdditionalOffset substringWithRange:range] UTF8String];
				additionalOffset = strtol(szAdditionalOffsetInHex, NULL, 16);
			}
			
			long subtractOffset = 0x0;
			if ( [dictSubtractOffset length] > 0 ){
				range.location = 2;
				range.length = [dictSubtractOffset length]-range.location;
				
				const char *szSubtractOffsetInHex = [[dictSubtractOffset substringWithRange:range] UTF8String];
				subtractOffset = strtol(szSubtractOffsetInHex, NULL, 16);
			}
			
			// allocate our bytes variable which will store our signature
			Byte *bytes = calloc( [dictSignature length]/2, sizeof( Byte ) );
			unsigned int i = 0, k = 0;

			// incrementing by 4 (to skip the beginning \x)
			for ( ;i < [dictSignature length]; i+=4 ){
				range.length = 2;
				range.location = i+2;
				
				const char *sigMask = [[dictSignature substringWithRange:range] UTF8String];
				long one = strtol(sigMask, NULL, 16);
				bytes[k++] = (Byte)one;
			}
			
			// get our mask
			const char *szMaskUTF8 = [dictMask UTF8String];
			char *szMask = strdup(szMaskUTF8);
			
			unsigned long offset = 0x0;
			// Intel
			if ( IS_X86 && !emulatePPC ){
				offset = [self dwFindPattern:bytes
										withStringMask:szMask 
											  withData:data
											   withLen:len
									  withStartAddress:startAddress 
										 withMinOffset:startScanAddress
											 withCount:count] + additionalOffset - subtractOffset;
			}
			// PPC
			else {
				offset = [self dwFindPatternPPC:bytes
							  withStringMask:szMask 
									withData:data
									 withLen:len
							withStartAddress:startAddress 
							   withMinOffset:startScanAddress
								   withCount:count] + additionalOffset - subtractOffset;
			}
				
			[offsets setObject: [NSNumber numberWithUnsignedLong:offset] forKey:key];
			if ( offset > 0x0 ){
				PGLog(@"%@: 0x%X", key, offset);
			}
			else{
				PGLog(@"[Offset] Error! No offset found for key %@", key);
			}
		}
		
		// can hard code some here
		
		// world state: 0xC7A350		// 3.3.2
		
		// connecting/auth/success = 1,2
		// char list retreiving = 3
		// race/faction change (or customize) in progress? = 9
		// char decline in progress = 8
		// char rename in progress = 7
		// game loading = 10?
		// game loaded = 0
		
		//[offsets setObject:[NSNumber numberWithUnsignedLong:0xC7A350] forKey:@"WorldState"];				// 3.3.2
        //[offsets setObject:[NSNumber numberWithUnsignedLong:0xE06660] forKey:@"Lua_GetPartyMember"];		// 3.3.2
 		

        // 0xD8BD20 - charselect, login, charcreate, patchdownload		
		
        _offsetsLoaded = YES;
	}
	// technically should never be here
	else{
		PGLog(@"[Offsets] No offset dictionary found, PG will be unable to function!");
	}
}

- (void)memoryChunk{
	// don't need to load them more than once!
	if ( _offsetsLoaded )
		return;
	
    // get the WoW PID
    pid_t wowPID = 0;
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    OSStatus err = GetProcessPID(&wowPSN, &wowPID);
    
    if((err == noErr) && (wowPID > 0)) {
        
        // now we need a Task for this PID
        mach_port_t MySlaveTask;
        kern_return_t KernelResult = task_for_pid(current_task(), wowPID, &MySlaveTask);
        if(KernelResult == KERN_SUCCESS) {
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

				
				//PGLog(@"[Offset] Success for reading from 0x%X to 0x%X  SourceInfo: 0x%X 0x%X", SourceAddress, SourceSize, SourceInfo, SourceInfoSize);
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
							
							//PGLog(@"Reading from %d to %d", SourceAddress, SourceAddress + SourceSize);
							
							// Lets grab all our offsets!
							[self findOffsets: ReturnedBuffer Len:SourceSize StartAddress: SourceAddress];
						}
                    } NS_HANDLER {
                    } NS_ENDHANDLER
                    
                    if ( ReturnedBuffer != nil ) {
                        free( ReturnedBuffer );
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

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask){
	for(;*szMask;++szMask,++pData,++bMask){
		if(*szMask=='x' && *pData!=*bMask ){
			return false;
		}
	}
	return true;
}

// not very different from the intel scanner, except we will COMBINE the ?? we find in the signatures
//  this is due to how PPC handles assembly instructions (at most 4 instructions per line)
//	so these offsets can be moved over multiple lines + we need to combine it!
//	we don't have to invert the bytes either as PPC is in big endian - woohoo!
- (unsigned long) dwFindPatternPPC: (unsigned char*)bMask 
				 withStringMask:(char*)szMask 
					   withData:(Byte*)dw_Address 
						withLen:(unsigned long)dw_Len 
			   withStartAddress:(unsigned long)startAddressOffset 
				  withMinOffset:(long)minOffset 
					  withCount:(int)count
{
	unsigned long i;
	int foundCount = 0;
	for(i=0; i < dw_Len; i++){
	
		if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){
			
			foundCount++;

			const unsigned char* pData = (unsigned char*)( dw_Address+i );
			char *mask = szMask;
			unsigned long offset = 0x0;
			for ( ;*mask;++mask,++pData){
				if ( *mask == '?' ){
					offset <<= 8;  
					offset ^= (long)*pData & 0xFF;   
				}
			}
			
			if ( offset >= minOffset && count == foundCount ){
				return offset;
			}
			else if ( offset > 0x0 ){
				//PGLog(@"[Offset] Found 0x%X < 0x%X at 0x%X, ignoring... (%d)", offset, minOffset, i, foundCount);
			}
		}
	}
	
	return 0;
}

- (unsigned long) dwFindPattern: (unsigned char*)bMask 
				 withStringMask:(char*)szMask 
					   withData:(Byte*)dw_Address 
						withLen:(unsigned long)dw_Len 
			   withStartAddress:(unsigned long)startAddressOffset 
				  withMinOffset:(long)minOffset 
					  withCount:(int)count
{
	unsigned long i;
	int foundCount = 0;
	for(i=0; i < dw_Len; i++){
		
		if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){
			
			foundCount++;
			
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
			
			if ( offset >= minOffset && count == foundCount ){
				return offset;
			}
			else if ( offset > 0x0 ){
				//PGLog(@"[Offset] Found 0x%X < 0x%X at 0x%X, ignoring... (%d)", offset, minOffset, i, foundCount);
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

#pragma mark New Offset Scanning Functions


- (NSData*)getChunk:(vm_address_t)SourceAddress withSourceSize:(vm_size_t)SourceSize{
	
	NSMutableData *data = [[NSMutableData alloc] init];
	
    // get the WoW PID
    pid_t wowPID = 0;
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    OSStatus err = GetProcessPID(&wowPSN, &wowPID);
	
    if ( (err == noErr) && (wowPID > 0) ) {
        
        // now we need a Task for this PID
        mach_port_t MySlaveTask;
        kern_return_t KernelResult = task_for_pid(current_task(), wowPID, &MySlaveTask);
		
		// task found
        if ( KernelResult == KERN_SUCCESS ) {
            //vm_address_t SourceAddress = 0;
            //vm_size_t SourceSize = 0;
            vm_region_basic_info_data_t SourceInfo;
            mach_msg_type_number_t SourceInfoSize = VM_REGION_BASIC_INFO_COUNT;
            mach_port_t ObjectName = MACH_PORT_NULL;
            vm_size_t ReturnedBufferContentSize;
			Byte *ReturnedBuffer = nil;
            
            if ( KERN_SUCCESS == ( KernelResult = vm_region(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO,(vm_region_info_t) &SourceInfo,&SourceInfoSize,&ObjectName) ) ){
				
				// we only want to read this block
                if ( ( SourceInfo.protection & VM_PROT_READ ) ) {
                    NS_DURING {
						ReturnedBuffer = malloc(SourceSize);
                        ReturnedBufferContentSize = SourceSize;
                        if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                            (ReturnedBufferContentSize > 0) )
                        {
							
							// copy the raw data to our object
							[data appendBytes:ReturnedBuffer length:ReturnedBufferContentSize];
						}
						else{
							PGLog(@"[Offset] Memory read failed");
						}
                    } NS_HANDLER {
                    } NS_ENDHANDLER
					
					if ( ReturnedBuffer != nil ) {
                        free( ReturnedBuffer );
                        ReturnedBuffer = nil;
                    }
                }
            }
        }
    }
	
	return [[data retain] autorelease];
}

// Success for reading from 0x0 to 0x1000  SourceInfo: 0x0 0x0
// Success for reading from 0x1000 to 0xC6E000  SourceInfo: 0x5 0x7

#define TEXT_SEGMENT_START		0x1000
- (NSArray*)offsetWithByteSignature: (NSString*)signature 
								withMask:(NSString*)mask 
						   withEmulation:(BOOL)emulatePPC{
	
	// grab our chunk of memory (we only want data in the text address)
	int len = TEXT_SEGMENT_MAX_ADDRESS - TEXT_SEGMENT_START;
	NSData *data = [self getChunk:(vm_address_t)TEXT_SEGMENT_START withSourceSize:len];
	
	// convert to Byte*
	NSUInteger newLength = [data length];
	Byte *byteData = (Byte*)malloc(newLength);
	memcpy(byteData, [data bytes], newLength);
	
	// the list we'll return!
	NSArray *offsetList = nil;
	
	// we're good to go!
	if ( data != nil ){
		
		// allocate our bytes variable which will store our signature
		Byte *bytes = calloc( [signature length]/2, sizeof( Byte ) );
		unsigned int i = 0, k = 0;
		NSRange range;

		// incrementing by 4 (to skip the beginning \x)
		for ( ;i < [signature length]; i+=4 ){
			range.length = 2;
			range.location = i+2;
			
			const char *sigMask = [[signature substringWithRange:range] UTF8String];
			long one = strtol(sigMask, NULL, 16);
			bytes[k++] = (Byte)one;
		}

		// get our mask
		const char *szMaskUTF8 = [mask UTF8String];
		char *szMask = strdup(szMaskUTF8);
		
		if ( IS_X86 && !emulatePPC ){

			offsetList = [self findPattern:bytes
							withStringMask:szMask 
								  withData:byteData
								   withLen:len
							 withMinOffset:0x0];

		}
		// PPC
		else {
			offsetList = [self findPatternPPC:bytes
							   withStringMask:szMask 
									 withData:byteData
									  withLen:len
								withMinOffset:0x0];
		}
	}
	else {
		PGLog(@"[Offset] Unable to read memory!");
	}
	
	// free our buffer
	if ( byteData )
		free( byteData );
	
	return [[offsetList retain] autorelease];
}

- (NSArray*) findPatternPPC: (unsigned char*)bMask 
					withStringMask:(char*)szMask 
						  withData:(Byte*)dw_Address 
						   withLen:(unsigned long)dw_Len 
					 withMinOffset:(long)minOffset 
{
	unsigned long i;
	NSMutableArray *list = [[NSMutableArray array] retain];
	for(i=0; i < dw_Len; i++){
		
		if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){
			
			const unsigned char* pData = (unsigned char*)( dw_Address+i );
			char *mask = szMask;
			unsigned long offset = 0x0;
			for ( ;*mask;++mask,++pData){
				if ( *mask == '?' ){
					offset <<= 8;  
					offset ^= (long)*pData & 0xFF;   
				}
			}
			
			if ( offset >= minOffset ){
				//PGLog(@"[Offset] Found 0x%X, adding to array", offset);
				[list addObject:[NSNumber numberWithInt:offset]];
			}
			else if ( offset > 0x0 ){
				//PGLog(@"[Offset] Found 0x%X < 0x%X, ignoring... (%d)", offset, minOffset, i);
			}
		}
	}
	
	return [[list retain] autorelease];
}

- (NSArray*) findPattern: (unsigned char*)bMask 
				 withStringMask:(char*)szMask 
					   withData:(Byte*)dw_Address 
						withLen:(unsigned long)dw_Len 
				  withMinOffset:(long)minOffset 
{
	unsigned long i;
	NSMutableArray *list = [[NSMutableArray array] retain];
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
			
			if ( offset >= minOffset && offset > 0x0 ){
				//PGLog(@"[Offset] Found 0x%X, adding to array", offset);
				[list addObject:[NSNumber numberWithInt:offset]];
			}
			else if ( offset > 0x0 ){
				//PGLog(@"[Offset] Found 0x%X < 0x%X, ignoring... (%d)", offset, minOffset, i);
			}
		}
	}
	
	return [[list retain] autorelease];
}

@end

/*
 
 Official place for notes on offsets!!
 
 GetNumCompanions
	0x0		- Number of Pets
	0x4		- Pointers to list of pets
	0x10	- Number of mounts
	0x14	- Pointer to list of mounts
 
 PLAYER_NAME_LIST	- Basically you have a bunch of linked lists here, wish I understand some calling functions better
	0x10	- Friends list
	0x14	- Guildies
	0x24	- People within range
 
 PLAYER_GUID_NAME	- This has the player's 64-bit GUID + name!
	0x0		- 64-bit GUID
	0x8		- Player name
 
 
 */
