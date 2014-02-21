//
//  HZGame.m
//  Heyzap
//
//  Created by Daniel Rhodes on 4/3/13.
//
//

#import "HZGame.h"
#import "HZAPIClient.h"
#import "HeyzapSDK.h"
#import "HeyzapSDKPrivate.h"
#import "HZDictionaryUtils.h"

@implementation HZGame

+ (void) checkinWithCompletion:(void (^)(NSDictionary *data, NSError *error))completionBlock {
    
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    
    [[HZAPIClient sharedClient] get:@"in_game_api/v1_mobile/checkin"
                         withParams:@{@"for_game_store_id" : appID, @"show_user": @"1"}
                            success:^(id json){
                                
                                NSNumber *statusCode = [HZDictionaryUtils hzObjectForKey: @"status" ofClass: [NSNumber class] default: [NSNumber numberWithInt: 500] withDict: json];
                                
                                if ([json objectForKey: @"status"] && [statusCode intValue] != 200) {
                                    if (completionBlock != nil) {
                                        NSError *error = [NSError errorWithDomain: @"com.heyzap.sdk" code: [statusCode intValue] userInfo: json];
                                        completionBlock(nil, error);
                                        return;
                                    }
                                } else {
                                    if (completionBlock != nil) {
                                        completionBlock(json, nil);
                                        return;
                                    }
                                }
                                
                            } failure:^(NSError *error){
                                if (completionBlock != nil) {
                                    completionBlock(nil, error);
                                }
                            }];
}

@end
