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
    float wIconState;
    float hStateLabel;
    
    NSTimer *onTimerUp1 ;
    NSTimer *onTimerUp2;
    NSTimer *onTimerUp3;
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
    
    [self addTransparentLayerForView];
    
    [self turnOnCircle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
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
    
    _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Calling"];
    _imgCallState.image = [UIImage imageNamed:@"icon_calling"];
    [self updateStateCallForView];
    
    // basic setup
    PulsingHaloLayer *layer = [PulsingHaloLayer layer];
    self.halo = layer;
    [_imgAvatar.superview.layer insertSublayer:self.halo below:_imgAvatar.layer];
    [self setupInitialValuesWithNumLayer:5 radius:0.8 duration:0.45 color:[UIColor colorWithRed:(220/255.0) green:(220/255.0) blue:(220/255.0) alpha:0.7]];
    [self.halo start];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(callUpdateEvent:)
                                               name:kLinphoneCallUpdate
                                             object:nil];
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

- (void)addTransparentLayerForView {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    gradient.colors = @[(id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor];
    [self.view.layer insertSublayer:gradient atIndex:0];
}

- (void)setPhoneNumberForView: (NSString *)phoneNumber {
    _phoneNumber = phoneNumber;
}

- (void)updateStateCallForView {
    [_lbCallState sizeToFit];
    NSLog(@"%f", _lbCallState.frame.size.width);
    
    float originX = (SCREEN_WIDTH - (wIconState + 10 + _lbCallState.frame.size.width))/2;
    _imgCallState.frame = CGRectMake(originX, _lbCallState.frame.origin.y+4, wIconState, wIconState);
    _lbCallState.frame = CGRectMake(_imgCallState.frame.origin.x+wIconState+10, _lbCallState.frame.origin.y, _lbCallState.frame.size.width, hStateLabel);
}

- (void)setupUIForView {
    float margin = 25.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE] || [deviceMode isEqualToString: simulator])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        wAvatar = 90.0;
        wSmallIcon = 45.0;
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        wAvatar = 110.0;
        
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
        wIconEndCall = 70.0;
        wSmallIcon = 50.0;
        wIconState = 15.0;
        hStateLabel = 25.0;
        
        textFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size:24.0];
        textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
    }else{
        wIconEndCall = 60.0;
        
        wIconState = 15.0;
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
        make.bottom.equalTo(_lbCallState.mas_top);
        make.width.height.mas_equalTo(25.0);
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

- (void) turnOnCircle {
    return;
    [self addanimateCircle1];
    [self addanimateCircle2];
    [self addanimateCircle3];
    onTimerUp1 = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addanimateCircle1) userInfo:nil repeats:YES];
    
    onTimerUp2 = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addanimateCircle2) userInfo:nil repeats:YES];
    onTimerUp3 = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addanimateCircle3) userInfo:nil repeats:YES];
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
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Calling"];
            _imgCallState.image = [UIImage imageNamed:@"icon_calling"];
            break;
        }
        case LinphoneCallOutgoingRinging:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Ringing"];
            _imgCallState.image = [UIImage imageNamed:@"icon_ringing"];
            break;
        }
        case LinphoneCallOutgoingEarlyMedia:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Calling"];
            _imgCallState.image = [UIImage imageNamed:@"icon_calling"];
            break;
        }
        case LinphoneCallConnected:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey:@"Connected"];
            
            break;
        }
        case LinphoneCallStreamsRunning: {
            _lbCallState.text = @"Streams Running";
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
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Terminated"];
            _imgCallState.image = [UIImage imageNamed:@"icon_state_endcall"];
            break;
        }
        case LinphoneCallError:{
            _imgCallState.image = [UIImage imageNamed:@"icon_state_endcall"];
            
            switch (linphone_call_get_reason(call)) {
                case LinphoneReasonNotFound:
                    NSLog(@"123");
                    break;
                case LinphoneReasonBusy:{
                    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
                    if (count > 0) {
                        [[PhoneMainView instance] popToView:CallView.compositeViewDescription];
                    }{
                        NSString *reason = [NSString stringWithFormat:@"%@ %@", userName, [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey:@"Busy"]];
                        _lbCallState.text = reason;
                    }
                    break;
                }
                default:
                    _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: @"Terminated"];
                    break;
            }
            break;
        }
        default:
            break;
    }
    [self updateStateCallForView];
}

#pragma mark - Animation
- (void)addanimateCircle1 {
    
    CGFloat scale = 5.5;
    CGFloat width = _imgAvatar.bounds.size.width, height = _imgAvatar.bounds.size.height;
    CAShapeLayer *circleShape = [self createCircleShapeWithPosition:CGPointMake(_imgAvatar.center.x, _imgAvatar.center.y)
                                                           pathRect:CGRectMake(-CGRectGetMidX(_imgAvatar.bounds), -CGRectGetMidY(_imgAvatar.bounds), width, height)
                                                             radius:_imgAvatar.layer.cornerRadius];
    [self.view.layer addSublayer:circleShape];
    [circleShape addAnimation:[self createFlashAnimationWithScale:scale duration:3.0f] forKey:nil];
}

- (void)addanimateCircle2 {
    
    CGFloat scale = 3.0;
    CGFloat width = _imgAvatar.bounds.size.width, height = _imgAvatar.bounds.size.height;
    CAShapeLayer *circleShape = [self createCircleShapeWithPosition:CGPointMake(_imgAvatar.center.x, _imgAvatar.center.y)
                                                           pathRect:CGRectMake(-CGRectGetMidX(_imgAvatar.bounds), -CGRectGetMidY(_imgAvatar.bounds), width, height)
                                                             radius:_imgAvatar.layer.cornerRadius];
    [self.view.layer addSublayer:circleShape];
    [circleShape addAnimation:[self createFlashAnimationWithScale:scale duration:2.0f] forKey:nil];
}

- (void)addanimateCircle3 {
    
    CGFloat scale = 1.7;
    CGFloat width = _imgAvatar.bounds.size.width, height = _imgAvatar.bounds.size.height;
    CAShapeLayer *circleShape = [self createCircleShapeWithPosition:CGPointMake(_imgAvatar.center.x, _imgAvatar.center.y)
                                                           pathRect:CGRectMake(-CGRectGetMidX(_imgAvatar.bounds), -CGRectGetMidY(_imgAvatar.bounds), width, height)
                                                             radius:_imgAvatar.layer.cornerRadius];
    [self.view.layer addSublayer:circleShape];
    [circleShape addAnimation:[self createFlashAnimationWithScale:scale duration:1.5f] forKey:nil];
}

- (CAAnimationGroup *)createFlashAnimationWithScale:(CGFloat)scale duration:(CGFloat)duration
{
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale, scale, 1)];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;
    
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.delegate = self;
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return animation;
}

- (CAShapeLayer *)createCircleShapeWithPosition:(CGPoint)position pathRect:(CGRect)rect radius:(CGFloat)radius
{
    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = [self createCirclePathWithRadius:rect radius:radius];
    circleShape.position = position;
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.strokeColor = [UIColor lightGrayColor].CGColor;
    
    circleShape.opacity = 0;
    circleShape.lineWidth = 0.3;
    
    return circleShape;
}

- (CGPathRef)createCirclePathWithRadius:(CGRect)frame radius:(CGFloat)radius
{
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius].CGPath;
}

@end
