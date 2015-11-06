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
#define COLUMN_CREATIVETYPE @"creativeType"
#define COLUMN_ADTAG @"adTag"
#define COLUMN_AUCTIONTYPE @"auctionType"

// SQLite table insert trigger
#define TRIGGER_NAME @"limit_table_size"
#define TRIGGER_ROW_LIMIT 1000

@interface HZImpressionEvent : NSObject

@property (nonatomic, nonnull) NSDate *timestamp;
@property (nonatomic) HZCreativeType creativeType;
@property (nonnull, nonatomic) NSString *adTag;
@property (nonatomic) HZAuctionType auctionType;
@end

@interface HZImpressionHistory()
@property (nonatomic) dispatch_queue_t writeQueue;
@end

@implementation HZImpressionHistory

+ (nullable instancetype) sharedInstance {
    static HZImpressionHistory *history;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        history = [[HZImpressionHistory alloc] init];
    });
    
    return history;
}

- (nullable instancetype) init {
    self = [super init];
    if (self) {
        _writeQueue = dispatch_queue_create("com.heyzap.sdk.mediation.impressionhistory", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


#pragma mark - Insert
// performs insertion on background thread asynchronously
- (void) recordImpressionWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag auctionType:(HZAuctionType)auctionType date:(nonnull NSDate *)date {
    __block NSDate *methodStartPreQueue = [NSDate date];
    dispatch_async(self.writeQueue, ^{
        NSDate *methodStart = [NSDate date];
        int returnCode;
        BOOL failed = NO;
        
        NSString *query = [NSString stringWithFormat:@"INSERT INTO " TABLE_NAME " (" COLUMN_TIMESTAMP ", " COLUMN_CREATIVETYPE ", " COLUMN_ADTAG ", " COLUMN_AUCTIONTYPE ") VALUES (%f, %lu, ?, %lu)", [self databaseEntryForDate:date], (unsigned long)creativeType, (unsigned long)auctionType];
        sqlite3 * insertDb = [self safeImpressionTableDatabaseConnection];
        if(!insertDb) {
            failed = YES;
            HZELog(@"HZImpressionHistory: Failed to record impression. DB connection could not be established.");
        }
        
        sqlite3_stmt *compiledStatement;
        if (!failed) {
            if (!sqlite3_prepare_v2(insertDb, [query UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
                failed = YES;
                HZELog(@"HZImpressionHistory: Failed to record impression. DB statement could not be prepared.");
            }
        }
        
        if (!failed) {
            sqlite3_bind_text(compiledStatement, 1, [tag UTF8String], -1, SQLITE_TRANSIENT); // replaces `?` in query string with the ad tag (deals with escaping characters for us). (SQLITE_TRANSIENT tells the db to copy the string for memory management reasons). The second param (`1`) is the 1-based index of the question mark in the query string
            returnCode = sqlite3_step(compiledStatement);
            if (returnCode != SQLITE_DONE) {
                HZELog(@"HZImpressionHistory: Failed to record impression. Code: %i", returnCode);
                failed = YES;
            }
            
            sqlite3_finalize(compiledStatement);
        }
        
        NSDate *methodEnd = [NSDate date];
        if (failed) {
            HZELog(@"HZImpressionHistory: FAILED impression insert query took %f seconds after a %f second threading delay. Query: %@;", [methodEnd timeIntervalSinceDate:methodStart], [methodStart timeIntervalSinceDate:methodStartPreQueue], query);
        } else {
            //HZDLog(@"HZImpressionHistory: impression insert query took %f seconds after a %f second threading delay. Query: %@;", [methodEnd timeIntervalSinceDate:methodStart], [methodStart timeIntervalSinceDate:methodStartPreQueue], query);
        }
        
    });
}


#pragma mark - Query

- (NSMutableOrderedSet *) impressionsSince:(nonnull NSDate *)timestamp withCreativeType:(HZCreativeType)creativeType tag:(nullable NSString *)tag auctionType:(HZAuctionType)auctionType databaseConnection:(sqlite3 *)db mostRecentFirst:(BOOL)mostRecentFirst {
    return [self impressionsSince:timestamp withCreativeType:creativeType tags:(tag ? [NSSet setWithObject:tag] : nil) auctionType:auctionType databaseConnection:db mostRecentFirst:mostRecentFirst];
}

- (NSMutableOrderedSet *) impressionsSince:(nonnull NSDate *)timestamp withCreativeType:(HZCreativeType)creativeType tags:(nullable NSSet *)tags auctionType:(HZAuctionType)auctionType databaseConnection:(sqlite3 *)db mostRecentFirst:(BOOL)mostRecentFirst {
    if (!db) {
        HZELog(@"HZImpressionHistory: Can't count impressions without database connection.");
        return [[NSMutableOrderedSet alloc] init];
    }
    NSArray *const tagsArray = tags.allObjects;
    
    //NSDate *methodStart = [NSDate date];
    
    NSString *creativeTypeWhereClause = @"";
    if (creativeType != HZCreativeTypeUnknown) {
        creativeTypeWhereClause = [NSString stringWithFormat:COLUMN_CREATIVETYPE " = %lu", (unsigned long)creativeType];
    }
    
    NSString *auctionTypeWhereClause = @"";
    if (auctionType != HZAuctionTypeMixed) {
        auctionTypeWhereClause = [NSString stringWithFormat:COLUMN_AUCTIONTYPE " = %lu", (unsigned long)auctionType];
    }
    
    NSString *tagWhereClause = @"";
    if (tags && [tags count] > 0) {
        // for instance, insert `?,?,?` into the WHERE clause if there are 3 tags
        // the sqlite3_bind_text statement later will replace these `?`s with the tags (takes care of escaping for us)
        NSArray *questionMarks = hzMap(tagsArray, ^NSString *(NSString *tag){
            return @"?";
        });
        
        tagWhereClause = [NSString stringWithFormat:COLUMN_ADTAG " IN (%@)", [questionMarks componentsJoinedByString:@","]];
    }
    
    // we always search a specified time range (between passed timestamp & now)
    NSString *timestampWhereClause = [NSString stringWithFormat:COLUMN_TIMESTAMP " BETWEEN %f AND %f", [self databaseEntryForDate:timestamp], [self databaseEntryForDate:nil]];
    
    // remove unused clauses & combine the rest
    NSArray *whereClauses = hzFilter(@[creativeTypeWhereClause, auctionTypeWhereClause, tagWhereClause, timestampWhereClause], ^BOOL(NSString *clause) {
        return [clause length] > 0;
    });
    NSString *whereClausesString = [whereClauses componentsJoinedByString:@" AND "];
    
    NSString *query = [NSString stringWithFormat:@"SELECT " COLUMN_TIMESTAMP " FROM " TABLE_NAME " WHERE %@ ORDER BY " COLUMN_TIMESTAMP " %@", whereClausesString, (mostRecentFirst ? @"DESC" : @"ASC")];
    sqlite3_stmt *statement = NULL;
    int returnCode = 0;
    
    if((returnCode = sqlite3_prepare_v2(db, [query UTF8String], (int)strlen([query UTF8String])+1, &statement, NULL)) != SQLITE_OK || statement == NULL) {
        HZELog(@"HZImpressionHistory: Failed to create query. code:%d",returnCode);
        return [[NSMutableOrderedSet alloc] init];
    }
    
    // bind tags into statement, replacing `?`s from above
    for(uint i = 0; i < [tags count]; i++) {
        sqlite3_bind_text(statement, i + 1, [tagsArray[i] UTF8String], -1, SQLITE_TRANSIENT); // replaces `?` in query string with the ad tag (deals with escaping characters for us). (SQLITE_TRANSIENT tells the db to copy the string for memory management reasons). The second param (`1`) is the 1-based index of the question mark in the query string
    }
    
    NSMutableOrderedSet *impressions = [[NSMutableOrderedSet alloc] init];
    
    while(sqlite3_step(statement) == SQLITE_ROW) {
        [impressions addObject: [self dateFromDatabaseEntry:sqlite3_column_double(statement, 0)]]; // the second argument to sqlite3_column_double() is the column index in the expected result set
    }
    
    sqlite3_finalize(statement);
    
    //NSDate *methodEnd = [NSDate date];
    //HZDLog(@"HZImpressionHistory: impression list query (result size=%lu) took %f seconds. Query: %@;", (unsigned long)[impressions count], [methodEnd timeIntervalSinceDate:methodStart], (tags && tags.count > 0 ? [query stringByReplacingOccurrencesOfString:@"(\\?(,\\?)*)" withString:[tags componentsJoinedByString:@", "] options:NSRegularExpressionSearch range:NSMakeRange(0, query.length)] : query));
    
    return impressions;
}

#pragma mark - Connect

- (sqlite3 *) impressionTableDatabaseConnection {
    NSError *error;
    sqlite3 *database = [HZDatabaseHelper openDatabaseWithName:@"HZImpressionHistory" error:&error];
    if(error) {
        HZTrackError(error);
        HZELog(@"HZImpressionHistory: Error opening impression history. Segmentation settings may fail. Error: %@", error);
        return NULL;
    }
    
    return database;
}

- (sqlite3 *) safeImpressionTableDatabaseConnection {
    sqlite3 *db = [self impressionTableDatabaseConnection];
    if (!db || ![self createImpressionTableIfNotExistsInOpenDatabase:db]) {
        HZELog(@"HZImpressionHistory: Error creating impression history connection.");
        sqlite3_close(db);
        return NULL;
    }
    
    return db;
}

#pragma mark - Create/Delete

- (BOOL) createImpressionTableIfNotExistsInOpenDatabase:(sqlite3 *)db {
    if(!db) {
        return NO;
    }
    
    // the trigger is a way to limit the number of rows in the table. currently limited to 1000 rows of impression data. http://www.sqlite.org/lang_createtrigger.html
    // the trigger is (conditionally) dropped before being created so that if we change the impression limit later the old one will be removed (since it won't replace it if one of the same name currently exists)
    NSString * query =[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS " TABLE_NAME " ( " COLUMN_ID " INTEGER PRIMARY KEY AUTOINCREMENT, " COLUMN_TIMESTAMP " INTEGER, " COLUMN_CREATIVETYPE " INTEGER, " COLUMN_ADTAG " TEXT, " COLUMN_AUCTIONTYPE " INTEGER);\
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
    int returnCode;
    BOOL failed = NO;
    NSString *query;
    
    sqlite3 *db = [self impressionTableDatabaseConnection];
    
    if(!db) {
        HZELog(@"HZImpressionHistory: Failed to delete impression table. Could not create database connection.");
        return NO;
    }
    
    query = @"DROP TABLE IF EXISTS " TABLE_NAME;
    char * errMsg;
    returnCode = sqlite3_exec(db, [query UTF8String],NULL,NULL,&errMsg);
    
    if(SQLITE_OK != returnCode)
    {
        HZELog(@"HZImpressionHistory: Failed to delete impression table. Code: %d, Error: %s",returnCode,errMsg);
        failed = YES;
    }
    
    sqlite3_free(errMsg);
    sqlite3_close(db);
    
    return !failed;
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

- (NSDate *) dateFromDatabaseEntry:(NSTimeInterval)dbEntry {
    return [NSDate dateWithTimeIntervalSince1970:dbEntry];
}

@end