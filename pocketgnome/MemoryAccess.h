
#import <Cocoa/Cocoa.h>


@interface MemoryAccess : NSObject
{
    pid_t AppPid;
    mach_port_t MySlaveTask;
    AuthorizationRef gAuth;
    
    int readsProcessed;
    float throughput;
    
    NSMutableDictionary *loaderDict;
}
- (id)init;
- (id)initWithPID:(pid_t)PID;
- (BOOL)isValid;

- (BOOL)performToolVersionCheck;
- (BOOL)verifyAuthorization;

@property float throughput;
- (void)resetLoadCount;
- (void)printLoadCount;
- (int)loadCount;

- (BOOL)loadDataFromAddress: (UInt32)address intoBuffer: (Byte*)buffer ofLength: (vm_size_t)size;
- (BOOL)saveDataToAddress: (UInt32)address fromBuffer: (Byte*)buffer ofLength: (vm_size_t)size;

// save record to application addresses
- (BOOL)saveDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// load record from application addresses
- (BOOL)loadDataForObject: (id)object atAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
//- (BOOL)loadDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// raw reading, minimal error checking, actual return result
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

@end
