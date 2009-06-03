//
//  FishController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/23/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "FishController.h"
#import "Controller.h"
#import "NodeController.h"
#import "PlayerDataController.h"
#import "ChatController.h"
#import "BotController.h"
#import "InventoryController.h"

#import "Offsets.h"

#import "Node.h"
#import "Position.h"
#import "MemoryAccess.h"
#import "Player.h"
#import "Item.h"

#import "ScanGridView.h"
#import "TransparentWindow.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

#define USE_ITEM_MASK       0x80000000

#define SPELL_FISHING			51294

#define ANIMATION_CAST			8650752
#define ANIMATION_MOVED			8650753
#define ANIMATION_GONE			8716288
								//262144   42205184

#define M_DEG2RAD				0.01745329251f

#define PI						3.14159265358979323

@implementation FishController

- (id)init{
    self = [super init];
    if (self != nil) {
		
		_isFishing = NO;
		_xBobber = 0;
		_yBobber = 0;
		
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
	
	// set up overlay window
    [overlayWindow setLevel: NSFloatingWindowLevel];
    if([overlayWindow respondsToSelector: @selector(setCollectionBehavior:)]) {
        [overlayWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
    }
	
	[scanGrid setXIncrement: 16.0f];
    [scanGrid setYIncrement: 16.0f];
    [scanGrid display];
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
	
	_applyLure = [applyLureCheckbox state];

	// Lets start fishing!
	[self fishBegin];
}

- (void)fishBegin{
	if ( !_isFishing){
		return;
	}
	
	// Lets apply some lure if we need to!
	[self applyLure];
	
	// Fishing!
	[botController performAction: SPELL_FISHING];
	
	// Find our player's fishing bobber! - we need to wait a couple seconds after cast, so the object list can re-populate
	[self performSelector: @selector(findBobber)
			   withObject: nil
			   afterDelay: 2.0];
}

- (void)applyLure{
	if ( !_applyLure ){
		return;
	}

	Item *item = [itemController itemForGUID: [[playerController player] itemGUIDinSlot: SLOT_MAIN_HAND]];

	if ( ![item hasTempEnchantment] ){
		
		// Lets actually use the item we want to apply!
		[botController performAction:(USE_ITEM_MASK + 6530)];
		
		// Wait a bit before we cast the next one!
		usleep([controller refreshDelay]);
		
		// Now use our fishing pole so it's applied!
		[botController performAction:(USE_ITEM_MASK + [item entryID])];
	}
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
			
			_bobber = bobber;
			
			// Start scanning to  check for when the bobber animation changes!
			[self performSelector: @selector(checkBobberAnimation:)
					   withObject: bobber
					   afterDelay: 0.1];
			
			//[self performSelector:@selector(findBobberOnScreen:) 
			//		   withObject:bobber 
			//		   afterDelay:2.0];		// Start 4 seconds after cast began!
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
			PGLog(@"[Fishing] It moved!  Click it!");
			[self clickBobber: sender];
			
			// This is where we should call to fish again! Let's add a delay in case of server lag, so we have time to auto-loot!
			[self performSelector: @selector(fishBegin)
					   withObject: nil
					   afterDelay: 3.0];
			
			return;
			
		}
		
		// Our bobber is gone! O no! I hope we clicked it!		
		if ( animation == ANIMATION_GONE ){//|| (animation != ANIMATION_MOVED && animation != ANIMATION_CAST) ){
			PGLog(@"[Fishing] It's gone :(  %d", animation);
			// This is where we should call to fish again! Let's add a delay in case of server lag, so we have time to auto-loot!
			[self performSelector: @selector(fishBegin)
					   withObject: nil
					   afterDelay: 3.0];
			
			return;
		}
		
		PGLog(@"[Fishing] Animation: %d", animation);
				  
		[self performSelector: @selector(checkBobberAnimation:)
				   withObject: sender
				   afterDelay: 0.1];
	}
	else{
		PGLog(@"[Fishing] failbot?");
	}
}

