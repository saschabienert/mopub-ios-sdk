//
//  HZAPIClient.h
//  Heyzap
//
//  Created by Daniel Rhodes on 10/10/12.
//
//

#import <Foundation/Foundation.h>
#import "HZAPIClient.h"
#ifndef _HZAFNetworking_
#import "HZAFNetworking.h"
#endif

@interface HZAPIClient : HZAFHTTPRequestOperationManager

+ (HZAPIClient *)sharedClient;

/** Logs an error message to Heyzap's server. Intended for logging bad behavior, like an ad having invalid properties or not being able to access StoreKit.
 
 @param message The message to log. If `nil`, the method does nothing.
 @param error An NSError to pass to the server (The result of its `description` method is used). Can be `nil`.
 @param userInfo An NSDictionary of additional information to send to the server.
 */
- (void)logMessageToHeyzap:(NSString *)message
                     error:(NSError *)error
                  userInfo:(NSDictionary *)userInfo;

@end
