//
//  HZVideoAdModel.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdModel.h"
#import "HZAFNetworking.h"
#import "HZVideoAdDisplayOptions.h"

@interface HZVideoAdModel : HZAdModel

// Interstitial
@property (nonatomic, readonly) NSString *HTMLContent;
@property (nonatomic, readonly) NSNumber *interstitialHeight;
@property (nonatomic, readonly) NSNumber *interstitialWidth;

// Video Meta
@property (nonatomic, readonly) NSNumber *videoWidth;
@property (nonatomic, readonly) NSNumber *videoHeight;
@property (nonatomic, readonly) NSNumber *videoDuration;
@property (nonatomic, readonly) NSNumber *videoSizeBytes;

// Video Sources
@property (nonatomic, readonly) NSMutableArray *staticURLs;
@property (nonatomic, readonly) NSMutableArray *streamingURLs;

// On-screen Video Behaviors
@property (nonatomic, readonly) HZVideoAdDisplayOptions *displayOptions;

// Download Ops
@property (nonatomic) BOOL fileCached;
@property (nonatomic) UIWebView *preloadWebview;

- (BOOL) onCompleteWithViewDuration: (NSTimeInterval)time andTotalDuration: (NSTimeInterval)duration andFinished: (BOOL) finished;
- (NSURL *) URLForVideo;
- (void) onInterstitialFallback;

@end
