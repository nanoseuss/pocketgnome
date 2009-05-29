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
#import "NodeController.h"
#import "Node.h"
#import "PlayerDataController.h"
#import "MemoryAccess.h"
#import "ChatController.h"
#import "Position.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

#define ANIMATION_CAST			8650752
#define ANIMATION_MOVED			8650753
#define ANIMATION_GONE			8716288

#define M_DEG2RAD				0.01745329251f

@implementation FishController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_isFishing = NO;
		
        [NSBundle loadNibNamed: @"Fishing" owner: self];
    }
    return self;
}

- (void)awakeFromNib {
    self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = NSZeroSize;
	
    [fishingRecorder setCanCaptureGlobalHotKeys: YES];
    
    KeyCombo combo1 = { NSShiftKeyMask, kSRKeysF13 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"FishingCode"])
        combo1.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"FishingCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"FishingFlags"])
        combo1.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"FishingFlags"] intValue];
	
    [fishingRecorder setDelegate: nil];
	
    [fishingRecorder setKeyCombo: combo1];
    
    [fishingRecorder setDelegate: self];
}


@synthesize view;
@synthesize minSectionSize;
@synthesize maxSectionSize;

- (NSString*)sectionTitle {
    return @"Fishing";
}

- (IBAction)startStopFishing: (id)sender {
	
	Player *player = [playerController player];
	if ( !player ) return;
	
	if ( _isFishing ){
		[startStopButton setTitle: @"Start Fishing"];
		_isFishing = NO;
	}
	else{
		[startStopButton setTitle: @"Stop Fishing"];	
		_isFishing = YES;
	}
	
	// Lets start fishing!
	[self fishBegin];
}

- (void)fishBegin{
	if ( !_isFishing){
		return;
	}
	
	// Send the fishing hotkey to wow!
	KeyCombo fishingCombo = [fishingRecorder keyCombo];
    int fishingHotkey = fishingCombo.code;
    int fishingHotkeyModifier = fishingCombo.flags;
	
	//PGLog(@"[Fishing] Sending key!");
	[chatController pressHotkey: fishingHotkey withModifier: fishingHotkeyModifier];
	
	// Find our player's fishing bobber! - we need to wait a couple seconds after cast, so the object list can re-populate
	[self performSelector: @selector(findBobber)
			   withObject: nil
			   afterDelay: 2.0];
}


// Lets find our bobber - then start monitoring it every 0.1 seconds
- (void)findBobber{
	if ( !_isFishing ){
		return;
	}
	
	NSArray *fishingBobbers = [nodeController allFishingBobbers];
	Player *player = [playerController player];
	BOOL bobberFound = NO;
	
	for ( Node *bobber in fishingBobbers ){
		//PGLog(@"[Fishing] Checking bobber: %@  For player: %d", bobber, [player GUID]);
		
		// We need to check to see if it is our players - and that it isn't a previous one!
		UInt32 animation = 0;
		[[controller wowMemoryAccess] loadDataForObject: self atAddress: ([bobber baseAddress] + 0xB4) Buffer: (Byte *)&animation BufLength: sizeof(animation)];
			
		// BAM our player's bobber is found yay!
		if ( [bobber owner] == [player GUID] && animation != ANIMATION_GONE ){
			bobberFound = YES;
			//PGLog(@"[Fishing] Found our bobber! %d", animation);
			
			// Start scanning to  check for when the bobber animation changes!
			[self performSelector: @selector(checkBobberAnimation:)
					   withObject: bobber
					   afterDelay: 0.1];
		}
	}
	
	if ( !bobberFound ){
		[self performSelector: @selector(findBobber)
				   withObject: nil
				   afterDelay: 0.1];
	}
	
}

