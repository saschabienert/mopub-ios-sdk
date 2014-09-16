//
//  HZClassProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Subclass this to proxy a class. Add methods to your subclass's header filer that match the API of what you're proxying. Don't add implementation methods, instead ignore the warnings with "-Wincomplete-implementation" (see HZChartboost.m). 
 *  Implement properties with @dynamic in the implementation file.
 *  Anything that is discarded at compile time——enums, preprocessor macros, etc.——that is kept private doesn't need prefixing.
 *  Protocols I don't have a good solution for. My current approach is to prepend the protocol name with HZ, then have the delegate override `conformsToProtocol`.
 *
 *  Methods on this class should be prefixed with hz to avoid selector collisions with the proxied class.
 *  NSProxy declares some methods that we actually want forwared to the class. In these cases, override that method in the subclass and manually forward it to the proxied class (`HZClassProxy` already handles this for `alloc`).
 */
@interface HZClassProxy : NSProxy

/**
 *  Whether or not the class being proxied actually exists. This will return NO if e.g. Chartboost is being proxied, but the Chartboost SDK hasn't been added.
 *
 *  @return If the class is present.
 */
+ (BOOL)hzProxiedClassIsAvailable;

/**
 *  Subclasses must override this method for proxying to work.
 *
 *  @return The name of the class to be proxied.
 */
+ (NSString *)hzProxiedClassName;

@end
