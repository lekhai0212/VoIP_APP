//
//  RecordsListViewController.m
//  linphone
//
//  Created by lam quang quan on 3/27/19.
//

#import "RecordsListViewController.h"
#import "RecordAudioCallCell.h"
#import <AVFoundation/AVAudioPlayer.h>
#import <AVKit/AVKit.h>

@interface RecordsListViewController (){
    NSMutableArray *listRecords;
    float hCell;
    
    UIView *optionsView;
    UIButton *btnSend;
    UIButton *btnDelete;
    BOOL isEdit;
    NSMutableArray *listChoosed;
    UIActivityIndicatorView *icWaiting;
}

@end

@implementation RecordsListViewController
@synthesize viewHeader, bgHeader, icBack, lbHeader, icChoose, tbList;

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
    
    [self createOptionsView];
    [self autoLayoutForView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [WriteLogsUtils writeForGoToScreen:@"RecordsCallViewController"];
    
    if (listChoosed == nil) {
        listChoosed = [[NSMutableArray alloc] init];
    }else{
        [listChoosed removeAllObjects];
    }
    
    btnSend.enabled = NO;
    [btnSend setTitle:@"Gửi" forState:UIControlStateNormal];
    btnDelete.enabled = NO;
    [btnDelete setTitle:@"Xoá" forState:UIControlStateNormal];
    
    [self reloadRecordsListFile];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (tbList.frame.size.height < tbList.contentSize.height) {
        tbList.scrollEnabled = YES;
    }else{
        tbList.scrollEnabled = NO;
    }
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

- (IBAction)icBackClick:(UIButton *)sender {
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)icChoosePress:(UIButton *)sender {
    if (!isEdit) {
        isEdit = YES;
        [sender setTitle:@"Hủy" forState:UIControlStateNormal];
        [self displayOptionView: YES];
    }else{
        isEdit = NO;
        [sender setTitle:@"Chọn" forState:UIControlStateNormal];
        [self displayOptionView: NO];
        
        [listChoosed removeAllObjects];
    }
    [self updateViewWithList];
    [tbList reloadData];
}

- (void)updateViewWithList {
    if (listChoosed.count > 0) {
        btnSend.enabled = YES;
        btnDelete.enabled = YES;
        [btnSend setTitle:[NSString stringWithFormat:@"Gửi (%d)", (int)listChoosed.count] forState:UIControlStateNormal];
        [btnDelete setTitle:[NSString stringWithFormat:@"Xoá (%d)", (int)listChoosed.count] forState:UIControlStateNormal];
    }else{
        btnSend.enabled = NO;
        btnDelete.enabled = NO;
        [btnSend setTitle:@"Gửi" forState:UIControlStateNormal];
        [btnDelete setTitle:@"Xoá" forState:UIControlStateNormal];
    }
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
    
    icChoose.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [icChoose setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [icChoose setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
    [icChoose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(viewHeader).offset(-10.0);
        make.centerY.equalTo(lbHeader.mas_centerY);
        make.width.mas_equalTo(80.0);
        make.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    tbList.backgroundColor = UIColor.clearColor;
    [tbList mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(optionsView.mas_top);
    }];
    tbList.delegate = self;
    tbList.dataSource = self;
    tbList.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)createOptionsView {
    optionsView = [[UIView alloc] init];
    optionsView.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0)
                                                   blue:(235/255.0) alpha:1.0];
    optionsView.clipsToBounds = YES;
    [self.view addSubview: optionsView];
    [optionsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(0);
    }];
    
    btnSend = [[UIButton alloc] init];
    btnSend.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btnSend.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [btnSend setTitle:@"Gửi" forState:UIControlStateNormal];
    [btnSend setTitleColor:[UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                            blue:(70/255.0) alpha:1.0]
                  forState:UIControlStateNormal];
    [btnSend setTitleColor:UIColor.darkGrayColor forState:UIControlStateDisabled];
    [optionsView addSubview: btnSend];
    [btnSend mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optionsView).offset(20.0);
        make.centerY.equalTo(optionsView.mas_centerY);
        make.width.mas_equalTo(100.0);
        make.height.mas_equalTo(40.0);
    }];
    [btnSend addTarget:self
                action:@selector(btnSendClicked)
      forControlEvents:UIControlEventTouchUpInside];
    
    
    //  delete button
    btnDelete = [[UIButton alloc] init];
    btnDelete.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    btnDelete.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [btnDelete setTitle:@"Xoá" forState:UIControlStateNormal];
    [btnDelete setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [btnDelete setTitleColor:UIColor.darkGrayColor forState:UIControlStateDisabled];
    [optionsView addSubview: btnDelete];
    [btnDelete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(optionsView).offset(-20.0);
        make.centerY.equalTo(optionsView.mas_centerY);
        make.width.mas_equalTo(100.0);
        make.height.mas_equalTo(40.0);
    }];
    [btnDelete addTarget:self
                  action:@selector(deleteRecordAudioFile)
        forControlEvents:UIControlEventTouchUpInside];
    
    icWaiting = [[UIActivityIndicatorView alloc] init];
    icWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    icWaiting.backgroundColor = UIColor.whiteColor;
    icWaiting.alpha = 0.5;
    icWaiting.hidden = YES;
    [self.view addSubview: icWaiting];
    [icWaiting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
}