// We want to check out bobber every 0.1 seconds to see if it has changed!
- (void)checkBobberAnimation:(id)sender{
	if ( !_isFishing ){
		return;
	}
	
	UInt32 animation = 0;
	
	if([[controller wowMemoryAccess] loadDataForObject: self atAddress: ([sender baseAddress] + 0xB4) Buffer: (Byte *)&animation BufLength: sizeof(animation)]) {
	
		// Click!
		if ( animation == ANIMATION_MOVED ){
			//PGLog(@"[Fishing] It moved!  Click it!");
			[self clickBobber: sender];
			return;
			
		}
		
		// Our bobber is gone! O no! I hope we clicked it!		
		if ( animation == ANIMATION_GONE || (animation != ANIMATION_MOVED && animation != ANIMATION_CAST) ){
			//PGLog(@"[Fishing] It's gone :(  %d", animation);
			// This is where we should call to fish again! Let's add a delay in case of server lag, so we have time to auto-loot!
			[self performSelector: @selector(fishBegin)
					   withObject: nil
					   afterDelay: 3.0];
			
			return;
		}
				  
		[self performSelector: @selector(checkBobberAnimation:)
				   withObject: sender
				   afterDelay: 0.1];
	}
	else{
		//PGLog(@"[Fishing] failbot?");
	}
}

- (void)clickBobber:(Node*)bobber{
	//PGLog(@"[Fishing] Clicking %@  Position of bobber: %@", bobber, [bobber position]);
	
	Position *pos = [bobber position];
	
	[self moveMouseToWoWCoordsWithX:[pos xPosition] 
								  Y:[pos yPosition] 
								  Z:[pos zPosition]];
}

typedef struct CameraInfo{
	UInt32		dwFoo1[2];
	float	fPos[3];
	float	fViewMat[3][3];
	UInt32		dwFoo2[2];
	float	fFov;
} CameraInfo;

