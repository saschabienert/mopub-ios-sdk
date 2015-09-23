//
//  HZSKVASTViewController.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/24/15.
//  Heavily modified from original SKVASTViewController.m (see below comments for original info).
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

//
//  SKVASTViewController.m
//  VAST
//
//  Created by Thomas Poland on 9/30/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "HZSKVASTViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HZVASTSettings.h"
#import "HZSKLogger.h"
#import "HZSKVAST2Parser.h"
#import "HZSKVASTEventProcessor.h"
#import "HZSKVASTUrlWithId.h"
#import "HZSKVASTMediaFile.h"
#import "HZSKVASTMediaFilePicker.h"

#import "HZVideoView.h"
#import "HZDevice.h"
#import "HZVASTVideoCache.h"

static const NSString* kPlaybackFinishedUserInfoErrorKey=@"error";

typedef enum {
    VASTFirstQuartile,
    VASTSecondQuartile,
    VASTThirdQuartile,
    VASTFourtQuartile,
} CurrentVASTQuartile;

@interface HZSKVASTViewController() <HZAdPopupActionDelegate>
{
    NSURL *mediaFileURL;
    NSArray *clickTracking;
    NSArray *vastErrors;
    NSArray *impressions;
    NSTimer *playbackTimer;
    NSTimeInterval movieDuration;
    NSTimeInterval playedSeconds;
    
    float currentPlayedPercentage;
    BOOL isPlaying;
    BOOL isViewOnScreen;
    BOOL hasPlayerStarted;
    BOOL isLoadCalled;
    BOOL vastReady;
    BOOL statusBarHiddenOutsideOfVAST;
    BOOL hasReportedEngagedView;
    CurrentVASTQuartile currentQuartile;
}

@property (nonatomic, weak) id<HZSKVASTViewControllerDelegate>delegate;

@property(nonatomic, strong) HZSKVASTEventProcessor *eventProcessor;

@property (nonatomic) BOOL didFinishSuccessfully;
@property(nonatomic, strong) HZVideoView *videoView;
@property(nonatomic, strong) HZVASTVideoSettings *videoSettings;
@property(nonatomic, strong) HZVASTVideoCache *videoCache;

@end

@implementation HZSKVASTViewController

#pragma mark - Init & dealloc

// designated initializer
- (instancetype)initWithDelegate:(id<HZSKVASTViewControllerDelegate>)delegate forCreativeType:(HZCreativeType)creativeType
{
    self = [super init];
    if (self) {
        _creativeType = creativeType;
        _delegate = delegate;
        currentQuartile=VASTFirstQuartile;
        hasReportedEngagedView = NO;
        _didFinishSuccessfully = false;
        
        _videoView = [[HZVideoView alloc] initWithFrame:CGRectZero];
        _videoView.actionDelegate = self;
        _videoView.player.shouldAutoplay = NO;
    }
    return self;
}

#pragma mark - Load methods

- (void)loadVideoWithURL:(NSURL *)url
{
    [self loadVideoUsingSource:url];
}

- (void)loadVideoWithData:(NSData *)xmlContent
{
    [self loadVideoUsingSource:xmlContent];
}

