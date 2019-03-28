/* InCallViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <AVFoundation/AVAudioSession.h>
#import <AddressBook/AddressBook.h>
#import <AudioToolbox/AudioToolbox.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <UserNotifications/UserNotifications.h>

#import "CallView.h"
#import "CallSideMenuView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"

#include "linphone/linphonecore.h"

#import "NSData+Base64.h"
#import "UIConferenceCell.h"
#import "ContactDetailObj.h"
#import "UIMiniKeypad.h"
#import "ChooseRouteOutputCell.h"
#import "NSDatabase.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "UploadPicture.h"
#import <AVFoundation/AVFoundation.h>

void message_received(LinphoneCore *lc, LinphoneChatRoom *room, const LinphoneAddress *from, const char *message) {
    printf(" Message [%s] received from [%s] \n",message,linphone_address_as_string (from));
}

const NSInteger SECURE_BUTTON_TAG = 5;

@interface CallView ()<UITableViewDelegate, UITableViewDataSource>{
    BOOL isAudioCall;
    float wAvatar;
    float wEndIcon;
    float wSmallIcon;
    float marginIcon;
    
    LinphoneAppDelegate *appDelegate;
    
    float marginX;
    
    UIButton *btnNumpad;
    
    int typeCurrentCall;
    BOOL changeConference;
    
    const MSList *list;
    
    UITapGestureRecognizer *tapOnVideoCall;
    
    NSTimer *updateTimeConf;
    
    NSMutableAttributedString *videoStateString;
    
    
    UIImageView *icVideoCall;
    UIImageView *icWaveVideo;
    
    AVCaptureDevice *defaultDevice;
    
    UIView *viewOffCam;
    UIImageView *imgOffCam;
    float marginQuality;
    float marginPhone;
}

@end

@implementation CallView {
	BOOL hiddenVolume;
}

@synthesize callView, bgAudioCall, nameLabel, lbPhoneNumber, durationLabel, _lbQuality, avatarImage, hangupButton, speakerButton, microButton, callPauseButton, numpadButton;
@synthesize viewVideoCall, _lbVideoTime, lbAddressVideoCall, lbVideoQuality, btnHangupVideo, btnMicroVideo, btnSpeakerVideo, btnOffCamera, btnSwitchCamera, btnKeypadVideo;
@synthesize durationTimer;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
	if (self != nil) {
		singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls:)];
		videoZoomHandler = [[VideoZoomHandler alloc] init];
		videoHidden = TRUE;
	}
	return self;
}

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
- (void)changeRotationOfDevice {
    NSLog(@"Current orientation %ld", (long)UIDevice.currentDevice.orientation);
//    NSNumber *value1 = [NSNumber numberWithInt:UIDeviceOrientationFaceUp];
//    [[UIDevice currentDevice] setValue:value1 forKey:@"orientation"];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_routesEarpieceButton.enabled = !IPAD;

    defaultDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
// TODO: fixme! video preview frame is too big compared to openGL preview
// frame, so until this is fixed, temporary disabled it.
#if 0
	_videoPreview.layer.borderColor = UIColor.whiteColor.CGColor;
	_videoPreview.layer.borderWidth = 1;
#endif
    
    
    tapOnVideoCall = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(whenTapOnVideoCall)];
    tapOnVideoCall.delegate = self;
    [viewVideoCall addGestureRecognizer: tapOnVideoCall];
    
    [tapOnVideoCall requireGestureRecognizerToFail: singleFingerTap];
    singleFingerTap.numberOfTapsRequired = 2;
    singleFingerTap.cancelsTouchesInView = NO;
	[viewVideoCall addGestureRecognizer:singleFingerTap];
	[videoZoomHandler setup: viewVideoCall];

	UIPanGestureRecognizer *dragndrop =
		[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveVideoPreview:)];
	dragndrop.minimumNumberOfTouches = 1;
	[_videoPreview addGestureRecognizer:dragndrop];

	[_zeroButton setDigit:'0'];
	[_zeroButton setDtmf:true];
	[_oneButton setDigit:'1'];
	[_oneButton setDtmf:true];
	[_twoButton setDigit:'2'];
	[_twoButton setDtmf:true];
	[_threeButton setDigit:'3'];
	[_threeButton setDtmf:true];
	[_fourButton setDigit:'4'];
	[_fourButton setDtmf:true];
	[_fiveButton setDigit:'5'];
	[_fiveButton setDtmf:true];
	[_sixButton setDigit:'6'];
	[_sixButton setDtmf:true];
	[_sevenButton setDigit:'7'];
	[_sevenButton setDtmf:true];
	[_eightButton setDigit:'8'];
	[_eightButton setDtmf:true];
	[_nineButton setDigit:'9'];
	[_nineButton setDtmf:true];
	[_starButton setDigit:'*'];
	[_starButton setDtmf:true];
	[_hashButton setDigit:'#'];
	[_hashButton setDtmf:true];
    
    //  Add ney by Khai Le on 09/11/2017
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [speakerButton setHidden: YES];
}

- (void)dealloc {
	[PhoneMainView.instance.view removeGestureRecognizer:singleFingerTap];
	// Remove all observer
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    [self setupUIForView];
    NSString *isvideo = [[NSUserDefaults standardUserDefaults] objectForKey:IS_VIDEO_CALL_KEY];
    if (![AppUtils isNullOrEmpty: isvideo] && [isvideo isEqualToString:@"1"]) {
        isAudioCall = NO;
        [self createOffCameraView];
    }else{
        isAudioCall = YES;
    }
    
    //  Leo Kelvin
    _bottomBar.hidden = YES;
    _bottomBar.clipsToBounds = YES;
    
	LinphoneManager.instance.nextCallIsTransfer = NO;
    
    [self setQualityForFirstTime];
    
    nameLabel.text = @"";
    lbAddressVideoCall.text = @"";

	// Update on show
	[self hideRoutes:TRUE animated:FALSE];
	[self hideOptions:TRUE animated:FALSE];
	[self hidePad:TRUE animated:FALSE];
	[self hideSpeaker:LinphoneManager.instance.bluetoothAvailable];
	[self callDurationUpdate];
	[self onCurrentCallChange];
    
    if (!isAudioCall) {
        // Set windows (warn memory leaks)
        linphone_core_set_native_video_window_id(LC, (__bridge void *)(_videoView));
        linphone_core_set_native_preview_window_id(LC, (__bridge void *)(_videoPreview));
    }

	[self previewTouchLift];
	// Enable tap
    singleFingerTap.enabled = YES;
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bluetoothAvailabilityUpdateEvent:)
											   name:kLinphoneBluetoothAvailabilityUpdate object:nil];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callEnded)
                                               name:@"callEnded" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(CallConnectedSuccessful)
                                               name:@"CallConnectedSuccessful" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateStateForSpekearButton)
                                               name:speakerEnabledForVideoCall object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForBluetoothEnabled)
                                               name:@"bluetoothEnabled" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForSpeakerEnabled)
                                               name:@"speakerEnabled" object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(uiForiPhoneReceiverEnabled)
                                               name:@"iPhoneReceiverEnabled" object:nil];
    
	durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                   selector:@selector(callDurationUpdate)
                                                   userInfo:nil repeats:YES];
    
    //  Update address
    [self updateAddress];
    
    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
    if (count > 0) {
        if (isAudioCall) {
            if ([DeviceUtils getCurrentRouteForCall] == eEarphone) {
                [speakerButton setImage:[UIImage imageNamed:@"speaker_bluetooth_enable"]
                               forState:UIControlStateNormal];
            }else{
                if (LinphoneManager.instance.speakerEnabled) {
                    [speakerButton setImage:[UIImage imageNamed:@"speaker_enable"]
                                   forState:UIControlStateNormal];
                }else{
                    [speakerButton setImage:[UIImage imageNamed:@"speaker_normal"]
                                   forState:UIControlStateNormal];
                }
            }
            //  detect micro
            if (linphone_core_mic_enabled(LC)) {
                [microButton setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
            }else{
                [microButton setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
            }
            
        }else{
            [self performSelector:@selector(tryToUpdateCamera) withObject:nil afterDelay:1.0];
            [self enableVideoForCurrentCall];
            
            if ([DeviceUtils getCurrentRouteForCall] == eEarphone) {
                [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_bluetooth_enable"]
                               forState:UIControlStateNormal];
            }else{
                if (LinphoneManager.instance.speakerEnabled) {
                    [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_enable"]
                                     forState:UIControlStateNormal];
                }else{
                    [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_normal"]
                                     forState:UIControlStateNormal];
                }
            }
            
            //  detect micro
            if (linphone_core_mic_enabled(LC)) {
                [btnMicroVideo setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
            }else{
                [btnMicroVideo setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
            }
        }
    }
    callView.hidden = !isAudioCall;
    viewVideoCall.hidden = isAudioCall;
}

- (void)tryToUpdateCamera {
    linphone_call_enable_camera(linphone_core_get_current_call(LC), YES);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
    if (isAudioCall) {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }

	[PhoneMainView.instance setVolumeHidden:TRUE];
	hiddenVolume = TRUE;

	// we must wait didAppear to reset fullscreen mode because we cannot change it in viewwillappear
	LinphoneCall *call = linphone_core_get_current_call(LC);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state animated:FALSE];
}

- (void)CallConnectedSuccessful {
    [self enableVideoForCurrentCall];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self disableVideoDisplay:TRUE animated:NO];

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}

	if (videoDismissTimer) {
		[self dismissVideoActionSheet:videoDismissTimer];
		[videoDismissTimer invalidate];
		videoDismissTimer = nil;
	}

	// Remove observer
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    
	[[UIApplication sharedApplication] setIdleTimerDisabled:false];
	[DeviceUtils enableProximityMonitoringEnabled: NO];

	[PhoneMainView.instance fullScreen:false];
	// Disable tap
	[singleFingerTap setEnabled:FALSE];

	if (linphone_core_get_calls_nb(LC) == 0) {
		// reseting speaker button because no more call
		speakerButton.selected = FALSE;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self previewTouchLift];
	[self hideStatusBar:!videoHidden && (nameLabel.alpha <= 0.f)];
}

#pragma mark - UI modification

- (void)hideSpinnerIndicator:(LinphoneCall *)call {
	_videoWaitingForFirstImage.hidden = TRUE;
}

static void hideSpinner(LinphoneCall *call, void *user_data) {
	CallView *thiz = (__bridge CallView *)user_data;
	[thiz hideSpinnerIndicator:call];
}

- (void)updateBottomBar:(LinphoneCall *)call state:(LinphoneCallState)state {
	[callPauseButton update];
	[hangupButton update];

	_optionsButton.enabled = (!call || !linphone_core_sound_resources_locked(LC));
	// enable conference button if 2 calls are presents and at least one is not in the conference
	int confSize = linphone_core_get_conference_size(LC) - (linphone_core_is_in_conference(LC) ? 1 : 0);
	_optionsConferenceButton.enabled =
		((linphone_core_get_calls_nb(LC) > 1) && (linphone_core_get_calls_nb(LC) != confSize));

	switch (state) {
		case LinphoneCallEnd:
		case LinphoneCallError:
		case LinphoneCallIncoming:
		case LinphoneCallOutgoing:
			[self hidePad:TRUE animated:TRUE];
			[self hideOptions:TRUE animated:TRUE];
			[self hideRoutes:TRUE animated:TRUE];
		default:
			break;
	}
}

- (void)toggleControls:(id)sender {
	bool controlsHidden = (_bottomBar.alpha == 0.0);
	[self hideControls:!controlsHidden sender:sender];
}

- (void)timerHideControls:(id)sender {
	[self hideControls:TRUE sender:sender];
}

- (void)hideControls:(BOOL)hidden sender:(id)sender {
	if (videoHidden && hidden)
		return;

	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[PhoneMainView.instance currentView] equal:CallView.compositeViewDescription]) {
		// show controls
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.35];
        
		nameLabel.alpha = durationLabel.alpha = (hidden ? 0 : .8f);

		[self hideStatusBar:hidden];

		[UIView commitAnimations];

		[PhoneMainView.instance hideTabBar:hidden];

		if (!hidden) {
			// hide controls in 5 sec
			hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
																 target:self
															   selector:@selector(timerHideControls:)
															   userInfo:nil
																repeats:NO];
		}
	}
}

- (void)disableVideoDisplay:(BOOL)disabled animated:(BOOL)animation {
	if (disabled == videoHidden && animation)
		return;
	videoHidden = disabled;

	if (!disabled) {
		[videoZoomHandler resetZoom];
	}
	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

    //  Leo Kelvin
    callView.hidden = YES;
    viewVideoCall.hidden = NO;

	[self hideControls:!disabled sender:nil];

	if (animation) {
		[UIView commitAnimations];
	}

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

    [[PhoneMainView instance] fullScreen: false];
    /*  Leo Kelvin
	[PhoneMainView.instance fullScreen:!disabled];
	[PhoneMainView.instance hideTabBar:!disabled];
    */

	if (!disabled) {
#ifdef TEST_VIDEO_VIEW_CHANGE
		[NSTimer scheduledTimerWithTimeInterval:5.0
										 target:self
									   selector:@selector(_debugChangeVideoView)
									   userInfo:nil
										repeats:YES];
#endif
		// [self batteryLevelChanged:nil];

		[_videoWaitingForFirstImage setHidden:NO];
		[_videoWaitingForFirstImage startAnimating];

		LinphoneCall *call = linphone_core_get_current_call(LC);
		// linphone_call_params_get_used_video_codec return 0 if no video stream enabled
		if (call != NULL && linphone_call_params_get_used_video_codec(linphone_call_get_current_params(call))) {
			linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, (__bridge void *)(self));
		}
	}
}

