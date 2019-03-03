//
//  AudioCallView.m
//  linphone
//
//  Created by admin on 3/3/19.
//

#import "AudioCallView.h"

#define kMaxRadius 200
#define kMaxDuration 10

@implementation AudioCallView
@synthesize imgAvatar, bgCall, lbName, lbDuration, lbQuality, iconMute, iconEndCall, iconSpeaker, qualityTimer, durationTimer, hLabel, padding, hAvatar, paddingYAvatar, needEnableSpeaker;


- (void)updatePositionHaloView {
    self.halo.position = imgAvatar.center;
    float y = lbName.frame.origin.y - paddingYAvatar - hAvatar;
    if (imgAvatar.frame.origin.y == y) {
        self.halo.hidden = NO;
    }
}

- (IBAction)iconEndCallClick:(UIButton *)sender {
    linphone_core_terminate_all_calls(LC);
}

- (void)setupUIForView {
    hLabel = 40.0;
    padding = 30.0;
    hAvatar = 140.0;
    paddingYAvatar = 20.0;
    
    float wIcon = [DeviceUtils getSizeOfIconEndCall];
    wIcon = 65.0;
    
    float smallIcon = 55.0;
    
    [bgCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self);
    }];
    
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

- (void)registerNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
                                               name:kLinphoneCallUpdate object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(headsetPluginChanged:)
                                               name:@"headsetPluginChanged" object:nil];
}

- (NSString *)getPhoneNumberOfCall {
    LinphoneCall* call = linphone_core_get_current_call([LinphoneManager getLc]);
    const LinphoneAddress* addr = linphone_call_get_remote_address(call);
    if (addr != NULL) {
        // contact name
        char* lAddress = linphone_address_as_string_uri_only(addr);
        if(lAddress) {
            NSString *normalizedSipAddress = [SipUtils normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            NSRange range = NSMakeRange(3, [normalizedSipAddress rangeOfString:@"@"].location - 3);
            NSString *tmp = [normalizedSipAddress substringWithRange:range];
            // tmp: -> :8889998007
            if (tmp.length > 2) {
                NSString *phoneStr = [tmp substringFromIndex: 1];
                return phoneStr;
            }
            ms_free(lAddress);
        }
    }
    
    return @"";
}

- (void)addAnimationForOutgoingCall {
    LinphoneCall *call = linphone_core_get_current_call(LC);
    LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
    
    LinphoneCallDir callDirection = linphone_call_get_dir(call);
    
    if (callDirection == LinphoneCallOutgoing && state != LinphoneCallConnected && state != LinphoneCallStreamsRunning) {
        // basic setup
        PulsingHaloLayer *layer = [PulsingHaloLayer layer];
        self.halo = layer;
        [imgAvatar.superview.layer insertSublayer:self.halo below:imgAvatar.layer];
        [self setupInitialValuesWithNumLayer:5 radius:0.8 duration:0.45
                                       color:[UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:0.7]];
    }
}

- (void)setupInitialValuesWithNumLayer: (int)numLayer radius: (float)radius duration: (float)duration color: (UIColor *)color
{
    self.halo.haloLayerNumber = numLayer;
    self.halo.radius = radius * kMaxRadius;
    self.halo.animationDuration = duration * kMaxDuration;
    [self.halo setBackgroundColor:color.CGColor];
}

- (void)updateQualityForCall {
    if (qualityTimer != nil) {
        [qualityTimer invalidate];
        qualityTimer = nil;
    }
    [self callQualityUpdate];
    qualityTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(callQualityUpdate) userInfo:nil repeats:YES];
}

//  Call quality
- (void)callQualityUpdate {
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call == NULL) {
        [qualityTimer invalidate];
        qualityTimer = nil;
        return;
    }
    NSMutableAttributedString *attr = [SipUtils getQualityOfCall: call];
    if (attr == nil) {
        NSLog(@"WTF!!!!!");
    }else{
        lbQuality.attributedText = attr;
    }
}

