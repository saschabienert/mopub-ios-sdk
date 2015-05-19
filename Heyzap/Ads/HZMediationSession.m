//
//  HZMediationSession.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationSession.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter.h"
#import "HZMediationConstants.h"
#import "HZMediationAPIClient.h"
#import "HZLog.h"

@interface HZMediationSession()

#pragma mark - Properties from the client
@property (nonatomic) HZAdType adType;
@property (nonatomic, strong) NSString *tag;

#pragma mark - Properties from the server
@property (nonatomic, strong) NSDictionary *originalJSON;
/**
 *  The parameters we sent to /mediate. We all the parameters on every request, so it's less likely we're missing data.
 */
@property (nonatomic, strong) NSDictionary *mediateParams;
@property (nonatomic, strong) NSString *impressionID;
@property (nonatomic, strong) NSOrderedSet *chosenAdapters;
@property (nonatomic) double interstitialVideoIntervalMillis;
@property (nonatomic) BOOL interstitialVideoEnabled;

#pragma mark - Stateful properties

/**
 *  The number of banner impressions we've reported to the server.
 */
@property (nonatomic) NSUInteger bannerImpressionCount;

/**
 *  Returns the SDK version if present, otherwise defaults to empty string.
 *
 *  @param version the version
 *
 *  @return Guaranteed non-nil string.
 */
NSString * sdkVersionOrDefault(NSString *const version);

@end

@implementation HZMediationSession

#define CHECK_NOT_NIL(value) do { \
if (value == nil) { \
*error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil]; \
return nil; \
} \
} while (0)


- (instancetype)initWithJSON:(NSDictionary *)json mediateParams:(NSDictionary *)mediateParams setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error
{
    HZParameterAssert(error != NULL);
    HZParameterAssert(mediateParams);
    
    self = [super init];
    if (self) {
        _originalJSON = json;
        CHECK_NOT_NIL(_originalJSON);
        _adType = adType;
        _tag = tag;
        CHECK_NOT_NIL(_tag);
        _mediateParams = mediateParams;
        
        _impressionID = [HZDictionaryUtils objectForKey:@"id" ofClass:[NSString class] dict:json error:error];
        CHECK_NOT_NIL(_impressionID);
        
        _interstitialVideoIntervalMillis = [[HZDictionaryUtils hzObjectForKey:@"interstitial_video_interval" ofClass:[NSNumber class] default:@(30 * 1000) withDict:json] doubleValue];
        
        _interstitialVideoEnabled = [[HZDictionaryUtils hzObjectForKey:@"interstitial_video_enabled" ofClass:[NSNumber class] default:@1 withDict:json] boolValue];
        
        // Check error macro for impression ID being nil.
        
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
        CHECK_NOT_NIL(networks);
        // Check error macro for networks being nil/empty
        
        NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *network in networks) {
            NSString *networkName = network[@"network"];
            Class adapter = [HZBaseAdapter adapterClassForName:networkName];
            if (adapter
                && [adapter isSDKAvailable]
                && [setupMediators containsObject:[adapter sharedInstance]]
                && [(HZBaseAdapter *)[adapter sharedInstance] supportsAdType:adType]) {
                
                HZBaseAdapter *instance = (HZBaseAdapter *)[adapter sharedInstance];
                if (adType != HZAdTypeInterstitial || _interstitialVideoEnabled || !instance.isVideoOnlyNetwork) {
                    [adapters addObject:[adapter sharedInstance]];
                }
            }
        }
        
        self.chosenAdapters = adapters;
        HZDLog(@"Available SDKs for this fetch (assuming no video rate limiting) are = %@",self.chosenAdapters);
    }
    return self;
}

- (HZBaseAdapter *)firstAdapterWithAd:(NSDate *const)lastInterstitialVideoShown
{
    
    NSArray *preferredMediatorList = [[self availableAdapters:lastInterstitialVideoShown] array];
    
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return [adapter hasAdForType:self.adType tag:self.tag];
    }];
    
    if (idx != NSNotFound) {
        return preferredMediatorList[idx];
    } else {
        return nil;
    }
}

- (NSString *) adUnit {
    return NSStringFromAdType(self.adType);
}

- (BOOL)withinInterval:(NSDate *const)lastInterstitialVideoShown {
    if (!lastInterstitialVideoShown) {
        return YES;
    }
    const NSTimeInterval secondsSinceLastInterstitial = [[NSDate date] timeIntervalSinceDate:lastInterstitialVideoShown];
    return (secondsSinceLastInterstitial * 1000) > self.interstitialVideoIntervalMillis;
}


