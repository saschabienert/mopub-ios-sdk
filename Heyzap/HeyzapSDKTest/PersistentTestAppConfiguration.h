//
//  TestAppConfiguration.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Singleton class for get/setting persistent configuration options that need to be set at launch time.
 */
@interface PersistentTestAppConfiguration : NSObject

+ (instancetype)sharedConfiguration;

@property (nonatomic) BOOL autoPrefetch;

@end