- (void)clickBobber:(Node*)bobber{
	PGLog(@"[Fishing] Clicking %@  Position of bobber: %@", bobber, [bobber position]);
	
	
	UInt64 value = [bobber GUID];
	
	// write the mouse over GUID!
	BOOL ret1, ret2;
	// save this value to the target table
	ret1 = [[controller wowMemoryAccess] saveDataForAddress: (ON_MOUSE_OVER_GUID) Buffer: (Byte *)&value BufLength: sizeof(value)];
	ret2 = [[controller wowMemoryAccess] saveDataForAddress: (TARGET_TABLE_STATIC + TARGET_MOUSEOVER) Buffer: (Byte *)&value BufLength: sizeof(value)];
	
	
	
	PGLog(@"Setting value to %qi, ret: %d  ret2: %d", value, ret1, ret2);

	
	KeyCombo hotkey = [fishingRecorder keyCombo];
	int fishingHotkeyModifier = hotkey.flags;
	int fishingHotkey = hotkey.code;

	// wow needs time to process the spell change
	usleep([controller refreshDelay]*4);

	// then post keydown if the chat box is not open
	if(![controller isWoWChatBoxOpen] || (fishingHotkey == kVK_F13)) {
		[chatController pressHotkey: fishingHotkey withModifier: fishingHotkeyModifier];
		PGLog(@"Sending keys!");
	}
	
	// now interact with mouseover!
	
	
	return;
	
	
	if ( _xBobber == 0 || _yBobber == 0 )
		return;
	
	// Bring wow to front!
	[controller saveFrontProcess];
	[controller makeWoWFront];
	usleep(10000);
	
	CGPoint clickPt = CGPointMake(_xBobber, _yBobber);
	
	// get ahold of the previous mouse position
	NSPoint nsPreviousPt = [NSEvent mouseLocation];
	CGPoint previousPt = CGPointMake(nsPreviousPt.x, nsPreviousPt.y);
	
	CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStatePrivate);
	ProcessSerialNumber wowProcess = [controller getWoWProcessSerialNumber];
	
	
	// configure the various events
	CGEventRef moveToBobber = CGEventCreateMouseEvent(eventSource, kCGEventMouseMoved, clickPt, kCGMouseButtonLeft);
	CGEventRef moveToPrevPt = CGEventCreateMouseEvent(eventSource, kCGEventMouseMoved, previousPt, kCGMouseButtonLeft);
	CGEventRef rightClickDn = CGEventCreateMouseEvent(eventSource, kCGEventRightMouseDown, clickPt, kCGMouseButtonRight);
	CGEventRef rightClickUp = CGEventCreateMouseEvent(eventSource, kCGEventRightMouseUp, clickPt, kCGMouseButtonRight);
	//_xBobber
	
	// bug in Tiger... event type isn't set in the Create method
	CGEventSetType(rightClickDn, kCGEventRightMouseDown);
	CGEventSetType(rightClickUp, kCGEventRightMouseUp);
	CGEventSetType(moveToBobber, kCGEventMouseMoved);
	CGEventSetType(moveToPrevPt, kCGEventMouseMoved);
	
	// post the mouse events
	CGEventPostToPSN(&wowProcess, moveToBobber);
	usleep(100000);	// wait 0.1 sec
	CGEventPostToPSN(&wowProcess, rightClickDn);
	CGEventPostToPSN(&wowProcess, rightClickUp);
	usleep(100000); // wait 0.1 sec
	CGEventPostToPSN(&wowProcess, moveToPrevPt);
	
	// release events
	if(rightClickDn)    CFRelease(rightClickDn); 
	if(rightClickUp)    CFRelease(rightClickUp); 
	if(moveToBobber)    CFRelease(moveToBobber);
	if(moveToPrevPt)    CFRelease(moveToPrevPt);
	
	NSPoint screenPt = NSZeroPoint; 
	screenPt.x = _xBobber;
	screenPt.y = _yBobber;
	
	PGLog(@"[Fishing] Clicking { %d, %d }", _xBobber, _yBobber);
	
	[controller restoreFrontProcess];
	//Position *pos = [bobber position];
	//[self moveMouse: pos];
	
	/*[self moveMouseToWoWCoordsWithX:[pos xPosition] 
								  Y:[pos yPosition] 
								  Z:[pos zPosition]];*/
}



