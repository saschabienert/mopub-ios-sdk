//
//  HZDatabaseHelper.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/4/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface HZDatabaseHelper : NSObject

+ (sqlite3 *) openDatabaseWithName:(NSString *)dbName error:(NSError **)error;

@end