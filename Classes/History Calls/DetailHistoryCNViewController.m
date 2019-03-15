//
//  DetailHistoryCNViewController.m
//  linphone
//
//  Created by user on 18/3/14.
//
//

#import "DetailHistoryCNViewController.h"
#import "NewHistoryDetailCell.h"
#import "HistoryCallDetailTableViewCell.h"
#import "CallHistoryObject.h"
#import "NSData+Base64.h"

@interface DetailHistoryCNViewController ()<UIAlertViewDelegate> {
    NSMutableArray *listHistoryCalls;
    UIFont *textFont;
    BOOL newLayout;
}
@end

@implementation DetailHistoryCNViewController

@synthesize _viewHeader, _iconBack, _lbHeader, _imgAvatar, _lbName, icDelete, _tbHistory, lbPhone, viewInfo, iconAudio, iconVideo;
@synthesize phoneNumber, onDate, onlyMissedCall;

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

#pragma mark - View controllers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Property Functions

- (void)setPhoneNumberForView:(NSString *)phone andDate: (NSString *)date onlyMissed: (BOOL)onlyMissed {
    phoneNumber = [[NSString alloc] initWithString:[phone copy]];
    onDate = [[NSString alloc] initWithString:[date copy]];
    onlyMissedCall = onlyMissed;
    
    [self updateView];
    
    //  reset missed call
    [NSDatabase resetMissedCallOfRemote:phoneNumber onDate:onDate ofAccount:USERNAME];
    [[NSNotificationCenter defaultCenter] postNotificationName:k11UpdateBarNotifications object:nil];
}

- (IBAction)btnCallPressed:(UIButton *)sender {
    if (phoneNumber != nil && ![phoneNumber isEqualToString:@""]) {
        [SipUtils makeCallWithPhoneNumber: phoneNumber];
    }else{
        [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"The phone number can not empty"] duration:2.0 position:CSToastPositionCenter];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUIForView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    newLayout = YES;
    
    [WriteLogsUtils writeForGoToScreen:@"DetailHistoryCNViewController"];
    
    [self showContentWithCurrentLanguage];
    
    // Tắt màn hình cảm biến
    UIDevice *device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled: NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView)
                                                 name:reloadHistoryCall object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showContentWithCurrentLanguage {
    if (![AppUtils isNullOrEmpty: phoneNumber]) {
        PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: phoneNumber];
        if (![AppUtils isNullOrEmpty:contact.name]) {
            _lbHeader.text = contact.name;
        }else{
            _lbHeader.text = [[LanguageUtil sharedInstance] getContent:@"Calls detail"];
        }
    }
}

//  Cập nhật view sau khi get xong phone number
- (void)updateView
{
    if ([phoneNumber isEqualToString: hotline]) {
        _lbName.text = [[LanguageUtil sharedInstance] getContent:@"Hotline"];
        _imgAvatar.image = [UIImage imageNamed:@"hotline_avatar.png"];
    }else{
        PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: phoneNumber];
        if (![AppUtils isNullOrEmpty:contact.name]) {
            _lbName.text = contact.name;
        }else{
            _lbName.text = [[LanguageUtil sharedInstance] getContent:@"Unknown"];
        }
        
        if (![AppUtils isNullOrEmpty: contact.avatar]) {
            _imgAvatar.image = [UIImage imageWithData: [NSData dataFromBase64String: contact.avatar]];
        }else{
            _imgAvatar.image = [UIImage imageNamed:@"no_avatar.png"];
        }
        lbPhone.text = phoneNumber;
    }
    
    // Check section
    [listHistoryCalls removeAllObjects];
    if ([AppUtils isNullOrEmpty: onDate]) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Get all list call with phone number %@", __FUNCTION__, phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        [listHistoryCalls addObjectsFromArray: [NSDatabase getAllListCallOfMe:USERNAME withPhoneNumber:phoneNumber]];
    }else{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Get all list call with phone number %@, on date %@", __FUNCTION__, phoneNumber, onDate] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        [listHistoryCalls addObjectsFromArray: [NSDatabase getAllCallOfMe:USERNAME withPhone:phoneNumber onDate:onDate onlyMissedCall: onlyMissedCall]];
    }
    [_tbHistory reloadData];
}

#pragma mark - my functions

