//
//  OutgoingCallViewController.m
//  linphone
//
//  Created by admin on 12/17/17.
//

#import "OutgoingCallViewController.h"
#import "StatusBarView.h"
#import "NSData+Base64.h"
#import "ChooseRouteOutputCell.h"

#define kMaxRadius 200
#define kMaxDuration 10

@interface OutgoingCallViewController ()<UITableViewDelegate, UITableViewDataSource>{
    float wIconEndCall;
    float wSmallIcon;
    float wAvatar;
    float hStateLabel;
    float marginQuality;
    
    UIFont *textFontBold;
    UIFont *textFont;
    
    NSString *userName;
}

@end

@implementation OutgoingCallViewController
@synthesize _imgBackground, _imgAvatar, _lbName, _lbCallState, _btnEndCall, _imgCallState, _btnSpeaker, _btnMute, lbPhone;
@synthesize _phoneNumber;

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:StatusBarView.class
                                                                 tabBar:nil
                                                               sideMenu:nil
                                                             fullscreen:false
                                                         isLeftFragment:YES
                                                           fragmentWith:nil];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  My code here
    [self setupUIForView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    _btnMute.delegate = self;
    
    PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: _phoneNumber];
    
    userName = contact.name;
    
    if ([AppUtils isNullOrEmpty: userName]) {
        userName = [[LanguageUtil sharedInstance] getContent:@"Unknown"];
        _lbName.text = userName;
    }else{
        _lbName.text = userName;
    }
    lbPhone.text = _phoneNumber;
    
    if ([AppUtils isNullOrEmpty: contact.avatar]) {
        _imgAvatar.image = [UIImage imageNamed:@"no_avatar"];
    }else{
        _imgAvatar.image = [UIImage imageWithData:[NSData dataFromBase64String: contact.avatar]];
    }
    
    _btnSpeaker.selected = NO;
    _btnMute.selected = NO;
    
    _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
    
    // basic setup
    PulsingHaloLayer *layer = [PulsingHaloLayer layer];
    self.halo = layer;
    [_imgAvatar.superview.layer insertSublayer:self.halo below:_imgAvatar.layer];
    [self setupInitialValuesWithNumLayer:5 radius:0.8 duration:0.45 color:[UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:0.8]];
    [self.halo start];
    
    //  [Khai Le - 12/02/2019]
    NSString *isVideo = [[NSUserDefaults standardUserDefaults] objectForKey:IS_VIDEO_CALL_KEY];
    if (![AppUtils isNullOrEmpty: isVideo] && [isVideo isEqualToString:@"1"]) {
        _imgCallState.image = [UIImage imageNamed:@"state_video_call"];
    }else{
        _imgCallState.image = [UIImage imageNamed:@"state_audio_call"];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
                                               name:kLinphoneCallUpdate object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForBluetoothEnabled)
                                               name:@"bluetoothEnabled" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForSpeakerEnabled)
                                               name:@"speakerEnabled" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForiPhoneReceiverEnabled)
                                               name:@"iPhoneReceiverEnabled" object:nil];
    
    NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.halo.position = _imgAvatar.center;
}

- (void)setupInitialValuesWithNumLayer: (int)numLayer radius: (float)radius duration: (float)duration color: (UIColor *)color
{
    self.halo.haloLayerNumber = numLayer;
    self.halo.radius = radius * kMaxRadius;
    self.halo.animationDuration = duration * kMaxDuration;
    [self.halo setBackgroundColor:color.CGColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
//    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_btnEndCallPressed:(UIButton *)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [LinphoneAppDelegate sharedInstance]._meEnded = YES;
    
    int numCall = linphone_core_get_calls_nb([LinphoneManager getLc]);
    if (numCall == 0) {
        [LinphoneAppDelegate sharedInstance].phoneNumberEnd = _phoneNumber;
    }
    linphone_core_terminate_all_calls([LinphoneManager getLc]);
    [[PhoneMainView instance] popCurrentView];
}
#pragma mark - My functions

- (void)setPhoneNumberForView: (NSString *)phoneNumber {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] phoneNumber = %@", __FUNCTION__, phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    _phoneNumber = phoneNumber;
}

