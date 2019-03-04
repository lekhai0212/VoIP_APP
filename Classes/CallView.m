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
#import <AVFoundation/AVCaptureDevice.h>
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
#import "Utils.h"
#include "linphone/linphonecore.h"

#import "NSData+Base64.h"
#import "UIConferenceCell.h"
#import "ContactDetailObj.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "UploadPicture.h"
#import "UIImageView+WebCache.h"
#import "ConferenceTableViewCell.h"
#import "AudioCallView.h"
#import "VideoCallView.h"

#define kMaxRadius 200
#define kMaxDuration 10

void message_received(LinphoneCore *lc, LinphoneChatRoom *room, const LinphoneAddress *from, const char *message) {
    printf(" Message [%s] received from [%s] \n",message,linphone_address_as_string (from));
}

const NSInteger SECURE_BUTTON_TAG = 5;

@interface CallView (){
    LinphoneAppDelegate *appDelegate;
    const MSList *list;
    
    NSTimer *qualityTimer;
    
    BOOL needEnableSpeaker;
    LinphoneCallDir callDirection;
    
    AudioCallView *audioCallView;
    VideoCallView *videoCallView;
}

@end

@implementation CallView {
	BOOL hiddenVolume;
}
@synthesize bgCall;
@synthesize _lbQuality;

@synthesize durationTimer, phoneNumber;

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

- (void)viewDidLoad {
	[super viewDidLoad];

    //  Add ney by Khai Le on 09/11/2017
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	_routesEarpieceButton.enabled = !IPAD;

// TODO: fixme! video preview frame is too big compared to openGL preview
// frame, so until this is fixed, temporary disabled it.
#if 0
#endif
    singleFingerTap.numberOfTapsRequired = 2;
    singleFingerTap.cancelsTouchesInView = NO;

    //  Added by Khai Le on 06/10/2018
    _durationLabel.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
    _durationLabel.textColor = UIColor.whiteColor;
}

