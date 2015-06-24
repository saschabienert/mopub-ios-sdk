//
//  SKVASTViewController.h
//  VAST
//
//  Created by Thomas Poland on 9/30/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

// VASTViewController is the main component of the SourceKit VAST Implementation.
//
// This class creates and manages an iOS MPMediaPlayerViewController to playback a video from a VAST 2.0 document.
// The document may be loaded using a URL or directly from an exisitng XML document (as NSData).
//
// See the VASTViewControllerDelegate Protocol for the required vastReady: and other useful methods.
// Screen controls are exposed for play, pause, info, and dismiss, which are handled by the VASTControls class as an overlay toolbar.
//
// VASTEventProcessor handles tracking events and impressions.
// Errors encountered are listed in in VASTError.h
//
// Please note:  Only one video may be played at a time, you must wait for the vastReady: callback before sending the 'play' message.

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HZSKVASTError.h"

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

@property (nonatomic, unsafe_unretained) id<HZSKVASTViewControllerDelegate>delegate;
@property (nonatomic, strong) NSURL *clickThrough;

- (id)initWithDelegate:(id<HZSKVASTViewControllerDelegate>)delegate withViewController:(UIViewController *)viewController;  // designated initializer for VASTViewController

- (void)loadVideoWithURL:(NSURL *)url;            // load and prepare to play a VAST video from a URL
- (void)loadVideoWithData:(NSData *)xmlContent;   // load and prepare to play a VAST video from existing XML data

- (void)play;// command to play the video, this is only valid after receiving the vastReady: callback (which will be called after a loadVideo...: call)

@end
