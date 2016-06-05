//
//  JPSVolumeButtonHandler.h
//  JPSImagePickerController
//
//  Created by JP Simard on 1/31/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JPSVolumeButtonBlock)();

@interface JPSVolumeButtonHandler : NSObject

// A block to run when the volume up button is pressed
@property (nonatomic, copy) JPSVolumeButtonBlock upBlock;

// A block to run when the volume down button is pressed
@property (nonatomic, copy) JPSVolumeButtonBlock downBlock;

// A block to run when the volume mute button is pressed
@property (nonatomic, copy) JPSVolumeButtonBlock muteBlock;

// Returns a button handler with the specified up/down volume button blocks
+ (instancetype)volumeButtonHandlerWithUpBlock:(JPSVolumeButtonBlock)upBlock downBlock:(JPSVolumeButtonBlock)downBlock;

// Returns a button handler with the specified volume up/down/mute blocks
// volume mute handling is intended to work with a media remote, and may not function correctly with hardware mute
+ (instancetype)volumeButtonHandlerWithUpBlock:(JPSVolumeButtonBlock)upBlock
                                     downBlock:(JPSVolumeButtonBlock)downBlock
                                     muteBlock:(JPSVolumeButtonBlock)muteBlock;

@end
