//
//  RecordsFileListView.m
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import "RecordsFileListView.h"
#import "RecordAudioCallCell.h"

@implementation RecordsFileListView
@synthesize viewHeader, bgHeader, icBack, lbHeader, icSend, tbList, listRecords, hCell;

- (void)setupUIForView {
    if (SCREEN_WIDTH > 320) {
        icBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        hCell = 60.0;
    }else{
        icBack.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
        hCell = 50.0;
    }
    
    //  header view
    [viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo([LinphoneAppDelegate sharedInstance]._hRegistrationState);
    }];
    
    [icBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(viewHeader);
        make.centerY.equalTo(lbHeader.mas_centerY);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
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
        make.bottom.left.right.equalTo(self);
    }];
    tbList.delegate = self;
    tbList.dataSource = self;
    tbList.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)reloadDataForView {
    if (listRecords == nil) {
        listRecords = [[NSMutableArray alloc] init];
    }
    [listRecords removeAllObjects];
    [listRecords addObjectsFromArray:[AppUtils getAllFilesInDirectory:recordsFolderName]];
    [tbList reloadData];
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
