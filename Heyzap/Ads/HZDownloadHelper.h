//
//  HZDownloadHelper.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZAFHTTPRequestOperation;

@interface HZDownloadHelper : NSObject
+ (HZAFHTTPRequestOperation *) downloadURL: (NSURL *) url toFilePath: (NSString *) filePath forTag:(NSString *) tag andType:(NSString *)type withCompletion:(void (^)(BOOL result))completion;
@end