- (void)countUpTimeForCall {
    if (durationTimer != nil) {
        [durationTimer invalidate];
        durationTimer = nil;
    }
    durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                   selector:@selector(callDurationUpdate)
                                                   userInfo:nil repeats:YES];
}

- (void)callDurationUpdate {
    int duration;
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call != NULL) {
        duration = linphone_call_get_duration(call);
        lbDuration.text = [LinphoneUtils durationToString:duration];
        lbDuration.textColor = UIColor.greenColor;
        lbQuality.hidden = NO;
    }else{
        duration = 0;
        lbQuality.hidden = YES;
    }
}

#pragma mark - Call Event

- (void)callUpdateEvent:(NSNotification *)notif {
    NSString *message = [notif.userInfo objectForKey:@"message"];
    LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
    [self callUpdate:call state:state animated:TRUE message: message];
}

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated message: (NSString *)message
{
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] The current call state is %d, with message = %@", __FUNCTION__, state, message] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    // Fake call update
    if (call == NULL) {
        return;
    }
    
    switch (state) {
        case LinphoneCallOutgoingRinging:{
            lbDuration.text = [[LanguageUtil sharedInstance] getContent:@"Ringing"];
            lbDuration.textColor = UIColor.whiteColor;
            
            [self getPhoneNumberOfCall];
            break;
        }
        case LinphoneCallIncomingReceived:{
            [self getPhoneNumberOfCall];
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingProgress:{
            lbDuration.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            lbDuration.textColor = UIColor.whiteColor;
            
            break;
        }
        case LinphoneCallOutgoingInit:{
            if (self.halo == nil) {
                [self addAnimationForOutgoingCall];
            }
            self.halo.hidden = YES;
            [self.halo start];
            
            iconMute.enabled = NO;
            iconSpeaker.enabled = YES;
            lbQuality.hidden = YES;
            
            break;
        }
        case LinphoneCallConnected:{
            lbDuration.font = [UIFont systemFontOfSize:30.0 weight:UIFontWeightThin];
            
            iconMute.enabled = YES;
            iconSpeaker.enabled = YES;
            
            lbQuality.hidden = NO;
            NSMutableAttributedString *attr = [SipUtils getQualityOfCall: call];
            if (attr != nil) {
                lbQuality.attributedText = attr;
            }else{
                lbQuality.attributedText = [[NSAttributedString alloc] initWithString:@""];
            }
            
            [self callDurationUpdate];
            [self countUpTimeForCall];
            [self updateQualityForCall];
            
            //  Stop halo waiting
            self.halo.hidden = YES;
            [self.halo start];
            self.halo = nil;
            [self.halo removeFromSuperlayer];
            
            break;
        }
        case LinphoneCallStreamsRunning: {
            // check video
            if (!linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
                const LinphoneCallParams *param = linphone_call_get_current_params(call);
                const LinphoneCallAppData *callAppData =
                (__bridge const LinphoneCallAppData *)(linphone_call_get_user_pointer(call));
                if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
                    linphone_call_params_low_bandwidth_enabled(param)) {
                }
            }
            iconMute.enabled = YES;
            
            break;
        }
        case LinphoneCallUpdatedByRemote: {
            const LinphoneCallParams *current = linphone_call_get_current_params(call);
            const LinphoneCallParams *remote = linphone_call_get_remote_params(call);
            
            /* remote wants to add video */
            if ((linphone_core_video_display_enabled(LC) && !linphone_call_params_video_enabled(current) &&
                 linphone_call_params_video_enabled(remote)) &&
                (!linphone_core_get_video_policy(LC)->automatically_accept ||
                 (([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) &&
                  floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max))) {
                     linphone_core_defer_call_update(LC, call);
                     
                 } else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
                     
                 }
            break;
        }
        case LinphoneCallPausing:
        case LinphoneCallPaused:{
            break;
        }
        case LinphoneCallPausedByRemote:
            if (call == linphone_core_get_current_call(LC)) {
                //  _pausedByRemoteView.hidden = NO;
            }
            break;
        case LinphoneCallEnd:{
            if (durationTimer != nil) {
                [durationTimer invalidate];
                durationTimer = nil;
            }
            if (qualityTimer != nil) {
                [qualityTimer invalidate];
                qualityTimer = nil;
            }
            
            //  Stop halo waiting
            self.halo.hidden = YES;
            [self.halo start];
            self.halo = nil;
            [self.halo removeFromSuperlayer];
            
            break;
        }
        case LinphoneCallError:{
            if (durationTimer != nil) {
                [durationTimer invalidate];
                durationTimer = nil;
            }
            if (qualityTimer != nil) {
                [qualityTimer invalidate];
                qualityTimer = nil;
            }
            [self displayCallError:call message:message];
            [self performSelector:@selector(hideCallView) withObject:nil afterDelay:2.0];
            break;
        }
        case LinphoneCallReleased:{
            if (durationTimer != nil) {
                [durationTimer invalidate];
                durationTimer = nil;
            }
            if (qualityTimer != nil) {
                [qualityTimer invalidate];
                qualityTimer = nil;
            }
            
            //  Stop halo waiting
            self.halo.hidden = YES;
            [self.halo start];
            self.halo = nil;
            [self.halo removeFromSuperlayer];
            
            [self performSelector:@selector(hideCallView) withObject:nil afterDelay:2.0];
            break;
        }
        default:
            break;
    }
}