- (void)drawWithPt: (CGPoint)point{
	
    NSPoint screenPt = NSZeroPoint; 
    screenPt.x += point.x;
    screenPt.y += point.y;
	
    // create new window bounds
	NSRect newRect = NSMakeRect(point.x, [[NSScreen mainScreen] frame].size.height - (point.y), 40, 40);
    [overlayWindow setFrame: newRect display: YES];
    [overlayWindow makeKeyAndOrderFront: nil];	
	
	PGLog(@"drawing!  %f %f", newRect.origin, newRect.size);
}

- (IBAction)draw: (id)sender{
	// get the window size/location
    CGRect windowRect = [controller wowWindowRect];
	
    int minX = (windowRect.size.width*0.375f), maxX = windowRect.size.width - minX;
    int minY = (windowRect.size.height*0.375f), maxY = windowRect.size.height - minY;
	
    NSPoint screenPt = NSZeroPoint; 
    screenPt.x += windowRect.origin.x;
    screenPt.y += ([[NSScreen mainScreen] frame].size.height - (windowRect.origin.y + windowRect.size.height));
	
	PGLog(@"X:%f, Y:%F", screenPt.x, screenPt.y);
	PGLog(@"minX:%f, minY:%F", minX, minY);
    
    // create new window bounds
    NSRect newRect = NSMakeRect(minX+windowRect.origin.x, [[NSScreen mainScreen] frame].size.height - (maxY+windowRect.origin.y), maxX-minX, maxY-minY);
    [overlayWindow setFrame: newRect display: YES];
    [overlayWindow makeKeyAndOrderFront: nil];	
	
	PGLog(@"drawing!  %f %f", newRect.origin, newRect.size);
}

- (IBAction)hide: (id)sender{
	[overlayWindow orderOut: nil];	
}

- (IBAction)showBobberStructure: (id)sender{
	[memoryViewController showObjectMemory: _bobber];
    [controller showMemoryView];
}

#pragma mark ShortcutRecorder Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
    if(recorder == fishingRecorder) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"FishingCode"];
        [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"FishingFlags"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}