- (void)displayVideoCall:(BOOL)animated {
    float x = 0.5;
    float y = 0.5;
    linphone_call_zoom_video(linphone_core_get_current_call(LC), 1.32, &x, &y);
    
	[self disableVideoDisplay:FALSE animated:animated];
}

- (void)displayAudioCall:(BOOL)animated {
	[self disableVideoDisplay:TRUE animated:animated];
}

- (void)hideStatusBar:(BOOL)hide {
	/* we cannot use [PhoneMainView.instance show]; because it will automatically
	 resize current view to fill empty space, which will resize video. This is
	 indesirable since we do not want to crop/rescale video view */
	PhoneMainView.instance.mainViewController.statusBarView.hidden = hide;
}

- (void)callDurationUpdate
{
    int duration;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    if (list != NULL) {
        duration = linphone_call_get_duration((LinphoneCall*)list->data);
    }else{
        duration = 0;
    }
    if (isAudioCall) {
        durationLabel.text = [LinphoneUtils durationToString:duration];
    }else{
        _lbVideoTime.text = [LinphoneUtils durationToString:duration];
    }
    if (duration > 0) {
        [self callQualityUpdate];
    }
    
    //  MSVideoSize receivedVideoSize = linphone_core_get_preferred_video_size(LC);
//    MSVideoSize receivedVideoSize = linphone_call_params_get_received_video_size(linphone_call_get_remote_params((LinphoneCall*)list->data));
//    NSLog(@"%d - %d", receivedVideoSize.width, receivedVideoSize.height);
    
//    MSVideoSize sent = linphone_call_params_get_sent_video_size(linphone_call_get_remote_params((LinphoneCall*)list->data));
//    NSLog(@"sent: %d - %d", sent.width, sent.height);
    
    
//    BOOL capture_enabled =  linphone_core_video_capture_enabled(LC);
//    NSLog(@"capture_enabled = %d", capture_enabled);
//
//    BOOL display_enabled =  linphone_core_video_display_enabled(LC);
//    NSLog(@"display_enabled = %d", display_enabled);
    
//    BOOL video_enabled =  linphone_core_video_enabled(LC);
//    NSLog(@"video_enabled = %d", video_enabled);
    
//    LinphoneCall *currentCall = linphone_core_get_current_call(LC);
//    MSVideoSize videoSize = linphone_call_params_get_received_video_size(linphone_call_get_current_params(currentCall));
//    NSLog(@"videoSize: %d - %d", videoSize.width, videoSize.height);
}

