//
//  HZAnalytics.h
//  Heyzap
//
//  Created by Simon Maynard on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Max: WARNING: this class is not thread safe -- only call it from the main thread. (Mutating an NSMutableArray's contents is not a thread safe operation)
@interface HZAnalytics : NSObject

+ (HZAnalytics*) sharedInstance;
+ (void) logAnalyticsEvent: (NSString *) eventName;
+ (void) logAnalyticsEvent: (NSString *) eventName withValuesFromDictionary: (NSDictionary *)dictionary;
+ (void) logAnalyticsEvent: (NSString *) eventName andParams: (NSDictionary*)params;
+ (void) logAnalyticsEvent: (NSString *) eventName andValue: (NSString *)value forKey: (NSString *)key;
+ (NSString*) generateAnalyticsFilename;


- (id) init;

- (void) sendAnalytic: (NSDictionary *) analytic;

@end
