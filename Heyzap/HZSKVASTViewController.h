//
//  HZSKVASTViewController.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/24/15.
//  Heavily modified from original SKVASTViewController.h (see below comments for original info).
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

//
//  SKVASTViewController.h
//  VAST
//
//  Created by Thomas Poland on 9/30/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

// VASTViewController is the main component of the SourceKit VAST Implementation.
//
// VASTEventProcessor handles tracking events and impressions.
// Errors encountered are listed in in VASTError.h
//
// Please note:  Only one video may be played at a time, you must wait for the vastReady: callback before sending the 'play' message.

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HZSKVASTError.h"
#import "HZCreativeType.h"
#import "HZSKVASTModel.h"
#import "HZLabeledActivityIndicator.h"

@class HZSKVASTViewController;

@protocol HZSKVASTViewControllerDelegate <NSObject>
@required
- (void)vastReady:(HZSKVASTViewController *)vastVC;  // sent when the video is ready to play - required
@optional
- (void)vastError:(HZSKVASTViewController *)vastVC error:(HZSKVASTError)error;  // sent when any VASTError occurs - optional
// These optional callbacks are for basic presentation, dismissal, and calling video clickthrough url browser.
- (void)vastWillPresentFullScreen:(HZSKVASTViewController *)vastVC;
- (void)vastDidDismissFullScreen:(HZSKVASTViewController *)vastVC;
- (void)vastOpenBrowseWithUrl:(NSURL *)url;
- (void)vastTrackingEvent:(NSString *)eventName;
@end

@interface HZSKVASTViewController : UIViewController


@property (nonatomic, strong) NSURL *clickThrough;
@property (nonatomic) HZCreativeType creativeType;
@property (nonatomic, readonly) BOOL didFinishSuccessfully;

@property(nonatomic) UIViewController *rootViewController;

@property (nonatomic) HZLabeledActivityIndicator *activityIndicator;

- (instancetype)initWithDelegate:(id<HZSKVASTViewControllerDelegate>)delegate forCreativeType:(HZCreativeType)creativeType; // designated initializer for VASTViewController

- (void)loadVideoWithURL:(NSURL *)url;            // load and prepare to play a VAST video from a URL
- (void)loadVideoWithData:(NSData *)xmlContent;   // load and prepare to play a VAST video from existing XML data

- (void)play;// command to play the video, this is only valid after receiving the vastReady: callback (which will be called after a loadVideo...: call)
- (BOOL)vastVideoCached; // returns whether or not the video (sent to one of the loadVideoWith...: methods) has been cached yet

- (void)handlePauseState;
- (void)handleResumeState;

@end

@interface HZVASTVideoSettings : NSObject
@property (nonatomic) BOOL allowHide;
@property (nonatomic) BOOL allowClick;
@property (nonatomic) BOOL allowSkip;
@property (nonatomic) BOOL allowTimer;
@property (nonatomic) BOOL allowInstallButton;
@property (nonatomic) NSNumber *skipOffsetSeconds;
- (instancetype) initForCreativeType:(HZCreativeType)creativeType vastModel:(HZSKVASTModel *)vastModel;
@end
