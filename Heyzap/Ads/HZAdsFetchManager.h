//
//  HZAdsFetchManager.h
//  Heyzap
//
//  Created by Daniel Rhodes on 1/6/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZAdFetchRequest;
@class HZAdModel;


@interface HZAdsFetchManager : NSObject

- (void) fetch: (HZAdFetchRequest *) request withCompletion:(void (^)(HZAdModel *, NSString *, NSError *))completion;
+ (instancetype)sharedManager;

@end
