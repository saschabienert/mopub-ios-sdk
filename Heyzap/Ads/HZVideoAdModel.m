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
@property (nonatomic) NSDictionary *videoSettingsDictionary;
@property (nonatomic) HZVideoAdDisplayOptions *displayOptions;

@end

@implementation HZVideoAdModel

- (instancetype) initWithDictionary: (NSDictionary *) dict fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType {
    self = [super initWithDictionary: dict fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:auctionType];
    if (self) {
        NSDictionary *interstitial = [HZDictionaryUtils objectForKey: @"interstitial" ofClass: [NSDictionary class] default: @{} dict: dict];
        if ([interstitial objectForKey: @"html_data"] != nil) {
            _HTMLContent = [HZDictionaryUtils objectForKey: @"html_data" ofClass: [NSString class] default: @"" dict: interstitial];
        }
        
        _videoSettingsDictionary = [HZDictionaryUtils objectForKey: @"video" ofClass: [NSDictionary class] default: @{} dict: dict];
        
        if ([_videoSettingsDictionary objectForKey: @"static_url"] != nil) {
            NSArray *staticURLs = [HZDictionaryUtils objectForKey: @"static_url" ofClass: [NSArray class] default: @[] dict: _videoSettingsDictionary];
            
            _staticURLs = [[NSMutableArray alloc] init];
            
            for (NSString *staticURL in staticURLs) {
                [_staticURLs addObject: [NSURL URLWithString: staticURL]];
            }
        } else {
            _staticURLs = [[NSMutableArray alloc] initWithCapacity: 0];
        }
        
        if ([_videoSettingsDictionary objectForKey: @"streaming_url"] != nil) {
            NSArray *streamingURLs = [HZDictionaryUtils objectForKey: @"streaming_url" ofClass: [NSArray class] default: @[] dict: _videoSettingsDictionary];
            
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
        
        /* 
         Expected format of video dict (defaults at top level, overrides per ad unit underneath "ad_unit"):
         See `updateDisplayOptionsWithUpdatedRequestingAdType` below for parsing the overrides.
         {
             ...
         
             "allow_hide" : true,
             "allow_skip" : false,
             "required_download_percent" : 100,
             "allow_click" : true,
             "skip_later_formatted_text" : "Skip in %is",
         
             ...
         
             "ad_unit" : {
                 "incentivized" : {
                     "allow_hide" : false,
                     "allow_click" : false,
                     ...
                },
                "video" : {...},
                "interstitial" : {...}
             }
         }
         */
        
        NSDictionary *meta = [HZDictionaryUtils objectForKey: @"meta"  ofClass: [NSDictionary class] default: @{} dict: _videoSettingsDictionary];
        
        // Video Meta
        _videoWidth = [HZDictionaryUtils objectForKey: @"width" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoHeight = [HZDictionaryUtils objectForKey: @"height" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoSizeBytes = [HZDictionaryUtils objectForKey: @"bytes" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoDuration = [HZDictionaryUtils objectForKey: @"length" ofClass: [NSNumber class] default: @0 dict: meta];
        
        // Other
        _fileCached = NO;

        _displayOptions = [[HZVideoAdDisplayOptions alloc] initWithDefaultsDictionary:_videoSettingsDictionary adUnitDictionary:@{}];
    }
    
    return self;
}

- (NSString *)adUnitKey {
    return NSStringFromAdType(self.requestingAdType);
}

- (void)setRequestingAdType:(HZAdType)requestingAdType {
    [super setRequestingAdType:requestingAdType];
    [self updateDisplayOptionsWithUpdatedRequestingAdType];
}

- (void)updateDisplayOptionsWithUpdatedRequestingAdType {
    // JSON structure we're parsing:
    /*
     "ad_unit" : {
        "incentivized" : {
            "allow_hide" : false,
            "allow_click" : false,
            ...
        },
        "video" : {...},
        "interstitial" : {...}
     }
     */
    NSDictionary *const settingsByAdUnitDict = [HZDictionaryUtils objectForKey: @"ad_unit" ofClass: [NSDictionary class] default:@{} dict:self.videoSettingsDictionary];
    
    NSString *const adUnitKey = [self adUnitKey]; // parses the updated `self.requestingAdType` to a dict key string
    NSDictionary *const adUnitDict = [HZDictionaryUtils objectForKey:adUnitKey ofClass:[NSDictionary class] default:@{} dict:settingsByAdUnitDict];
    
    self.displayOptions = [[HZVideoAdDisplayOptions alloc] initWithDefaultsDictionary:self.videoSettingsDictionary adUnitDictionary:adUnitDict];
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
    
    if (!self.displayOptions.forceStreaming) {
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
                                                    withCompletion:^(BOOL result) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                             __strong __typeof(&*weakSelf)strongSelf = weakSelf;
                                                            strongSelf.fileCached = result;
                                                            if (completion != nil) {
                                                                if (strongSelf.displayOptions.allowFallbacktoStreaming) {
                                                                    completion(YES);
                                                                } else {
                                                                    completion(result);
                                                                }
                                                            }
                                                        });
                                                    }];
        });
        
    }
    
    if (self.displayOptions.forceStreaming) {
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
        
        NSTimeInterval lockoutTimeSeconds = [self.displayOptions.lockoutTime doubleValue]/1000.0;
        
        [params setObject: [NSString stringWithFormat: @"%f", lockoutTimeSeconds] forKey: @"lockout_time_seconds"];
        
        if (self.showableCreativeType == HZCreativeTypeIncentivized) {
            [params setObject: @"true" forKey: @"incentivized"];
        }
        
        [[HZAdsAPIClient sharedClient] POST:@"event/video_impression_complete" parameters:params success:^(HZAFHTTPRequestOperation *operation, id JSON) {
            if ([[HZDictionaryUtils objectForKey: @"status" ofClass: [NSNumber class] default: @0 dict: JSON] intValue] == 200) {
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
    if (self.fileCached) {
        return [NSURL fileURLWithPath: [self filePathForCachedVideo]];
    } else {
        if ([self.streamingURLs count] > 0 && (self.displayOptions.allowFallbacktoStreaming || self.displayOptions.forceStreaming)) {
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
