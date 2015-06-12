//
//  HZMediationCurrentShownAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZMediationSessionKey;
@class HZBaseAdapter;
@class HZMediationSession;

typedef NS_ENUM(NSUInteger, HZAdState) {
    HZAdStateRequestedShow,
    HZAdStateShown,
};

@interface HZMediationCurrentShownAd : NSObject

@property (nonatomic, readonly) HZMediationSessionKey *key;
@property (nonatomic, readonly) HZMediationSession *session;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) HZBaseAdapter *adapter;
@property (nonatomic) HZAdState adState; // Mutable

- (instancetype)initWithSessionKey:(HZMediationSessionKey *)key session:(HZMediationSession *)session tag:(NSString *)tag adapter:(HZBaseAdapter *)adapter;

@end