/*
- (void)findBobberOnScreen:(id)sender{
	
	//[self moveMouse: sender];
	
	CGRect windowRect = [controller wowWindowRect];
	
    int min_x = (windowRect.size.width*0.375f), max_x = windowRect.size.width - min_x;
    int min_y = (windowRect.size.height*0.375f), max_y = windowRect.size.height - min_y;
	int x_interval = (max_x - min_x) / 8;
	int y_interval = (max_y - min_y) / 8;
	
	[controller saveFrontProcess];
	[controller makeWoWFront];
	usleep(10000);
	
	_xBobber = 0;
	_yBobber = 0;
	
	PGLog(@"[Fishing] Origin: {%0.2f,%0.2f}  Width:%0.2f  Height:%0.2f", windowRect.origin.x, windowRect.origin.y, windowRect.size.width, windowRect.size.height);
	
	BOOL foundBobber = NO;
	int x=0,y=0,value=0, numFound=0;
	for (x = min_x; x<max_x && !foundBobber;x+=x_interval){
		for (y = min_y; y<max_y && !foundBobber;y+=y_interval){
			
			
			CGPoint aPoint = CGPointMake(windowRect.origin.x + x, windowRect.origin.y + y);
            CGPostMouseEvent(aPoint, TRUE, 2, FALSE, FALSE);
			
			usleep(10000);
			
			// Lets get the GUID of the object the mouse is over!
			[[controller wowMemoryAccess] loadDataForObject: self atAddress: ON_MOUSE_OVER_GUID Buffer: (Byte *)&value BufLength: sizeof(value)];
			
			usleep(50);
			if ( value > 0 )
			{
				PGLog(@"[Fishing] Found our bobber! %d  { %d, %d }", value, x, y);
				_xBobber += x;
				_yBobber += y;
				numFound++;
			}
			usleep(50);
			//if(moveTest)    CFRelease(moveTest);
		}
	}
	
	if ( numFound > 0 ){
		_xBobber /= numFound;
		_yBobber /= numFound;
		
		_xBobber += windowRect.origin.x;
		_yBobber += windowRect.origin.y;
		
		// create new window bounds
		//CGPoint point = CGPointMake(_xBobber, _yBobber);
		
		//[self drawWithPt:point];
	}
	
	[controller restoreFrontProcess];
	
	//if ( foundBobber ){
	PGLog(@"[Fishing] Found { %d, %d } from %d samples", _xBobber, _yBobber, numFound);
	//}
}
*/
/*
 typedef struct CameraInfo{
 UInt32		dwFoo1[2];
 float	fPos[3];			// Position of our camera
 float	fViewMat[3][3];
 UInt32		dwFoo2[2];
 float	fFov;
 } CameraInfo;
 */
/*
 - (void)moveMouse: (Position*)gP {
 
 CameraInfo camera;
 // Lets get the camera info!
 UInt32 cAddress1, cAddress2;
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (CAMERA_PTR) Buffer: (Byte*)&cAddress1 BufLength: sizeof(cAddress1)] && cAddress1) {
 
 // We now have the address that is at CAMERA_PTR, lets add 0x782C to it and jump again!
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress1 + CAMERA_OFFSET) Buffer: (Byte*)&cAddress2 BufLength: sizeof(cAddress2)] && cAddress2) {
 
 // Now we can get the camera info! w00t!
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress2) Buffer:(Byte*)&camera BufLength: sizeof(camera)]) {
 PGLog(@"[Fishing] Camera data loaded from 0x%X", cAddress2 );
 }
 }
 }
 
 
 float ax = -[gP xPosition];
 float ay = -[gP zPosition];
 float az = [gP yPosition];
 
 PGLog(@"Game position: { %.2f, %.2f, %.2f } (%@)", ax, ay, az, gP);
 
 float cx = -camera.fPos[0];
 float cy = -camera.fPos[2];
 float cz = camera.fPos[1];
 
 PGLog(@"Camera position: { %.2f, %.2f, %.2f }", cx, cy, cz);
 
 float facing = camera.fViewMat[1][1];
 if(facing > M_PI) facing -= 2*M_PI;
 PGLog(@"Facing: %.2f (%.2f), tilt = %.2f", facing, camera.fViewMat[1][1], camera.fViewMat[1][0]);
 
 float ox = camera.fViewMat[1][0];
 float oy = -facing;
 float oz = 0;
 
 PGLog(@"Camera direction: { %.2f, %.2f, %.2f }", ox, oy, oz);
 
 
 float dx = cosf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx)) - sinf(oy) * (az - cz);
 float dy = sinf(ox) * ( cosf(oy) * (az - cz) + sinf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx))) + cosf(ox) * ( cosf(oz) * (ay - cy) - sinf(oz) * (ax - cx) );
 float dz = cosf(ox) * ( cosf(oy) * (az - cz) + sinf(oy) * ( sinf(oz) * (ay - cy) + cosf(oz) * (ax - cx))) - sinf(ox) * ( cosf(oz) * (ay - cy) - sinf(oz) * (ax - cx) );
 
 PGLog(@"Calcu position: { %.2f, %.2f, %.2f }", dx, dy, dz);
 
 float bx = (dx - cx) * (cz/dz);
 float by = (dy - cy) * (cz/dz);
 
 PGLog(@"Projected 2d position: { %.2f, %.2f }", bx, by);
 
 if(dz <= 0) {
 PGLog(@"behind the camera1");
 //return CGPointMake(-1, -1);
 }
 
 CGRect wowSize = [controller wowWindowRect];
 CGPoint wowCenter = CGPointMake( wowSize.origin.x+wowSize.size.width/2.0f, wowSize.origin.y+wowSize.size.height/2.0f);
 
 PGLog(@"WowWindowSize: %@", NSStringFromRect(NSRectFromCGRect(wowSize)));
 PGLog(@"WoW Center: %@", NSStringFromPoint(NSPointFromCGPoint(wowCenter)));
 
 float FOV1 = 0.1;
 float FOV2 = 3  * wowSize.size.width;
 int sx = dx * (FOV1 / (dz + FOV1)) * FOV2 + wowCenter.x;
 int sy = dy * (FOV1 / (dz + FOV1)) * FOV2 + wowCenter.y;
 
 // ensure on screen
 if(sx < wowSize.origin.x || sy < wowSize.origin.y || sx >= wowSize.origin.x+wowSize.size.width || sy >= wowSize.origin.y+wowSize.size.height) {
 PGLog(@"behind the camera2");
 //return CGPointMake(-1, -1);
 }	
 
 PGLog(@"Clicking { %.2f, %.2f }", sx, sy);
 
 }
 */

