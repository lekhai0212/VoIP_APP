//
//  OutgoingCallViewController.m
//  linphone
//
//  Created by admin on 12/17/17.
//

#import "OutgoingCallViewController.h"
#import "StatusBarView.h"
#import "PhoneMainView.h"
#import "NSDatabase.h"
#import "NSData+Base64.h"

#define kMaxRadius 200
#define kMaxDuration 10

@interface OutgoingCallViewController (){
    float hLabel;
    float padding;
    float hAvatar;
    float paddingYAvatar;
    
    
    
    float wIconEndCall;
    float wSmallIcon;
    float wAvatar;
    float wIconState;
    
    NSTimer *onTimerUp1 ;
    NSTimer *onTimerUp2;
    NSTimer *onTimerUp3;
    UIFont *textFontBold;
    UIFont *textFont;
    
    NSString *userName;
}

@end

@implementation OutgoingCallViewController
@synthesize _imgBackground, _imgAvatar, _lbName, _lbCallState, _btnEndCall, _imgCallState, _btnSpeaker, _btnMute;
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
    
    [self turnOnCircle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    NSArray *contactInfo = [NSDatabase getNameAndAvatarOfContactWithPhoneNumber: _phoneNumber];
    userName = [contactInfo objectAtIndex: 0];
    NSString *avatar = [contactInfo objectAtIndex: 1];
    
    if ([userName isEqualToString:@""]) {
        userName = _phoneNumber;
        _lbName.text = _phoneNumber;
    }else{
        _lbName.text = userName;
    }
    
    if ([avatar isEqualToString:@""]) {
        _imgAvatar.image = [UIImage imageNamed:@"default-avatar"];
    }else{
        _imgAvatar.image = [UIImage imageWithData:[NSData dataFromBase64String: avatar]];
    }
    
    _btnSpeaker.selected = NO;
    _btnMute.selected = NO;
    
    _lbCallState.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
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
    hLabel = 40.0;
    padding = 30.0;
    hAvatar = 140.0;
    paddingYAvatar = 20.0;
    
    [_imgBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    
    CGSize textSize = [AppUtils getSizeWithText:[[LanguageUtil sharedInstance] getContent:@"Calling"] withFont:textFont andMaxWidth:SCREEN_WIDTH];
    
    float sizeImgStatus = 20.0;
    float originX = (SCREEN_WIDTH - (sizeImgStatus + 5.0 + textSize.width))/2;
    
    [_imgCallState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view.mas_centerY);
        make.width.height.mas_equalTo(sizeImgStatus);
        
    }];
    
    
    
    _lbCallState.font = textFont;
    [_lbCallState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view);
        make.height.mas_equalTo(hLabel);
    }];
    
    
    _imgAvatar.frame = CGRectMake((SCREEN_WIDTH-wAvatar)/2, (SCREEN_WIDTH-wAvatar)/2, wAvatar, wAvatar);
    _imgAvatar.clipsToBounds = YES;
    _imgAvatar.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _imgAvatar.layer.borderWidth = 1.0;
    _imgAvatar.layer.cornerRadius = wAvatar/2;
    
    _lbName.frame = CGRectMake(0, _imgAvatar.frame.origin.y+_imgAvatar.frame.size.height+20, SCREEN_WIDTH, 40);
    _lbName.font = textFontBold;
    
    
    
    _btnEndCall.frame = CGRectMake((SCREEN_WIDTH-wIconEndCall)/2, SCREEN_HEIGHT-20-50-wIconEndCall, wIconEndCall, wIconEndCall);
    _btnEndCall.layer.cornerRadius = wIconEndCall/2;
    
    //  video speaker
    float margin = 25.0;
    _btnSpeaker.frame = CGRectMake(_btnEndCall.frame.origin.x-(margin+wSmallIcon), _btnEndCall.frame.origin.y+wIconEndCall/2-wSmallIcon/2, wSmallIcon, wSmallIcon);
    
    [(UIButton *)_btnSpeaker setBackgroundImage:[UIImage imageNamed:@"call_speaker_on"]
                                         forState:UIControlStateNormal];
    [(UIButton *)_btnSpeaker setBackgroundImage:[UIImage imageNamed:@"call_speaker_on_selected"]
                                         forState:UIControlStateHighlighted];
    [(UIButton *)_btnSpeaker setBackgroundImage:[UIImage imageNamed:@"call_speaker_on_selected"]
                                         forState:UIControlStateSelected];
    _btnSpeaker.layer.cornerRadius = wSmallIcon/2;
    _btnSpeaker.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(255/255.0)
                                                   blue:(255/255.0) alpha:0.15];
    
    //  mute button
    _btnMute.frame = CGRectMake(_btnEndCall.frame.origin.x+_btnEndCall.frame.size.width+margin, _btnSpeaker.frame.origin.y, wSmallIcon, wSmallIcon);
    [(UIButton *)_btnMute setBackgroundImage:[UIImage imageNamed:@"call_microphone_off"]
                                      forState:UIControlStateNormal];
    [(UIButton *)_btnMute setBackgroundImage:[UIImage imageNamed:@"call_microphone_off_selected"]
                                      forState:UIControlStateHighlighted];
    [(UIButton *)_btnMute setBackgroundImage:[UIImage imageNamed:@"call_microphone_off_selected"]
                                      forState:UIControlStateSelected];
    _btnMute.layer.cornerRadius = wSmallIcon/2;
    _btnMute.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(255/255.0)
                                                blue:(255/255.0) alpha:0.15];
    
    
    
    
    
    
    
    - (void)setupUIForView {
        
        
        float wIcon = [DeviceUtils getSizeOfIconEndCall];
        wIcon = 65.0;
        
        float smallIcon = 55.0;
        
        
        
        lbDuration.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightThin];
        lbDuration.textColor = UIColor.whiteColor;
        [lbDuration mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.centerY.equalTo(self.mas_centerY);
            make.height.mas_equalTo(hLabel);
        }];
        
        
        imgAvatar.clipsToBounds = YES;
        imgAvatar.layer.cornerRadius = hAvatar/2;
        imgAvatar.layer.borderWidth = 2.0;
        imgAvatar.layer.borderColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0)
                                                       blue:(230/255.0) alpha:1.0].CGColor;
        [imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.bottom.equalTo(lbName.mas_top).offset(-paddingYAvatar);
            make.width.height.mas_equalTo(hAvatar);
        }];
        
        lbQuality.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightThin];
        lbQuality.textColor = UIColor.whiteColor;
        [lbQuality mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lbDuration.mas_bottom);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(hLabel);
        }];
        
        lbName.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightRegular];
        lbName.textColor = UIColor.whiteColor;
        [lbName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(lbDuration.mas_top);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(hLabel);
        }];
        
        iconEndCall.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);
        iconEndCall.layer.cornerRadius = wIcon/2;
        iconEndCall.clipsToBounds = YES;
        [iconEndCall mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-padding);
            make.centerX.equalTo(self.mas_centerX);
            make.width.height.mas_equalTo(wIcon);
        }];
        
        iconSpeaker.delegate = self;
        iconSpeaker.backgroundColor = [UIColor colorWithRed:(30/255.0) green:(30/255.0)
                                                       blue:(30/255.0) alpha:0.3];
        iconSpeaker.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        iconSpeaker.layer.cornerRadius = smallIcon/2;
        iconSpeaker.clipsToBounds = YES;
        [iconSpeaker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(iconEndCall.mas_centerY);
            make.left.equalTo(self).offset(padding);
            make.width.height.mas_equalTo(smallIcon);
        }];
        
        iconMute.delegate = self;
        iconMute.backgroundColor = iconSpeaker.backgroundColor;
        iconMute.imageEdgeInsets = iconSpeaker.imageEdgeInsets;
        iconMute.layer.cornerRadius = smallIcon/2;
        iconMute.clipsToBounds = YES;
        [iconMute mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(iconEndCall.mas_centerY);
            make.right.equalTo(self).offset(-padding);
            make.width.height.mas_equalTo(smallIcon);
        }];
    }
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
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: text_calling];
            _imgCallState.image = [UIImage imageNamed:@"icon_calling"];
            break;
        }
        case LinphoneCallOutgoingRinging:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: text_ringing];
            _imgCallState.image = [UIImage imageNamed:@"icon_ringing"];
            break;
        }
        case LinphoneCallOutgoingEarlyMedia:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: text_calling];
            _imgCallState.image = [UIImage imageNamed:@"icon_calling"];
            break;
        }
        case LinphoneCallConnected:{
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey:text_connected];
            
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
            _lbCallState.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: text_terminated];
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
                        NSString *reason = [NSString stringWithFormat:@"%@ %@", userName, [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey:text_busy]];
                        _lbName.text = reason;
                    }
                    break;
                }
                default:
                    _lbName.text = [[LinphoneAppDelegate sharedInstance].localization localizedStringForKey: text_terminated];
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
