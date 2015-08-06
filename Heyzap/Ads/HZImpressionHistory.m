//
//  HZImpressionHistory.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZImpressionHistory.h"
#import "HZDatabaseHelper.h"
#import "HZLog.h"
#import "HZUtils.h"

// SQLite table name / column names
#define TABLE_NAME @"impressions"
#define COLUMN_ID @"id"
#define COLUMN_TIMESTAMP @"timestamp"
#define COLUMN_ADTYPE @"adType"
#define COLUMN_ADTAG @"adTag"
#define COLUMN_AUCTIONTYPE @"auctionType"

// SQLite table insert trigger
#define TRIGGER_NAME @"limit_table_size"
#define TRIGGER_ROW_LIMIT 1000

@interface HZImpressionEvent : NSObject

@property (nonatomic, nonnull) NSDate *timestamp;
@property (nonatomic) HZAdType adType;
@property (nonnull, nonatomic) NSString *adTag;
@property (nonatomic) HZAuctionType auctionType;

@end

@implementation HZImpressionHistory

+ (nullable instancetype) sharedInstance {
    static HZImpressionHistory *history;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        history = [[HZImpressionHistory alloc] init];
        
        sqlite3 *database = [history impressionTableDatabaseConnection];
        if (!database || ![history createImpressionTableIfNotExistsInOpenDatabase:database]) {
            HZELog(@"HZImpressionHistory: Error creating impression history.");
        }
        
        sqlite3_close(database);
    });
    
    return history;
}


#pragma mark - Insert

- (BOOL) recordImpressionWithType:(HZAdType)adType tag:(nonnull NSString *)tag auctionType:(HZAuctionType)auctionType {
    NSDate *methodStart = [NSDate date];
    
    sqlite3 *db = [self impressionTableDatabaseConnection];
    if(!db) {
        return NO;
    }
    
    NSString *query = [NSString stringWithFormat:@"INSERT INTO " TABLE_NAME " (" COLUMN_TIMESTAMP ", " COLUMN_ADTYPE ", " COLUMN_ADTAG ", " COLUMN_AUCTIONTYPE ") VALUES (%f, %lu, '%s', %lu)", [self databaseEntryForDate:nil], (unsigned long)adType, [tag UTF8String], (unsigned long)auctionType];
    
    char *errorMessage;
    int returnCode = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errorMessage);
    if (returnCode != SQLITE_OK) {
        HZELog(@"Failed to record impression. Code: %i, Error: %s", returnCode, errorMessage);
    }
    
    sqlite3_close(db);
    sqlite3_free(errorMessage);
    
    NSDate *methodEnd = [NSDate date];
    HZDLog(@"HZImpressionHistory: impression insert query took %f seconds. Query: %@;", [methodEnd timeIntervalSinceDate:methodStart], query);
    return returnCode == SQLITE_OK;
}


#pragma mark - Query

- (NSUInteger) countImpressionsSince:(nonnull NSDate *)timestamp withType:(HZAdType)adType tag:(nullable NSString *)tag auctionType:(HZAuctionType)auctionType {
    NSString *tagWhereClause = tag ? [NSString stringWithFormat:@"AND " COLUMN_ADTAG " = '%s'", [tag UTF8String]] : @"";
    return [self countImpressionsSince:timestamp withType:adType tagWhereClause:tagWhereClause auctionType:auctionType];
}

- (NSUInteger) countImpressionsSince:(nonnull NSDate *)timestamp withType:(HZAdType)adType tags:(nullable NSArray *)tags auctionType:(HZAuctionType)auctionType {
    NSString *tagWhereClause = @"";
    
    if(tags) {
        // surround tags with '' for the query string
        NSArray * modifiedTags = hzMap(tags, ^NSString *(NSString *tag) {
            return [NSString stringWithFormat:@"'%s'", [tag UTF8String]];
        });
    
        tagWhereClause = [NSString stringWithFormat:@"AND " COLUMN_ADTAG " IN (%@)", [modifiedTags componentsJoinedByString:@","]];
    }
    
    return [self countImpressionsSince:timestamp withType:adType tagWhereClause:tagWhereClause auctionType:auctionType];
}

