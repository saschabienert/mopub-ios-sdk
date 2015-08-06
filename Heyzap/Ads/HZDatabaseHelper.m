//
//  HZDatabaseHelper.m
//  Heyzap
//
//  Created by Monroe Ekilah on 8/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//


#import "HZDatabaseHelper.h"

@implementation HZDatabaseHelper

+ (sqlite3 *) openDatabaseWithName:(NSString *)dbName error:(NSError **)error {
    [HZDatabaseHelper createDatabaseDirectory];
    NSString *dbFilePath = [HZDatabaseHelper databaseDirectoryWithFilename:[NSString stringWithFormat:@"%@.hzdb", dbName]];
    
    sqlite3 *database;
    
    int open = sqlite3_open_v2([dbFilePath UTF8String], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if(open != SQLITE_OK) {
        *error = [HZDatabaseHelper databaseErrorWithString:[NSString stringWithUTF8String:sqlite3_errmsg(database)]];
        sqlite3_close(database); // don't use `sqlite3_close_v2()` for now - http://stackoverflow.com/questions/31821375/sqlite3-close-v2-crashes-on-ios-sqlite3-close-doesnt
        return nil;
    }
    return database;
}


+ (NSString *) databaseDirectoryPath {
    static NSString *cachePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        cachePath = [[pathList objectAtIndex: 0] stringByAppendingPathComponent: @"com.heyzap.sdk.ads"];
    });
    return cachePath;
}

+ (NSString *) databaseDirectoryWithFilename: (NSString *) filename {
    return [[self databaseDirectoryPath] stringByAppendingPathComponent: filename];
}

+ (void) createDatabaseDirectory {
    NSString *databasePath = [self databaseDirectoryPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:databasePath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
}

+ (NSError *) databaseErrorWithString:(NSString *)errorString {
    return [NSError errorWithDomain:@"HZDatabaseHelper" code:1 userInfo:@{NSLocalizedDescriptionKey: errorString}];
}

@end