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
#import "HZAdsRequestSerializer.h"

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

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [HZAdsRequestSerializer serializer];
    }
    return self;
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
    
    [self POST:@"in_game_api/ads/log_message" parameters:params success:nil failure:nil];
}

@end
