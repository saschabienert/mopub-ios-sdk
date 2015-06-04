//
//  HZVideoAdModel.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZVideoAdModel.h"
#import "HZDictionaryUtils.h"
#import "HZAdVideoViewController.h"
#import "HZDownloadHelper.h"
#import "HZUtils.h"
#import "HZAdsAPIClient.h"
#import "HZLog.h"
#import "HZEnums.h"
#import "HZWebViewPool.h"

@interface HZVideoAdModel()<UIWebViewDelegate>
@property (nonatomic) BOOL sentComplete;
@property (nonatomic) HZAFHTTPRequestOperation *downloadOperation;
@end

@implementation HZVideoAdModel

- (instancetype) initWithDictionary: (NSDictionary *) dict adUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType {
    self = [super initWithDictionary: dict adUnit:adUnit auctionType:auctionType];
    if (self) {
        NSDictionary *interstitial = [HZDictionaryUtils hzObjectForKey: @"interstitial" ofClass: [NSDictionary class] default: @{} withDict: dict];
        if ([interstitial objectForKey: @"html_data"] != nil) {
            _HTMLContent = [HZDictionaryUtils hzObjectForKey: @"html_data" ofClass: [NSString class] default: @"" withDict: interstitial];
        }
        
        NSDictionary *video = [HZDictionaryUtils hzObjectForKey: @"video" ofClass: [NSDictionary class] default: @{} withDict: dict];
        
        if ([video objectForKey: @"static_url"] != nil) {
            NSArray *staticURLs = [HZDictionaryUtils hzObjectForKey: @"static_url" ofClass: [NSArray class] default: @[] withDict: video];
            
            _staticURLs = [[NSMutableArray alloc] init];
            
            for (NSString *staticURL in staticURLs) {
                [_staticURLs addObject: [NSURL URLWithString: staticURL]];
            }
        } else {
            _staticURLs = [[NSMutableArray alloc] initWithCapacity: 0];
        }
        
        if ([video objectForKey: @"streaming_url"] != nil) {
            NSArray *streamingURLs = [HZDictionaryUtils hzObjectForKey: @"streaming_url" ofClass: [NSArray class] default: @[] withDict: video];
            
            _streamingURLs = [[NSMutableArray alloc] init];
            
            for (NSString *streamingURL in streamingURLs) {
                [_streamingURLs addObject: [NSURL URLWithString: streamingURL]];
            }
        } else {
            _streamingURLs = [[NSMutableArray alloc] initWithCapacity: 0];
        }
        
        if ([_staticURLs count] == 0 && [_streamingURLs count] == 0) {
            return nil;
        }
    
        // On-Screen Video Behaviors
        _allowHide = [[HZDictionaryUtils hzObjectForKey: @"allow_hide" ofClass: [NSNumber class] default: @(0) withDict: video] boolValue];
        _allowSkip = [[HZDictionaryUtils hzObjectForKey: @"allow_skip" ofClass: [NSNumber class] default: @(0) withDict: video] boolValue];
        _allowInstallButton = [[HZDictionaryUtils hzObjectForKey: @"allow_install_button" ofClass: [NSNumber class] default: @(1) withDict: video] boolValue];
        _allowAdTimer = [[HZDictionaryUtils hzObjectForKey: @"allow_ad_timer" ofClass: [NSNumber class] default: @(1) withDict: video] boolValue];
        _lockoutTime = [HZDictionaryUtils hzObjectForKey: @"lockout_time" ofClass: [NSNumber class] default: @(0) withDict: video];
        _postRollInterstitial = [[HZDictionaryUtils hzObjectForKey: @"post_roll_interstitial" ofClass: [NSNumber class] default: @(0) withDict: video] boolValue];
        
        _installButtonText = [NSString stringWithFormat:@"%@", [HZDictionaryUtils hzObjectForKey:@"install_button_text" ofClass:[NSString class] default:@"Install Now" withDict:video]];
        _skipNowText = [NSString stringWithFormat:@"%@", [HZDictionaryUtils hzObjectForKey:@"skip_now_text" ofClass:[NSString class] default:@"Skip" withDict:video]];
        _skipLaterFormattedText = [NSString stringWithFormat:@"%@", [HZDictionaryUtils hzObjectForKey:@"skip_later_formatted_text" ofClass:[NSString class] default:@"Skip in %is" withDict:video]];
        
        _allowFallbacktoStreaming = [[HZDictionaryUtils hzObjectForKey: @"allow_streaming_fallback" ofClass: [NSNumber class] default: @(0) withDict: video] boolValue];
        _forceStreaming = [[HZDictionaryUtils hzObjectForKey: @"force_streaming" ofClass: [NSNumber class] default: @(0) withDict: video] boolValue];
        
        NSDictionary *meta = [HZDictionaryUtils hzObjectForKey: @"meta"  ofClass: [NSDictionary class] default: @{} withDict: video];
        
        // Video Meta
        _videoWidth = [HZDictionaryUtils hzObjectForKey: @"width" ofClass: [NSNumber class] default: @(0) withDict: meta];
        _videoHeight = [HZDictionaryUtils hzObjectForKey: @"height" ofClass: [NSNumber class] default: @(0) withDict: meta];
        _videoSizeBytes = [HZDictionaryUtils hzObjectForKey: @"bytes" ofClass: [NSNumber class] default: @(0) withDict: meta];
        _videoDuration = [HZDictionaryUtils hzObjectForKey: @"length" ofClass: [NSNumber class] default: @(0) withDict: meta];
        
        // Other
        _fileCached = NO;

    }
    
    return self;
}