/*
 - (BOOL)moveMouseToWoWCoordsWithX: (float)x Y:(float)y Z:(float)z{
 
 
 // Lets get the camera info!
 UInt32 cAddress1, cAddress2;
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (CAMERA_PTR) Buffer: (Byte*)&cAddress1 BufLength: sizeof(cAddress1)] && cAddress1) {
 
 // We now have the address that is at CAMERA_PTR, lets add 0x782C to it and jump again!
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress1 + CAMERA_OFFSET) Buffer: (Byte*)&cAddress2 BufLength: sizeof(cAddress2)] && cAddress2) {
 
 // Now we can get the camera info! w00t!
 CameraInfo camera;
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress2) Buffer:(Byte*)&camera BufLength: sizeof(camera)]) {
 
 int i,f;
 for(i=0;i<3;i++){
 PGLog(@"[Fishing] fPos[%d]=%f", i, camera.fPos[i]);
 }
 for(i=0;i<3;i++){
 for(f=0;f<3;f++){
 PGLog(@"[Fishing] fViewMat[%d][%d]=%f", i, f, camera.fViewMat[i][f]);
 }
 }
 PGLog(@"[Fishing] fFov: %f", camera.fFov);
 
 PGLog(@"[Fishing] Camera data loaded from 0x%X", cAddress2 );
 
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
 PGLog(@"[Fishing] fProd < 0  %f", fProd);
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
 
 CGRect windowRect = [controller wowWindowRect];
 // Get our rect!
 float    fScreenX = (windowRect.size.width - windowRect.origin.x)/2.0f;
 float    fScreenY = (windowRect.size.height - windowRect.origin.y)/2.0f;
 
 //PGLog(@"[Fishing] WoW Window Coords: <%f,%f>", windowRect.size.width, windowRect.size.height);
 
 // Thanks pat0! Aspect ratio fix
 float    fTmpX    = fScreenX/tan(((camera.fFov*44.0f)/2.0f)*M_DEG2RAD);
 float    fTmpY    = fScreenY/tan(((camera.fFov*35.0f)/2.0f)*M_DEG2RAD);
 
 PGLog(@"Tmp: <%f,%f>   fScreen <%f,%f>", fTmpX, fTmpY, fScreenX, fScreenY);
 
 
 NSPoint pctMouse;
 pctMouse.x = fScreenX + fCam[0]*fTmpX/fCam[2];
 pctMouse.y = fScreenY + fCam[1]*fTmpY/fCam[2];
 
 PGLog(@"[Fishing] Clicking X:%f  Y:%f", pctMouse.x, pctMouse.y);
 
 if( pctMouse.x < 0 || pctMouse.y < 0 || pctMouse.x > windowRect.size.width || pctMouse.y > windowRect.size.height ){
 return NO;
 }
 
 PGLog(@"[Fishing] Window: <%f,%f>", windowRect.origin.x, windowRect.origin.y);
 
 
 int minX = (windowRect.size.width*0.375f), maxX = windowRect.size.width - minX;
 int minY = (windowRect.size.height*0.375f), maxY = windowRect.size.height - minY;
 
 NSPoint screenPt = NSZeroPoint; 
 screenPt.x += windowRect.origin.x;
 screenPt.y += ([[NSScreen mainScreen] frame].size.height - (windowRect.origin.y + windowRect.size.height));
 
 PGLog(@"X:%f, Y:%F", screenPt.x, screenPt.y);
 PGLog(@"minX:%f, minY:%F", minX, minY);
 
 NSPoint screenPt = pctMouse; 
 screenPt.x += windowRect.origin.x;
 screenPt.y += ([[overlayWindow screen] frame].size.height - (windowRect.origin.y + windowRect.size.height));
 //NSLog(@"Found pt in Q1 screen space: %@", NSStringFromPoint(screenPt));
 // now we have screen point in Q1 space
 
 PGLog(@"[Fishing] Drawing <%f, %f>", screenPt.x, screenPt.y);
 
 PGLog(@"[Fishing] %f %f %f %f", windowRect.origin.x, [[overlayWindow screen] frame].size.height, windowRect.origin.y, windowRect.size.height);
 
 // create new window bounds
 NSRect newRect = NSZeroRect;
 newRect.origin = screenPt;
 newRect = NSInsetRect(newRect, (15+20)*-1.0, (15+20)*-1.0);
 
 // create new window bounds
 //NSRect newRect = NSMakeRect(minX+windowRect.origin.x, [[NSScreen mainScreen] frame].size.height - (maxY+windowRect.origin.y), 10, 10);
 [overlayWindow setFrame: newRect display: YES];
 [overlayWindow makeKeyAndOrderFront: nil];	
 
 //if( !::SetCursorPos(pctMouse.x,pctMouse.y) )
 //	return NO;
 
 // New way to click?  http://stackoverflow.com/questions/726952/simulate-mouse-click-to-window-instead-of-screen
 
 
 ProcessSerialNumber psn = [controller getWoWProcessSerialNumber];
 CGEventRef CGEvent;
 NSEvent *customEvent;
 
 
 customEvent = [NSEvent mouseEventWithType: [event type]
 location: [event locationInWindow]
 modifierFlags: [event modifierFlags] | NSCommandKeyMask
 timestamp: [event timestamp]
 windowNumber: WID
 context: nil
 eventNumber: 0
 clickCount: 1
 pressure: 0];
 
 CGEvent = [customEvent CGEvent];
 
 //NSAssert(GetProcessForPID(PID, &psn) == noErr, @"GetProcessForPID failed!");
 
 CGEventPostToPSN(&psn, CGEvent);
 }
 }
 }
 
 return YES;
 }*/

