//
//  JPSVolumeButtonHandler.h
//  JPSImagePickerController
//
//  Created by JP Simard on 1/31/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^JPSVolumeButtonBlock)(void);

@interface JPSVolumeButtonHandler : NSObject

// A block to run when the volume up button is pressed
@property (nonatomic, copy) JPSVolumeButtonBlock upBlock;

// A block to run when the volume down button is pressed
@property (nonatomic, copy) JPSVolumeButtonBlock downBlock;

// A shared audio session category
@property (nonatomic, strong) NSString * sessionCategory;

@property (nonatomic, assign) AVAudioSessionCategoryOptions sessionOptions;

- (void)startHandler:(BOOL)disableSystemVolumeHandler;
- (void)stopHandler;

// A Function to set exactJumpsOnly.  When set to YES, only volume jumps of .0625 call the code blocks.
// If it doesn't match, the code blocks are not called and setInitialVolume is called
- (void)useExactJumpsOnly:(BOOL)enabled;

// Returns a button handler with the specified up/down volume button blocks
+ (instancetype)volumeButtonHandlerWithUpBlock:(JPSVolumeButtonBlock)upBlock downBlock:(JPSVolumeButtonBlock)downBlock;

@end
