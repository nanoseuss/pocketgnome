//
//  DatabaseManager.m
//  Pocket Gnome
//
//  Created by Josh on 4/12/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "DatabaseManager.h"
#import "Controller.h"


@implementation DatabaseManager

- (id) init{
    self = [super init];
    if ( self != nil ){
		
		_tables = [[NSMutableDictionary dictionary] retain];
		
		// if I was awesome I would make this a DB object
		//	read the data the first time so we don't have to later!
		[_tables setObject:[NSNumber numberWithUnsignedInt:0xD2E300] forKey:@"Spell"];	// 0x194
		
		// add spell table
		//DbTable *table = [WbTable WoWDbTableWithTablePtr:0xD2E300];
		//[_tables setObject:table forKey:[NSNumber numberWithUnsignedInt:0x194];
		 
		 // ideally I'd like to loop through this and read all of the table info, to be done later ;)
	}
	return self;
}
		 
- (void)dealloc{
	[super dealloc];
}

#pragma mark -

typedef struct ClientDb {
    UInt32 _vtable;			// 0x0
    UInt32 isLoaded;		// 0x4
    UInt32 numRows;			// 0x8				// 49379
    UInt32 maxIndex;		// 0xC				// 74445
    UInt32 minIndex;		// 0x10				// 1
	UInt32 stringTablePtr;	// 0x14
	UInt32 _vtable2;		// 0x18
	// array of row pointers after this...
	UInt32 row1;			// 0x1C				// this points to the first actual row in the database (in theory we could use this, then loop until we hit numRows and we have all the rows)
	UInt32 row2;			// 0x20
	
} ClientDb;

// huge thanks to Apoc! Code below frm him
- (BOOL)unPackRow:(UInt32)addressOfStruct withStruct:(void*)obj withStructSize:(size_t)structSize{
	
	//NSLog(@"Obj address3: 0x%X", obj);
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory || ![memory isValid] ){
		return NO;
	}
	
	Byte byteBuffer[0x5000] = {0};
	
	byteBuffer[0] = [memory readInt:addressOfStruct withSize:sizeof(Byte)];
	int currentAddress = 1;
	int i = 0;
	const int size = 0x2C0;
	
	for ( i = addressOfStruct + 1; currentAddress < size; ++i ){
		
		byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)];
		
		Byte atI = [memory readInt:i withSize:sizeof(Byte)];
		Byte prevI = [memory readInt:i - 1 withSize:sizeof(Byte)];
		
		if ( atI == prevI ){
			
			Byte j = 0;
			for ( j = [memory readInt:i + 1 withSize:sizeof(Byte)]; j != 0; byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)] ){
				j--;
			}
			i += 2;
			if ( currentAddress < size ){
				byteBuffer[currentAddress++] = [memory readInt:i withSize:sizeof(Byte)];
			}
		}
	}
	
	memcpy( obj, &byteBuffer, structSize);
	
	return YES;
}

- (BOOL)getObjectForRow:(int)index withTable:(NSString*)table withStruct:(void*)obj withStructSize:(size_t)structSize{
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	if ( !memory || ![memory isValid] ){
		return NO;
	}
	
	//NSLog(@"Obj address2: 0x%X", obj);
	
	// snag our address
	NSNumber *addr = [_tables objectForKey:table];
	UInt32 dbAddress = 0x0;
	if ( addr ){
		dbAddress = [addr unsignedIntValue];
	}
	
	//NSLog(@"[Db] Loading data for index %d", index);
	
	// time to load our data
	ClientDb db;
	if ( dbAddress && [memory loadDataForObject:self atAddress:dbAddress Buffer:(Byte *)&db BufLength:sizeof(db)] ){
		//NSLog(@"[Db] Loaded database '%@' with base pointer 0x%X and row2: 0x%X", table, dbAddress, db.row2);
		
		// time to snag our row!
		if ( index >= db.minIndex && index <= db.maxIndex ){
			
			UInt32 rowPointer = db.row2 + ( 4 * (index - db.minIndex) );
			//NSLog(@"[Db] Row pointer: 0x%X %d", rowPointer, (index - db.minIndex));
			UInt32 structAddress = [memory readInt:rowPointer withSize:sizeof(UInt32)];
			
			// we don't have a pointer to a struct, quite unfortunate
			if ( structAddress == 0 ){
				return NO;
			}
			
			//NSLog(@"[Db] We have a valid struct address! Row is pointing to 0x%X", structAddress);
			
			if ( [table isEqualToString:@"Spell"] ){
				if ( [self unPackRow:structAddress withStruct:obj withStructSize:structSize] ){
					return YES;
				}
			}
		}
	}
	
	return NO;	
}

		 
@end