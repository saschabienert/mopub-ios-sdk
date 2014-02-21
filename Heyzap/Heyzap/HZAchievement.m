//
//  Achievement.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZAchievement.h"

@interface HZAchievement()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *imageURLString;
@property (nonatomic) BOOL isNew;
@property (nonatomic) BOOL unlocked;

@end

@implementation HZAchievement

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>: title: %@; subtitle: %@; imageURLString: %@; isUnlocked:%i; isNew:%i",[self class],self.title,self.subtitle,self.imageURLString,self.unlocked,self.isNew];
}

- (NSURL *)imageURL
{
    return [NSURL URLWithString:self.imageURLString];
}

- (HZAchievement *)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle imageURLString:(NSString *)imageURLString isNew:(BOOL)isNew
{
    self = [super init];
    if (self) {
        _title = title;
        _subtitle = subtitle;
        _imageURLString = imageURLString;
        _isNew = isNew;
    }
    return self;
}

- (HZAchievement *)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.title = [dictionary objectForKey:@"name"];
        self.imageURLString = [dictionary objectForKey:@"image_url"];
        self.subtitle = [dictionary objectForKey:@"description"];
        
        self.isNew = [[dictionary objectForKey:@"just_unlocked"] boolValue];
        self.unlocked = [[dictionary objectForKey:@"unlocked"] boolValue];
    }
    return self;
    
}

@end