- (NSOrderedSet *)availableAdapters:(NSDate *const)lastInterstitialVideoShown {
    if (!lastInterstitialVideoShown || self.adType != HZAdTypeInterstitial) {
        return self.chosenAdapters;
    }
    
    const BOOL withinInterval = [self withinInterval:lastInterstitialVideoShown];
    
    NSIndexSet *indexes = [self.chosenAdapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return withinInterval || !adapter.isVideoOnlyNetwork;
    }];
    
    return [NSOrderedSet orderedSetWithArray:[self.chosenAdapters objectsAtIndexes:indexes]];
}

- (BOOL)adapterIsRateLimited:(HZBaseAdapter *const)adapter lastInterstitialVideoShown:(NSDate *const)lastInterstitialVideoShown {
    return self.adType == HZAdTypeInterstitial && adapter.isVideoOnlyNetwork && ![self withinInterval:lastInterstitialVideoShown];
}

#pragma mark - Reporting Events to the server

NSString *const kHZImpressionIDKey = @"mediation_id";
NSString *const kHZNetworkKey = @"network";
NSString *const kHZNetworkVersionKey = @"network_version";
NSString *const kHZBannerOrdinalKey = @"banner_ordinal";
/**
 *  The dictionary key for the position of a network within the list received from the server; for the list [chartboost, applovin], chartboost is 0.
 */
NSString *const kHZOrdinalKey = @"ordinal";

- (void)reportFetchWithSuccessfulAdapter:(HZBaseAdapter *)chosenAdapter
{
    // Profiling showed this to take > 5 ms (the API requests stuff is surprisingly expensive).
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self.chosenAdapters enumerateObjectsUsingBlock:^(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
            // If we got up to the successful adapter, don't report anything for the remaining adapters
            // If the chosenAdapter is `nil`, this condition will never be true.
            if (adapter == chosenAdapter) {
                *stop = YES;
            }
            NSNumber *const success = @(adapter == chosenAdapter);
            
            NSDictionary *const params = [self addParametersToDefaults:@{@"success": success,
                                                                         kHZImpressionIDKey : self.impressionID,
                                                                         kHZOrdinalKey : @(idx),
                                                                         kHZNetworkKey : [adapter name],
                                                                         kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                                                         }];
            [[HZMediationAPIClient sharedClient] POST:@"fetch" parameters:params success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
                HZDLog(@"Success reporting fetch");
            } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
                 HZDLog(@"Error reporting fetch = %@",error);
            }];
        }];
    });
}

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter
{
    const NSUInteger ordinal = [self.chosenAdapters indexOfObject:adapter];
    NSMutableDictionary *const params = [self addParametersToDefaults:
                                  @{kHZImpressionIDKey: self.impressionID,
                                    kHZNetworkKey: [adapter name],
                                    kHZOrdinalKey : @(ordinal),
                                    kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                    }].mutableCopy;
    
    if (self.adType == HZAdTypeBanner) {
        params[kHZBannerOrdinalKey] = @(self.bannerImpressionCount);
    }
    
    [[HZMediationAPIClient sharedClient] POST:@"click" parameters:params success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
        HZDLog(@"Success reporting click");
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error reporting click = %@",error);
    }];
}

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter
{
    const NSUInteger ordinal = [self.chosenAdapters indexOfObject:adapter];
    NSMutableDictionary *const params = [self addParametersToDefaults:
                                  @{
                                    kHZImpressionIDKey: self.impressionID,
                                    kHZNetworkKey: [adapter name],
                                    kHZOrdinalKey: @(ordinal),
                                    kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                    }].mutableCopy;
    
    if (self.adType == HZAdTypeBanner) {
        params[kHZBannerOrdinalKey] = @(self.bannerImpressionCount);
    }
    
    [[HZMediationAPIClient sharedClient] POST:@"impression" parameters:params success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
        HZDLog(@"Success reporting impression");
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error reporting impression = %@",error);
    }];
    
    if (self.adType == HZAdTypeBanner) {
        self.bannerImpressionCount += 1;
    }
}

NSString * sdkVersionOrDefault(NSString *const version) {
    return version ?: @"";
}

- (NSDictionary *)addParametersToDefaults:(NSDictionary *const)parameters {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:self.mediateParams];
    [dict addEntriesFromDictionary:parameters];
    return dict;
}

@end