- (void)loadVideoUsingSource:(id)source
{
    if ([source isKindOfClass:[NSURL class]])
    {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Starting loadVideoWithURL"];
    } else {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Starting loadVideoWithData"];
    }
    
    if (isLoadCalled) {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Ignoring loadVideo because a load is in progress."];
        return;
    }
    isLoadCalled = YES;

    void (^parserCompletionBlock)(HZSKVASTModel *vastModel, HZSKVASTError vastError) = ^(HZSKVASTModel *vastModel, HZSKVASTError vastError) {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"back from block in loadVideoFromData"];
        
        if (!vastModel) {
            [HZSKLogger error:@"VAST - View Controller" withMessage:@"parser error"];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {  // The VAST document was not readable, so no Error urls exist, thus none are sent.
                [self.delegate vastError:self error:vastError];
            }
            return;
        }
        
        self.eventProcessor = [[HZSKVASTEventProcessor alloc] initWithTrackingEvents:[vastModel trackingEvents] withDelegate:self->_delegate];
        self->impressions = [vastModel impressions];
        self->vastErrors = [vastModel errors];
        self.clickThrough = [[vastModel clickThrough] url];
        self->clickTracking = [vastModel clickTracking];
        self->mediaFileURL = [HZSKVASTMediaFilePicker pick:[vastModel mediaFiles]].url;
        
        self.videoSettings = [[HZVASTVideoSettings alloc] initForCreativeType:self.creativeType vastModel:vastModel];
        self.videoView.skipButtonEnabled = self.videoSettings.allowSkip;
        self.videoView.hideButtonEnabled = self.videoSettings.allowHide;
        self.videoView.timerLabelEnabled = self.videoSettings.allowTimer;
        self.videoView.installButtonEnabled = self.videoSettings.allowInstallButton;
        [self.videoView shouldUseClickableVideoConfiguration];
        
        [self.videoView setSkipButtonTimeInterval: [self.videoSettings.skipOffsetSeconds doubleValue]];
        
        if(!self->mediaFileURL) {
            [HZSKLogger error:@"VAST - View Controller" withMessage:@"Error - VASTMediaFilePicker did not find a compatible mediaFile - VASTViewcontroller will not be presented"];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoCompatibleMediaFile];
            }
            if (self->vastErrors) {
                [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [self.eventProcessor sendVASTUrlsWithId:self->vastErrors];
            }
            return;
        }
        
        //setting the url here causes prepareToPlay to be called. doing this before the frame of the player is set causes some autolayout warnings
        //instead, it's called in showAndPlayVideo
        //[self.videoView setVideoURL:self->mediaFileURL];
        self.videoCache = [[HZVASTVideoCache alloc] init];
        [self.videoCache startCaching:self->mediaFileURL withCompletion:^(BOOL success){
            if(success) {
                // VAST document parsing OK & video cached, so send vastReady
                [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending vastReady: callback"];
                self->vastReady = YES;
                [self.delegate vastReady:self];
            } else {
                [HZSKLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"video cache error"]];
                if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                    [self.delegate vastError:self error:VASTErrorCacheFailed];
                }
                if (self->vastErrors) {
                    [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                    [self.eventProcessor sendVASTUrlsWithId:self->vastErrors];
                }
            }
        }];
    };
    
    HZSKVAST2Parser *parser = [[HZSKVAST2Parser alloc] init];
    if ([source isKindOfClass:[NSURL class]]) {
        [parser parseWithUrl:(NSURL *)source completion:parserCompletionBlock];     // Load the and parse the VAST document at the supplied URL
    } else {
        [parser parseWithData:(NSData *)source completion:parserCompletionBlock];   // Parse a VAST document in supplied data
    }
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    isViewOnScreen=YES;

    [self handleResumeState];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    statusBarHiddenOutsideOfVAST = [[UIApplication sharedApplication] isStatusBarHidden];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:statusBarHiddenOutsideOfVAST withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - App lifecycle

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [HZSKLogger debug:@"VAST - View Controller" withMessage:@"applicationDidBecomeActive"];
    [self handleResumeState];
}

#pragma mark - Orientation handling

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    if ([self applicationSupportsLandscape]) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[UIApplication sharedApplication].keyWindow];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Timers

