//
//  HZWebViewPool.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/24/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

// This Web view pool serves two purposes:
// First, initializing the first webview takes 31–42 ms; it takes something like 11ms for subsequent initializations. By initializing the pool when the SDK is started (before gameplay happens), we avoid taking a 40ms hit when we can't afford it (during 60 FPS gameplay).

// Second, we avoid the 11ms cost later by giving back a cached web view.

// Currently this class is only being used for the preloadWebViews. They're the only thing that was causing performance problems and they're the safest place to do this.

// This class could probably be generalized to other objects, with blocks to initialize the object and sanitize the returned object.
@interface HZWebViewPool : NSObject

+ (instancetype)sharedPool;

- (void)seedWithPools:(NSUInteger)pools;

// Grab a web view from the pool (this creates a new one if the pool is empty).
- (UIWebView *)checkoutPool;

// Sends a web view back to the pool. See the implementation for the sanitization this does.
- (void)returnWebView:(UIWebView *)webView;

#pragma mark - Debugging / Testing

- (NSUInteger)cachedPools;

@end