/*
 // From http://www.gamedev.net/community/forums/topic.asp?topic_id=529305
 - (void)moveMouse: (Position*)gP {
 CGRect windowRect = [controller wowWindowRect];
 
 CameraInfo camera;
 // Lets get the camera info!
 UInt32 cAddress1, cAddress2;
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (CAMERA_PTR) Buffer: (Byte*)&cAddress1 BufLength: sizeof(cAddress1)] && cAddress1) {
 
 // We now have the address that is at CAMERA_PTR, lets add 0x782C to it and jump again!
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress1 + CAMERA_OFFSET) Buffer: (Byte*)&cAddress2 BufLength: sizeof(cAddress2)] && cAddress2) {
 
 // Now we can get the camera info! w00t!
 if([[controller wowMemoryAccess] loadDataForObject: self atAddress: (cAddress2) Buffer:(Byte*)&camera BufLength: sizeof(camera)]) {
 PGLog(@"[Fishing] Camera data loaded from 0x%X", cAddress2 );
 }
 }
 }
 
 Position *camPosition = [[Position alloc] initWithX:camera.fPos[0] Y:camera.fPos[1] Z:camera.fPos[2]];
 Position *vecViewMatrix0 = [[Position alloc] initWithX:camera.fViewMat[0][0] Y:camera.fViewMat[0][1] Z:camera.fViewMat[0][2]];
 Position *vecViewMatrix1 = [[Position alloc] initWithX:camera.fViewMat[1][0] Y:camera.fViewMat[1][1] Z:camera.fViewMat[1][2]];
 Position *vecViewMatrix2 = [[Position alloc] initWithX:camera.fViewMat[2][0] Y:camera.fViewMat[2][1] Z:camera.fViewMat[2][2]];
 //NSArray *vecViewMatrix = [[NSArray alloc] initWithObjects:vecViewMatrix0, vecViewMatrix1, vecViewMatrix2, nil];
 
 Position *difference = [gP difference: camPosition];
 
 if ( [difference dotProduct:vecViewMatrix0] < 0.0f ){
 return;
 }
 
 PGLog(@"[Fishing] Difference: %@", difference);
 
 // Get the inverse!
 float inv[3][3];
 int i,j;
 for( i = 0; i < 3; i++ ) {
 for( j = 0; j < 3; j++ ) {
 inv[ i ][ j ] = camera.fViewMat[ j ][ i ];
 }
 }
 
 float View[3];
 View[0] = [difference xPosition] * camera.fViewMat[0][0] + [difference yPosition]*camera.fViewMat[1][0] + [difference zPosition]*camera.fViewMat[2][0];
 View[1] = [difference xPosition] * camera.fViewMat[0][1] + [difference yPosition]*camera.fViewMat[1][1] + [difference zPosition]*camera.fViewMat[2][1];
 View[2] = [difference xPosition] * camera.fViewMat[0][2] + [difference yPosition]*camera.fViewMat[1][2] + [difference zPosition]*camera.fViewMat[2][2];
 
 PGLog(@"[Fishing] View: { %0.2f, %0.2f, %0.2f }", View[0], View[1], View[2] );
 
 float Camera[3];
 Camera[0] = -View[1];
 Camera[1] = -View[2];
 Camera[2] = View[0];
 
 PGLog(@"[Fishing] Camera: { %0.2f, %0.2f, %0.2f }", Camera[0], Camera[1], Camera[2] );
 
 if ( Camera[2] > 0 ){
 float    ScreenX    = windowRect.size.width / 2.0f;
 float    ScreenY    = windowRect.size.height / 2.0f;
 
 // Thanks pat0! Aspect ratio fix
 
 float    TmpX    = ScreenX / tanf ( ( (camera.fFov * 44.0f) / 2.0f ) * M_DEG2RAD );
 float    TmpY    = ScreenY / tanf ( ( (camera.fFov * 35.0f) / 2.0f ) * M_DEG2RAD );
 
 float final_x    = ( Camera[0] * TmpX / Camera[2] ) + ScreenX;
 float final_y    = ( Camera[1] * TmpY / Camera[2] ) + ScreenY;	
 
 PGLog(@"[Fishing] { %0.2f, %0.2f }", final_x, final_y);
 
 CGPoint point = CGPointMake(final_x, final_y);
 
 [self drawWithPt:point];
 }
 
 
 [camPosition release];
 [difference release];
 [vecViewMatrix0 release];
 [vecViewMatrix1 release];
 [vecViewMatrix2 release];
 }*/
@end