- (void)dealloc {
	[PhoneMainView.instance.view removeGestureRecognizer:singleFingerTap];
	// Remove all observer
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    // Set windows (warn memory leaks)
    if (videoCallView != nil) {
        linphone_core_set_native_video_window_id(LC, (__bridge void *)(videoCallView.videoView));
        linphone_core_set_native_preview_window_id(LC, (__bridge void *)(videoCallView.previewVideo));
    }
    
    if (LinphoneManager.instance.bluetoothAvailable) {
        NSLog(@"Test: BLuetooth da ket noi");
    }else{
        NSLog(@"Test: Khong thay gi");
    }
    
    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
    if (count > 0) {
        phoneNumber = [self getPhoneNumberOfCall];
        
        LinphoneCall *curCall = linphone_core_get_current_call([LinphoneManager getLc]);
        if (curCall != NULL) {
            LinphoneCallState callState = linphone_call_get_state(curCall);
            NSLog(@"call state = %d", callState);
            
            BOOL videoEnabled = linphone_call_params_video_enabled(linphone_call_get_remote_params(curCall));
            if (videoEnabled) {
                [self addVideoCallView];
            }else{
                [self addAudioCallView];
            }
        }
    }
    
    [WriteLogsUtils writeForGoToScreen: @"CallView"];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"------------> phone number is %@", phoneNumber] toFilePath:appDelegate.logFilePath];
    
    //  [Khai le - 03/11/2018]
    PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: phoneNumber];
    if (![AppUtils isNullOrEmpty: contact.avatar]) {
        
    }else{
        
    }
    
    //  Leo Kelvin
    _bottomBar.hidden = YES;
    _bottomBar.clipsToBounds = YES;
    
	LinphoneManager.instance.nextCallIsTransfer = NO;
    _nameLabel.text = @"";

	// Update on show
	[self hideRoutes:TRUE animated:FALSE];
	[self hideOptions:TRUE animated:FALSE];
	[self callDurationUpdate];
	
	// Enable tap
    singleFingerTap.enabled = YES;
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bluetoothAvailabilityUpdateEvent:)
											   name:kLinphoneBluetoothAvailabilityUpdate object:nil];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(headsetPluginChanged:)
                                               name:@"headsetPluginChanged" object:nil];
    //  Update address
    [self updateAddress];
    
    [self btnHideKeypadPressed];
    
    _callView.hidden = NO;
    if (count == 0) {
        _durationLabel.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
        _durationLabel.textColor = UIColor.whiteColor;
    }else{
        LinphoneCall *curCall = linphone_core_get_current_call([LinphoneManager getLc]);
        if (curCall == NULL) {
            [[PhoneMainView instance] popCurrentView];
        }else{
            callDirection = linphone_call_get_dir(curCall);
            if (callDirection == LinphoneCallIncoming) {
                [self countUpTimeForCall];
                [self updateQualityForCall];
            }
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (audioCallView != nil) {
        [audioCallView updatePositionHaloView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIDevice.currentDevice.proximityMonitoringEnabled = YES;

	[PhoneMainView.instance setVolumeHidden:TRUE];
	hiddenVolume = TRUE;

	// we must wait didAppear to reset fullscreen mode because we cannot change it in viewwillappear
	LinphoneCall *call = linphone_core_get_current_call(LC);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state animated:FALSE message:@""];
    
    [self requestAccessToMicroIfNot];
    
    UIButton *bluetooth = [[UIButton alloc] initWithFrame:CGRectMake(10, 50, 100, 50)];
    bluetooth.backgroundColor = UIColor.redColor;
    [bluetooth setTitle:@"bluetooth" forState:UIControlStateNormal];
    [bluetooth addTarget:self
                  action:@selector(testtest)
        forControlEvents:UIControlEventTouchUpInside];
    //  [self.view addSubview: bluetooth];
    
    UIButton *speaker = [[UIButton alloc] initWithFrame:CGRectMake(120, 50, 100, 50)];
    speaker.backgroundColor = UIColor.redColor;
    [speaker setTitle:@"speaker" forState:UIControlStateNormal];
    [speaker addTarget:self
                action:@selector(testtest1)
      forControlEvents:UIControlEventTouchUpInside];
    //  [self.view addSubview: speaker];
    
    UIButton *normal = [[UIButton alloc] initWithFrame:CGRectMake(230, 50, 100, 50)];
    normal.backgroundColor = UIColor.redColor;
    [normal setTitle:@"normal" forState:UIControlStateNormal];
    [normal addTarget:self
               action:@selector(testtest2)
     forControlEvents:UIControlEventTouchUpInside];
    //  [self.view addSubview: normal];
}

- (AVAudioSessionPortDescription*)bluetoothAudioDevice
{
    NSArray* bluetoothRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    return [self audioDeviceFromTypes:bluetoothRoutes];
}

- (void)enableBluetooth{
    [LinphoneManager.instance setBluetoothEnabled:TRUE];
}

- (void)testtest {
    [LinphoneManager.instance setSpeakerEnabled:TRUE];
    [self performSelector:@selector(enableBluetooth)
               withObject:nil afterDelay:0.5];
    
//
//    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
//    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
        //  [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
}

- (void)disableBluetooth{
    [LinphoneManager.instance setBluetoothEnabled:FALSE];
}

- (void)testtest1 {
    [LinphoneManager.instance setSpeakerEnabled:TRUE];
    [self performSelector:@selector(disableBluetooth)
               withObject:nil afterDelay:0.5];
    
//    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
//    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
}

- (void)testtest2 {
    [LinphoneManager.instance setSpeakerEnabled:FALSE];
    [self performSelector:@selector(disableBluetooth)
               withObject:nil afterDelay:0.5];
    
//    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
//    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
}

- (AVAudioSessionPortDescription*)audioDeviceFromTypes:(NSArray*)types
{
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if ([types containsObject:route.portType])
        {
            return route;
        }
    }
    return nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

    
	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:false];
	UIDevice.currentDevice.proximityMonitoringEnabled = NO;

	[PhoneMainView.instance fullScreen:false];
	// Disable tap
	[singleFingerTap setEnabled:FALSE];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self hideStatusBar:!videoHidden && (_nameLabel.alpha <= 0.f)];
}

- (void)updateBottomBar:(LinphoneCall *)call state:(LinphoneCallState)state {
	//  [_speakerButton update];
	//  [_callPauseButton update];
	[_hangupButton update];

	_optionsButton.enabled = (!call || !linphone_core_sound_resources_locked(LC));
    //  Closed by Khai Le on 07/10/2018
	//  _optionsTransferButton.enabled = call && !linphone_core_sound_resources_locked(LC);
	// enable conference button if 2 calls are presents and at least one is not in the conference
	int confSize = linphone_core_get_conference_size(LC) - (linphone_core_is_in_conference(LC) ? 1 : 0);
	_optionsConferenceButton.enabled =
		((linphone_core_get_calls_nb(LC) > 1) && (linphone_core_get_calls_nb(LC) != confSize));

	switch (state) {
		case LinphoneCallEnd:
		case LinphoneCallError:
		case LinphoneCallIncoming:
		case LinphoneCallOutgoing:
			[self hideOptions:TRUE animated:TRUE];
			[self hideRoutes:TRUE animated:TRUE];
		default:
			break;
	}
}