//  Call quality
- (void)callQualityUpdate {
    LinphoneCall *call;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    
    call = (LinphoneCall*)list->data;
    if(call != NULL) {
        NSMutableAttributedString *qualityAttr = [SipUtils getQualityOfCall: call];
        if (isAudioCall) {
            _lbQuality.attributedText = qualityAttr;
        }else{
            lbVideoQuality.attributedText = qualityAttr;
        }
    }else{
        lbVideoQuality.text = @"";
    }
}

- (void)onCurrentCallChange {
	LinphoneCall *call = linphone_core_get_current_call(LC);

	//  _callView.hidden = !call;
	//  _callPauseButton.hidden = !call && !linphone_core_is_in_conference(LC);

	//  [_callPauseButton setType:UIPauseButtonType_CurrentCall call:call];
	//  [_conferencePauseButton setType:UIPauseButtonType_Conference call:call];

    //  Leo Kelvin
    //  _callView.hidden = !call;
    
    BOOL check = !call && !linphone_core_is_in_conference(LC);
    if (check) {
        callPauseButton.selected = YES;
    }else{
        callPauseButton.selected = NO;
    }
    [callPauseButton setType:UIPauseButtonType_CurrentCall call:call];
    /*
    [_conferencePauseButton setType:UIPauseButtonType_Conference call:call];    */
    
	if (!callView.hidden) {
        /*  Leo Kelvin
		const LinphoneAddress *addr = linphone_call_get_remote_address(call);
		[ContactDisplay setDisplayNameLabel:_nameLabel forAddress:addr];
		char *uri = linphone_address_as_string_uri_only(addr);
		ms_free(uri);
		[_avatarImage setImage:[FastAddressBook imageForAddress:addr thumbnail:NO] bordered:YES withRoundedRadius:YES]; */
	}
}