// playbackTimer - keeps track of currentPlayedPercentage
- (void)startPlaybackTimer
{
    @synchronized (self) {
        [self stopPlaybackTimer];
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"start playback timer"];
        playbackTimer = [NSTimer scheduledTimerWithTimeInterval:kHZPlayTimeCounterInterval
                                                         target:self
                                                       selector:@selector(updatePlayedSeconds)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)stopPlaybackTimer
{
    [HZSKLogger debug:@"VAST - View Controller" withMessage:@"stop playback timer"];
    [playbackTimer invalidate];
    playbackTimer = nil;
}

- (void)updatePlayedSeconds
{
    @try {
        playedSeconds = self.videoView.player.currentPlaybackTime;
    }
    @catch (NSException *e) {
        [HZSKLogger warning:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - updatePlayedSeconds: %@", e]];
        playedSeconds = 0;
    }

    NSTimeInterval duration = self.videoView.player.duration;
    if(duration <= 0){
        [HZSKLogger warning:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Duration is not >0"]];
        return;
    }
    
    //engaged view is defined as at least 30 seconds watched or completed, whichever comes first (completed is handled later)
    if(!hasReportedEngagedView && playedSeconds >= 30) {
        hasReportedEngagedView = YES;
        [self.eventProcessor trackEvent:VASTEventTrackEngagedView];
    }
    
   	currentPlayedPercentage = (float)100.0*(playedSeconds/self.videoView.player.duration);
    
    switch (currentQuartile) {
        case VASTFirstQuartile:
            if (currentPlayedPercentage>25.0) {
                [self.eventProcessor trackEvent:VASTEventTrackFirstQuartile];
                currentQuartile=VASTSecondQuartile;
            }
            break;
        case VASTSecondQuartile:
            if (currentPlayedPercentage>50.0) {
                [self.eventProcessor trackEvent:VASTEventTrackMidpoint];
                currentQuartile=VASTThirdQuartile;
            }
            break;
        case VASTThirdQuartile:
            if (currentPlayedPercentage>75.0) {
                [self.eventProcessor trackEvent:VASTEventTrackThirdQuartile];
                currentQuartile=VASTFourtQuartile;
            }
            break;
        default:
            break;
    }
}

- (void)killTimers
{
    [self stopPlaybackTimer];
}

#pragma mark - Methods needed to support toolbar buttons

- (void)play
{
    @synchronized (self) {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"playVideo"];
        
        if (!vastReady) {
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlayerNotReady];                  // This is not a VAST player error, so no external Error event is sent.
                [HZSKLogger warning:@"VAST - View Controller" withMessage:@"Ignoring call to playVideo before the player has sent vastReady."];
                return;
            }
        }
        
        if (isViewOnScreen) {
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlaybackAlreadyInProgress];       // This is not a VAST player error, so no external Error event is sent.
                [HZSKLogger warning:@"VAST - View Controller" withMessage:@"Ignoring call to playVideo while playback is already in progress"];
                return;
            }
        }
        
        // Now we are ready to launch the player and start buffering the content
        // It will throw error if the url is invalid for any reason. In this case, we don't even need to open ViewController.
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"initializing player"];
        
        @try {
            playedSeconds = 0.0;
            currentPlayedPercentage = 0.0;
            
            [self startPlaybackTimer];
            [self presentPlayer];
        }
        @catch (NSException *e) {
            [HZSKLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - moviePlayer.prepareToPlay: %@", e]];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlaybackError];
            }
            if (vastErrors) {
                [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [self.eventProcessor sendVASTUrlsWithId:vastErrors];
            }
            return;
        }
    }
}

