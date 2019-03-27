//
//  RecordsListViewController.m
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import "RecordsListViewController.h"
#import "RecordAudioCallCell.h"

@interface RecordsListViewController (){
    NSMutableArray *listRecords;
    float hCell;
}

@end

@implementation RecordsListViewController
@synthesize viewHeader, bgHeader, icBack, lbHeader, icSend, tbList;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:nil
                                                               sideMenu:nil
                                                             fullscreen:NO
                                                         isLeftFragment:YES
                                                           fragmentWith:nil];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self autoLayoutForView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self reloadRecordsListFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadRecordsListFile {
    if (listRecords == nil) {
        listRecords = [[NSMutableArray alloc] init];
    }else{
        [listRecords removeAllObjects];
    }
    [listRecords addObjectsFromArray:[AppUtils getAllFilesInDirectory:recordsFolderName]];
    [tbList reloadData];
}

- (void)autoLayoutForView {
    if (SCREEN_WIDTH > 320) {
        icBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        hCell = 60.0;
    }else{
        icBack.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
        hCell = 50.0;
    }
    
    //  header view
    [viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo([LinphoneAppDelegate sharedInstance]._hRegistrationState);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewHeader);
    }];
    
    lbHeader.font = [LinphoneAppDelegate sharedInstance].headerFontNormal;
    [lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.bottom.equalTo(viewHeader);
        make.centerX.equalTo(viewHeader.mas_centerX);
        make.width.mas_equalTo(200);
    }];
    
    [icBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(viewHeader);
        make.centerY.equalTo(lbHeader.mas_centerY);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    [icSend setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [icSend setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
    [icSend mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(viewHeader).offset(-10.0);
        make.centerY.equalTo(lbHeader.mas_centerY);
        make.width.mas_equalTo(80.0);
        make.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    tbList.backgroundColor = UIColor.clearColor;
    [tbList mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader.mas_bottom);
        make.bottom.left.right.equalTo(self.view);
    }];
    tbList.delegate = self;
    tbList.dataSource = self;
    tbList.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - UITableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return listRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"RecordAudioCallCell";
    RecordAudioCallCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RecordAudioCallCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSString *fileName = [listRecords objectAtIndex: indexPath.row];
    cell.lbName.text = fileName;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return hCell;
}

@end
