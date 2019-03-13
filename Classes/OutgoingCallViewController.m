//
//  OutgoingCallViewController.m
//  linphone
//
//  Created by admin on 12/17/17.
//

#import "OutgoingCallViewController.h"
#import "StatusBarView.h"
#import "NSData+Base64.h"

#define kMaxRadius 200
#define kMaxDuration 10

@interface OutgoingCallViewController (){
    float wIconEndCall;
    float wSmallIcon;
    float wAvatar;
    float hStateLabel;
    
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
    
    _btnSpeaker.delegate = self;
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_btnEndCallPressed:(UIButton *)sender {
    int numCall = linphone_core_get_calls_nb([LinphoneManager getLc]);
    if (numCall == 0) {
        [LinphoneAppDelegate sharedInstance].phoneNumberEnd = _phoneNumber;
    }
    linphone_core_terminate_all_calls([LinphoneManager getLc]);
    [[PhoneMainView instance] popCurrentView];
}
#pragma mark - My functions

- (void)setPhoneNumberForView: (NSString *)phoneNumber {
    _phoneNumber = phoneNumber;
}

- (void)setupUIForView {
    float margin = 25.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE] || [deviceMode isEqualToString: simulator])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        wAvatar = 90.0;
        wIconEndCall = 60.0;
        wSmallIcon = 45.0;
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
        wSmallIcon = 55.0;
        margin = 30.0;
        
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
        make.bottom.equalTo(_imgAvatar.mas_top).offset(-50.0);
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
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingInit:{
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            break;
        }
        case LinphoneCallOutgoingRinging:{
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Ringing"];
            break;
        }
        case LinphoneCallOutgoingEarlyMedia:{
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            break;
        }
        case LinphoneCallOutgoingProgress:{
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
            _lbCallState.text = @"Updated By Remote";
            break;
        }
        case LinphoneCallPausing:
        case LinphoneCallPaused:{
            //  Close by Khai Le
            //  [self displayAudioCall:animated];
            break;
        }
        case LinphoneCallPausedByRemote:
            
            break;
        case LinphoneCallEnd:{
            _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Terminated"];
            break;
        }
        case LinphoneCallError:{
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

@end