- (void)hidePad:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[numpadButton setOff];
	} else {
		[numpadButton setOn];
	}
	if (hidden != _numpadView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_numpadView completion:nil];
		} else {
			[_numpadView setHidden:hidden];
		}
	}
}

- (void)hideRoutes:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[_routesButton setOff];
	} else {
		[_routesButton setOn];
	}

	_routesBluetoothButton.selected = LinphoneManager.instance.bluetoothEnabled;
    
	if (hidden != _routesView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_routesView completion:nil];
		} else {
			[_routesView setHidden:hidden];
		}
	}
}

- (void)hideOptions:(BOOL)hidden animated:(BOOL)animated {
	if (hidden) {
		[_optionsButton setOff];
	} else {
		[_optionsButton setOn];
	}
	if (hidden != _optionsView.hidden) {
		if (animated) {
			[self hideAnimation:hidden forView:_optionsView completion:nil];
		} else {
			[_optionsView setHidden:hidden];
		}
	}
}

- (void)hideSpeaker:(BOOL)hidden {
    return;
	speakerButton.hidden = hidden;
	_routesButton.hidden = !hidden;
}

#pragma mark - Event Functions

- (void)bluetoothAvailabilityUpdateEvent:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool available = [[notif.userInfo objectForKey:@"available"] intValue];
        [self hideSpeaker:available];
    });
}

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state animated:TRUE];
}

- (NSString *)createDirectory {
    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"test.mp3"];
    NSLog(@"%@", path);
    return path;
}

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated
{
	[self updateBottomBar:call state:state];
	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
    
	static LinphoneCall *currentCall = NULL;
	if (!currentCall || linphone_core_get_current_call(LC) != currentCall) {
		currentCall = linphone_core_get_current_call(LC);
		[self onCurrentCallChange];
	}

	// Fake call update
	if (call == NULL) {
		return;
	}

	BOOL shouldDisableVideo =
		(!currentCall || !linphone_call_params_video_enabled(linphone_call_get_current_params(currentCall)));
	if (videoHidden != shouldDisableVideo) {
		if (!shouldDisableVideo) {
			[self displayVideoCall:animated];
		} else {
			[self displayAudioCall:animated];
		}
	}

	switch (state) {
        case LinphoneCallIncomingReceived:{
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingInit:{
            typeCurrentCall = callOutgoing;
            
            // Nếu không phải Outgoing trong conference thì set disable các button
            if (!changeConference) {
                btnNumpad.enabled = NO;
                callPauseButton.enabled = NO;
                microButton.enabled = NO;
            }
            break;
        }
        case LinphoneCallConnected:{
            //  ghi am
            /*
            LinphoneCall* currentCall = linphone_core_get_current_call(LC);
            LinphoneCallParams* paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(currentCall));
            linphone_call_params_set_privacy(paramsCopy, 1);
            const char* lPlay = [[self createDirectory] cStringUsingEncoding:[NSString defaultCStringEncoding]];
            linphone_call_params_set_record_file(paramsCopy,lPlay);
            NSLog(@"File : %s",linphone_call_params_get_record_file(paramsCopy));
            linphone_call_start_recording(currentCall); */
            
            btnNumpad.enabled = YES;
            speakerButton.enabled = YES;
            callPauseButton.enabled = YES;
            microButton.enabled = YES;
            
            lbVideoQuality.text = @"Đã kết nối";
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
            btnNumpad.enabled = YES;
            callPauseButton.enabled = YES;
            microButton.enabled = YES;
            
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
				[self displayAskToEnableVideoCall:call];
			} else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
				[self displayAudioCall:animated];
			}
			break;
		}
		case LinphoneCallPausing:
        case LinphoneCallPaused:{
            //  Close by Khai Le
            //  [self displayAudioCall:animated];
            break;
        }
		case LinphoneCallPausedByRemote:
			[self displayAudioCall:animated];
			if (call == linphone_core_get_current_call(LC)) {
				//  _pausedByRemoteView.hidden = NO;
			}
			break;
        case LinphoneCallEnd:{
            [self hideMiniKeypad];
            
            if (durationTimer != nil) {
                [durationTimer invalidate];
                durationTimer = nil;
            }
            break;
        }
        case LinphoneCallError:{
            [self hideMiniKeypad];
            
            break;
        }
		default:
			break;
	}
}

#pragma mark - ActionSheet Functions

- (void)displayAskToEnableVideoCall:(LinphoneCall *)call {
	if (linphone_core_get_video_policy(LC)->automatically_accept &&
		!([UIApplication sharedApplication].applicationState == UIApplicationStateBackground))
		return;

}

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	UIConfirmationDialog *sheet = (UIConfirmationDialog *)timer.userInfo;
	[sheet dismiss];
}

#pragma mark VideoPreviewMoving

- (void)moveVideoPreview:(UIPanGestureRecognizer *)dragndrop {
	CGPoint center = [dragndrop locationInView:_videoPreview.superview];
	_videoPreview.center = center;
	if (dragndrop.state == UIGestureRecognizerStateEnded) {
		[self previewTouchLift];
	}
}

- (CGFloat)coerce:(CGFloat)value betweenMin:(CGFloat)min andMax:(CGFloat)max {
	return MAX(min, MIN(value, max));
}

- (void)previewTouchLift {
	CGRect previewFrame = _videoPreview.frame;
	previewFrame.origin.x = [self coerce:previewFrame.origin.x
							  betweenMin:5
								  andMax:(UIScreen.mainScreen.bounds.size.width - 5 - previewFrame.size.width)];
	previewFrame.origin.y = [self coerce:previewFrame.origin.y
							  betweenMin:5
								  andMax:(UIScreen.mainScreen.bounds.size.height - 5 - previewFrame.size.height)];

	if (!CGRectEqualToRect(previewFrame, _videoPreview.frame)) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		  [UIView animateWithDuration:0.3
						   animations:^{
                               NSLog(@"Recentering preview to %@", NSStringFromCGRect(previewFrame));
                               _videoPreview.frame = previewFrame;
						   }];
		});
	}
}

#pragma mark - Action Functions

