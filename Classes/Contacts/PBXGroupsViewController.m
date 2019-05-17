//
//  PBXGroupsViewController.m
//  linphone
//
//  Created by lam quang quan on 5/16/19.
//

#import "PBXGroupsViewController.h"
#import "WebServices.h"
#import "PBXContactTableCell.h"
#import "GroupHeaderView.h"

@interface PBXGroupsViewController ()<WebServicesDelegate, UITableViewDelegate, UITableViewDataSource> {
    WebServices *webService;
    NSMutableArray *listGroup;
    NSMutableArray *listQueuename;
    
    NSMutableDictionary *contactSections;
    float hSection;
    
    GroupHeaderView *tbHeader;
    
}
@end

@implementation PBXGroupsViewController
@synthesize tbGroup;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupUIForView];
    [self addHeaderForTableContactsView];
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

- (void)addHeaderForTableContactsView {
    NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"GroupHeaderView" owner:nil options:nil];
    for(id currentObject in toplevelObject){
        if ([currentObject isKindOfClass:[GroupHeaderView class]]) {
            tbHeader = (GroupHeaderView *) currentObject;
            break;
        }
    }
    tbHeader.frame = CGRectMake(0, 0, SCREEN_WIDTH, 50.0);
    [tbHeader setupUIForView];
    tbGroup.tableHeaderView = tbHeader;
}

- (void)setupUIForView {
    hSection = 50.0;
    
    tbGroup.backgroundColor = UIColor.orangeColor;
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
    if (tbHeader != nil) {
        if (listQueuename.count == 0) {
            tbHeader.lbTitle.text = @"Chưa có danh sách nhóm";
        }else{
            tbHeader.lbTitle.text = [NSString stringWithFormat:@"Tổng cộng %ld nhóm", listQueuename.count];
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
    return listQueuename.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
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
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, hSection)];
    headerView.backgroundColor = UIColor.whiteColor;
    
    UIImageView *imgArrow = [[UIImageView alloc] init];
    imgArrow.image = [UIImage imageNamed:@"right-arrow"];
    [headerView addSubview: imgArrow];
    [imgArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(headerView).offset(15.0);
        make.centerY.equalTo(headerView.mas_centerY);
        make.width.height.mas_equalTo(18.0);
    }];
    
    UIButton *btnCall = [[UIButton alloc] init];
    btnCall.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [btnCall setImage:[UIImage imageNamed:@"contact_audio_call.png"] forState:UIControlStateNormal];
    [headerView addSubview: btnCall];
    [btnCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(headerView).offset(-7.0);
        make.centerY.equalTo(headerView.mas_centerY);
        make.width.height.mas_equalTo(40.0);
    }];
    
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.textColor = [UIColor colorWithRed:(50/255.0) green:(50/255.0) blue:(50/255.0) alpha:1.0];
    descLabel.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    descLabel.text = [listQueuename objectAtIndex: section];
    descLabel.backgroundColor = UIColor.clearColor;
    [headerView addSubview: descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(btnCall);
        make.left.equalTo(imgArrow.mas_right).offset(10.0);
        make.right.equalTo(btnCall.mas_left).offset(-10.0);
    }];
    
    UILabel *lbSepa = [[UILabel alloc] init];
    lbSepa.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:1.0];
    [headerView addSubview: lbSepa];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(headerView);
        make.height.mas_equalTo(1.0);
    }];
    
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
    return 0;
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