- (BOOL)moveMouseToWoWCoordsWithX: (float)x Y:(float)y Z:(float)z{
	
	CameraInfo camera;
	
	// I really need to initialize these to remove warnings?
	int i,f;
	for(i=0;i<3;i++){
		for(f=0;f<3;f++){
			camera.fViewMat[i][f]=0;
		}
		camera.fPos[i]=0;
		
		if ( i < 2 ){
			camera.dwFoo1[i] = 0;
			camera.dwFoo2[i] = 0;
		}
	}
	camera.fFov = 0;
	
	// Lets get the camera info!
	UInt32 cAddress1, cAddress2;
	if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (CAMERA_PTR) Buffer: (Byte*)&cAddress1 BufLength: sizeof(cAddress1)] && cAddress1) {
		
		// We now have the address that is at CAMERA_PTR, lets add 0x782C to it and jump again!
		if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress1 + CAMERA_OFFSET) Buffer: (Byte*)&cAddress2 BufLength: sizeof(cAddress2)] && cAddress2) {
			
			// Now we can get the camera info! w00t!
			CameraInfo camera;
			if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress2) Buffer:(Byte*)&camera BufLength: sizeof(camera)]) {
				
				//CVec3 vDiff = vWoWPos - camera.vPos;
				float fDiff[3];
				fDiff[0] = x;
				fDiff[1] = y;
				fDiff[2] = z;
				
				//float fProd = vDiff*camera.matView[0];
				float fProd = 
				fDiff[0]*camera.fViewMat[0][0] +
				fDiff[1]*camera.fViewMat[0][1] +
				fDiff[2]*camera.fViewMat[0][2];
				if( fProd < 0 ){
					return NO;
				}
				
				//CVec3 vView = vDiff*!camera.matView;
				float fInv[3][3];
				fInv[0][0] = camera.fViewMat[1][1]*camera.fViewMat[2][2]-camera.fViewMat[1][2]*camera.fViewMat[2][1];
				fInv[1][0] = camera.fViewMat[1][2]*camera.fViewMat[2][0]-camera.fViewMat[1][0]*camera.fViewMat[2][2];
				fInv[2][0] = camera.fViewMat[1][0]*camera.fViewMat[2][1]-camera.fViewMat[1][1]*camera.fViewMat[2][0];
				
				float fDet = camera.fViewMat[0][0]*fInv[0][0]+camera.fViewMat[0][1]*fInv[1][0]+camera.fViewMat[0][2]*fInv[2][0];
				float fInvDet = 1.0f / fDet;
				
				fInv[0][1] = camera.fViewMat[0][2]*camera.fViewMat[2][1]-camera.fViewMat[0][1]*camera.fViewMat[2][2];
				fInv[0][2] = camera.fViewMat[0][1]*camera.fViewMat[1][2]-camera.fViewMat[0][2]*camera.fViewMat[1][1];
				fInv[1][1] = camera.fViewMat[0][0]*camera.fViewMat[2][2]-camera.fViewMat[0][2]*camera.fViewMat[2][0];
				fInv[1][2] = camera.fViewMat[0][2]*camera.fViewMat[1][0]-camera.fViewMat[0][0]*camera.fViewMat[1][2];
				fInv[2][1] = camera.fViewMat[0][1]*camera.fViewMat[2][0]-camera.fViewMat[0][0]*camera.fViewMat[2][1];
				fInv[2][2] = camera.fViewMat[0][0]*camera.fViewMat[1][1]-camera.fViewMat[0][1]*camera.fViewMat[1][0];
				camera.fViewMat[0][0] = fInv[0][0]*fInvDet;
				camera.fViewMat[0][1] = fInv[0][1]*fInvDet;
				camera.fViewMat[0][2] = fInv[0][2]*fInvDet;
				camera.fViewMat[1][0] = fInv[1][0]*fInvDet;
				camera.fViewMat[1][1] = fInv[1][1]*fInvDet;
				camera.fViewMat[1][2] = fInv[1][2]*fInvDet;
				camera.fViewMat[2][0] = fInv[2][0]*fInvDet;
				camera.fViewMat[2][1] = fInv[2][1]*fInvDet;
				camera.fViewMat[2][2] = fInv[2][2]*fInvDet;
				float fView[3];
				fView[0] = fInv[0][0]*fDiff[0]+fInv[1][0]*fDiff[1]+fInv[2][0]*fDiff[2];
				fView[1] = fInv[0][1]*fDiff[0]+fInv[1][1]*fDiff[1]+fInv[2][1]*fDiff[2];
				fView[2] = fInv[0][2]*fDiff[0]+fInv[1][2]*fDiff[1]+fInv[2][2]*fDiff[2];
				
				//CVec3 vCam( -vView.fY,-vView.fZ,vView.fX );
				float fCam[3];
				fCam[0] = -fView[1];
				fCam[1] = -fView[2];
				fCam[2] =  fView[0];
				
				// Get our rect!
				float    fScreenX = (windowRect.size.width)/2.0f;
				float    fScreenY = (windowRect.size.height)/2.0f;
				
				// Thanks pat0! Aspect ratio fix
				float    fTmpX    = fScreenX/tan(((camera.fFov*44.0f)/2.0f)*M_DEG2RAD);
				float    fTmpY    = fScreenY/tan(((camera.fFov*35.0f)/2.0f)*M_DEG2RAD);
				
				
				NSPoint pctMouse;
				pctMouse.x = fScreenX + fCam[0]*fTmpX/fCam[2];
				pctMouse.y = fScreenY + fCam[1]*fTmpY/fCam[2];
				
				PGLog(@"[Fishing] Clicking X:%f  Y:%f", pctMouse.x, pctMouse.y);
				
				if( pctMouse.x < 0 || pctMouse.y < 0 || pctMouse.x > rc.right || pctMouse.y > rc.bottom ){
					return NO;
				}
				
				//if( !::SetCursorPos(pctMouse.x,pctMouse.y) )
				//	return NO;
				
				// New way to click?  http://stackoverflow.com/questions/726952/simulate-mouse-click-to-window-instead-of-screen
			}
		}
	}
	
	return YES;
}

#pragma mark ShortcutRecorder Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
    if(recorder == fishingRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"FishingCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"FishingFlags"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