- (void)setupUIForView {
    float margin = 25.0;
    wIconEndCall = 80.0;
    marginQuality = 50.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE] || [deviceMode isEqualToString: simulator])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        wAvatar = 110.0;
        wIconEndCall = 60.0;
        wSmallIcon = 45.0;
        marginQuality = 30.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        wAvatar = 120.0;
        wIconEndCall = 80.0;
        wSmallIcon = 60.0;
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        //  Screen width: 414.000000 - Screen height: 736.000000
        wAvatar = 130.0;
        wIconEndCall = 80.0;
        wSmallIcon = 60.0;
        margin = 45.0;
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        wAvatar = 110.0;
    }else{
        wAvatar = 90.0;
    }
    
    if (SCREEN_WIDTH > 320) {
        hStateLabel = 25.0;
        textFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size:24.0];
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
    }else{
        hStateLabel = 25.0;
        
        textFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size:20.0];
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:16.0];
    }
    
    [_imgBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    [_imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_centerY);
        make.width.height.mas_equalTo(wAvatar);
    }];
    _imgAvatar.clipsToBounds = YES;
    _imgAvatar.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _imgAvatar.layer.borderWidth = 1.0;
    _imgAvatar.layer.cornerRadius = wAvatar/2;
    
    
    _lbCallState.font = textFont;
    [_lbCallState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(_imgAvatar.mas_top).offset(-marginQuality);
        make.width.mas_equalTo(300.0);
        make.height.mas_equalTo(30.0);
    }];
    
    [_imgCallState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(_lbCallState.mas_top).offset(-5.0);
        make.width.height.mas_equalTo(28.0);
    }];
    
    lbPhone.font = textFont;
    [lbPhone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(_imgCallState.mas_top).offset(-30.0);
        make.height.mas_equalTo(25.0);
        make.width.mas_equalTo(300.0);
    }];
    
    _lbName.font = textFontBold;
    [_lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(lbPhone.mas_top);
        make.height.mas_equalTo(35.0);
        make.width.mas_equalTo(300.0);
    }];
    
    [_btnEndCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view).offset(-40.0);
        make.width.height.mas_equalTo(wIconEndCall);
    }];
    _btnEndCall.layer.cornerRadius = wIconEndCall/2;
    
    //  video speaker
    
    [_btnSpeaker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_btnEndCall.mas_centerY);
        make.left.equalTo(_btnEndCall.mas_right).offset(margin);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    _btnSpeaker.layer.cornerRadius = wSmallIcon/2;
    _btnSpeaker.backgroundColor = UIColor.clearColor;
    
    //  mute button
    [_btnMute mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_btnEndCall.mas_centerY);
        make.right.equalTo(_btnEndCall.mas_left).offset(-margin);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    _btnMute.layer.cornerRadius = wSmallIcon/2;
    _btnMute.backgroundColor = UIColor.clearColor;
}

