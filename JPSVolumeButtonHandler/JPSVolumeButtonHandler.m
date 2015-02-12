//
//  JPSVolumeButtonHandler.m
//  JPSImagePickerController
//
//  Created by JP Simard on 1/31/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

#import "JPSVolumeButtonHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static NSString *const sessionVolumeKeyPath = @"outputVolume";
static void *sessionContext                 = &sessionContext;
static CGFloat maxVolume                    = 0.99999f;
static CGFloat minVolume                    = 0.00001f;

@interface JPSVolumeButtonHandler ()

@property (nonatomic, assign) CGFloat          initialVolume;
@property (nonatomic, strong) AVAudioSession * session;
@property (nonatomic, strong) MPVolumeView   * volumeView;

@end

@implementation JPSVolumeButtonHandler

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        [self setupSession];
        [self disableVolumeHUD];
        
        // Wait for the volume view to be ready before setting the volume to avoid showing the HUD
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self setInitialVolume];
        });
    }
    return self;
}

- (void)dealloc {
    [self.session removeObserver:self forKeyPath:sessionVolumeKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.volumeView removeFromSuperview];
}

- (void)setupSession {
    NSError *error = nil;
    self.session = [AVAudioSession sharedInstance];
    [self.session setCategory:AVAudioSessionCategoryAmbient withOptions:0 error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    [self.session setActive:YES error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }

    // Observe outputVolume
    [self.session addObserver:self
                   forKeyPath:sessionVolumeKeyPath
                      options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                      context:sessionContext];
    
    // Audio session is interrupted when you send the app to the background,
    // and needs to be set to active again when it goes to app goes back to the foreground
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

- (void)audioSessionInterrupted:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    switch (interuptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            // NSLog(@"Audio Session Interruption case started.");
            break;
        case AVAudioSessionInterruptionTypeEnded:
        {
            // NSLog(@"Audio Session Interruption case ended.");
            NSError *error = nil;
            [self.session setActive:YES error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
            break;
        }
        default:
            // NSLog(@"Audio Session Interruption Notification case default.");
            break;
    }
}

- (void)disableVolumeHUD {
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0)];
    [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self.volumeView];
}

    
- (void)setInitialVolume {
    self.initialVolume = self.session.outputVolume;
    if (self.initialVolume > maxVolume) {
        self.initialVolume = maxVolume;
        [self setSystemVolume:self.initialVolume];
    } else if (self.initialVolume < minVolume) {
        self.initialVolume = minVolume;
        [self setSystemVolume:self.initialVolume];
    }
}

#pragma mark - Convenience

+ (instancetype)volumeButtonHandlerWithUpBlock:(JPSVolumeButtonBlock)upBlock downBlock:(JPSVolumeButtonBlock)downBlock {
    JPSVolumeButtonHandler *instance = [[JPSVolumeButtonHandler alloc] init];
    if (instance) {
        instance.upBlock = upBlock;
        instance.downBlock = downBlock;
    }
    return instance;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == sessionContext) {
        CGFloat newVolume = [change[NSKeyValueChangeNewKey] floatValue];
        CGFloat oldVolume = [change[NSKeyValueChangeOldKey] floatValue];
        
        if (newVolume == self.initialVolume) {
            // Resetting volume, skip blocks
            return;
        }
        
        if (newVolume > oldVolume) {
            if (self.upBlock) self.upBlock();
        } else {
            if (self.downBlock) self.downBlock();
        }
        
        // Reset volume
        [self setSystemVolume:self.initialVolume];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - System Volume

- (void)setSystemVolume:(CGFloat)volume {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:(float)volume];
#pragma clang diagnostic pop
}

@end
