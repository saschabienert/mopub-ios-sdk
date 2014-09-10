//
//  HZNativeAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

/**
 *  HZNativeAd represents an ad for a single game. It includes properties like the game's name and iconURL. 
 */
@interface HZNativeAd : NSObject

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
 *  `HZNativeAd` is created from JSON returned from our servers. `HZNativeAd` parses the JSON and sets the properties you see above, but we may in the future return more values from the server. In this case, you can manually access these values from the `rawResponse` property.
 */
@property (nonatomic, readonly) NSDictionary *rawResponse;

#pragma mark - Reporting Events

/**
 *  When the user clicks the ad, call this method to present an SKStoreProductViewController for that ad. This method will handle reporting the click to Heyzap.
 *
 *  @param viewController The view controller which should present the `SKStoreProductViewController`.
 *  @param storeDelegate  The delegate for the `SKStoreProductViewController`. The delegate should dismiss the `SKStoreProductViewController` when `productViewControllerDidFinish:` is called on it.
 *  @param completion     In rare cases, `SKStoreProductViewController` will fail to load the App Store, as described in `loadProductWithParameters:completionBlock:`. This method will call the completion block with the values that API returns. If the `SKStoreProductViewController` fails to load, we open the App Store App.
 
 It's recommended that you display a loading spinner before calling this method, in case the app store takes some time to load. You can dismiss the loading spinner in the `completion` block of this method.
 */
- (void)presentAppStoreFromViewController:(UIViewController *)viewController
                            storeDelegate:(id<SKStoreProductViewControllerDelegate>)storeDelegate
                               completion:(void (^)(BOOL result, NSError *error))completion;

@end
