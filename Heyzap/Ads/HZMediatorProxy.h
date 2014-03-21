//
//  HZMediatorProtocol.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZMediatorProxy <NSObject>

+ (instancetype)sharedInstance;

- (void)prefetch;

- (BOOL)hasAd;

- (void)showAd;

@end
