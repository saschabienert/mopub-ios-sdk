//
//  HZAdColony.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZAdColonyDelegate <NSObject>
@optional

- (void)onAdColonyAdAvailabilityChange:(BOOL)available inZone:(NSString *)zoneID;

- (void)onAdColonyV4VCReward:(BOOL)success currencyName:(NSString *)currencyName currencyAmount:(int)amount inZone:(NSString *)zoneID;

@end

@protocol HZAdColonyAdDelegate <NSObject>
@optional
/**
 * Notifies your app that an ad will actually play in response to the app's request to play an ad.
 * This method is called when AdColony has taken control of the device screen and is about to begin
 * showing an ad. Apps should implement app-specific code such as pausing a game and turning off app music.
 * @param zoneID The affected zone
 */
- (void)onAdColonyAdStartedInZone:(NSString *)zoneID;

/**
 * Notifies your app that an ad completed playing (or never played) and control has been returned to the app.
 * This method is called when AdColony has finished trying to show an ad, either successfully or unsuccessfully.
 * If an ad was shown, apps should implement app-specific code such as unpausing a game and restarting app music.
 * @param shown Whether an ad was actually shown
 * @param zoneID The affected zone
 */
- (void)onAdColonyAdAttemptFinished:(BOOL)shown inZone:(NSString *)zoneID;

@end


typedef enum {
    HZ_ADCOLONY_ZONE_STATUS_NO_ZONE = 0,   /**< AdColony has not been configured with that zone ID. */
    HZ_ADCOLONY_ZONE_STATUS_OFF,           /**< The zone has been turned off on the www.adcolony.com control panel */
    HZ_ADCOLONY_ZONE_STATUS_LOADING,       /**< The zone is preparing ads for display */
    HZ_ADCOLONY_ZONE_STATUS_ACTIVE,        /**< The zone has completed preparing ads for display */
    HZ_ADCOLONY_ZONE_STATUS_UNKNOWN        /**< AdColony has not yet received the zone's configuration from the server */
} HZ_ADCOLONY_ZONE_STATUS;

@interface HZAdColony : HZClassProxy

+ (void)configureWithAppID:(NSString *)appID zoneIDs:(NSArray *)zoneIDs delegate:(id <HZAdColonyDelegate>)del logging:(BOOL)log;

+ (HZ_ADCOLONY_ZONE_STATUS)zoneStatusForZone:(NSString *)zoneID;

+ (void)playVideoAdForZone:(NSString *)zoneID withDelegate:(id<HZAdColonyDelegate>)del;

+ (BOOL)isVirtualCurrencyRewardAvailableForZone:(NSString *)zoneID;

+ (void)playVideoAdForZone:(NSString *)zoneID
              withDelegate:(id<HZAdColonyDelegate>)del
          withV4VCPrePopup:(BOOL)showPrePopup
          andV4VCPostPopup:(BOOL)showPostPopup;

+ (void)setUserMetadata:(NSString *)metadataType withValue:(NSString *)value;

@end