- (void)setupUIForView
{
    self.view.backgroundColor = UIColor.whiteColor;
    if (SCREEN_WIDTH > 320) {
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
        
        _lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
    }else{
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:16.0];
        
        _lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    }
    //  header
    float hHeader = 220+[LinphoneAppDelegate sharedInstance]._hStatus;
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    _iconBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [_iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus+5.0);
        make.left.equalTo(_viewHeader);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    icDelete.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [icDelete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_iconBack);
        make.right.equalTo(_viewHeader).offset(-5);
        make.width.equalTo(_iconBack.mas_width);
        make.height.equalTo(_iconBack.mas_height);
    }];
    
    [_lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(_iconBack);
        make.left.equalTo(_iconBack.mas_right).offset(5);
        make.right.equalTo(icDelete.mas_left).offset(-5);
    }];
    
    _imgAvatar.layer.cornerRadius = 100.0/2;
    _imgAvatar.layer.borderWidth = 2.0;
    _imgAvatar.layer.borderColor = UIColor.whiteColor.CGColor;
    _imgAvatar.clipsToBounds = YES;
    [_imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lbHeader.mas_bottom).offset(10);
        make.centerX.equalTo(_viewHeader.mas_centerX);
        make.width.height.mas_equalTo(100.0);
    }];
    
    _lbName.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    _lbName.textColor = UIColor.whiteColor;
    [_lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar.mas_bottom);
        make.left.right.equalTo(_viewHeader);
        make.height.mas_equalTo(30.0);
    }];
    
    lbPhone.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    lbPhone.textColor = UIColor.whiteColor;
    [lbPhone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lbName.mas_bottom);
        make.left.right.equalTo(_viewHeader);
        make.height.mas_equalTo(30.0);
    }];
    
    //  view info
    [viewInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader.mas_bottom);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(80.0);
    }];
    
    iconVideo.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [iconVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(viewInfo);
        make.right.equalTo(viewInfo.mas_centerX).offset(-8.0);
        make.width.height.mas_equalTo(60.0);
    }];
    
    iconAudio.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [iconAudio mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(iconVideo);
        make.left.equalTo(viewInfo.mas_centerX).offset(8.0);
        make.width.mas_equalTo(60.0);
    }];
    
    //  content
    [_tbHistory mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewInfo.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    _tbHistory.delegate = self;
    _tbHistory.dataSource = self;
    _tbHistory.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIView *headerView = [[UIView alloc] init];
    headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 70.0/2);
    headerView.backgroundColor = UIColor.clearColor;
    _tbHistory.tableHeaderView = headerView;
    
    listHistoryCalls = [[NSMutableArray alloc] init];
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint: CGPointMake(0, 0)];
    [path addLineToPoint: CGPointMake(0, hHeader-50)];
    [path addQuadCurveToPoint:CGPointMake(SCREEN_WIDTH, hHeader-50) controlPoint:CGPointMake(SCREEN_WIDTH/2, hHeader+50)];
    [path addLineToPoint: CGPointMake(SCREEN_WIDTH, 0)];
    [path closePath];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer new];
    shapeLayer.path = path.CGPath;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, hHeader+100);
    gradientLayer.startPoint = CGPointMake(0, 1);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.colors = @[(id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor];
    
    //Add gradient layer to view
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    gradientLayer.mask = shapeLayer;
}

#pragma mark - tableview delegate