- (void)showMiniKeypadForAudioCall {
    [self showMiniKeypadOnView: callView];
}

- (void)showMiniKeypadOnView: (UIView *)aview {
    NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"UIMiniKeypad" owner:nil options:nil];
    UIMiniKeypad *viewKeypad;
    for(id currentObject in toplevelObject){
        if ([currentObject isKindOfClass:[UIMiniKeypad class]]) {
            viewKeypad = (UIMiniKeypad *) currentObject;
            break;
        }
    }
    [viewKeypad.iconBack addTarget:self
                            action:@selector(hideMiniKeypad)
                  forControlEvents:UIControlEventTouchUpInside];
    [aview addSubview:viewKeypad];
    [viewKeypad.iconMiniKeypadEndCall addTarget:self
                                         action:@selector(endCallFromMiniKeypad)
                               forControlEvents:UIControlEventTouchUpInside];
    
    [viewKeypad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(aview);
    }];
    [viewKeypad setupUIForView];
    
    viewKeypad.tag = 10;
    [viewKeypad.zeroButton setDigit:'0'];
    [viewKeypad.zeroButton setDtmf:true] ;
    [viewKeypad.oneButton    setDigit:'1'];
    [viewKeypad.oneButton setDtmf:true];
    [viewKeypad.twoButton    setDigit:'2'];
    [viewKeypad.twoButton setDtmf:true];
    [viewKeypad.threeButton  setDigit:'3'];
    [viewKeypad.threeButton setDtmf:true];
    [viewKeypad.fourButton   setDigit:'4'];
    [viewKeypad.fourButton setDtmf:true];
    [viewKeypad.fiveButton   setDigit:'5'];
    [viewKeypad.fiveButton setDtmf:true];
    [viewKeypad.sixButton    setDigit:'6'];
    [viewKeypad.sixButton setDtmf:true];
    [viewKeypad.sevenButton  setDigit:'7'];
    [viewKeypad.sevenButton setDtmf:true];
    [viewKeypad.eightButton  setDigit:'8'];
    [viewKeypad.eightButton setDtmf:true];
    [viewKeypad.nineButton   setDigit:'9'];
    [viewKeypad.nineButton setDtmf:true];
    [viewKeypad.starButton   setDigit:'*'];
    [viewKeypad.starButton setDtmf:true];
    [viewKeypad.sharpButton  setDigit:'#'];
    [viewKeypad.sharpButton setDtmf:true];
    
    [self fadeIn:viewKeypad];
}

- (void)fadeIn :(UIView*)view{
    view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    view.alpha = 0.0;
    [UIView animateWithDuration:.35 animations:^{
        view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        view.alpha = 1.0;
    }];
}

//  Hide keypad mini
- (void)hideMiniKeypad{
    if (isAudioCall) {
        for (UIView *subView in callView.subviews) {
            if (subView.tag == 10) {
                [UIView animateWithDuration:.35 animations:^{
                    subView.transform = CGAffineTransformMakeScale(1.3, 1.3);
                    subView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [subView removeFromSuperview];
                    }
                }];
            }
        }
    }else{
        for (UIView *subView in viewVideoCall.subviews) {
            if (subView.tag == 10) {
                [UIView animateWithDuration:.35 animations:^{
                    subView.transform = CGAffineTransformMakeScale(1.3, 1.3);
                    subView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [subView removeFromSuperview];
                    }
                }];
            }
        }
    }
}

- (void)endCallFromMiniKeypad {
    linphone_core_terminate_all_calls(LC);
    [self hideMiniKeypad];
}

- (IBAction)onChatClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
}

- (IBAction)onRoutesBluetoothClick:(id)sender {
	[self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:TRUE];
}

- (IBAction)onRoutesEarpieceClick:(id)sender {
	[self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:FALSE];
}

- (IBAction)onRoutesSpeakerClick:(id)sender {
    //  [self hideRoutes:TRUE animated:TRUE];
    if (![(UIButton *)sender isSelected]) {
        [LinphoneManager.instance setBluetoothEnabled:TRUE];
        [LinphoneManager.instance setSpeakerEnabled:FALSE];
    }else{
        [LinphoneManager.instance setBluetoothEnabled:FALSE];
        [LinphoneManager.instance setSpeakerEnabled:TRUE];
    }
}

- (IBAction)onRoutesClick:(id)sender {
	if ([_routesView isHidden]) {
		[self hideRoutes:FALSE animated:ANIMATED];
	} else {
		[self hideRoutes:TRUE animated:ANIMATED];
	}
}

- (IBAction)onOptionsClick:(id)sender {
	if ([_optionsView isHidden]) {
		[self hideOptions:FALSE animated:ANIMATED];
	} else {
		[self hideOptions:TRUE animated:ANIMATED];
	}
}

- (IBAction)onOptionsTransferClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = YES;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsAddClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = NO;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsConferenceClick:(id)sender {
	[self hideOptions:TRUE animated:TRUE];
	linphone_core_add_all_to_conference(LC);
}

#pragma mark - Animation

- (void)hideAnimation:(BOOL)hidden forView:(UIView *)target completion:(void (^)(BOOL finished))completion {
	if (hidden) {
	int original_y = target.frame.origin.y;
	CGRect newFrame = target.frame;
	newFrame.origin.y = self.view.frame.size.height;
	[UIView animateWithDuration:0.5
		delay:0.0
		options:UIViewAnimationOptionCurveEaseIn
		animations:^{
		  target.frame = newFrame;
		}
		completion:^(BOOL finished) {
		  CGRect originFrame = target.frame;
		  originFrame.origin.y = original_y;
		  target.hidden = YES;
		  target.frame = originFrame;
		  if (completion)
			  completion(finished);
		}];
	} else {
		CGRect frame = target.frame;
		int original_y = frame.origin.y;
		frame.origin.y = self.view.frame.size.height;
		target.frame = frame;
		frame.origin.y = original_y;
		target.hidden = NO;

		[UIView animateWithDuration:0.5
			delay:0.0
			options:UIViewAnimationOptionCurveEaseOut
			animations:^{
			  target.frame = frame;
			}
			completion:^(BOOL finished) {
			  target.frame = frame; // in case application did not finish
			  if (completion)
				  completion(finished);
			}];
	}
}