- (void)toggleControls:(id)sender {
	
}

- (void)hideStatusBar:(BOOL)hide {
	/* we cannot use [PhoneMainView.instance show]; because it will automatically
	 resize current view to fill empty space, which will resize video. This is
	 indesirable since we do not want to crop/rescale video view */
	PhoneMainView.instance.mainViewController.statusBarView.hidden = hide;
}

- (void)callDurationUpdate
{
//    int size = linphone_core_get_conference_size(LC);
//    NSLog(@"KL-----size: %d", size);
    int duration;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    if (list != NULL) {
        duration = linphone_call_get_duration((LinphoneCall*)list->data);
        _durationLabel.text = [LinphoneUtils durationToString:duration];
        _durationLabel.textColor = UIColor.greenColor;
        _lbQuality.hidden = NO;
    }else{
        duration = 0;
        _lbQuality.hidden = YES;
    }
}

//  Call quality
- (void)callQualityUpdate {
    LinphoneCall *call;
    list = linphone_core_get_calls([LinphoneManager getLc]);
    if (list == NULL) {
        if (qualityTimer != nil) {
            [qualityTimer invalidate];
            qualityTimer = nil;
        }
        return;
    }
    call = (LinphoneCall*)list->data;
    
    if(call != NULL) {
        //FIXME double check call state before computing, may cause core dump
        float quality = linphone_call_get_average_quality(call);
        if (quality < 0) {
            //  Hide call quality value if have not connected yet
        }else if(quality < 1) {
            NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Worse"];
            NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
            
            _lbQuality.attributedText = attr;
            
        } else if (quality < 2) {
            NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Very low"];
            NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.orangeColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
            
            _lbQuality.attributedText = attr;
            
        } else if (quality < 3) {
            NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Low"];
            NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
            
            _lbQuality.attributedText = attr;
            
        } else if(quality < 4){
            NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Average"];
            NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
            
            _lbQuality.attributedText = attr;
            
        } else{
            NSString *qualityValue = [[LanguageUtil sharedInstance] getContent:@"Good"];
            NSString *quality = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Quality"], qualityValue];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: quality];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, quality.length)];
            [attr addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(quality.length-qualityValue.length, qualityValue.length)];
            
            _lbQuality.attributedText = attr;
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
	_routesEarpieceButton.selected = !_routesBluetoothButton.selected;

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
	//  _speakerButton.hidden = hidden;
	//  _routesButton.hidden = !hidden;
}

#pragma mark - Event Functions

- (void)bluetoothAvailabilityUpdateEvent:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool available = [[notif.userInfo objectForKey:@"available"] intValue];
        [self hideSpeaker:available];
        //  [Khai Le - 25/01/2019]
        if (available) {
            //  [LinphoneManager.instance setSpeakerEnabled:FALSE];
            //  [LinphoneManager.instance setBluetoothEnabled:TRUE];
            
//            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]:\n-------------> setSpeakerEnabled = FALSE and setBluetoothEnabled = TRUE \n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
        }
    });
}

- (void)callUpdateEvent:(NSNotification *)notif {
    NSString *message = [notif.userInfo objectForKey:@"message"];
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
    [self callUpdate:call state:state animated:TRUE message: message];
}

