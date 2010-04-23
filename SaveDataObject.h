//
//  SaveDataObject.h
//  Pocket Gnome
//
//  Created by Josh on 1/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SaveDataObject : NSObject <NSCoding, NSCopying> {
	NSString *_UUID;		// unique ID
	
	BOOL _changed;			// use so we know if we should re-save or not
}

@property (readwrite, assign) BOOL changed;
@property (readonly, retain) NSString *UUID;

@end
