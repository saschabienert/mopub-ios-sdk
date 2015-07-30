//
//  HZInterstitialVideoConfig.h
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZInterstitialVideoConfig : NSObject

@property (nonatomic, readonly) double interstitialVideoIntervalMillis;
@property (nonatomic, readonly) BOOL interstitialVideoEnabled;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
