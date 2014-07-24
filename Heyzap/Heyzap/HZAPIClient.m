//
//  HZAPIClient.m
//  Heyzap
//
//  Created by Daniel Rhodes on 10/10/12.
//
//
#import "HZAPIClient.h"
#import "HZDevice.h"

#ifndef _HZAFNetworking_
#import "HZAFNetworking.h"
#endif

#import "HZLog.h"
#import "HZAvailability.h"
#import "HZUtils.h"

#import "HZDictionaryUtils.h"
#import "HeyzapAds.h"

#import "HZAdsManager.h"

static NSString * const kHZAPIBaseURLString = @"https://ads.heyzap.com";

//don't change these without also changing them in the test app's view controller
NSString * const HZAPIClientDidReceiveResponseNotification = @"HZAPIClientDidReceiveResponse";
NSString * const HZAPIClientDidSendRequestNotification = @"HZAPIClientDidSendRequest";


@implementation HZAPIClient

+ (HZAPIClient *)sharedClient {
    static HZAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kHZAPIBaseURLString]];
    });
    
    return _sharedClient;
}

+ (NSMutableDictionary *) defaultParamsWithDictionary: (NSDictionary *) dictionary {
    
    NSString *deviceFormFactor;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        deviceFormFactor = @"tablet";
    } else {
        deviceFormFactor = @"phone";
    }
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    versionString = versionString ?: @"";
    
    NSString *publisherID = [HZUtils publisherID] ?: @"";
    
    NSMutableDictionary *params = [@{@"publisher_id": publisherID,
                                     @"device_id": [HZUtils deviceID],
                                     @"app_bundle_id": [[NSBundle mainBundle] bundleIdentifier],
                                     @"app_version": versionString,
                                     @"device_form_factor": deviceFormFactor,
                                     @"platform": @"iphone",
                                     @"sdk_platform": @"iphone",
                                     @"sdk_version": SDK_VERSION,
                                     @"ios_version": [UIDevice currentDevice].systemVersion,
                                     @"device_type": [HZAvailability platform],
                                     @"advertising_id" : [HZUtils deviceID],
                                   } mutableCopy];
    
    if (dictionary) {
        [params addEntriesFromDictionary: dictionary];
    }
    
    [params addEntriesFromDictionary:[[HZDevice currentDevice] HZIdentifierDictionary]];
    
    return params;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[HZAFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (void) get:(NSString *)endpoint withParams:(NSDictionary *)params success:(HZRequestSuccessBlock)success failure:(HZRequestFailureBlock)failure {
    
    NSMutableDictionary *requestParams = [[self class] defaultParamsWithDictionary: params];
    
    [HZLog debug: [NSString stringWithFormat: @"Client: GET : %@ %@", [[NSURL URLWithString: endpoint relativeToURL: self.baseURL] absoluteString], requestParams]];
    
    // This method can be called from a background thread or main thread, so we dispatch to the main thread (error if this runs on background b/c recipient modifies the UI)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidSendRequestNotification
                                                            object:nil
                                                          userInfo:@{@"info":requestParams, @"endpoint":endpoint, @"url": [NSURL URLWithString: endpoint relativeToURL: self.baseURL]}];
    });
    
    [self getPath: endpoint parameters: requestParams success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if (success) {
            NSDictionary *userInfo;
            if (JSON) {
                userInfo = [JSON isKindOfClass:[NSDictionary class]] ? JSON : @{@"response": JSON};
                if ([userInfo objectForKey:@"dev_message"]) {
                    [HZLog error:[userInfo objectForKey:@"dev_message"]];
                }
            } else {
                userInfo = nil;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidReceiveResponseNotification object:nil userInfo:userInfo];

            success(JSON);
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidReceiveResponseNotification object:nil userInfo:@{@"error_name": [error domain], @"error_info": [error userInfo]}];
            
            failure(error);
        }
    }];
}

- (void) post:(NSString *)endpoint withParams:(NSDictionary *)params success:(HZRequestSuccessBlock)success failure:(HZRequestFailureBlock)failure {
    
    NSMutableDictionary *requestParams = [[self class] defaultParamsWithDictionary: params];
    
    ;
    
    [HZLog debug: [NSString stringWithFormat: @"Client: POST : %@ %@", [[NSURL URLWithString: endpoint relativeToURL: self.baseURL] absoluteString], requestParams]];
    
    // This method can be called from a background thread or main thread, so we dispatch to the main thread (error if this runs on background b/c recipient modifies the UI)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidSendRequestNotification object:nil userInfo:@{@"info":requestParams, @"endpoint":endpoint}];
    });
    
    [self postPath: endpoint parameters: requestParams success:^(HZAFHTTPRequestOperation *operation, id JSON) {
        if (success) {
            NSDictionary *userInfo;
            if (JSON) {
                userInfo = [JSON isKindOfClass:[NSDictionary class]] ? JSON : @{@"response": JSON};
                if ([userInfo objectForKey:@"dev_message"]) {
                    [HZLog error:[userInfo objectForKey:@"dev_message"]];
                }
            } else {
                userInfo = nil;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidReceiveResponseNotification object:nil userInfo:userInfo];

            success(JSON);
        }
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            [[NSNotificationCenter defaultCenter] postNotificationName:HZAPIClientDidReceiveResponseNotification object:nil userInfo:@{@"error_name": [error domain], @"error_info": [error userInfo]}];

            failure(error);
        }
    }];
}

- (void)logMessageToHeyzap:(NSString *)message
                     error:(NSError *)error
                  userInfo:(NSDictionary *)userInfo
{
    if (!message) {
        return;
    }
    NSMutableDictionary *params = [@{@"message": message} mutableCopy];
    [params addEntriesFromDictionary:userInfo];
    
    if (error) {
        [params setObject:[NSString stringWithFormat:@"%@",error] forKey:@"NSError"];
    }
    
    [self post:@"in_game_api/ads/log_message"
    withParams:params
       success:^(id response) {
           
       }
       failure:^(NSError *anError) {
           
       }];
}

@end
