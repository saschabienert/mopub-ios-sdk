//
//  HZImpressionHistory.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZEnums.h"
#import "HZCreativeType.h"
#import <sqlite3.h>

@interface HZImpressionHistory : NSObject

+ (nullable instancetype) sharedInstance;


/**
 *  Asynchronously stores an impression with the given attributes in the HZImpressionHistory database (returns immediately)
 */
- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag auctionType:(HZAuctionType)auctionType date:(nonnull NSDate *)date;

/**
 *  Returns an ordered set of NSDate*s (in the order specified with the mostRecentFirst param) with the given search parameters and database connection. If the tag is `nil`, impressions with any tag will count as a match. If adType is `NULL`, impressions with any ad type will count as a match.
 */
- (nonnull NSMutableOrderedSet *) impressionsSince:(nonnull NSDate *)timestamp withCreativeType:(HZCreativeType)creativeType tag:(nullable NSString *)tag auctionType:(HZAuctionType)auctionType databaseConnection:(nonnull sqlite3 *)db mostRecentFirst:(BOOL)mostRecentFirst;

/**
 *  Returns an ordered set of NSDate*s (in the order specified with the mostRecentFirst param) with the given search parameters and database connection. If the tags array is `nil`, impressions with any tag will count as a match. If adType is `NULL`, impressions with any ad type will count as a match.
 */
- (nonnull NSMutableOrderedSet *) impressionsSince:(nonnull NSDate *)timestamp withCreativeType:(HZCreativeType)creativeType tags:(nullable NSArray *)tags auctionType:(HZAuctionType)auctionType databaseConnection:(nonnull sqlite3 *)db mostRecentFirst:(BOOL)mostRecentFirst;

/**
 *  Returns a SQLite3 connection to the HZImpressionHistory database. It is "safe" in that the table will be created if it does not exist prior to returning.
 */
- (nullable sqlite3 *) safeImpressionTableDatabaseConnection;

/**
 *  Deletes the HZImpressionHistory table that tracks impressions.
 */
- (BOOL) deleteHistory;
@end