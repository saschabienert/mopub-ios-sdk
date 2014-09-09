//
//  HZNativeAdModel.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

/**
 *  HZNativeAdModel represents an ad for a single game. It includes properties like the game's name and iconURL. 
 */
@interface HZNativeAdModel : NSObject

#pragma mark - Native Ad Properties

/**
 *  The name of the game being advertised, e.g. "Clash of Clans". This property is guaranteed to be non-nil.
 */
@property (nonatomic, readonly) NSString *appName;
/**
 *  The URL of the game's icon. Images are in JPEG format (which doesn't support transparency), so you'll need to apply a corner radius yourself. Guaranteed to be non-nil.
 */
@property (nonatomic, readonly) NSURL *iconURL;
/**
 *  The rating of the game. This number is a value between 0 and 5, incremented in half-step increments (i.e. 0, 0.5, 1.0,... 5.0). This property is guaranteed to be non-nil.
 */
@property (nonatomic, readonly) NSNumber *rating;

/**
 *  The game's category, e.g. "Role Playing". May be nil.
 */
@property (nonatomic, readonly) NSString *category;
/**
 *  The game's description, as you'd find on the app store. Note that this string will be quite long and may need truncation. May be nil.
 */
@property (nonatomic, readonly) NSString *appDescription;
/**
 *  The developer of the game, e.g. "Supercell". May be nil.
 */
@property (nonatomic, readonly) NSString *developerName;

#pragma mark - Accessing the underlying JSON data

/**
 *  `HZNativeAdModel` is created from JSON returned from our servers. `HZNativeAdModel` parses the JSON and sets the properties you see above, but we may in the future return more values from the server. In this case, you can manually access these values from the `rawResponse` property.
 */
@property (nonatomic, readonly) NSDictionary *rawResponse;

#pragma mark - Reporting Events

/**
 *  Call this method when the ad has been clicked on to report the click to Heyzap.
 */

- (void)presentAppStoreFromViewController:(UIViewController *)viewController
                            storeDelegate:(id<SKStoreProductViewControllerDelegate>)storeDelegate
                               completion:(void (^)(BOOL result, NSError *error))completion;

@end