- (void)displayCallError:(LinphoneCall *)call message:(NSString *)message
{
    if (call != NULL) {
        const char *lUserNameChars = linphone_address_get_username(linphone_call_get_remote_address(call));
        NSString *lUserName =
        lUserNameChars ? [[NSString alloc] initWithUTF8String:lUserNameChars] : NSLocalizedString(@"Unknown", nil);
        NSString *lMessage;
        
        switch (linphone_call_get_reason(call)) {
            case LinphoneReasonNotFound:
                lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is not registered.", nil), lUserName];
                break;
            case LinphoneReasonBusy:
                lbDuration.text = [[LanguageUtil sharedInstance] getContent:@"The user is busy"];
                lbDuration.textColor = UIColor.whiteColor;
                break;
            default:
                if (message != nil) {
                    lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@\nReason was: %@", nil), lMessage, message];
                }
                break;
        }
    }
}

- (void)hideCallView {
    NSLog(@"hideCallView");
}

- (void)headsetPluginChanged: (NSNotification *)notif {
    if (notif.object != nil && [notif.object isKindOfClass:[NSNumber class]]) {
        int routeChangeReason = [notif.object intValue];
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            if (needEnableSpeaker) {
                [iconSpeaker setOn];
                
            }else{
                [iconSpeaker setOff];
            }
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable", __FUNCTION__]
                                 toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        }
        if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable) {
            needEnableSpeaker = iconSpeaker.isEnabled;
            [iconSpeaker setOff];
            
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        }
    }
}

#pragma mark - Footer button delegate
- (void)onMuteStateChangedTo:(BOOL)muted {
    if (muted) {
        iconMute.backgroundColor = UIColor.whiteColor;
        [iconMute setImage:[UIImage imageNamed:@"ic_muted_black"] forState:UIControlStateNormal];
    }else{
        iconMute.backgroundColor = [UIColor colorWithRed:(30/255.0) green:(30/255.0)
                                                    blue:(30/255.0) alpha:0.3];
        [iconMute setImage:[UIImage imageNamed:@"ic_muted_white"] forState:UIControlStateNormal];
    }
}

-(void)onSpeakerStateChangedTo:(BOOL)speaker {
    if (speaker) {
        iconSpeaker.backgroundColor = UIColor.whiteColor;
        [iconSpeaker setImage:[UIImage imageNamed:@"ic_speaker_black"] forState:UIControlStateNormal];
    }else{
        iconSpeaker.backgroundColor = [UIColor colorWithRed:(30/255.0) green:(30/255.0)
                                                    blue:(30/255.0) alpha:0.3];
        [iconSpeaker setImage:[UIImage imageNamed:@"ic_speaker_white"] forState:UIControlStateNormal];
    }
}

@end
