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
- (BOOL) bDataCompare: (const char *)pData byteMask:(const char*)byteMask stringMask:(const char*)stringMask;
- (unsigned long) findPatternWithByteMask: (char*)byteMask 
						   withStringMask: (char*)stringMask 
								 withData: (Byte *)data
								  withLen: (vm_size_t)dwLen;
- (void)memoryChunk;

@end

@implementation OffsetController

//sub_26A988
#define PLAYER_NAME_STATIC "\xBA\x48\xFD\x53\x01\x0F\x45\xC2\x5D\xC3"
#define PLAYER_NAME_STATIC_MASK "x????xxxxx"


- (void)dumpOffsets{
	
	//UInt32 dwStartFunc						=	[self findPatternWithByteMask: (UInt8*)"\x56\x57\x68\x00\x00\x00\x00\xB8\x05" withStringMask:"xxx????xx"];
	//PGLog(@"#define PLAYER_NAME_STATIC        0x%08X", dwStartFunc );
	
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
                if ((SourceInfo.protection & VM_PROT_WRITE) && (SourceInfo.protection & VM_PROT_READ)) {
                    NS_DURING {
                        ReturnedBuffer = malloc(SourceSize);
                        ReturnedBufferContentSize = SourceSize;
                        if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                            (ReturnedBufferContentSize > 0) )
                        {
							// This is where we want to find patterns!
                            
							unsigned long player_name = [self findPatternWithByteMask:PLAYER_NAME_STATIC withStringMask:PLAYER_NAME_STATIC_MASK withData:ReturnedBuffer withLen:SourceSize];

							PGLog(@"0x%x", player_name);
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
				
				if ( SourceAddress > 0x015E7736 ){
					break;
				}
            }
        }
    }
}

- (unsigned long) findPatternWithByteMask: (char*)byteMask 
						   withStringMask: (char*)stringMask 
								 withData: (Byte*)data
								  withLen: (vm_size_t)dwLen{
	
	//PGLog(@"Searching length %d", dwLen);
	
	//PGLog(@"Using byte pattern '%s' and mask '%s'", bMask, stringMask);
	
	unsigned long i = 0;
	for(i=0;i<dwLen;i++){
		if ( [self bDataCompare: (char*)( data+i ) byteMask:byteMask stringMask:stringMask] ){
			return (unsigned int)(data+i);
		}
	}
	
	return 0;	
}
/*
 unsigned long dwStartAddress = 0x00401000, dwLen = 0x00861FFF;
 unsigned long dwFindPattern( unsigned char *bMask,char * szMask, unsigned long dw_Address = dwStartAddress, unsigned long dw_Len = dwLen )
 {
 for(unsigned long i=0; i < dw_Len; i++)
 if( bDataCompare( (unsigned char*)( dw_Address+i ),bMask,szMask) )
 return (unsigned long)(dw_Address+i);
 return 0;
 }
 */

- (BOOL) bDataCompare: (const char *)pData byteMask:(const char*)byteMask stringMask:(const char*)stringMask{
	
	for(;*stringMask;++stringMask,++pData,++byteMask){
		if ( *stringMask == 'x' && *pData!=*byteMask ){
			return NO;
		}
		
		//PGLog(@"Comparing '%c' != '%c'", *pData, *byteMask);
	}
	
	//PGLog(@"Mask: %d", *stringMask);
	
	return ((*stringMask) == 0);
}
/*
 bool bDataCompare(const unsigned char* pData, const unsigned char* bMask, const char* szMask)
 {
 for(;*szMask;++szMask,++pData,++bMask)
 if(*szMask=='x' && *pData!=*bMask )
 return false;
 return (*szMask) == 0;
 }
 */


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