#pragma mark - My Functions

- (void)setQualityForFirstTime {
    NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Good"];
    NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
    [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
    _lbQuality.attributedText = attr;
}



- (void)changeCamera {
    CABasicAnimation *animationView = [CABasicAnimation animationWithKeyPath:@"transform"];
    self.view.layer.zPosition = 100;
    CATransform3D transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    transform.m34 = 1.0/800.0;
    [animationView setToValue:[NSValue valueWithCATransform3D:transform]];
    [animationView setDuration:0.2];
    [animationView setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [animationView setFillMode:kCAFillModeBoth];
    [animationView setRemovedOnCompletion:YES];
    //[animationView setDelegate:self];
    [_videoPreview.layer addAnimation:animationView forKey:nil];
}

- (void)callEnded {
}

/*----- Kết thúc cuộc gọi trong màn hình video call -----*/
- (void)endVideoCall{
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentcall = linphone_core_get_current_call(lc);
    if (currentcall != nil) {
        linphone_core_terminate_call(lc, currentcall);
    }
}

- (void)whenTapOnVideoCall {
    if (btnHangupVideo.hidden) {
        lbVideoQuality.hidden = NO;
        _lbVideoTime.hidden = NO;
        lbAddressVideoCall.hidden = NO;
        btnMicroVideo.hidden = NO;
        btnSpeakerVideo.hidden = NO;
        btnOffCamera.hidden = NO;
        btnSwitchCamera.hidden = NO;
        btnKeypadVideo.hidden = NO;
        btnHangupVideo.hidden = NO;
    }else{
        lbVideoQuality.hidden = YES;
        _lbVideoTime.hidden = YES;
        lbAddressVideoCall.hidden = YES;
        btnMicroVideo.hidden = YES;
        btnSpeakerVideo.hidden = YES;
        btnOffCamera.hidden = YES;
        btnSwitchCamera.hidden = YES;
        btnKeypadVideo.hidden = YES;
        btnHangupVideo.hidden = YES;
    }
}

- (void)updateAddress {
    [self view]; //Force view load
    __block NSString *addressPhoneNumber = @"";
    __block NSString *avatar = @"";
    __block NSString *fullName = @"";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call != NULL) {
            addressPhoneNumber = [SipUtils getPhoneNumberOfCall:call orLinphoneAddress:nil];
            
            PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: addressPhoneNumber];
            if ([AppUtils isNullOrEmpty: contact.name]) {
                fullName = [[LanguageUtil sharedInstance] getContent:@"Unknown"];
            }else{
                fullName = contact.name;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (isAudioCall) {
                nameLabel.text = fullName;
                lbPhoneNumber.text = addressPhoneNumber;
                
                if (![AppUtils isNullOrEmpty: avatar]) {
                    avatarImage.image = [UIImage imageWithData: [NSData dataFromBase64String: avatar]];
                }else{
                    avatarImage.image = [UIImage imageNamed:@"no_avatar.png"];
                }
            }else{
                lbAddressVideoCall.text = fullName;
            }
        });
    });
}