- (NSString *)convertIntToTime : (int) time{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *startData = [NSDate dateWithTimeIntervalSince1970:time];
    dateFormatter.dateFormat = @"HH:mm";
    NSString *str_time = [dateFormatter stringFromDate:startData];
    return str_time;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)checkDateCurrentAndYesterday: (NSString *)strTime {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[[NSDate alloc] init]];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *today = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0];
    
    [components setHour:-24];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *yesterday = [cal dateByAddingComponents:components toDate: today options:0];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd/MM/yyyy";
    
    if ([strTime isEqualToString:[dateFormatter stringFromDate:yesterday] ]) {
        return [[LanguageUtil sharedInstance] getContent:@"Yesterday"];
    }
    
    if ([strTime isEqualToString:[dateFormatter stringFromDate:today]]) {
        return [[LanguageUtil sharedInstance] getContent:@"Today"];
    }
    
    return strTime;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return listHistoryCalls.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (newLayout) {
        static NSString *identifier = @"HistoryCallDetailTableViewCell";
        HistoryCallDetailTableViewCell *cell = (HistoryCallDetailTableViewCell *)[tableView dequeueReusableCellWithIdentifier: identifier];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"HistoryCallDetailTableViewCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CallHistoryObject *aCall = [listHistoryCalls objectAtIndex: indexPath.row];
        
        cell.lbTime.text = aCall._time;
        cell.lbDuration.text = [AppUtils convertDurtationToString: aCall._duration];
        
        //  Show direction and type call
        if (aCall.typeCall == AUDIO_CALL_TYPE) {
            cell.imgCallType.image = [UIImage imageNamed:@"contact_audio_call.png"];
        }else{
            cell.imgCallType.image = [UIImage imageNamed:@"contact_video_call.png"];
        }
        
        if ([aCall._status isEqualToString: aborted_call]){
            cell.lbCallState.text = [NSString stringWithFormat:@"Bị hủy bỏ"];
            
        }else if ([aCall._status isEqualToString: declined_call]){
            cell.lbCallState.text = [NSString stringWithFormat:@"Bị từ chối"];
            
        }else if ([aCall._status isEqualToString: missed_call]){
            cell.lbCallState.text = [NSString stringWithFormat:@"Cuộc gọi nhỡ"];
            
        }else if ([aCall._status isEqualToString: success_call]){
            cell.lbCallState.text = [NSString stringWithFormat:@"Đã kết nối"];
            
        }else{
            cell.lbCallState.text = @"";
        }
        
        if ([aCall._callDirection isEqualToString: incomming_call]) {
            if ([aCall._status isEqualToString: missed_call]) {
                cell.imgDirection.image = [UIImage imageNamed:@"ic_call_missed.png"];
            }else{
                cell.imgDirection.image = [UIImage imageNamed:@"ic_call_incoming.png"];
            }
        }else{
            cell.imgDirection.image = [UIImage imageNamed:@"ic_call_outgoing.png"];
        }
        
        NSString *dateStr = [AppUtils checkTodayForHistoryCall: onDate];
        
        if (![dateStr isEqualToString:@"Today"]) {
            dateStr = [AppUtils checkYesterdayForHistoryCall: aCall._date];
            if ([dateStr isEqualToString:@"Yesterday"]) {
                dateStr = [[LanguageUtil sharedInstance] getContent:@"Yesterday"];
            }
        }else{
            dateStr = [[LanguageUtil sharedInstance] getContent:@"Today"];
        }
        cell.lbDate.text = dateStr;
        
        return cell;
        
    }else{
        static NSString *identifier = @"NewHistoryDetailCell";
        NewHistoryDetailCell *cell = (NewHistoryDetailCell *)[tableView dequeueReusableCellWithIdentifier: identifier];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NewHistoryDetailCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CallHistoryObject *aCall = [listHistoryCalls objectAtIndex: indexPath.row];
        
        //  cell.lbTime.text = [AppUtils getTimeStringFromTimeInterval: aCall._timeInt];
        cell.lbTime.text = aCall._time;
        cell.lbDuration.text = [AppUtils convertDurtationToString: aCall._duration];
        
        //  Show direction and type call
        if ([aCall._status isEqualToString: aborted_call])
        {
            if (aCall.typeCall == AUDIO_CALL_TYPE) {
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi thoại bị huỷ bỏ"];
            }else{
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi video bị huỷ bỏ"];
            }
            
        }else if ([aCall._status isEqualToString: declined_call]){
            if (aCall.typeCall == AUDIO_CALL_TYPE) {
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi thoại bị từ chối"];
            }else{
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi video bị từ chối"];
            }
            
        }else if ([aCall._status isEqualToString: missed_call]){
            if (aCall.typeCall == AUDIO_CALL_TYPE) {
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi thoại nhỡ"];
            }else{
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi video nhỡ"];
            }
            
        }else if ([aCall._status isEqualToString: success_call]){
            if (aCall.typeCall == AUDIO_CALL_TYPE) {
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi thoại"];
            }else{
                cell.lbState.text = [NSString stringWithFormat:@"Cuộc gọi video"];
            }
            
        }else{
            cell.lbState.text = @"";
        }
        
        if ([aCall._callDirection isEqualToString: incomming_call]) {
            if ([aCall._status isEqualToString: missed_call]) {
                cell.imgStatus.image = [UIImage imageNamed:@"ic_call_missed.png"];
            }else{
                cell.imgStatus.image = [UIImage imageNamed:@"ic_call_incoming.png"];
            }
        }else{
            cell.imgStatus.image = [UIImage imageNamed:@"ic_call_outgoing.png"];
        }
        
        NSString *dateStr = [AppUtils checkTodayForHistoryCall: onDate];
        
        if (![dateStr isEqualToString:@"Today"]) {
            dateStr = [AppUtils checkYesterdayForHistoryCall: aCall._date];
            if ([dateStr isEqualToString:@"Yesterday"]) {
                dateStr = [[LanguageUtil sharedInstance] getContent:@"Yesterday"];
            }
        }else{
            dateStr = [[LanguageUtil sharedInstance] getContent:@"Today"];
        }
        cell.lbDate.text = dateStr;
        
        return cell;
    }
}

- (IBAction)_iconBackClicked:(UIButton *)sender {
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)icDeleteClick:(UIButton *)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Bạn có muốn xoá lịch sử cuộc gọi?" delegate:self cancelButtonTitle:@"Không" otherButtonTitles:@"Xoá", nil];
    alertView.delegate = self;
    [alertView show];
}

- (NSString *)getEventTimeFromDuration:(NSTimeInterval)duration
{
    NSDateComponentsFormatter *cFormatter = [[NSDateComponentsFormatter alloc] init];
    cFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
    cFormatter.includesApproximationPhrase = NO;
    cFormatter.includesTimeRemainingPhrase = NO;
    cFormatter.allowedUnits = NSCalendarUnitHour |NSCalendarUnitMinute | NSCalendarUnitSecond;
    cFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropAll;
    
    return [cFormatter stringFromTimeInterval:duration];
}

- (IBAction)iconAudioClick:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:IS_VIDEO_CALL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [LinphoneAppDelegate sharedInstance].phoneForCall = phoneNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:getDIDListForCall object:nil];
}

- (IBAction)iconVideoClick:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:IS_VIDEO_CALL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [LinphoneAppDelegate sharedInstance].phoneForCall = phoneNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:getDIDListForCall object:nil];
}

#pragma mark - Alertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                             toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        [NSDatabase deleteCallHistoryOfRemote:phoneNumber onDate:onDate ofAccount:USERNAME];
        [[PhoneMainView instance] popCurrentView];
    }
}

@end

