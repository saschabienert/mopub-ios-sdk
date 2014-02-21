//
//  HZUser.m
//  Heyzap
//
//  Created by Daniel Rhodes on 4/3/13.
//
//

#import "HZUser.h"
#import "HZDictionaryUtils.h"
#import "HeyzapSDKPrivate.h"
#import "HZAPIClient.h"

@implementation HZUser

- (id) initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _username = [HZDictionaryUtils hzObjectForKey: @"username" ofClass: [NSString class] default: @"" withDict: dict];
        _picture = [HZDictionaryUtils hzObjectForKey: @"picture" ofClass: [NSString class] default: @"" withDict: dict];
    }
    
    return self;
}

+ (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password withCompletion:(void (^)(NSDictionary *, NSError *))completionBlock {

    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    
    NSDictionary *params = @{@"for_game_store_id" : appID, @"username_or_email": username, @"password": password};
    
    [[HZAPIClient sharedClient] get:@"in_game_api/v1_mobile/login"
                         withParams: params
                            success:^(id json){
                                
                                if (completionBlock != nil) {
                                    completionBlock(json, nil);
                                }
                                
                            } failure:^(NSError *error){
                                if (completionBlock != nil) {
                                    completionBlock(nil, error);
                                }
                            }];
}

+ (void) logout {
    
    NSString *appID = [[HeyzapSDK sharedSDK] appId];
    
    NSDictionary *params = @{@"for_game_store_id" : appID};
    
    [[HZAPIClient sharedClient] get:@"in_game_api/v1_mobile/logout"
                         withParams: params
                            success:^(id json){
                                
                            } failure:^(NSError *error){
                            
                            }];
}



@end