#pragma mark - Call update event
- (void)callUpdateEvent:(NSNotification *)notif {
    LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
    [self callUpdate:call state:state animated:TRUE];
}

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated
{
    // Fake call update
    if (call == NULL) {
        return;
    }
    switch (state) {
        case LinphoneCallIncomingReceived:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallIncomingReceived", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            break;
        }
        case LinphoneCallOutgoingInit:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallOutgoingInit", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            break;
        }
        case LinphoneCallOutgoingRinging:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallOutgoingRinging", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Ringing"];
            break;
        }
        case LinphoneCallOutgoingEarlyMedia:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallOutgoingEarlyMedia", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            break;
        }
        case LinphoneCallOutgoingProgress:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallOutgoingProgress", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            
            //  [Khai Le -14/02/2019]
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call &&
                (linphone_core_get_calls_nb(LC) < 2)) {
                // Link call ID to UUID
                NSString *callId =
                [NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
                NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:@""];
                if (uuid) {
                    [LinphoneManager.instance.providerDelegate.uuids removeObjectForKey:@""];
                    [LinphoneManager.instance.providerDelegate.uuids setObject:uuid forKey:callId];
                    [LinphoneManager.instance.providerDelegate.calls setObject:callId forKey:uuid];
                }
            }
            
            break;
        }
        case LinphoneCallConnected:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallConnected", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Connected"];
            
            //  [Khai Le - 14/02/2019]
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call) {
                NSString *callId =
                [NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
                NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:callId];
                if (uuid) {
                    [LinphoneManager.instance.providerDelegate.provider reportOutgoingCallWithUUID:uuid
                                                                           startedConnectingAtDate:nil];
                }
            }
            
            break;
        }
        case LinphoneCallStreamsRunning: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallStreamsRunning", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            //  [Khai Le - 14/02/2019]
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call) {
                NSString *callId =
                [NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
                NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:callId];
                if (uuid) {
                    [LinphoneManager.instance.providerDelegate.provider reportOutgoingCallWithUUID:uuid
                                                                                   connectedAtDate:nil];
                    
                    CXCallUpdate *update = [[CXCallUpdate alloc] init];
                    NSString *phoneNumber = [SipUtils getPhoneNumberOfCall:call orLinphoneAddress:nil];
                    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:phoneNumber];
                    update.supportsGrouping = TRUE;
                    update.supportsDTMF = TRUE;
                    update.supportsHolding = TRUE;
                    update.supportsUngrouping = TRUE;
                    [LinphoneManager.instance.providerDelegate.provider reportCallWithUUID:uuid updated:update];
                }
            }
            break;
        }
        case LinphoneCallUpdatedByRemote: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallUpdatedByRemote", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            _lbCallState.text = @"Updated By Remote";
            break;
        }
        case LinphoneCallPausing: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallPausing", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            break;
        }
        case LinphoneCallPaused:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallPaused", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            break;
        }
        case LinphoneCallPausedByRemote:
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallPausedByRemote", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            break;
        case LinphoneCallEnd:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallEnd", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Terminated"];
            break;
        }
        case LinphoneCallError:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call state is LinphoneCallError", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            LinphoneReason reason = linphone_call_get_reason(call);
            switch (reason) {
                case LinphoneReasonNotFound:
                    NSLog(@"123");
                    break;
                case LinphoneReasonBusy:{
                    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
                    if (count > 0) {
                        [[PhoneMainView instance] popToView:CallView.compositeViewDescription];
                    }{
                        NSString *reason = [NSString stringWithFormat:@"%@ %@", userName, [[LanguageUtil sharedInstance] getContent:@"Busy"]];
                        _lbCallState.text = reason;
                    }
                    break;
                }
                default:
                    _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Terminated"];
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - Speaker button delegate
- (void)onSpeakerStateChangedTo:(BOOL)speaker {
    if (speaker) {
        [_btnSpeaker setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
    }else{
        [_btnSpeaker setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
    }
}

- (void)onMuteStateChangedTo:(BOOL)muted {
    if (muted) {
        [_btnMute setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
    }else{
        [_btnMute setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
    }
}

- (IBAction)btnSpeakerPress:(UIButton *)sender {
    if ([DeviceUtils isConnectedEarPhone]) {
        //  [self showOptionChooseRouteOutputForCall];
    }else{
        BOOL isEnabled = LinphoneManager.instance.speakerEnabled;
        if (isEnabled) {
            [sender setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
            [LinphoneManager.instance setSpeakerEnabled: NO];
        }else{
            [sender setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
            [LinphoneManager.instance setSpeakerEnabled: YES];
        }
    }
}

- (void)showOptionChooseRouteOutputForCall {
    UIAlertController * alertViewController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* hideAction = [UIAlertAction actionWithTitle:[[LanguageUtil sharedInstance] getContent:@"Hide"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
    [hideAction setValue:UIColor.redColor forKey:@"titleTextColor"];
    [alertViewController addAction: hideAction];
    
    
    UITableViewController *tbRoutes = [[UITableViewController alloc] init];
    tbRoutes.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tbRoutes.tableView.delegate = self;
    tbRoutes.tableView.scrollEnabled = NO;
    tbRoutes.tableView.dataSource = self;
    [alertViewController setValue:tbRoutes forKey:@"contentViewController"];
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:alertViewController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:58*4];
    [alertViewController.view addConstraint: height];
    
    [self presentViewController:alertViewController animated:YES completion:nil];
}

#pragma mark - UITableview route
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"ChooseRouteOutputCell";
    ChooseRouteOutputCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ChooseRouteOutputCell" owner:nil options:nil] lastObject];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    TypeOutputRoute routeType = [DeviceUtils getCurrentRouteForCall];
    switch (indexPath.row) {
        case 0:{
            cell.lbContent.text = [DeviceUtils getNameOfEarPhoneConnected];
            cell.imgType.image = [UIImage imageNamed:@"route_earphone"];
            cell.imgType.hidden = NO;
            if (routeType == eEarphone) {
                cell.imgSelected.hidden = NO;
            }else{
                cell.imgSelected.hidden = YES;
            }
            break;
        }
        case 1:{
            cell.lbContent.text = @"iPhone";
            cell.imgType.hidden = YES;
            if (routeType == eReceiver) {
                cell.imgSelected.hidden = NO;
            }else{
                cell.imgSelected.hidden = YES;
            }
            break;
        }
        case 2:{
            cell.lbContent.text = [[LanguageUtil sharedInstance] getContent:@"Speaker"];
            cell.imgType.image = [UIImage imageNamed:@"route_speaker"];
            cell.imgType.hidden = NO;
            if (routeType == eSpeaker) {
                cell.imgSelected.hidden = NO;
            }else{
                cell.imgSelected.hidden = YES;
            }
            break;
        }
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:^{
        switch (indexPath.row) {
            case 0:{
                [self setBluetoothEarphoneForCurrentCall];
                break;
            }
            case 1:{
                [self setiPhoneRouteForCall];
                break;
            }
            case 2:{
                [self setSpeakerForCurrentCall];
                break;
            }
            default:
                break;
        }
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58.0;
}

- (void)setSpeakerForCurrentCall {
    [LinphoneManager.instance setSpeakerEnabled:TRUE];
    [self performSelector:@selector(disableBluetooth)
               withObject:nil afterDelay:0.5];
}

- (void)disableBluetooth{
    [LinphoneManager.instance setBluetoothEnabled:FALSE];
}

- (void)enableBluetooth{
    [LinphoneManager.instance setBluetoothEnabled:TRUE];
}

- (void)setBluetoothEarphoneForCurrentCall {
    [LinphoneManager.instance setSpeakerEnabled:TRUE];
    [self performSelector:@selector(enableBluetooth)
               withObject:nil afterDelay:0.25];
}

- (void)setiPhoneRouteForCall {
    [LinphoneManager.instance setSpeakerEnabled:FALSE];
    [self performSelector:@selector(disableBluetooth)
               withObject:nil afterDelay:0.5];
}

- (void)uiForBluetoothEnabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_btnSpeaker setImage:[UIImage imageNamed:@"speaker_bluetooth_enable"] forState:UIControlStateNormal];
    });
}

- (void)uiForSpeakerEnabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_btnSpeaker setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
    });
}

- (void)uiForiPhoneReceiverEnabled{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_btnSpeaker setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
    });
}

@end