- (void)setupUIForView {
    [self setupSizeWithDevice];
    
    //  Audio call view
    [callView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    [bgAudioCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(callView);
    }];
    
    avatarImage.backgroundColor = UIColor.redColor;
    [avatarImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(callView.mas_centerX);
        make.centerY.equalTo(callView.mas_centerY);
        make.width.height.mas_equalTo(wAvatar);
    }];
    avatarImage.clipsToBounds = YES;
    avatarImage.layer.borderColor = UIColor.whiteColor.CGColor;
    avatarImage.layer.borderWidth = 2.0;
    avatarImage.layer.cornerRadius = wAvatar/2;
    
    _lbQuality.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightThin];
    [_lbQuality setTextColor: [UIColor whiteColor]];
    [_lbQuality mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(callView.mas_centerX);
        make.bottom.equalTo(avatarImage.mas_top).offset(-marginQuality);
        make.width.mas_equalTo(200.0);
        make.height.mas_equalTo(30);
    }];
    
    durationLabel.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:40.0];
    [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(callView.mas_centerX);
        make.bottom.equalTo(_lbQuality.mas_top);
        make.width.mas_equalTo(200.0);
        make.height.mas_equalTo(50);
    }];
    
    lbPhoneNumber.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    [lbPhoneNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(callView.mas_centerX);
        make.bottom.equalTo(durationLabel.mas_top).offset(-marginPhone);
        make.width.mas_equalTo(200.0);
        make.height.mas_equalTo(30);
    }];
    
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(callView).offset(5.0);
        make.right.equalTo(callView).offset(-5.0);
        make.bottom.equalTo(lbPhoneNumber.mas_top);
        make.height.mas_equalTo(40);
    }];
    nameLabel.marqueeType = MLContinuous;
    nameLabel.scrollDuration = 10.0;
    nameLabel.animationCurve = UIViewAnimationOptionCurveEaseInOut;
    nameLabel.fadeLength = 10.0;
    nameLabel.continuousMarqueeExtraBuffer = 10.0f;
    nameLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    nameLabel.textColor = UIColor.whiteColor;

    [hangupButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(callView.mas_centerX);
        make.bottom.equalTo(callView).offset(-40.0);
        make.width.height.mas_equalTo(wEndIcon);
    }];
    [hangupButton addTarget:self
                     action:@selector(btnHangupButtonPressed)
           forControlEvents:UIControlEventTouchUpInside];
    
    [speakerButton setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
    [speakerButton setImage:[UIImage imageNamed:@"speaker_dis"] forState:UIControlStateDisabled];
    [speakerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(hangupButton.mas_centerY);
        make.right.equalTo(hangupButton.mas_left).offset(-marginIcon);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [microButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(speakerButton);
        make.right.equalTo(speakerButton.mas_left).offset(-marginIcon);
        make.width.mas_equalTo(wSmallIcon);
    }];
    
    callPauseButton.delegate = self;
    [callPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(speakerButton);
        make.left.equalTo(hangupButton.mas_right).offset(marginIcon);
        make.width.mas_equalTo(wSmallIcon);
    }];
    
    [numpadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(speakerButton);
        make.left.equalTo(callPauseButton.mas_right).offset(marginIcon);
        make.width.mas_equalTo(wSmallIcon);
    }];
    [numpadButton addTarget:self
                     action:@selector(showMiniKeypadForAudioCall)
           forControlEvents:UIControlEventTouchUpInside];
    
    //  video call view
    float paddingVideo = 20.0;
    [viewVideoCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    [_videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewVideoCall);
    }];
    
    _videoPreview.backgroundColor = UIColor.blackColor;
    _videoPreview.layer.cornerRadius = 10;
    _videoPreview.layer.borderColor = [UIColor whiteColor].CGColor;
    _videoPreview.layer.borderWidth = 1.0;
    _videoPreview.clipsToBounds = YES;
    [_videoPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewVideoCall).offset(appDelegate._hStatus);
        make.right.equalTo(viewVideoCall).offset(-paddingVideo);
        make.width.mas_equalTo(100.0);
        make.height.mas_equalTo(135.0);
    }];
    
    lbAddressVideoCall.textAlignment = NSTextAlignmentLeft;
    [lbAddressVideoCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewVideoCall).offset(appDelegate._hStatus);
        make.left.equalTo(viewVideoCall).offset(paddingVideo);
        make.right.equalTo(_videoPreview).offset(-paddingVideo);
        make.height.mas_equalTo(50.0);
    }];
    lbAddressVideoCall.marqueeType = MLContinuous;
    lbAddressVideoCall.scrollDuration = 10.0;
    lbAddressVideoCall.animationCurve = UIViewAnimationOptionCurveEaseInOut;
    lbAddressVideoCall.fadeLength = 10.0;
    lbAddressVideoCall.continuousMarqueeExtraBuffer = 10.0f;
    lbAddressVideoCall.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    lbAddressVideoCall.textColor = UIColor.whiteColor;
    
    _lbVideoTime.textAlignment = NSTextAlignmentLeft;
    _lbVideoTime.textColor = UIColor.whiteColor;
    _lbVideoTime.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [_lbVideoTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbAddressVideoCall.mas_bottom).offset(3.0);
        make.left.equalTo(lbAddressVideoCall);
        make.right.equalTo(viewVideoCall.mas_centerX);
        make.height.mas_equalTo(25.0);
    }];
    
    lbVideoQuality.textAlignment = NSTextAlignmentLeft;
    lbVideoQuality.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [lbVideoQuality mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lbVideoTime.mas_bottom).offset(3.0);
        make.left.equalTo(lbAddressVideoCall);
        make.right.equalTo(viewVideoCall.mas_centerX);
        make.height.mas_equalTo(25.0);
    }];
    
    btnOffCamera.tag = 0;
    [btnOffCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewVideoCall.mas_centerX);
        make.bottom.equalTo(viewVideoCall).offset(-20.0);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
    [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_dis"] forState:UIControlStateDisabled];
    [btnSpeakerVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnOffCamera.mas_centerY);
        make.right.equalTo(btnOffCamera.mas_left).offset(-marginIcon);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [btnMicroVideo setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
    [btnMicroVideo setImage:[UIImage imageNamed:@"mute_dis"] forState:UIControlStateDisabled];
    [btnMicroVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnSpeakerVideo.mas_centerY);
        make.right.equalTo(btnSpeakerVideo.mas_left).offset(-marginIcon);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [btnSwitchCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnOffCamera.mas_centerY);
        make.left.equalTo(btnOffCamera.mas_right).offset(marginIcon);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [btnKeypadVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnSwitchCamera.mas_centerY);
        make.left.equalTo(btnSwitchCamera.mas_right).offset(marginIcon);
        make.width.height.mas_equalTo(wSmallIcon);
    }];
    
    [btnHangupVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewVideoCall.mas_centerX);
        make.bottom.equalTo(btnOffCamera.mas_top).offset(-marginIcon);
        make.width.height.mas_equalTo(wEndIcon);
    }];
//    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];
}


//  Kết thúc cuộc gọi hiện tại
- (void)btnHangupButtonPressed {
    // Bien cho biết mình kết thúc cuộc gọi
    appDelegate._meEnded = YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == _videoPreview){
        return FALSE;
    }else{
        // here is remove keyBoard code
        return TRUE;
    }
}

- (void)enableVideoForCurrentCall {
    if (!linphone_core_video_display_enabled(LC))
        return;
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call) {
        LinphoneCallAppData *callAppData = (__bridge LinphoneCallAppData *)linphone_call_get_user_pointer(call);
        callAppData->videoRequested = TRUE; /* will be used later to notify user if video was not activated because of the linphone core*/
        //  LinphoneCallParams *call_params = linphone_core_create_call_params(LC,call);
        LinphoneCallParams* call_params = linphone_call_params_copy(linphone_call_get_current_params(call));
        
        linphone_call_params_enable_video(call_params, TRUE);
        linphone_core_update_call(LC, call, call_params);
        linphone_call_params_destroy(call_params);
    } else {
        NSLog(@"Cannot toggle video button, because no current call");
    }
}

