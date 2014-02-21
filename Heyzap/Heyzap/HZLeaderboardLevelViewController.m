//
//  HZLeaderboardLevelViewController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 3/29/13.
//
//

#import "HZLeaderboardLevelViewController.h"
#import "HZLeaderboardLevel.h"
#import "HeyzapSDKPrivate.h"
#import "HZLeaderboardLevelCell.h"
#import "HZLeaderboardPopup.h"

@interface HZLeaderboardLevelViewController ()

@property (nonatomic) NSString *appID;
@property (nonatomic) NSArray *levels;

@end

@implementation HZLeaderboardLevelViewController

- (id) init {
    self = [super initWithStyle: UITableViewStylePlain];
    if (self) {
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:239/255.0f alpha:1];
        self.tableView.separatorColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.autoresizesSubviews = NO;
        self.tableView.autoresizingMask = UIViewAutoresizingNone;
        
        [HZLeaderboardLevel levelsWithCompletion:^(NSArray *levels, NSError *error) {
            self.levels = levels;
            [self.tableView reloadData];
        }];
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.levels) {
        return [self.levels count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LeaderboardLevelCell";
    
    HZLeaderboardLevelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HZLeaderboardLevelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < [self.levels count]) { //this could get expensive :-(
        HZLeaderboardLevel *level = [self.levels objectAtIndex: indexPath.row];
        [self configureCell: cell forLevel: level atIndexPath: indexPath];
    } else {
        
    }
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75f];
    
    return cell;
}

- (void)configureCell:(HZLeaderboardLevelCell *)cell forLevel: (HZLeaderboardLevel *) level atIndexPath:(NSIndexPath *)indexPath {
    cell.levelNameLabel.text = level.name;
    
    NSString *text = @"Nobody has played this level yet.";
    if ([level.everyoneCount intValue] > 0) {
        NSString *peopleText = @"person";
        if ([level.everyoneCount intValue] > 1) {
            peopleText = @"people";
        }
        
        text = [NSString stringWithFormat: @"%i %@ have played this level.", [level.everyoneCount intValue], peopleText];
    }
    
    cell.scoreLabel.text = text;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HZLeaderboardLevel *level = [self.levels objectAtIndex: indexPath.row];
    if ([self.delegate respondsToSelector: @selector(selectLevel:)]) {
        [self.delegate selectLevel: level.levelID];
    }
}

@end