- (NSUInteger) countImpressionsSince:(nonnull NSDate *)timestamp withType:(HZAdType)adType tagWhereClause:(NSString *)tagWhereClause auctionType:(HZAuctionType)auctionType {
    NSDate *methodStart = [NSDate date];
    
    NSUInteger impressionCount = 0;
    sqlite3 *db = [self impressionTableDatabaseConnection];
    if(!db) {
        return impressionCount;
    }
    
    NSString *query = [NSString stringWithFormat:@"SELECT count(*) FROM " TABLE_NAME " WHERE " COLUMN_ADTYPE " = %lu %@ AND " COLUMN_AUCTIONTYPE " = %lu AND " COLUMN_TIMESTAMP " BETWEEN %f AND %f", (unsigned long)adType, tagWhereClause, (unsigned long)auctionType, [self databaseEntryForDate:timestamp], [self databaseEntryForDate:nil]];
    
    
    sqlite3_stmt *statement = NULL;
    int returnCode = 0;
    if((returnCode = sqlite3_prepare_v2(db, [query UTF8String], (int)strlen([query UTF8String])+1, &statement, NULL)) != SQLITE_OK || statement == NULL) {
        HZELog(@"Failed to create query. code:%d",returnCode);
        sqlite3_close(db);
        return impressionCount;
    }
    
    while(sqlite3_step(statement) == SQLITE_ROW) {
        impressionCount = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(db);
    
    NSDate *methodEnd = [NSDate date];
    HZDLog(@"HZImpressionHistory: impression count query (result=%lu) took %f seconds. Query: %@;", impressionCount, [methodEnd timeIntervalSinceDate:methodStart], query);
    
    return impressionCount;
}

#pragma mark - Connect

- (sqlite3 *) impressionTableDatabaseConnection {
    NSError *error;
    sqlite3 *database = [HZDatabaseHelper openDatabaseWithName:@"HZImpressionHistory" error:&error];
    if(error) {
        HZELog(@"HZImpressionHistory: Error opening impression history. Segmentation settings may fail. Error: %@", error);
        return nil;
    }
    
    return database;
}

#pragma mark - Create/Delete

- (BOOL) createImpressionTableIfNotExistsInOpenDatabase:(sqlite3 *)db {
    // the trigger is a way to limit the number of rows in the table. currently limited to 1000 rows of impression data. http://www.sqlite.org/lang_createtrigger.html
    // the trigger is (conditionally) dropped before being created so that if we change the impression limit later the old one will be removed (since it won't replace it if one of the same name currently exists)
    NSString * query =[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS " TABLE_NAME " ( " COLUMN_ID " INTEGER PRIMARY KEY AUTOINCREMENT, " COLUMN_TIMESTAMP " INTEGER, " COLUMN_ADTYPE " INTEGER, " COLUMN_ADTAG " TEXT, " COLUMN_AUCTIONTYPE " INTEGER);\
    DROP TRIGGER IF EXISTS " TRIGGER_NAME ";\
    CREATE TRIGGER IF NOT EXISTS " TRIGGER_NAME " AFTER INSERT ON " TABLE_NAME " WHEN (SELECT count(*) from " TABLE_NAME ")>%d\
    BEGIN\
    DELETE FROM " TABLE_NAME " WHERE " COLUMN_ID " IN (SELECT " COLUMN_ID " FROM " TABLE_NAME " ORDER BY " COLUMN_ID " LIMIT (SELECT count(*) - %d from " TABLE_NAME " ));\
    END;", TRIGGER_ROW_LIMIT, TRIGGER_ROW_LIMIT];
    
    char * errMsg;
    int rc = sqlite3_exec(db, [query UTF8String],NULL,NULL,&errMsg);
    
    if(SQLITE_OK != rc)
    {
        HZELog(@"HZImpressionHistory: Failed to create impression table. Code: %d, Error: %s",rc,errMsg);
    }
    
    sqlite3_free(errMsg);
    
    return rc == SQLITE_OK;
}

- (BOOL) deleteHistory {
    NSError *error;
    sqlite3 *database = [HZDatabaseHelper openDatabaseWithName:@"HZImpressionHistory" error:&error];
    if(error) {
        HZELog(@"HZImpressionHistory: Error opening impression history. Can't delete table. Error: %@", error);
        return NO;
    }
    
    NSString* query =@"DROP TABLE IF EXISTS " TABLE_NAME;
    char * errMsg;
    int rc = sqlite3_exec(database, [query UTF8String],NULL,NULL,&errMsg);
    
    if(SQLITE_OK != rc)
    {
        HZELog(@"HZImpressionHistory: Failed to delete impression table. Code: %d, Error: %s",rc,errMsg);
    }
    
    sqlite3_free(errMsg);
    
    return rc == SQLITE_OK;
}


#pragma mark - Utilities

/**
 *  Converts an NSDate to a NSTimeInterval (double representing the #/seconds since a common date) that can be stored for the date. Use for all database entries and queries referencing a date for consistency.
    @param date The date to convert. If `nil`, the current date is used.
 */
- (NSTimeInterval) databaseEntryForDate:(nullable NSDate *)date {
    if(!date) date = [NSDate date];
    return [date timeIntervalSince1970];
}


@end