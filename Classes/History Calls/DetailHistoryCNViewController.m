//
//  DetailHistoryCNViewController.m
//  linphone
//
//  Created by user on 18/3/14.
//
//

#import "DetailHistoryCNViewController.h"
#import "NewContactViewController.h"
#import "AllContactListViewController.h"
#import "UIHistoryDetailCell.h"
#import "NewHistoryDetailCell.h"
#import "CallHistoryObject.h"
#import "NSData+Base64.h"

@interface DetailHistoryCNViewController () {
    LinphoneAppDelegate *appDelegate;
    NSMutableArray *listHistoryCalls;
    UIFont *textFont;
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
    
    // MY CODE HERE
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setupUIForView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Get all list call with phone number %@", __FUNCTION__, phoneNumber] toFilePath:appDelegate.logFilePath];
        
        [listHistoryCalls addObjectsFromArray: [NSDatabase getAllListCallOfMe:USERNAME withPhoneNumber:phoneNumber]];
    }else{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Get all list call with phone number %@, on date %@", __FUNCTION__, phoneNumber, onDate] toFilePath:appDelegate.logFilePath];
        
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
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
    if (aCall._duration == 0) {
        cell.lbDuration.text = [NSString stringWithFormat:@"%d %@", aCall._duration, [[LanguageUtil sharedInstance] getContent:@"sec"]];
    }else{
        if (aCall._duration < 60) {
            cell.lbDuration.text = [NSString stringWithFormat:@"%d %@", aCall._duration, [[LanguageUtil sharedInstance] getContent:@"sec"]];
        }else{
            int hour = aCall._duration/3600;
            int minutes = (aCall._duration - hour*3600)/60;
            int seconds = aCall._duration - hour*3600 - minutes*60;
            
            NSString *str = @"";
            if (hour > 0) {
                if (hour == 1) {
                    str = [NSString stringWithFormat:@"%ld %@", (long)hour, [[LanguageUtil sharedInstance] getContent:@"hour"]];
                }else{
                    str = [NSString stringWithFormat:@"%ld %@", (long)hour, [[LanguageUtil sharedInstance] getContent:@"hours"]];
                }
            }
            
            if (minutes > 0) {
                if (![str isEqualToString:@""]) {
                    if (minutes == 1) {
                        str = [NSString stringWithFormat:@"%@ %d %@", str, minutes, [[LanguageUtil sharedInstance] getContent:@"minute"]];
                    }else{
                        str = [NSString stringWithFormat:@"%@ %d %@", str, minutes, [[LanguageUtil sharedInstance] getContent:@"minutes"]];
                    }
                }else{
                    if (minutes == 1) {
                        str = [NSString stringWithFormat:@"%d %@", minutes, [[LanguageUtil sharedInstance] getContent:@"minute"]];
                    }else{
                        str = [NSString stringWithFormat:@"%d %@", minutes, [[LanguageUtil sharedInstance] getContent:@"minutes"]];
                    }
                }
            }
            
            if (seconds > 0) {
                if (![str isEqualToString:@""]) {
                    str = [NSString stringWithFormat:@"%@ %d %@", str, seconds, [[LanguageUtil sharedInstance] getContent:@"sec"]];
                }else{
                    str = [NSString stringWithFormat:@"%d %@", seconds, [[LanguageUtil sharedInstance] getContent:@"sec"]];
                }
            }
            cell.lbDuration.text = str;
        }
    }
    
    if ([aCall._status isEqualToString: aborted_call] || [aCall._status isEqualToString: declined_call]) {
        cell.lbState.text = [[LanguageUtil sharedInstance] getContent:@"Aborted call"];
    }else if ([aCall._status isEqualToString: missed_call]){
        cell.lbState.text = [[LanguageUtil sharedInstance] getContent:@"Missed call"];
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

- (IBAction)_iconBackClicked:(UIButton *)sender {
    appDelegate._newContact = nil;
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)_iconAddNewClicked:(UIButton *)sender {
    UIActionSheet *popupAddContact = [[UIActionSheet alloc] initWithTitle:phoneNumber delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Cancel"] destructiveButtonTitle:nil otherButtonTitles:
                                      [[LanguageUtil sharedInstance] getContent:@"Create new contact"],
                                      [[LanguageUtil sharedInstance] getContent:@"Add to existing contact"],
                                      nil];
    popupAddContact.tag = 100;
    [popupAddContact showInView:self.view];
}

- (IBAction)icDeleteClick:(UIButton *)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:appDelegate.logFilePath];
    
    [NSDatabase deleteCallHistoryOfRemote:phoneNumber onDate:onDate ofAccount:USERNAME];
    
    appDelegate._newContact = nil;
    [[PhoneMainView instance] popCurrentView];
}

#pragma mark - Actionsheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 100) {
        switch (buttonIndex) {
            case 0:{
                NewContactViewController *controller = VIEW(NewContactViewController);
                if (controller) {
                    if ([phoneNumber hasPrefix:@"778899"]) {
                        controller.currentPhoneNumber = @"";
                        controller.currentName = @"";
                    }else{
                        controller.currentPhoneNumber = phoneNumber;
                        controller.currentName = @"";
                    }
                }
                [[PhoneMainView instance] changeCurrentView:[NewContactViewController compositeViewDescription]
                                                       push:true];
                break;
            }
            case 1:{
                AllContactListViewController *controller = VIEW(AllContactListViewController);
                if (controller != nil) {
                    controller.phoneNumber = phoneNumber;
                }
                [[PhoneMainView instance] changeCurrentView:[AllContactListViewController compositeViewDescription]
                                                       push:true];
                break;
            }
            default:
                break;
        }
    }
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
}

- (IBAction)iconVideoClick:(UIButton *)sender {
}
@end

