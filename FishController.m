//
//  FishController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "FishController.h"
#import "Offsets.h"
#import "MemoryAccess.h"
#import "Controller.h"

@implementation FishController

typedef struct CameraInfo{
	GUID	guid;
	int		foo;
	float	fPos[3];
	float	fViewMat[3][3];
	int		dwFoo2[2];
	float	fFov;
} CameraInfo;


/*
	MemoryAccess *memory = [controller wowMemoryAccess];
	if(![memory isValid]) return;
	
	// Lets get the camera info!
	UInt32 cAddress1, cAddress2;
	if([memory loadDataForObject: self atAddress: (CAMERA_PTR) Buffer: (Byte*)&cAddress1 BufLength: sizeof(cAddress1)] && cAddress1) {
		
		// We now have the address that is at CAMERA_PTR, lets add 0x782C to it and jump again!
		if([memory loadDataForObject: self atAddress: (cAddress1 + CAMERA_OFFSET) Buffer: (Byte*)&cAddress2 BufLength: sizeof(cAddress2)] && cAddress2) {
			
			// Now we can get the camera info! w00t!
			CameraInfo camera;
			if([memory loadDataForObject: self atAddress: (cAddress2) + sizeof(camera) Buffer:(Byte*)&camera BufLength: sizeof(camera)]) {
			}
		}
	}
*/


@end