- (void)close
{
    @synchronized (self) {
        [self killTimers];
        [self.videoView removeFromSuperview];
        self.videoView = nil;
        
        if(hasPlayerStarted && !self.didFinishSuccessfully) {
            [self.eventProcessor trackEvent:VASTEventTrackSkip];
        }
        
        if (isViewOnScreen) {
            // send close any time the player has been dismissed
            [self.eventProcessor trackEvent:VASTEventTrackClose];
            [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Dismissing VASTViewController"];
            [self dismissViewControllerAnimated:NO completion:nil];
            
            if ([self.delegate respondsToSelector:@selector(vastDidDismissFullScreen:)]) {
                [self.delegate vastDidDismissFullScreen:self];
            }
        }
    }
}

#pragma mark - Other methods

- (BOOL)isPlaying
{
    return isPlaying;
}

-(BOOL)vastVideoCached {
    return self.videoCache && self.videoCache.fileCached;
}

- (void)showAndPlayVideo
{
    [HZSKLogger debug:@"VAST - View Controller" withMessage:@"adding player to on screen view and starting play sequence"];
    
    self.videoView.frame=self.view.bounds;
    [self.view addSubview:self.videoView];
    [self.videoView setVideoURL:[self.videoCache URLForVideo]];
    [self.videoView.player setInitialPlaybackTime:0];
    [self.videoView play];
    
    hasPlayerStarted=YES;
    
    if (impressions) {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending Impressions requests"];
        [self.eventProcessor sendVASTUrlsWithId:impressions];
    }
    [self.eventProcessor trackEvent:VASTEventTrackStart];
}

// not used right now, but could be in the future if there's a reason to pause
- (void)handlePauseState
{
    @synchronized (self) {
        if (isPlaying) {
            [HZSKLogger debug:@"VAST - View Controller" withMessage:@"handle pausing player"];
            [self.videoView pause];
            isPlaying = NO;
            [self.eventProcessor trackEvent:VASTEventTrackPause];
        }
        [self stopPlaybackTimer];
    }
}

- (void)handleResumeState
{
    @synchronized (self) {
        if (hasPlayerStarted) {
            [HZSKLogger debug:@"VAST - View Controller" withMessage:@"handleResumeState, resuming player"];
            [self.videoView play];
            isPlaying = YES;
            [self.eventProcessor trackEvent:VASTEventTrackResume];
            [self startPlaybackTimer];
        } else {
            [self showAndPlayVideo]; // resume is called when the view loads the first time.
        }
    }
}

- (void)presentPlayer
{
    if ([self.delegate respondsToSelector:@selector(vastWillPresentFullScreen:)]) {
        [self.delegate vastWillPresentFullScreen:self];
    }
    
    [self.rootViewController presentViewController:self animated:NO completion:nil];
}


#pragma mark - HZAdPopupActionDelegate methods

- (void) onActionHide: (id) sender {
    [self close];
}

- (void) onActionShow: (id) sender { }

- (void) onActionReady: (id) sender { }

- (void) onActionClick: (id) sender withURL: (NSURL *) url {
    if(self.videoSettings.allowClick) {
        if (clickTracking) {
            [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending clickTracking requests"];
            [self.eventProcessor sendVASTUrlsWithId:clickTracking];
        }
        if ([self.delegate respondsToSelector:@selector(vastOpenBrowseWithUrl:)]) {
            [self.delegate vastOpenBrowseWithUrl:self.clickThrough];
        }
    }
}

- (void) onActionCompleted: (id) sender {
    [self.eventProcessor trackEvent:VASTEventTrackComplete];
    self.didFinishSuccessfully = YES;
    
    //engaged view is defined as at least 30 seconds watched or completed, whichever comes first
    if(!hasReportedEngagedView) {
        hasReportedEngagedView = YES;
        [self.eventProcessor trackEvent:VASTEventTrackEngagedView];
    }
    
    [self updatePlayedSeconds];
    [self close];
}

- (void) onActionError: (id) sender {
    [HZSKLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"playback error"]];
    if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
        [self.delegate vastError:self error:VASTErrorPlaybackError];
    }
    if (vastErrors) {
        [HZSKLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
        [self.eventProcessor sendVASTUrlsWithId:vastErrors];
    }
    
    [self close];
}

- (void) onActionRestart: (id) sender { }

- (void) onActionInstallHeyzap: (id) sender { }

#pragma mark - Utility

- (BOOL) applicationSupportsLandscape {
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        return YES;
    } else {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: keyWindow] & UIInterfaceOrientationMaskLandscape;
    }
}

@end

@implementation HZVASTVideoSettings

- (instancetype) initForCreativeType:(HZCreativeType)creativeType vastModel:(HZSKVASTModel *)vastModel {
    self = [super init];
    if(self) {
        // defaults
        _allowClick = YES;
        _allowHide = NO;
        _allowSkip = YES;
        _allowTimer = YES;
        _allowInstallButton = NO;
        
        _skipOffsetSeconds = [vastModel skipOffsetSeconds];
        if(!_skipOffsetSeconds) {
            [HZSKLogger error:@"VAST - View Controller" withMessage:@"skipOffsetSeconds could not be parsed."];
        } else {
            [HZSKLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"skipOffsetSeconds read as: %@", _skipOffsetSeconds]];
        }
        
        if(creativeType == HZCreativeTypeIncentivized) {
            _allowSkip = NO;
            _allowHide = NO;
            _skipOffsetSeconds = @0;
        } else if(creativeType == HZCreativeTypeVideo) {
            _allowSkip = YES;
            _allowHide = NO;
            if(!_skipOffsetSeconds || [_skipOffsetSeconds doubleValue] < 0){
                _skipOffsetSeconds = @0;
            }
        }
    }
    
    return self;
}

@end