- (void)displayOptionView: (BOOL)show {
    float height = 50.0;
    if (!show) {
        height = 0;
        
    }
    [optionsView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(height);
    }];
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    if (listChoosed.count > 0) {
        btnSend.enabled = btnDelete.enabled = YES;
    }else{
        btnSend.enabled = btnDelete.enabled = NO;
    }
}

- (void)onIconButtonClicked: (UIButton *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    RecordAudioCallCell *curCell = [tbList cellForRowAtIndexPath: indexPath];
    if ([listChoosed containsObject:curCell.lbName.text]) {
        [listChoosed removeObject: curCell.lbName.text];
        [curCell.btnChoose setImage:[UIImage imageNamed:@"ic_not_check"]
                           forState:UIControlStateNormal];
    }else{
        [listChoosed addObject: curCell.lbName.text];
        [curCell.btnChoose setImage:[UIImage imageNamed:@"ic_checked"]
                           forState:UIControlStateNormal];
    }
    [self updateViewWithList];
}

- (void)deleteRecordAudioFile {
    [icWaiting startAnimating];
    icWaiting.hidden = NO;
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (listChoosed.count > 0) {
        for (int i=0; i<listChoosed.count; i++) {
            NSString *filename = [listChoosed objectAtIndex: i];
            NSString *subPath = [NSString stringWithFormat:@"%@/%@", recordsFolderName, filename];
            NSString *path = [documentDir stringByAppendingPathComponent: subPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath: path]) {
                BOOL removedSuccess = [AppUtils deleteFileWithPath: path];
                if (removedSuccess) {
                    NSLog(@"Removed file with name %@", filename);
                }
            }else{
                
            }
            
        }
    }
    [listChoosed removeAllObjects];
    isEdit = NO;
    
    [self reloadRecordsListFile];
    [self updateViewWithList];
    [tbList reloadData];
    
    [self displayOptionView: NO];
    [icChoose setTitle:@"Chọn" forState:UIControlStateNormal];
    
    [icWaiting stopAnimating];
    icWaiting.hidden = YES;
    [self.view makeToast:@"File ghi âm đã được xoá thành công." duration:2.0 position:CSToastPositionCenter];
}

- (void)openAudioRecordFileWithName: (NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *url = [paths objectAtIndex:0];
    NSString *localFile = [NSString stringWithFormat:@"%@/%@/%@", url, recordsFolderName, filename];
    NSURL *audioURL = [NSURL fileURLWithPath: localFile];
    //init player
    AVPlayer *player = [AVPlayer playerWithURL: audioURL];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.showsPlaybackControls = YES;
    playerViewController.player = player;
    //  [self presentViewController:playerViewController animated:YES completion:nil];
    [player play];
    
    [self.view.window.rootViewController presentViewController:playerViewController animated:YES completion:nil];
}

- (void)btnSendClicked {
    if ([MFMailComposeViewController canSendMail]) {
        BOOL networkReady = [DeviceUtils checkNetworkAvailable];
        if (!networkReady) {
            [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"Please check your internet connection!"] duration:2.0 position:CSToastPositionCenter];
            return;
        }
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        
        NSString *emailTitle =  @"";
        NSString *messageBody = @"";
        NSArray *toRecipents = [NSArray arrayWithObject:@""];
        
        for (int i=0; i<listChoosed.count; i++)
        {
            NSString *fileName = [listChoosed objectAtIndex: i];
            NSString *path = [NgnFileUtils getPathOfFileWithSubDir:[NSString stringWithFormat:@"%@/%@", recordsFolderName, fileName]];
            NSData *fileData = [[NSFileManager defaultManager] contentsAtPath: path];
            if (fileData != nil) {
                [mc addAttachmentData:fileData mimeType:@"audio/wav" fileName:fileName];
            }
        }
        mc.mailComposeDelegate = self;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        [mc setToRecipients:toRecipents];
        
        [self presentViewController:mc animated:YES completion:NULL];
    }else{
        [self.view makeToast:@"Không thể gửi. Vui lòng kiểm tra thông tin tài khoản email của bạn!" duration:3.0 position:CSToastPositionCenter];
    }
}

#pragma mark - Email
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (error) {
        [self.view makeToast:@"Gửi không thành công. Vui lòng thử lại sau!" duration:2.0 position:CSToastPositionCenter];
    }else{
        [self.view makeToast:@"Email của bạn đã được gửi thành công." duration:2.0 position:CSToastPositionCenter];
    }
    [self performSelector:@selector(goBack) withObject:nil afterDelay:2.0];
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:NULL];
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
    
    [cell updateFrameForEdit: isEdit];
    cell.btnChoose.tag = indexPath.row;
    [cell.btnChoose addTarget:self
                       action:@selector(onIconButtonClicked:)
             forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isEdit) {
        RecordAudioCallCell *curCell = [tableView cellForRowAtIndexPath: indexPath];
        if ([listChoosed containsObject:curCell.lbName.text]) {
            [listChoosed removeObject: curCell.lbName.text];
            [curCell.btnChoose setImage:[UIImage imageNamed:@"ic_not_check"]
                               forState:UIControlStateNormal];
        }else{
            [listChoosed addObject: curCell.lbName.text];
            [curCell.btnChoose setImage:[UIImage imageNamed:@"ic_checked"]
                               forState:UIControlStateNormal];
        }
        [self updateViewWithList];
    }else{
        NSString *filename = [listRecords objectAtIndex: indexPath.row];
        if (![AppUtils isNullOrEmpty: filename]) {
            [self openAudioRecordFileWithName: filename];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return hCell;
}


@end
