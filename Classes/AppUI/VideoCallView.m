//
//  VideoCallView.m
//  linphone
//
//  Created by lam quang quan on 3/4/19.
//

#import "VideoCallView.h"

@implementation VideoCallView
@synthesize videoView, previewVideo, iconSwitchCam, iconMute, iconHangup, iconOffCamera, lbQuality, lbDuration;
@synthesize qualityTimer, durationTimer;

- (void)setupUIForView {
    float wIcon = [DeviceUtils getSizeOfIconEndCall];
    wIcon = 65.0;
    float padding = 30.0;
    float hLabel = 40.0;
    
    float smallIcon = 55.0;
    
    [videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self);
    }];
    
    [previewVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self);
        make.width.mas_equalTo(100.0);
        make.height.mas_equalTo(135.0);
    }];
    
    iconSwitchCam.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
    [iconSwitchCam mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(previewVideo.mas_centerX);
        make.bottom.equalTo(previewVideo.mas_bottom).offset(-15.0);
        make.width.height.mas_equalTo(40.0);
    }];
    
    iconHangup.layer.cornerRadius = wIcon/2;
    iconHangup.clipsToBounds = YES;
    [iconHangup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-padding);
        make.centerX.equalTo(self.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    iconOffCamera.backgroundColor = [UIColor colorWithRed:(30/255.0) green:(30/255.0)
                                                     blue:(30/255.0) alpha:0.3];
    iconOffCamera.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    iconOffCamera.layer.cornerRadius = smallIcon/2;
    iconOffCamera.clipsToBounds = YES;
    [iconOffCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(iconHangup.mas_centerY);
        make.left.equalTo(self).offset(padding);
        make.width.height.mas_equalTo(smallIcon);
    }];
    
    iconMute.backgroundColor = iconOffCamera.backgroundColor;
    iconMute.imageEdgeInsets = iconOffCamera.imageEdgeInsets;
    iconMute.layer.cornerRadius = smallIcon/2;
    iconMute.clipsToBounds = YES;
    [iconMute mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(iconHangup.mas_centerY);
        make.right.equalTo(self).offset(-padding);
        make.width.height.mas_equalTo(smallIcon);
    }];
    
    lbDuration.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightThin];
    lbDuration.textColor = UIColor.whiteColor;
    [lbDuration mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(10.0);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(180);
        make.height.mas_equalTo(hLabel);
    }];
    
    lbQuality.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightThin];
    lbQuality.textColor = UIColor.whiteColor;
    [lbQuality mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbDuration.mas_bottom);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(180);
        make.height.mas_equalTo(hLabel);
    }];
}

- (void)registerNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
                                               name:kLinphoneCallUpdate object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(headsetPluginChanged:)
                                               name:@"headsetPluginChanged" object:nil];
}

- (IBAction)iconOffCameraClick:(UIButton *)sender {
    BOOL isEnabled = linphone_core_video_preview_enabled(LC);
    if (isEnabled) {
        NSLog(@"------> disable video preview");
        linphone_core_enable_video_preview(LC, NO);
    }else{
        NSLog(@"------> enable video preview");
        linphone_core_enable_video_preview(LC, YES);
    }
}

- (IBAction)iconMuteClick:(UIButton *)sender {
}

- (IBAction)iconWtitchCamClick:(UIButton *)sender {
}

- (void)headsetPluginChanged: (NSNotification *)notif {
    if (notif.object != nil && [notif.object isKindOfClass:[NSNumber class]]) {
        int routeChangeReason = [notif.object intValue];
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
//            if (needEnableSpeaker) {
//                [iconSpeaker setOn];
//
//            }else{
//                [iconSpeaker setOff];
//            }
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable", __FUNCTION__]
                                 toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        }
        if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable) {
//            needEnableSpeaker = iconSpeaker.isEnabled;
//            [iconSpeaker setOff];
//
//            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        }
    }
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
    
    BOOL shouldEnableVideo = (!call || linphone_call_params_video_enabled(linphone_call_get_current_params(call)));
    if (shouldEnableVideo) {
        NSLog(@"shouldEnableVideo");
    }
    
    switch (state) {
        case LinphoneCallOutgoingRinging:{
            lbDuration.text = [[LanguageUtil sharedInstance] getContent:@"Ringing"];
            lbDuration.textColor = UIColor.whiteColor;
            
            break;
        }
        case LinphoneCallIncomingReceived:{
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingProgress:{
            lbDuration.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            lbDuration.textColor = UIColor.whiteColor;
            
            break;
        }
        case LinphoneCallOutgoingInit:{
            [self showFullLocalCameraPreview: YES];
            
            iconMute.enabled = NO;
            lbQuality.hidden = YES;
            
            break;
        }
        case LinphoneCallConnected:{
            [self showFullLocalCameraPreview: NO];
            lbDuration.font = [UIFont systemFontOfSize:30.0 weight:UIFontWeightThin];
            
            iconMute.enabled = YES;
            
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

- (void)showFullLocalCameraPreview: (BOOL)full {
    if (full) {
        [previewVideo mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(self);
        }];
    }else{
        [previewVideo mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(self);
            make.width.mas_equalTo(100.0);
            make.height.mas_equalTo(135.0);
        }];
    }
}

//  linphone_core_take_preview_snapshot
//  linphone_call_take_preview_snapshot
@end
