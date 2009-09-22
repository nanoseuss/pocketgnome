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

@interface OffsetController (Internal)

//- (unsigned int) findPatternWithByteMask: (unsigned char*)byteMask withStringMask:(unsigned char*)stringMask;
/*- (BOOL) bDataCompare: (const char *)pData byteMask:(const char*)byteMask stringMask:(const char*)stringMask;
- (unsigned long) findPatternWithByteMask: (char*)byteMask 
						   withStringMask: (char*)stringMask 
								 withData: (Byte *)data
								  withLen: (vm_size_t)dwLen;*/
- (void)memoryChunk;

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask);
unsigned long dwFindPattern( unsigned char *bMask,char * szMask, Byte* dw_Address, unsigned long dw_Len, unsigned long startAddressOffset );

/*
BOOL bDataCompare(const Byte* pData, const Byte* bMask, const char* szMask);
uint32_t dwFindPattern(Byte * dwAddress,uint32_t dwLen,Byte *bMask,char * szMask);
*/
@end

@implementation OffsetController

//sub_26A7B8
//#define PLAYER_NAME_STATIC          ((IS_X86) ? 0x153FD48 : 0x0)		// 3.2.0

//	sub_1F22D0
//	PLAYER_GUID_STATIC
#define PLAYER_GUID_STATIC "\x8B\x75\x10\x8B\x7D\x14\x8B\x15\xE0\xBE\xB9\x00\x8D\x42\x01\xA3\xE0\xBE\xB9\x00"
#define PLAYER_GUID_STATIC_MASK "xxxxxxxx????xxxx????"
		// 0xB9BEE0

#define TEST2			"\xEB\x02\x33\x00\x64\x8B\x15\x2C\x00\x00\x00\x8B\x0D\x00\x00\x00\x00\x8B\x0C\x8A"
#define TEST2_MASK		"xxx?xxxxxxxxx????xxx"
		// 0x15709518


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
							
							if ( ReturnedBufferContentSize > 0x824DC0 ){
								ReturnedBufferContentSize = 0x824DC0;
								
							}
							// This is where we want to find patterns!
							
							PGLog(@"0x%X:0x%X  0x%X:0x%X", SourceAddress, SourceAddress + SourceSize, SourceAddress, ReturnedBufferContentSize);
                            
							//	dwFindPattern( (BYTE*)"\x55\x8B\xEC\xA1\x00\x00\x00\x00\x83\xEC\x08\x83\xF8\x01", "xxxx????xxxxxx" );
							
							unsigned long player_name = dwFindPattern( (Byte*)PLAYER_GUID_STATIC, PLAYER_GUID_STATIC_MASK, ReturnedBuffer, SourceSize, SourceAddress );
							//unsigned long player_name = [self findPatternWithByteMask:PLAYER_NAME_STATIC withStringMask:PLAYER_NAME_STATIC_MASK withData:ReturnedBuffer withLen:ReturnedBufferContentSize];
							PGLog(@"0x%X", player_name);
							
							//player_name = dwFindPattern( (Byte*)TEST2, TEST2_MASK, ReturnedBuffer, SourceSize );
							
							//player_name = [self findPatternWithByteMask:TEST2 withStringMask:TEST2_MASK withData:ReturnedBuffer withLen:ReturnedBufferContentSize];
							
							//PGLog(@"0x%X", player_name);
							
							/*NSString *searchString = [[NSString alloc] initWithBytes:ReturnedBufferContent length:ReturnedBufferContentSize encoding:NSUTF8StringEncoding];
							NSString *regexString  = @"(\\w+)\\s+(\\w+)\\s+(\\w+)";
							NSRange   matchedRange = NSMakeRange(NSNotFound, 0UL);
							NSError  *error        = NULL;
							
							matchedRange = [searchString rangeOfRegex:regexString options:RKLNoOptions inRange:searchRange capture:2L error:&error];
						*/
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
				
				if ( SourceAddress > 0x824DC0 ){
					break;
				}
            }
        }
    }
}

BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask)
{
	for(;*szMask;++szMask,++pData,++bMask){
		if(*szMask=='x' && *pData!=*bMask ){
			return false;
		}
	}
	return (*szMask) == 0;
}

unsigned long dwFindPattern( unsigned char *bMask,char * szMask, Byte*dw_Address, unsigned long dw_Len, unsigned long startAddressOffset )
{
	unsigned long i;
	for(i=0; i < dw_Len; i++)
		if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) ){
			PGLog(@"Found signature at 0x%X ", i + startAddressOffset);
			return (unsigned long)(dw_Address+i);
		}
	return 0;
}

/*
BOOL bDataCompare(const Byte* pData, const Byte* bMask, const char* szMask)
{
    for(;*szMask;++szMask,++pData,++bMask)
        if(*szMask=='x' && *pData!=*bMask ) 
            return false;
    return (*szMask) == 0;
}

uint32_t dwFindPattern(Byte *dwAddress,uint32_t dwLen,Byte *bMask,char * szMask)
{
	
	PGLog(@"Searching for pattern '0x%X' and mask '%s'", bMask, szMask);
	
	uint32_t i;
    for(i=0; i < dwLen; i++)
        if( bDataCompare( (Byte*)( dwAddress+i ),bMask,szMask) ){
			PGLog(@"Found after %d searches", i );
            return (uint32_t)(dwAddress+i);
		}
    
    return 0;
} */


/*
- (unsigned long) findPatternWithByteMask: (char*)byteMask 
						   withStringMask: (char*)stringMask 
								 withData: (Byte*)data
								  withLen: (vm_size_t)dwLen{
	
	//PGLog(@"Searching length %d", dwLen);
	
	//PGLog(@"Using byte pattern '%s' and mask '%s'", bMask, stringMask);
	
	unsigned long i = 0;
	for(i=0;i<dwLen;i++){
		if ( [self bDataCompare: (char*)( data+i ) byteMask:byteMask stringMask:stringMask] ){
			PGLog(@"Found! i: %d len:%d", i, dwLen);
			return (unsigned long)(data+i);
		}
	}
	
	return 0;	
}*/

 //unsigned long dwStartAddress = 0x00401000, dwLen = 0x00861FFF;
/* unsigned long dwFindPattern( unsigned char *bMask,char * szMask, unsigned long dw_Address, unsigned long dw_Len )
{
	 unsigned long i;
 for(i=0; i < dw_Len; i++)
 if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) )
 return (unsigned long)(dw_Address+i);
 return 0;
 }*/
 

/*
- (BOOL) bDataCompare: (const char *)pData byteMask:(const char*)byteMask stringMask:(const char*)stringMask{
	
	for(;*stringMask;++stringMask,++pData,++byteMask){
		if ( *stringMask == 'x' && *pData!=*byteMask ){
			return NO;
		}
	}
	
	return ((*stringMask) == 0);
}*/

 /*BOOL bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask)
{
 for(;*szMask;++szMask,++pData,++bMask)
 if(*szMask=='x' && *pData!=*bMask )
 return false;
 return (*szMask) == 0;
 }*/
 


/*
 
 short int byteDataCompare(const unsigned char *pData, const unsigned char* byteMask, const unsigned char* stringMask)
 {
 for(;*stringMask;++stringMask,++pData,++byteMask)
 if(*stringMask=='x' && *pData!=*byteMask ) 
 return 0;
 return (*stringMask) == NULL;
 }
 
 - (unsigned int) findPatternWithByteMask: (unsigned char*)byteMask withStringMask:(unsigned char*)stringMask
 {
 unsigned int i;
 unsigned long startAddress = dwStartAddress;
 unsigned long lengthFromStart = dwLen;
 
 for(i=0; i < lengthFromStart; i++) 
 {
 printf("Comparing\n");
 if( byteDataCompare( (unsigned char*)( startAddress+i ),byteMask,stringMask) ) {
 return (unsigned int)(startAddress+i);
 }
 }
 return 0;
 }*/

@end
