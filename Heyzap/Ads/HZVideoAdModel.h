//
//  HZVideoAdModel.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdModel.h"
#import "HZAFNetworking.h"

@interface HZVideoAdModel : HZAdModel

// Interstitial
@property (nonatomic) NSString *HTMLContent;
@property (nonatomic) NSNumber *interstitialHeight;
@property (nonatomic) NSNumber *interstitialWidth;

// Video Meta
@property (nonatomic) NSNumber *videoWidth;
@property (nonatomic) NSNumber *videoHeight;
@property (nonatomic) NSNumber *videoDuration;
@property (nonatomic) NSNumber *videoSizeBytes;

// Video Sources
@property (nonatomic) NSMutableArray *staticURLs;
@property (nonatomic) NSMutableArray *streamingURLs;

// On-screen Video Behaviors
@property (nonatomic) NSNumber *lockoutTime;
@property (nonatomic, assign) BOOL allowSkip;
@property (nonatomic, assign) BOOL allowHide;
@property (nonatomic, assign) BOOL allowClick;
@property (nonatomic, assign) BOOL postRollInterstitial;

// Download Ops
@property (nonatomic) HZAFHTTPRequestOperation *downloadOperation;

- (BOOL) onCompleteWithViewDuration: (NSTimeInterval)time andTotalDuration: (NSTimeInterval)duration andFinished: (BOOL) finished;
- (NSURL *) URLForVideo;

@end
