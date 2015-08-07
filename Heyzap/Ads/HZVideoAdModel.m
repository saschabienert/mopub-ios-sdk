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
        NSDictionary *interstitial = [HZDictionaryUtils objectForKey: @"interstitial" ofClass: [NSDictionary class] default: @{} dict: dict];
        if ([interstitial objectForKey: @"html_data"] != nil) {
            _HTMLContent = [HZDictionaryUtils objectForKey: @"html_data" ofClass: [NSString class] default: @"" dict: interstitial];
        }
        
        NSDictionary *video = [HZDictionaryUtils objectForKey: @"video" ofClass: [NSDictionary class] default: @{} dict: dict];
        
        if ([video objectForKey: @"static_url"] != nil) {
            NSArray *staticURLs = [HZDictionaryUtils objectForKey: @"static_url" ofClass: [NSArray class] default: @[] dict: video];
            
            _staticURLs = [[NSMutableArray alloc] init];
            
            for (NSString *staticURL in staticURLs) {
                [_staticURLs addObject: [NSURL URLWithString: staticURL]];
            }
        } else {
            _staticURLs = [[NSMutableArray alloc] initWithCapacity: 0];
        }
        
        if ([video objectForKey: @"streaming_url"] != nil) {
            NSArray *streamingURLs = [HZDictionaryUtils objectForKey: @"streaming_url" ofClass: [NSArray class] default: @[] dict: video];
            
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
                ...
             }
         }
         */
        [HZVideoAdDisplayOptions setDefaultsWithDict:video];
        NSDictionary * adUnitVideoOptionsResponse = [HZDictionaryUtils objectForKey: @"ad_unit" ofClass: [NSDictionary class] default: nil dict: video];
        // only save current ad unit display options, discard the others
        NSDictionary * optionsForCurrentAdUnit = [HZDictionaryUtils objectForKey:adUnit ofClass:[NSDictionary class] default:nil dict:adUnitVideoOptionsResponse];
        if(!optionsForCurrentAdUnit) {
            HZDLog(@"HZVideoAdModel did not find video display options for adUnit=\"%@\" in response. Using defaults.", adUnit);
            _displayOptions = [HZVideoAdDisplayOptions defaults];
        } else {
            _displayOptions = [[HZVideoAdDisplayOptions alloc] initWithDict:optionsForCurrentAdUnit];
        }
        
        NSDictionary *meta = [HZDictionaryUtils objectForKey: @"meta"  ofClass: [NSDictionary class] default: @{} dict: video];
        
        // Video Meta
        _videoWidth = [HZDictionaryUtils objectForKey: @"width" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoHeight = [HZDictionaryUtils objectForKey: @"height" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoSizeBytes = [HZDictionaryUtils objectForKey: @"bytes" ofClass: [NSNumber class] default: @0 dict: meta];
        _videoDuration = [HZDictionaryUtils objectForKey: @"length" ofClass: [NSNumber class] default: @0 dict: meta];
        
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
                                                            forTag:self.tag
                                                            adUnit:self.adUnit
                                                    andAuctionType:self.auctionType
                                                    withCompletion:^(BOOL result) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                             __strong __typeof(&*weakSelf)strongSelf = weakSelf;
                                                            strongSelf.fileCached = result;
                                                            if (![strongSelf.adUnit isEqualToString: @"interstitial"] && completion != nil) {
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
    
    if (self.displayOptions.forceStreaming || [self.adUnit isEqualToString: @"interstitial"]) {
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
        
        if ([self.adUnit isEqualToString: @"incentivized"]) {
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