-(void)onSpeakerStateChangedTo:(BOOL)speaker {
    if (isAudioCall) {
        if (speaker) {
            [speakerButton setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
        }else{
            [speakerButton setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
        }
    }else{
        if (speaker) {
            [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
        }else{
            [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_normal"] forState:UIControlStateNormal];
        }
    }
}

- (void)onMuteStateChangedTo:(BOOL)muted {
    if (isAudioCall) {
        if (muted) {
            [microButton setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
        }else{
            [microButton setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
        }
    }else{
        if (muted) {
            [btnMicroVideo setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
        }else{
            [btnMicroVideo setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
        }
    }
}

-(void)onPauseStateChangedTo:(BOOL)paused {
    if (isAudioCall) {
        if (paused) {
            [callPauseButton setImage:[UIImage imageNamed:@"hold_enable"] forState:UIControlStateNormal];
        }else{
            [callPauseButton setImage:[UIImage imageNamed:@"hold_normal"] forState:UIControlStateNormal];
        }
    }else{
        
    }
}

- (IBAction)btnMicroVideoClick:(id)sender {
    BOOL micEnable = linphone_core_mic_enabled(LC);
    if (micEnable) {
        linphone_core_enable_mic(LC, false);
        [sender setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
    }else{
        linphone_core_enable_mic(LC, true);
        [sender setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
    }
}

- (void)updateStateForSpekearButton {
    [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_enable"] forState:UIControlStateNormal];
}

- (IBAction)btnSpeakerVideoClick:(id)sender {
    if ([DeviceUtils isConnectedEarPhone]) {
        [self showOptionChooseRouteOutputForCall];
        
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

- (IBAction)btnOffCameraClick:(UIButton *)sender {
    if (sender.tag == 0) {
        linphone_core_enable_video_preview(LC, NO);
        linphone_call_enable_camera(linphone_core_get_current_call(LC), NO);
        sender.tag = 1;
        
        viewOffCam.hidden = NO;
        [sender setImage:[UIImage imageNamed:@"cam_enable.png"] forState:UIControlStateNormal];
    }else{
        linphone_core_enable_video_preview(LC, YES);
        linphone_call_enable_camera(linphone_core_get_current_call(LC), YES);
        sender.tag = 0;
        viewOffCam.hidden = YES;
        [sender setImage:[UIImage imageNamed:@"cam_normal.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)btnSwitchCameraClick:(id)sender {
    
}

- (IBAction)btnKeypadVideoClick:(id)sender {
    [self showMiniKeypadOnView: viewVideoCall];
}

- (IBAction)btnHangupVideoClick:(id)sender {
}

- (void)setupSizeWithDevice {
    marginQuality = 50.0;
    marginPhone = 30.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        wAvatar = 110.0;
        wEndIcon = 60.0;
        wSmallIcon = 45.0;
        marginQuality = 30.0;
        marginIcon = 10.0;
        marginPhone = 20.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        wAvatar = 130.0;
        wEndIcon = 70.0;
        wSmallIcon = 55.0;
        marginIcon = 10.0;
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        wAvatar = 150.0;
        wEndIcon = 75.0;
        wSmallIcon = 58.0;
        marginIcon = 12.0;
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        wAvatar = 150.0;
        wEndIcon = 75.0;
        wSmallIcon = 58.0;
        marginIcon = 12.0;
    }else{
        //  Screen width: 375.000000 - Screen height: 812.000000
        wAvatar = 150.0;
        wEndIcon = 75.0;
        wSmallIcon = 58.0;
        marginIcon = 12.0;
    }
}

- (void)createOffCameraView {
    if (viewOffCam == nil) {
        viewOffCam = [[UIView alloc] init];
        viewOffCam.hidden = YES;
        [_videoPreview addSubview: viewOffCam];
        viewOffCam.backgroundColor = UIColor.blackColor;
        [viewOffCam mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(_videoPreview);
        }];
        
        imgOffCam = [[UIImageView alloc] init];
        imgOffCam.image = [UIImage imageNamed:@"cam_enable.png"];
        [viewOffCam addSubview: imgOffCam];
        [imgOffCam mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(viewOffCam.mas_centerX);
            make.centerY.equalTo(viewOffCam.mas_centerY);
            make.width.height.mas_equalTo(35.0);
        }];
    }
}

- (IBAction)speakerButtonPress:(UIButton *)sender {
    if ([DeviceUtils isConnectedEarPhone]) {
        [self showOptionChooseRouteOutputForCall];
        
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

- (IBAction)microButtonPress:(UIButton *)sender {
    BOOL micEnable = linphone_core_mic_enabled(LC);
    if (micEnable) {
        linphone_core_enable_mic(LC, false);
        [sender setImage:[UIImage imageNamed:@"mute_enable"] forState:UIControlStateNormal];
    }else{
        linphone_core_enable_mic(LC, true);
        [sender setImage:[UIImage imageNamed:@"mute_normal"] forState:UIControlStateNormal];
    }
}

- (void)showOptionChooseRouteOutputForCall {
    UIAlertController * alertViewController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* hideAction = [UIAlertAction actionWithTitle:[[LanguageUtil sharedInstance] getContent:@"Hide"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
    [hideAction setValue:UIColor.redColor forKey:@"titleTextColor"];
    [alertViewController addAction: hideAction];
    
    
    UIViewController *contentVC = [[UIViewController alloc] init];
    [contentVC setPreferredContentSize:CGSizeMake(alertViewController.view.frame.size.width, 58.0*3)];
    
    UITableView *tbRoutes = [[UITableView alloc] init];
    tbRoutes.separatorStyle = UITableViewCellSeparatorStyleNone;
    tbRoutes.delegate = self;
    tbRoutes.scrollEnabled = NO;
    tbRoutes.dataSource = self;
    [contentVC.view addSubview: tbRoutes];
    [tbRoutes mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(contentVC.view);
    }];
    [alertViewController setValue:contentVC forKey:@"contentViewController"];
    
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
        if (isAudioCall) {
            [speakerButton setImage:[UIImage imageNamed:@"speaker_bluetooth_enable"]
                           forState:UIControlStateNormal];
        }else{
            [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_bluetooth_enable"]
                             forState:UIControlStateNormal];
        }
    });
}

- (void)uiForSpeakerEnabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isAudioCall) {
            [speakerButton setImage:[UIImage imageNamed:@"speaker_enable"]
                           forState:UIControlStateNormal];
        }else{
            [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_enable"]
                             forState:UIControlStateNormal];
        }
    });
}

- (void)uiForiPhoneReceiverEnabled{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isAudioCall) {
            [speakerButton setImage:[UIImage imageNamed:@"speaker_normal"]
                           forState:UIControlStateNormal];
        }else{
            [btnSpeakerVideo setImage:[UIImage imageNamed:@"speaker_normal"]
                             forState:UIControlStateNormal];
        }
    });
}
    
@end
