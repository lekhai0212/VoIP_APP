//
//  PBXGroupsViewController.m
//  linphone
//
//  Created by lam quang quan on 5/16/19.
//

#import "PBXGroupsViewController.h"
#import "WebServices.h"
#import "PBXContactTableCell.h"

@interface PBXGroupsViewController ()<WebServicesDelegate, UITableViewDelegate, UITableViewDataSource> {
    WebServices *webService;
    NSMutableArray *listGroup;
    NSMutableArray *listQueuename;
    
    NSMutableDictionary *contactSections;
    float hSection;
    
}
@end

@implementation PBXGroupsViewController
@synthesize tbGroup;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupUIForView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    if (webService == nil) {
        webService = [[WebServices alloc] init];
        webService.delegate = self;
    }
    
    if (listGroup == nil) {
        listGroup = [[NSMutableArray alloc] init];
    }
    [listGroup removeAllObjects];
    
    if (listQueuename == nil) {
        listQueuename = [[NSMutableArray alloc] init];
    }
    [listQueuename removeAllObjects];
    
    [self getPBXGroupContacts];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    webService = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getPBXGroupContacts {
    NSString *params = [NSString stringWithFormat:@"username=%@", USERNAME];
    [webService callGETWebServiceWithFunction:GetServerGroup andParams:params];
}

- (void)setupUIForView {
    hSection = 50.0;
    
    tbGroup.separatorStyle = UITableViewCellSelectionStyleNone;
    tbGroup.delegate = self;
    tbGroup.dataSource = self;
    [tbGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
}

- (void)prepareDataToDisplay: (NSArray *)data {
    [listGroup addObjectsFromArray:(NSArray *)data];
    for (int index=0; index<listGroup.count; index++) {
        NSDictionary *info = [listGroup objectAtIndex: index];
        NSString *queuename = [info objectForKey:@"queuename"];
        if (![AppUtils isNullOrEmpty: queuename]) {
            [listQueuename addObject: queuename];
        }
    }
    [tbGroup reloadData];
}

#pragma mark - Webservice Delegate

- (void)failedToCallWebService:(NSString *)link andError:(id)error
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] link: %@.\nResponse data: %@", __FUNCTION__, link, @[error]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] link: %@.\nResponse data: %@", __FUNCTION__, link, @[data]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: GetServerGroup]) {
        if (data != nil && [data isKindOfClass:[NSArray class]]) {
            [self prepareDataToDisplay: (NSArray *)data];
        }
    }
}

- (void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    NSLog(@"%d", responeCode);
}

#pragma mark - UITableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[contactSections allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSString *str = [[[contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
    return [[contactSections objectForKey:str] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PBXContactTableCell";
    PBXContactTableCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"PBXContactTableCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    
//    members =     (
//                   {
//                       name = "T\U00ean 201";
//                       num = 201;
//                   },
//                   {
//                       name = "thiep hoang";
//                       num = 203;
//                   }
//                   );
//    queue = 1000;
//    queuename = "nh\U00f3m test 1000";
    
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, hSection)];
    headerView.backgroundColor = UIColor.whiteColor;
    
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(marginLeft, 0, 150, hSection)];
    descLabel.textColor = [UIColor colorWithRed:(50/255.0) green:(50/255.0)
                                           blue:(50/255.0) alpha:1.0];
    descLabel.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
    if ([titleHeader isEqualToString:@"z#"]) {
        descLabel.text = @"#";
    }else{
        descLabel.text = titleHeader;
    }
    descLabel.backgroundColor = UIColor.clearColor;
    [headerView addSubview: descLabel];
    return headerView;
}

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
//    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray: [[contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
//
//    int iCount = 0;
//    while (iCount < tmpArr.count) {
//        NSString *title = [tmpArr objectAtIndex: iCount];
//        if ([title isEqualToString:@"z#"]) {
//            [tmpArr replaceObjectAtIndex:iCount withObject:@"#"];
//            break;
//        }
//        iCount++;
//    }
//    return tmpArr;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return hSection;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

@end
