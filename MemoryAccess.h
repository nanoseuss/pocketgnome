
#import <Cocoa/Cocoa.h>


@interface MemoryAccess : NSObject
{
    pid_t AppPid;
    mach_port_t MySlaveTask;
    AuthorizationRef gAuth;
    
    int readsProcessed;
    float throughput;
	
	// statistics info
	int _totalReadsProcessed;
	int _totalWritesProcessed;
    
    NSMutableDictionary *loaderDict;
}
- (id)init;
- (id)initWithPID:(pid_t)PID;
- (BOOL)isValid;

@property float throughput;
- (void)resetLoadCount;
- (void)printLoadCount;
- (int)loadCount;

// save record to application addresses
- (BOOL)saveDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// load record from application addresses
- (BOOL)loadDataForObject: (id)object atAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;
//- (BOOL)loadDataForAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

// raw reading, minimal error checking, actual return result
- (kern_return_t)readAddress: (UInt32)address Buffer: (Byte *)DataBuffer BufLength: (vm_size_t)Bytes;

@end