- (NSString *)createDirectory {
    NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    NSString *path = [NSString stringWithFormat:@"%@/%@", appFolderPath, @"test.mp3"];
    NSLog(@"%@", path);
    return path;
}

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated message: (NSString *)message
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] The current call state is %d, with message = %@", __FUNCTION__, state, message] toFilePath:appDelegate.logFilePath];
    
	[self updateBottomBar:call state:state];
	if (hiddenVolume) {
		[PhoneMainView.instance setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
    
    [self btnHideKeypadPressed];
    _callView.hidden = NO;
    
	static LinphoneCall *currentCall = NULL;
	if (!currentCall || linphone_core_get_current_call(LC) != currentCall) {
		currentCall = linphone_core_get_current_call(LC);
	}

	// Fake call update
	if (call == NULL) {
		return;
	}

	if (state != LinphoneCallPausedByRemote) {
		_pausedByRemoteView.hidden = YES;
	}

	switch (state) {
        case LinphoneCallOutgoingRinging:{
            _durationLabel.text = [[LanguageUtil sharedInstance] getContent:@"Ringing"];
            _durationLabel.textColor = UIColor.whiteColor;
            
            [self getPhoneNumberOfCall];
            break;
        }
        case LinphoneCallIncomingReceived:{
            [self getPhoneNumberOfCall];
            NSLog(@"incomming");
            break;
        }
        case LinphoneCallOutgoingProgress:{
            _durationLabel.text = [[LanguageUtil sharedInstance] getContent:@"Calling"];
            _durationLabel.textColor = UIColor.whiteColor;
            
            break;
        }
        case LinphoneCallOutgoingInit:{
            break;
        }
        case LinphoneCallConnected:{
            //  Check if in call with hotline
            _lbQuality.hidden = NO;
            
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

#pragma mark - Action Functions

- (IBAction)onNumpadClick:(id)sender{}

- (void)fadeIn :(UIView*)view{
    view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    view.alpha = 0.0;
    [UIView animateWithDuration:.35 animations:^{
        view.transform = CGAffineTransformMakeScale(1.0, 1.0);
        view.alpha = 1.0;
    }];
}

- (IBAction)onChatClick:(id)sender {
	[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
}

- (IBAction)onRoutesBluetoothClick:(id)sender {
	//  [self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:TRUE];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]:\n-------------> setSpeakerEnabled = FALSE and setBluetoothEnabled = TRUE \n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
}

- (IBAction)onRoutesEarpieceClick:(id)sender {
	//  [self hideRoutes:TRUE animated:TRUE];
	[LinphoneManager.instance setSpeakerEnabled:FALSE];
	[LinphoneManager.instance setBluetoothEnabled:FALSE];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]:\n-------------> setSpeakerEnabled = FALSE and setBluetoothEnabled = FALSE \n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
}

- (IBAction)onRoutesSpeakerClick:(id)sender
{
    if (![(UIButton *)sender isSelected]) {
        [LinphoneManager.instance setBluetoothEnabled:TRUE];
        [LinphoneManager.instance setSpeakerEnabled:FALSE];
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]:\n-------------> setBluetoothEnabled = TRUE and setSpeakerEnabled = FALSE \n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
        
    }else{
        [LinphoneManager.instance setBluetoothEnabled:FALSE];
        [LinphoneManager.instance setSpeakerEnabled:TRUE];
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]:\n-------------> setBluetoothEnabled = FALSE and setSpeakerEnabled = TRUE \n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
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

- (IBAction)onOptionsTransferClick:(id)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\n------------->[%s]\n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = YES;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsAddClick:(id)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\n------------->[%s]\n", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
	[self hideOptions:TRUE animated:TRUE];
	DialerView *view = VIEW(DialerView);
	[view setAddress:@""];
	LinphoneManager.instance.nextCallIsTransfer = NO;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

- (IBAction)onOptionsConferenceClick:(id)sender{}

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

#pragma mark - Bounce

- (void)updateUnreadMessage:(BOOL)appear {
	int unreadMessage = [LinphoneManager unreadMessageCount];
	if (unreadMessage > 0) {
		_chatNotificationLabel.text = [NSString stringWithFormat:@"%i", unreadMessage];
		[_chatNotificationView startAnimating:appear];
	} else {
		[_chatNotificationView stopAnimating:appear];
	}
}

#pragma mark - My Functions

//  Hide keypad mini
- (void)btnHideKeypadPressed
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:appDelegate.logFilePath];
    
    for (UIView *subView in _callView.subviews) {
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

/*----- Kết thúc cuộc gọi trong màn hình video call -----*/
- (void)endVideoCall{
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentcall = linphone_core_get_current_call(lc);
    if (currentcall != nil) {
        linphone_core_terminate_call(lc, currentcall);
    }
}

- (void)updateAddress {
    [self view]; //Force view load
    PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: phoneNumber];
    NSLog(@"%@", contact.name);
    _nameLabel.text = contact.name;
}

//  Kết thúc cuộc gọi hiện tại
- (void)btnHangupButtonPressed {
    // Bien cho biết mình kết thúc cuộc gọi
    appDelegate._meEnded = YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return TRUE;
}

- (NSString *)getPhoneNumberOfCall {
    __block NSString *addressPhoneNumber = @"";
    LinphoneCore* lc = [LinphoneManager getLc];
    list = linphone_core_get_calls(lc);
    if (list != NULL) {
        LinphoneCall* call = list->data;
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
                    addressPhoneNumber = [[NSString alloc] initWithString: phoneStr];
                    return addressPhoneNumber;
                }
                ms_free(lAddress);
            }
        }
    }
    
    return @"";
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
                _durationLabel.text = [[LanguageUtil sharedInstance] getContent:@"The user is busy"];
                _durationLabel.textColor = UIColor.whiteColor;
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
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"%s", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    
    int count = linphone_core_get_calls_nb([LinphoneManager getLc]);
    if (count == 0) {
        if (durationTimer != nil) {
            [durationTimer invalidate];
            durationTimer = nil;
        }
        
        phoneNumber = @"";
        
        // Remove observer
        [NSNotificationCenter.defaultCenter removeObserver:self];
    }else{
        NSLog(@"Van con call ne");
    }
    
    if ([PhoneMainView instance].currentView == CallView.compositeViewDescription) {
        [[PhoneMainView instance] popCurrentView];
    }else{
        NSLog(@"Not popCurrentView");
    }
    
    if ([LinphoneAppDelegate sharedInstance].callTransfered) {
        [LinphoneAppDelegate sharedInstance].callTransfered = NO;
        
        [[LinphoneAppDelegate sharedInstance].window makeToast:[[LanguageUtil sharedInstance] getContent:@"Your call has been transfered"] duration:3.0 position:CSToastPositionCenter];
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

- (void)headsetPluginChanged: (NSNotification *)notif {
    if (notif.object != nil && [notif.object isKindOfClass:[NSNumber class]]) {
        int routeChangeReason = [notif.object intValue];
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            if (needEnableSpeaker) {
                
            }else{
                
            }
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable", __FUNCTION__]
                                 toFilePath:appDelegate.logFilePath];
        }
        if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable) {
            
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable", __FUNCTION__]
                                 toFilePath:appDelegate.logFilePath];
        }
    }
}