- (void) dealloc {
    [self cleanup];
    UIWebView *preload = self.preloadWebview;
    self.preloadWebview = nil;
    if (self.preloadWebview) {
        [[HZWebViewPool sharedPool] returnWebView:preload];
    }
}

- (Class) controller {
    return [HZAdVideoViewController class];
}

#pragma mark - Post Fetch

- (void)initializeWebviewWithBaseURL:(NSURL *)baseURL {
    self.preloadWebview = [[HZWebViewPool sharedPool] checkoutPool];
    self.preloadWebview.delegate = self;
    [self.preloadWebview loadHTMLString: self.HTMLContent baseURL: baseURL];
}

- (void) doPostFetchActionsWithCompletion:(void (^)(BOOL))completion {
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    [self initializeWebviewWithBaseURL:baseURL];
    
    if (!self.forceStreaming) {
        __weak HZVideoAdModel *weakSelf = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Just in case it got deleted in meantime
            [HZUtils createCacheDirectory];
            
            // Cache video
            NSURL *URLToDownload;
            if ([self.staticURLs count] > 0) {
                URLToDownload = [self.staticURLs firstObject];
            } else if ([self.streamingURLs count] > 0) {
                URLToDownload = [self.streamingURLs firstObject];
            }
            
            self.downloadOperation = [HZDownloadHelper downloadURL: URLToDownload
                                                        toFilePath: [self filePathForCachedVideo]
                                                            forTag:self.tag
                                                            adUnit:self.adUnit
                                                    andAuctionType:self.auctionType
                                                    withCompletion:^(BOOL result) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                             __strong __typeof(&*weakSelf)strongSelf = weakSelf;
                                                            strongSelf.fileCached = result;
                                                            if (![strongSelf.adUnit isEqualToString: @"interstitial"] && completion != nil) {
                                                                if (strongSelf.allowFallbacktoStreaming) {
                                                                    completion(YES);
                                                                } else {
                                                                    completion(result);
                                                                }
                                                            }
                                                        });
                                                    }];
        });
        
    }
    
    if (self.forceStreaming || [self.adUnit isEqualToString: @"interstitial"]) {
        if (completion != nil) {
            completion(YES);
        }
    }
}

#pragma mark - Events

- (BOOL) onCompleteWithViewDuration: (NSTimeInterval)time andTotalDuration: (NSTimeInterval)duration andFinished: (BOOL) finished {
    
    if (!self.sentComplete) {
        if (finished) {
            time = duration;
        }
        
        NSMutableDictionary *params = [self paramsForEventCallback];
        
        [params setObject: [NSString stringWithFormat: @"%f", duration] forKey: @"video_duration_seconds"];
        [params setObject: [NSString stringWithFormat: @"%f", time] forKey: @"watched_duration_seconds"];
        
        NSString *finishedStr = finished ? @"true" : @"false";
        [params setObject: finishedStr forKey: @"video_finished"];
        
        NSTimeInterval lockoutTimeSeconds = [self.lockoutTime doubleValue]/1000.0;
        
        [params setObject: [NSString stringWithFormat: @"%f", lockoutTimeSeconds] forKey: @"lockout_time_seconds"];
        
        if ([self.adUnit isEqualToString: @"incentivized"]) {
            [params setObject: @"true" forKey: @"incentivized"];
        }
        
        [[HZAdsAPIClient sharedClient] POST:@"event/video_impression_complete" parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
            if ([[HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: @(0) withDict: JSON] intValue] == 200) {
                self.sentComplete = YES;
            }
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            [HZLog debug: [NSString stringWithFormat: @"(COMPLETE) %@ Error: %@", self, error]];
        }];
    }
    
    return YES;
}

- (void) onInterstitialFallback {
    [self cancelDownload];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject: @"1" forKey: @"interstitial_fallback"];
    [self setEventCallbackParams: dict];
}

#pragma mark - Video Caching/Files

- (NSURL *) URLForVideo {
    if ([[NSFileManager defaultManager] fileExistsAtPath: [self filePathForCachedVideo]]) {
        return [NSURL fileURLWithPath: [self filePathForCachedVideo]];
    } else {
        if ([self.streamingURLs count] > 0 && (self.allowFallbacktoStreaming || self.forceStreaming)) {
            return [self.streamingURLs objectAtIndex: 0];
        }
    }
    
    return nil;
}

- (NSString *) filePathForCachedVideo {
    NSString *filename = [NSString stringWithFormat: @"imp.%@.mp4", self.impressionID];
    return [HZUtils cacheDirectoryWithFilename: filename];
}

- (void) cleanup {
    [super cleanup];
    
    // Kill any currently running ops
    [self cancelDownload];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: [self filePathForCachedVideo]]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath: [self filePathForCachedVideo] error: &error];
    }
}

- (void) cancelDownload {
    if (self.downloadOperation != nil && ![self.downloadOperation isFinished]) {
        [self.downloadOperation cancel];
    }
    
    self.downloadOperation = nil;
}

+ (BOOL) isValidForCreativeType: (NSString *) creativeType {
    return [creativeType isEqualToString: @"video"];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
