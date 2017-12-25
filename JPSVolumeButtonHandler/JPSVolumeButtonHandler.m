//
//  JPSVolumeButtonHandler.m
//  JPSImagePickerController
//
//  Created by JP Simard on 1/31/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

#import "JPSVolumeButtonHandler.h"
#import <MediaPlayer/MediaPlayer.h>

// Comment/uncomment out NSLog to enable/disable logging
#define JPSLog(fmt, ...) //NSLog(fmt, __VA_ARGS__)

static NSString *const sessionVolumeKeyPath = @"outputVolume";
static void *sessionContext                 = &sessionContext;
static CGFloat maxVolume                    = 0.99999f;
static CGFloat minVolume                    = 0.00001f;

@interface JPSVolumeButtonHandler ()

@property (nonatomic, assign) CGFloat          initialVolume;
@property (nonatomic, strong) AVAudioSession * session;
@property (nonatomic, strong) MPVolumeView   * volumeView;
@property (nonatomic, assign) BOOL             appIsActive;
@property (nonatomic, assign) BOOL             isStarted;
@property (nonatomic, assign) BOOL             disableSystemVolumeHandler;
@property (nonatomic, assign) BOOL             isAdjustingInitialVolume;
@property (nonatomic, assign) BOOL             exactJumpsOnly;

@end

@implementation JPSVolumeButtonHandler

#pragma mark - Init

- (id)init {
    self = [super init];
    
    if (self) {
        _appIsActive = YES;
        _sessionCategory = AVAudioSessionCategoryPlayback;
        _sessionOptions = AVAudioSessionCategoryOptionMixWithOthers;

        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0)];

        [[UIApplication sharedApplication].windows.firstObject addSubview:_volumeView];
        
        _volumeView.hidden = YES;

        _exactJumpsOnly = NO;
    }
    return self;
}

- (void)dealloc {
    [self stopHandler];
    
    MPVolumeView *volumeView = self.volumeView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [volumeView removeFromSuperview];
    });
}

- (void)startHandler:(BOOL)disableSystemVolumeHandler {
    [self setupSession];
    self.volumeView.hidden = NO; // Start visible to prevent changes made during setup from showing default volume
    self.disableSystemVolumeHandler = disableSystemVolumeHandler;

    // There is a delay between setting the volume view before the system actually disables the HUD
    [self performSelector:@selector(setupSession) withObject:nil afterDelay:1];
}

- (void)stopHandler {
    if (!self.isStarted) {
        // Prevent stop process when already stop
        return;
    }
    
    self.isStarted = NO;
    
    self.volumeView.hidden = YES;
    // https://github.com/jpsim/JPSVolumeButtonHandler/issues/11
    // http://nshipster.com/key-value-observing/#safe-unsubscribe-with-@try-/-@catch
    @try {
        [self.session removeObserver:self forKeyPath:sessionVolumeKeyPath];
    }
    @catch (NSException * __unused exception) {
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupSession {
    if (self.isStarted){
        // Prevent setup twice
        return;
    }
    
    self.isStarted = YES;

    NSError *error = nil;
    self.session = [AVAudioSession sharedInstance];
    // this must be done before calling setCategory or else the initial volume is reset
    [self setInitialVolume];
    [self.session setCategory:_sessionCategory
                  withOptions:_sessionOptions
                        error:&error];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    self.volumeView.hidden = !self.disableSystemVolumeHandler;
}

- (void) useExactJumpsOnly:(BOOL)enabled{
    _exactJumpsOnly = enabled;
}

- (void)audioSessionInterrupted:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    switch (interuptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            JPSLog(@"Audio Session Interruption case started.", nil);
            break;
        case AVAudioSessionInterruptionTypeEnded:
        {
            JPSLog(@"Audio Session Interruption case ended.", nil);
            NSError *error = nil;
            [self.session setActive:YES error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
            break;
        }
        default:
            JPSLog(@"Audio Session Interruption Notification case default.", nil);
            break;
    }
}

- (void)setInitialVolume {
    self.initialVolume = self.session.outputVolume;
    if (self.initialVolume > maxVolume) {
        self.initialVolume = maxVolume;
        self.isAdjustingInitialVolume = YES;
        [self setSystemVolume:self.initialVolume];
    } else if (self.initialVolume < minVolume) {
        self.initialVolume = minVolume;
        self.isAdjustingInitialVolume = YES;
        [self setSystemVolume:self.initialVolume];
    }
}

- (void)applicationDidChangeActive:(NSNotification *)notification {
    self.appIsActive = [notification.name isEqualToString:UIApplicationDidBecomeActiveNotification];
    if (self.appIsActive && self.isStarted) {
        [self setInitialVolume];
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
        if (!self.appIsActive) {
            // Probably control center, skip blocks
            return;
        }
        
        CGFloat newVolume = [change[NSKeyValueChangeNewKey] floatValue];
        CGFloat oldVolume = [change[NSKeyValueChangeOldKey] floatValue];

        if (self.disableSystemVolumeHandler && newVolume == self.initialVolume) {
            // Resetting volume, skip blocks
            return;
        } else if (self.isAdjustingInitialVolume) {
            if (newVolume == maxVolume || newVolume == minVolume) {
                // Sometimes when setting initial volume during setup the callback is triggered incorrectly
                return;
            }
            self.isAdjustingInitialVolume = NO;
        }

        CGFloat difference = fabs(newVolume-oldVolume);

        JPSLog(@"Old Vol:%f New Vol:%f Difference = %f", (double)oldVolume, (double)newVolume, (double) difference);

        if (_exactJumpsOnly && difference < .062 && (newVolume == 1. || newVolume == 0)) {
            JPSLog(@"Using a non-standard Jump of %f (%f-%f) which is less than the .0625 because a press of the volume button resulted in hitting min or max volume", difference, oldVolume, newVolume);
        } else if (_exactJumpsOnly && (difference > .063 || difference < .062)) {
            JPSLog(@"Ignoring non-standard Jump of %f (%f-%f), which is not the .0625 a press of the actually volume button would have resulted in.", difference, oldVolume, newVolume);
            [self setInitialVolume];
            return;
        }
        
        if (newVolume > oldVolume) {
            if (self.upBlock) self.upBlock();
        } else {
            if (self.downBlock) self.downBlock();
        }

        if (!self.disableSystemVolumeHandler) {
            // Don't reset volume if default handling is enabled
            return;
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