- (NSString *)getPhoneNumberOfCall: (LinphoneCall *)call {
    NSString *phone = @"";
    const LinphoneAddress* addr = linphone_call_get_remote_address(call);
    if (addr != NULL) {
        // contact name
        char* lAddress = linphone_address_as_string_uri_only(addr);
        if(lAddress) {
            NSString *normalizedSipAddress = [SipUtils normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            if (normalizedSipAddress.length >= 7) {
                phone = [normalizedSipAddress substringWithRange:NSMakeRange(4, 10)];
            }
            ms_free(lAddress);
        }
    }
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] result is %@", __FUNCTION__, phone]
                         toFilePath:appDelegate.logFilePath];
    
    return phone;
}

- (void)requestAccessToMicroIfNot
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:appDelegate.logFilePath];
    
    //show warning Microphone
    if (IS_IOS7) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted){
            if (granted) {
                NSLog(@"granted");
            } else {
                NSLog(@"denied");
            }
        }];
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
            if (granted) {
                NSLog(@"granted");
            } else {
                NSLog(@"denied");
            }
        }];
    }
}

- (void)addAudioCallView {
    if (audioCallView == nil) {
        audioCallView = [[[NSBundle mainBundle] loadNibNamed:@"AudioCallView" owner:nil options:nil] lastObject];
        [self.view addSubview: audioCallView];
        [audioCallView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(self.view);
        }];
        [audioCallView setupUIForView];
        [audioCallView registerNotifications];
    }
}

- (void)addVideoCallView {
    if (videoCallView == nil) {
        videoCallView = [[[NSBundle mainBundle] loadNibNamed:@"VideoCallView" owner:nil options:nil] lastObject];
        [self.view addSubview: videoCallView];
        [videoCallView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(self.view);
        }];
        
        [videoCallView setupUIForView];
        [videoCallView registerNotifications];
        
        
        if (videoCallView != nil) {
            linphone_core_set_native_video_window_id(LC, (__bridge void *)(videoCallView.videoView));
            linphone_core_set_native_preview_window_id(LC, (__bridge void *)(videoCallView.previewVideo));
        }
    }
}

@end
