/* LinphoneAppDelegate.m
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

#import "PhoneMainView.h"
#import "SignInViewController.h"


#import "ContactsListView.h"
#import "ContactDetailsView.h"
#import "ShopView.h"
#import "LinphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"

#import "ContactObject.h"
#import "ContactDetailObj.h"
#import "JSONKit.h"
#import "AppUtils.h"
#import "PBXContact.h"
#include <Intents/INInteraction.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "NSData+Base64.h"
#import "PhoneObject.h"
#import <Intents/Intents.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface LinphoneAppDelegate (){
    Reachability* hostReachable;
    
    ABAddressBookRef addressListBook;
    NSThread *getContactThread;
    NSThread *addContactThread;
}
@end

@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;

@synthesize internetActive, internetReachable;
@synthesize localization;
@synthesize _hRegistrationState, _hStatus, _hHeader, _hTabbar;
@synthesize _deviceToken, _updateTokenSuccess;
@synthesize _meEnded;
@synthesize _acceptCall;
@synthesize listContacts, pbxContacts;
@synthesize idContact;
@synthesize _database, _databasePath;
@synthesize _busyForCall;
@synthesize _newContact;
@synthesize _cropAvatar, _dataCrop;
@synthesize fromImagePicker;
@synthesize _isSyncing;
@synthesize contactLoaded;
@synthesize webService, keepAwakeTimer, listNumber, listInfoPhoneNumber, supportLoginWithPhoneNumber, logFilePath, dbQueue, splashScreen;
@synthesize supportVoice;
@synthesize contactType, historyType, callTransfered, hNavigation, hasBluetoothEar, ipadWaiting;
@synthesize phoneForCall, configPushToken, supportVideoCall, callPrefix, randomKey, hashStr, listGroup;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super init];
	if (self != nil) {
		startedInBackground = FALSE;
	}
	return self;
	[[UIApplication sharedApplication] setDelegate:self];
}

#pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\n%s", __FUNCTION__]
                         toFilePath:logFilePath];
    
    LinphoneCall *currentCall = linphone_core_get_current_call(LC);
    if (currentCall == nil) {
        LinphoneProxyConfig *defaultConfig = linphone_core_get_default_proxy_config(LC);
        if (defaultConfig != NULL) {
            [self tryToUnRegisterSIP];
            //  [SipUtils enableProxyConfig:defaultConfig withValue:NO withRefresh:TRUE];
        }
    }
    
	//  [LinphoneManager.instance enterBackgroundMode];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"%s", __FUNCTION__]
                         toFilePath:logFilePath];
    
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (call) {
		/* save call context */
		LinphoneManager *instance = LinphoneManager.instance;
		instance->currentCallContextBeforeGoingBackground.call = call;
		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);

		const LinphoneCallParams *params = linphone_call_get_current_params(call);
		if (linphone_call_params_video_enabled(params)) {
			linphone_call_enable_camera(call, false);
		}
	}

	if (![LinphoneManager.instance resignActive]) {
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\n%s", __FUNCTION__]
                         toFilePath:logFilePath];
    
    [self checkToReloginPBX];
    
	if (startedInBackground) {
		startedInBackground = FALSE;
		[PhoneMainView.instance startUp];
		[PhoneMainView.instance updateStatusBar:nil];
	}
	LinphoneManager *instance = LinphoneManager.instance;
	[instance becomeActive];
	
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (call) {
        [self showSplashScreenOnView: NO];
        
		if (call == instance->currentCallContextBeforeGoingBackground.call) {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] currentCallContextBeforeGoingBackground", __FUNCTION__] toFilePath:logFilePath];
            
			const LinphoneCallParams *params = linphone_call_get_current_params(call);
			if (linphone_call_params_video_enabled(params)) {
				linphone_call_enable_camera(call, instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
			}
			instance->currentCallContextBeforeGoingBackground.call = 0;
		} else if (linphone_call_get_state(call) == LinphoneCallIncomingReceived) {
			LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
			if (data && data->timer) {
				[data->timer invalidate];
				data->timer = nil;
			}
			if ((floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)) {
				if ([LinphoneManager.instance lpConfigBoolForKey:@"autoanswer_notif_preference"]) {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] call function linphone_core_accept_call and go to CallView", __FUNCTION__] toFilePath:logFilePath];
                    
					linphone_core_accept_call(LC, call);
					[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
				} else {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] displayIncomingCall", __FUNCTION__] toFilePath:logFilePath];
                    
					[PhoneMainView.instance displayIncomingCall:call];
				}
			} else if (linphone_core_get_calls_nb(LC) > 1) {
				[PhoneMainView.instance displayIncomingCall:call];
			}

			// in this case, the ringing sound comes from the notification.
			// To stop it we have to do the iOS7 ring fix...
			[self fixRing];
		}
    }else{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] -------------> Don't have call", __FUNCTION__] toFilePath:logFilePath];
        
        LinphoneProxyConfig *defaultConfig = linphone_core_get_default_proxy_config(LC);
        if (defaultConfig != NULL) {
            [SipUtils enableProxyConfig:defaultConfig withValue:YES withRefresh:TRUE];
        }
        
        NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:UserActivity];
        if (![AppUtils isNullOrEmpty: phoneNumber])
        {
            AccountState accState = [SipUtils getStateOfDefaultProxyConfig];
            switch (accState) {
                case eAccountNone:
                {
                    //  reset value
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserActivity];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [self.window makeToast:[[LanguageUtil sharedInstance] getContent:@"You have not signed your account yet"] duration:3.0 position:CSToastPositionCenter];
                    [self performSelector:@selector(hideSplashScreen) withObject:nil afterDelay:3.0];
                    
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Call with UserActivity phone number = %@, but have not signed with any account", phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                    
                    break;
                }
                case eAccountOff:
                {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Call with UserActivity phone number = %@, but current account was off", phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                    
                    UIAlertView *alertAcc = [[UIAlertView alloc] initWithTitle:nil message:[[LanguageUtil sharedInstance] getContent:@"Your account was turned off. Do you want to enable and call?"] delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"No"] otherButtonTitles: [[LanguageUtil sharedInstance] getContent:@"Yes"], nil];
                    alertAcc.delegate = self;
                    alertAcc.tag = 100;
                    [alertAcc show];
                    
                    break;
                }
                default:
                    break;
            }
            if (accState == eAccountNone) {
                
            }else if (accState == eAccountOff){
                
            }else{
                //  Check registration state
                LinphoneRegistrationState state = [SipUtils getRegistrationStateOfDefaultProxyConfig];
                if (state == LinphoneRegistrationOk) {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Call with UserActivity phone number = %@", phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                    
                    splashScreen.hidden = YES;
                    
                    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:IS_VIDEO_CALL_KEY];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [SipUtils makeCallWithPhoneNumber: phoneNumber];
                    
                    //  reset value
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserActivity];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }else {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Call with UserActivity phone number = %@, but waiting for register to SIP", phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                }
            }
        }
    }
	[LinphoneManager.instance.iapManager check];
}

- (void)hideSplashScreen {
    splashScreen.hidden = YES;
}

#pragma deploymate push "ignored-api-availability"
- (UIUserNotificationCategory *)getMessageNotificationCategory {
	NSArray *actions;

	if ([[UIDevice.currentDevice systemVersion] floatValue] < 9 ||
		[LinphoneManager.instance lpConfigBoolForKey:@"show_msg_in_notif"] == NO) {

		UIMutableUserNotificationAction *reply = [[UIMutableUserNotificationAction alloc] init];
		reply.identifier = @"reply";
		reply.title = NSLocalizedString(@"Reply", nil);
		reply.activationMode = UIUserNotificationActivationModeForeground;
		reply.destructive = NO;
		reply.authenticationRequired = YES;

		UIMutableUserNotificationAction *mark_read = [[UIMutableUserNotificationAction alloc] init];
		mark_read.identifier = @"mark_read";
		mark_read.title = NSLocalizedString(@"Mark Read", nil);
		mark_read.activationMode = UIUserNotificationActivationModeBackground;
		mark_read.destructive = NO;
		mark_read.authenticationRequired = NO;

		actions = @[ mark_read, reply ];
	} else {
		// iOS 9 allows for inline reply. We don't propose mark_read in this case
		UIMutableUserNotificationAction *reply_inline = [[UIMutableUserNotificationAction alloc] init];

		reply_inline.identifier = @"reply_inline";
		reply_inline.title = NSLocalizedString(@"Reply", nil);
		reply_inline.activationMode = UIUserNotificationActivationModeBackground;
		reply_inline.destructive = NO;
		reply_inline.authenticationRequired = NO;
		reply_inline.behavior = UIUserNotificationActionBehaviorTextInput;

		actions = @[ reply_inline ];
	}

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_msg";
	[localRingNotifAction setActions:actions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:actions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (UIUserNotificationCategory *)getCallNotificationCategory {
	UIMutableUserNotificationAction *answer = [[UIMutableUserNotificationAction alloc] init];
	answer.identifier = @"answer";
	answer.title = NSLocalizedString(@"Answer", nil);
	answer.activationMode = UIUserNotificationActivationModeForeground;
	answer.destructive = NO;
	answer.authenticationRequired = YES;
    
	UIMutableUserNotificationAction *decline = [[UIMutableUserNotificationAction alloc] init];
	decline.identifier = @"decline";
	decline.title = NSLocalizedString(@"Decline", nil);
	decline.activationMode = UIUserNotificationActivationModeBackground;
	decline.destructive = YES;
	decline.authenticationRequired = NO;

	NSArray *localRingActions = @[ decline, answer ];

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_call";
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (UIUserNotificationCategory *)getAccountExpiryNotificationCategory {
	
	UIMutableUserNotificationCategory *expiryNotification = [[UIMutableUserNotificationCategory alloc] init];
	expiryNotification.identifier = @"expiry_notification";
	return expiryNotification;
}


- (void)registerForNotifications:(UIApplication *)app {
	self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
	self.voipRegistry.delegate = self;

	// Initiate registration.
	self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
		// Call category
		UNNotificationAction *act_ans =
			[UNNotificationAction actionWithIdentifier:@"Answer"
												 title:NSLocalizedString(@"Answer", nil)
											   options:UNNotificationActionOptionForeground];
		UNNotificationAction *act_dec = [UNNotificationAction actionWithIdentifier:@"Decline"
																			 title:NSLocalizedString(@"Decline", nil)
																		   options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_call =
			[UNNotificationCategory categoryWithIdentifier:@"call_cat"
												   actions:[NSArray arrayWithObjects:act_ans, act_dec, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		// Msg category
		UNTextInputNotificationAction *act_reply =
			[UNTextInputNotificationAction actionWithIdentifier:@"Reply"
														  title:NSLocalizedString(@"Reply", nil)
														options:UNNotificationActionOptionNone];
		UNNotificationAction *act_seen =
			[UNNotificationAction actionWithIdentifier:@"Seen"
												 title:NSLocalizedString(@"Mark as seen", nil)
											   options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_msg =
			[UNNotificationCategory categoryWithIdentifier:@"msg_cat"
												   actions:[NSArray arrayWithObjects:act_reply, act_seen, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		// Video Request Category
		UNNotificationAction *act_accept =
			[UNNotificationAction actionWithIdentifier:@"Accept"
												 title:NSLocalizedString(@"Accept", nil)
											   options:UNNotificationActionOptionForeground];

		UNNotificationAction *act_refuse = [UNNotificationAction actionWithIdentifier:@"Cancel"
																				title:NSLocalizedString(@"Cancel", nil)
																			  options:UNNotificationActionOptionNone];
		UNNotificationCategory *video_call =
			[UNNotificationCategory categoryWithIdentifier:@"video_request"
												   actions:[NSArray arrayWithObjects:act_accept, act_refuse, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		// ZRTP verification category
		UNNotificationAction *act_confirm = [UNNotificationAction actionWithIdentifier:@"Confirm"
																				 title:NSLocalizedString(@"Accept", nil)
																			   options:UNNotificationActionOptionNone];

		UNNotificationAction *act_deny = [UNNotificationAction actionWithIdentifier:@"Deny"
																			  title:NSLocalizedString(@"Deny", nil)
																			options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_zrtp =
			[UNNotificationCategory categoryWithIdentifier:@"zrtp_request"
												   actions:[NSArray arrayWithObjects:act_confirm, act_deny, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];
		[UNUserNotificationCenter currentNotificationCenter].delegate = self;
		[[UNUserNotificationCenter currentNotificationCenter]
			requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
											 UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError *_Nullable error) {
							// Enable or disable features based on authorization.
							if (error) {
								LOGD(error.description);
							}
						  }];
		NSSet *categories = [NSSet setWithObjects:cat_call, cat_msg, video_call, cat_zrtp, nil];
		[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
	}
}
#pragma deploymate pop

void onUncaughtException(NSException* exception)
{
    NSString *reason = exception.reason;
    NSString *crashContent = [NSString stringWithFormat:@"%@",[exception callStackSymbols]];
    NSString *device = [AppUtils getDeviceNameFromModelName:[AppUtils getDeviceModel]];
    NSString *osVersion = [AppUtils getCurrentOSVersionOfDevice];
    NSString *appVersion = [AppUtils getCurrentVersionApplicaton];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    id info = [exception.userInfo objectForKey:@"NSTargetObjectUserInfoKey"];
    if (info != nil) {
        reason = [NSString stringWithFormat:@"%@: %@", NSStringFromClass([info class]), reason];
    }
    
    NSString *messageSend = [NSString stringWithFormat:@"------------------------------\nDevice: %@\nOS Version: %@\nApp version: %@\nApp bundle ID: %@\n------------------------------\nAccount ID: %@\n------------------------------\nReason: %@\n------------------------------\n%@", device, osVersion, appVersion, bundleIdentifier, USERNAME, reason, crashContent];
    
    NSString *totalEmail = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", @"lekhai0212@gmail.com", [NSString stringWithFormat:@"Report crash from %@", USERNAME], messageSend];
    NSString *url = [totalEmail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    //  NSString *subDirectory = [NSString stringWithFormat:@"%@/.%@.txt", logsFolderName, [AppUtils getCurrentDate]];
    NSString *subDirectory = [NSString stringWithFormat:@"%@/%@.txt", logsFolderName, [AppUtils getCurrentDate]];
    logFilePath = [WriteLogsUtils makeFilePathWithFileName: subDirectory];
    
    if (IS_IPHONE || IS_IPOD) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"==================================================\n==               START APPLICATION ON IPHONE OR IPOD              ==\n=================================================="] toFilePath:logFilePath];
    }else{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"==================================================\n==               START APPLICATION ON IPAD              ==\n=================================================="] toFilePath:logFilePath];
    }
    
    NSString *dndMode = [[NSUserDefaults standardUserDefaults] objectForKey:switch_dnd];
    if ([AppUtils isNullOrEmpty: dndMode]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:switch_dnd];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //  save value for pbx contacts sort
    [AppUtils setupFirstValueForSortContact];
    
    //  nhcla154 - rzfpGFlsEx
    NSString *str = [NSString stringWithFormat:@"%@: %@\n%@: %@", [[LanguageUtil sharedInstance] getContent:@"Version"], [AppUtils getAppVersionWithBuildVersion: YES], [[LanguageUtil sharedInstance] getContent:@"Release date"], [AppUtils getBuildDate]];
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\nApp's version is %@", str] toFilePath:logFilePath];
    
    //  set default ringtone if have not yet
    NSString *ringtone = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_RINGTONE];
    if (ringtone == nil || [ringtone isEqualToString:@""]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"htc_tone.mp3" forKey:DEFAULT_RINGTONE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    UIApplication *app = [UIApplication sharedApplication];
	UIApplicationState state = app.applicationState;
    
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    
    //  [Khai le - 25/10/2018]: Add write logs for app
    [self setupForWriteLogFileForApp];
    [DeviceUtils setupFontSizeForDevice];
    
    //  Khoi tao
    webService = [[WebServices alloc] init];
    webService.delegate = self;
    
    // Copy database and connect
    [self copyFileDataToDocument:@"cloudcall.sqlite"];
    [self renameFilesToHidden];
    [NSDatabase connectToDatabase];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:k11UpdateBarNotifications object:nil];
    
    //  Ghi âm cuộc gọi
    _isSyncing = false;
    supportLoginWithPhoneNumber = NO;
    supportVoice = NO;
    supportVideoCall = NO;
    callPrefix = @"";
    randomKey = [AppUtils randomStringWithLength: 10];
    listInfoPhoneNumber = [[NSMutableArray alloc] init];
    
    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:)
                                                 name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContactListAfterAddSuccess)
                                                 name:reloadContactAfterAdd object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(registrationUpdateEvent:)
                                               name:kLinphoneRegistrationUpdate object:nil];
    
    //  [Khai Le - 13/03/2019] Get DID list for user choose to call
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(startGetDIDListForCall)
                                               name:getDIDListForCall object:nil];
    
    internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];
    
    // check if a pathway to a random host exists
    hostReachable = [Reachability reachabilityWithHostName:@"www.apple.com"];
    [hostReachable startNotifier];
    
    [self setupValueForDevice];
    
    listNumber = [[NSArray alloc] initWithObjects: @"+", @"#", @"*", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];
    
    //  Set default language for app if haven't setted yet
    [[LanguageUtil sharedInstance] setCustomLanguage: key_vi];
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")){
        UNUserNotificationCenter *notifiCenter = [UNUserNotificationCenter currentNotificationCenter];
        notifiCenter.delegate = self;
        [notifiCenter requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
            }
        }];
    }
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)])
    {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    }
    
    //  get list contact
    contactLoaded = NO;
    [self getContactsListForFirstLoad];
    
	LinphoneManager *instance = [LinphoneManager instance];
	BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
	BOOL start_at_boot = [instance lpConfigBoolForKey:@"start_at_boot_preference"];
	[self registerForNotifications:app];

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
		self.del = [[ProviderDelegate alloc] init];
		[LinphoneManager.instance setProviderDelegate:self.del];
	}

	if (state == UIApplicationStateBackground) {
		// we've been woken up directly to background;
		if (!start_at_boot || !background_mode) {
			// autoboot disabled or no background, and no push: do nothing and wait for a real launch
			//output a log with NSLog, because the ortp logging system isn't activated yet at this time
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
			return YES;
		}
	}
    
	[LinphoneManager.instance startLinphoneCore];
	LinphoneManager.instance.iapManager.notificationCategory = @"expiry_notification";
    
    [self checkToReloginPBX];
    
	// initialize UI
	[self.window makeKeyAndVisible];
	[RootViewManager setupWithPortrait:(PhoneMainView *)self.window.rootViewController];
	[PhoneMainView.instance startUp];
    
    NSDictionary *userActivityDictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if (userActivityDictionary != nil) {
        [self showSplashScreenOnView: YES];
    }
    //  Enable all notification type. VoIP Notifications don't present a UI but we will use this to show local nofications later
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert| UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    
    //register the notification settings
    [application registerUserNotificationSettings:notificationSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCustomerTokenIOS)
                                                 name:updateTokenForXmpp object:nil];
    
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                contactLoaded = NO;
                [self getContactsListForFirstLoad];
            } else {
                NSLog(@"User denied access");
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        NSLog(@"The user has previously given access, add the contact");
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    
    //  get missed callfrom server
    if (USERNAME != nil && ![USERNAME isEqualToString: @""]) {
        //  [self getMissedCallFromServer];
    }
    
    double currentIOS = [[[UIDevice currentDevice] systemVersion] doubleValue];
    if (currentIOS <= 10) {
        //  [self removeAllRecordsAudioFile];    //  T_T
    }
    
    //  get pbx group contact list
    [self getPBXGroupContactList];
    
	return YES;
}

- (void)getPBXGroupContactList {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:logFilePath];
    
    listGroup = [[NSMutableArray alloc] init];
    
    NSData* myEncodedData = [[NSUserDefaults standardUserDefaults] objectForKey:@"group_pbx_list"];
    NSArray *myArray = (NSArray*) [NSKeyedUnarchiver unarchiveObjectWithData:myEncodedData];
    if (myArray != nil) {
        [listGroup addObjectsFromArray: myArray];
    }
    
    if (![AppUtils isNullOrEmpty: USERNAME] && ![AppUtils isNullOrEmpty: PASSWORD]) {
        NSString *params = [NSString stringWithFormat:@"username=%@", USERNAME];
        [webService callGETWebServiceWithFunction:GetServerGroup andParams:params];
    }
}

- (void)reloadContactListAfterAddSuccess {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:logFilePath];
    
    [self getContactsListForFirstLoad];
}

- (void) registerForVoIPPushes {
    self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    self.voipRegistry.delegate = self;
    
    // Initiate registration.
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self tryToUnRegisterSIP];
    /*  Leo Kelvin
	NSLog(@"%@", NSStringFromSelector(_cmd));
	LinphoneManager.instance.conf = TRUE;
	linphone_core_terminate_all_calls(LC);

	// destroyLinphoneCore automatically unregister proxies but if we are using
	// remote push notifications, we want to continue receiving them
	if (LinphoneManager.instance.pushNotificationToken != nil) {
		// trick me! setting network reachable to false will avoid sending unregister
		const MSList *proxies = linphone_core_get_proxy_config_list(LC);
		BOOL pushNotifEnabled = NO;
		while (proxies) {
			const char *refkey = linphone_proxy_config_get_ref_key(proxies->data);
			pushNotifEnabled = pushNotifEnabled || (refkey && strcmp(refkey, "push_notification") == 0);
			proxies = proxies->next;
		}
		// but we only want to hack if at least one proxy config uses remote push..
		if (pushNotifEnabled) {
			linphone_core_set_network_reachable(LC, FALSE);
		}
	}

	[LinphoneManager.instance destroyLinphoneCore];
    */
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	NSString *scheme = [[url scheme] lowercaseString];
	if ([scheme isEqualToString:@"linphone-config"] || [scheme isEqualToString:@"linphone-config"]) {
		NSString *encodedURL =
			[[url absoluteString] stringByReplacingOccurrencesOfString:@"linphone-config://" withString:@""];
		self.configURL = [encodedURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remote configuration", nil)
																		 message:NSLocalizedString(@"This operation will load a remote configuration. Continue ?", nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		UIAlertAction* yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil)
																style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {
															  [self showWaitingIndicator];
															  [self attemptRemoteConfiguration];
														  }];
		
		[errView addAction:defaultAction];
		[errView addAction:yesAction];

		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
	} else {
		if ([[url scheme] isEqualToString:@"sip"]) {
			// remove "sip://" from the URI, and do it correctly by taking resourceSpecifier and removing leading and
			// trailing "/"
			NSString *sipUri = [[url resourceSpecifier]
				stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
			[VIEW(DialerView) setAddress:sipUri];
		}
	}
	return YES;
}

- (void)fixRing {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
		// iOS7 fix for notification sound not stopping.
		// see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	}
}

- (void)processRemoteNotification:(NSDictionary *)userInfo {
    /*  Push content
    alert =     {
        "call-id" = 14953;
        "loc-key" = "Incoming call from 14953";
    };
    badge = 1;
    "call-id" = 14953;
    "content-available" = 1;
    "loc-key" = "Incoming call from 14953";
    sound = default;
    title = CloudCall;
    */
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] userInfo = %@", __FUNCTION__, @[userInfo]] toFilePath:logFilePath];
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if (aps != nil)
    {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        
        const MSList *list = linphone_core_get_proxy_config_list(LC);
        if (list == NULL) {
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:key_login];
            NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:key_password];
            NSString *domain = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_SERVER];
            NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_PORT];
            
            if (![AppUtils isNullOrEmpty: username] && ![AppUtils isNullOrEmpty: password] && ![AppUtils isNullOrEmpty: domain] && ![AppUtils isNullOrEmpty: port]) {
                [SipUtils registerPBXAccount:username password:password ipAddress:domain port:port];
                
                [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]: Don't have account. Try to register PBX with backup info: %@, %@, %@", __FUNCTION__, username, domain, port] toFilePath:logFilePath];
            }
        }else{
            [[LinphoneManager instance] refreshRegisters];
        }
        
        NSString *loc_key = [aps objectForKey:@"loc-key"];
        NSString *callId = [aps objectForKey:@"callerid"];
        
        NSString *caller = callId;
        PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: callId];
        if (![AppUtils isNullOrEmpty: contact.name]) {
            caller = contact.name;
        }else{
            caller = [AppUtils getGroupNameWithQueueNumber: callId];
            if ([AppUtils isNullOrEmpty: caller]) {
                caller = callId;
            }
        }
        
        NSString *content = [NSString stringWithFormat:@"Bạn có cuộc gọi từ %@", caller];

        UILocalNotification *messageNotif = [[UILocalNotification alloc] init];
        messageNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow: 0.1];
        messageNotif.timeZone = [NSTimeZone defaultTimeZone];
        messageNotif.timeZone = [NSTimeZone defaultTimeZone];
        messageNotif.alertBody = content;
        messageNotif.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification: messageNotif];
        
        
        //            NSString *loc_key = [aps objectForKey:@"loc-key"];
        //            NSString *callId = [aps objectForKey:@"call-id"];
        if (alert != nil) {
            loc_key = [alert objectForKey:@"loc-key"];
            /*if we receive a remote notification, it is probably because our TCP background socket was no more working.
             As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
            if (linphone_core_get_calls(LC) == NULL) { // if there are calls, obviously our TCP socket shall be working
                //linphone_core_set_network_reachable(LC, FALSE);
                if (!linphone_core_is_network_reachable(LC)) {
                    LinphoneManager.instance.connectivity = none; //Force connectivity to be discovered again
                    [LinphoneManager.instance setupNetworkReachabilityCallback];
                }
                if (loc_key != nil) {
                    
                    //  callId = [userInfo objectForKey:@"call-id"];
                    if (callId != nil) {
                        if ([callId isEqualToString:@""]){
                            //Present apn pusher notifications for info
                            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
                                UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
                                content.title = @"APN Pusher";
                                content.body = @"Push notification received !";
                                
                                UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"call_request" content:content trigger:NULL];
                                [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
                                    // Enable or disable features based on authorization.
                                    if (error) {
                                        NSLog(@"Error while adding notification request :%@", error.description);
                                    }
                                }];
                            } else {
                                UILocalNotification *notification = [[UILocalNotification alloc] init];
                                notification.repeatInterval = 0;
                                notification.alertBody = @"Push notification received !";
                                notification.alertTitle = @"APN Pusher";
                                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                            }
                        } else {
                            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] addPushCallId = %@", __FUNCTION__, callId] toFilePath:logFilePath];
                            
                            [LinphoneManager.instance addPushCallId:callId];
                        }
                    } else  if ([callId  isEqual: @""]) {
                        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]: PushNotification: does not have call-id yet, fix it !", __FUNCTION__] toFilePath:logFilePath];
                    }
                }
            }
        }
        
        if (callId && [self addLongTaskIDforCallID:callId]) {
            if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && loc_key &&
                index > 0) {
                if ([loc_key isEqualToString:@"IC_MSG"]) {
                    [LinphoneManager.instance startPushLongRunningTask:FALSE];
                    [self fixRing];
                } else if ([loc_key isEqualToString:@"IM_MSG"]) {
                    [LinphoneManager.instance startPushLongRunningTask:TRUE];
                }
            }
        }
    }
}

- (BOOL)addLongTaskIDforCallID:(NSString *)callId {
    NSDictionary *dict = LinphoneManager.instance.pushDict;
    if ([[dict allKeys] indexOfObject:callId] != NSNotFound) {
        return FALSE;
    }
    [dict setValue:[NSNumber numberWithInt:1] forKey:callId];
    return TRUE;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	//  [self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom *)findChatRoomForContact:(NSString *)contact {
	const MSList *rooms = linphone_core_get_chat_rooms(LC);
	const char *from = [contact UTF8String];
	while (rooms) {
		const LinphoneAddress *room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom *)rooms->data);
		char *room_from = linphone_address_as_string_uri_only(room_from_address);
		if (room_from && strcmp(from, room_from) == 0) {
			return rooms->data;
		}
		rooms = rooms->next;
	}
	return NULL;
}

/*
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	NSLog(@"%@ - state = %ld", NSStringFromSelector(_cmd), (long)application.applicationState);

	if ([notification.category isEqual:LinphoneManager.instance.iapManager.notificationCategory]){
		[PhoneMainView.instance changeCurrentView:ShopView.compositeViewDescription];
		return;
	}

	[self fixRing];

	if ([notification.userInfo objectForKey:@"callId"] != nil) {
		BOOL bypass_incoming_view = TRUE;
		// some local notifications have an internal timer to relaunch themselves at specified intervals
		if ([[notification.userInfo objectForKey:@"timer"] intValue] == 1) {
			[LinphoneManager.instance cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
			bypass_incoming_view = [LinphoneManager.instance lpConfigBoolForKey:@"autoanswer_notif_preference"];
		}
		if (bypass_incoming_view) {
			[LinphoneManager.instance acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];
		}
	} else if ([notification.userInfo objectForKey:@"from_addr"] != nil) {
		NSString *chat = notification.alertBody;
		NSString *remote_uri = (NSString *)[notification.userInfo objectForKey:@"from_addr"];
		NSString *from = (NSString *)[notification.userInfo objectForKey:@"from"];
		NSString *callID = (NSString *)[notification.userInfo objectForKey:@"call-id"];
		LinphoneChatRoom *room = [self findChatRoomForContact:remote_uri];
		if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ||
			((PhoneMainView.instance.currentView != ChatsListView.compositeViewDescription) &&
			 ((PhoneMainView.instance.currentView != ChatConversationView.compositeViewDescription))) ||
			(PhoneMainView.instance.currentView == ChatConversationView.compositeViewDescription &&
			 room != PhoneMainView.instance.currentRoom)) {
			// Create a new notification

			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
				// Do nothing
			} else {
				UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
				content.title = NSLocalizedString(@"Message received", nil);
				if ([LinphoneManager.instance lpConfigBoolForKey:@"show_msg_in_notif" withDefault:YES]) {
					content.subtitle = from;
					content.body = chat;
				} else {
					content.body = from;
				}
				content.sound = [UNNotificationSound soundNamed:@"msg.caf"];
				content.categoryIdentifier = @"msg_cat";
				content.userInfo = @{ @"from" : from, @"from_addr" : remote_uri, @"call-id" : callID };
				content.accessibilityLabel = @"Message notif";
				UNNotificationRequest *req =
					[UNNotificationRequest requestWithIdentifier:@"call_request" content:content trigger:NULL];
				req.accessibilityLabel = @"Message notif";
				[[UNUserNotificationCenter currentNotificationCenter]
					addNotificationRequest:req
					 withCompletionHandler:^(NSError *_Nullable error) {
					   // Enable or disable features based on authorization.
					   if (error) {
						   LOGD(@"Error while adding notification request :");
						   LOGD(error.description);
					   }
					 }];
			}
		}
	} else if ([notification.userInfo objectForKey:@"callLog"] != nil) {
		NSString *callLog = (NSString *)[notification.userInfo objectForKey:@"callLog"];
		HistoryDetailsView *view = VIEW(HistoryDetailsView);
		[view setCallLogId:callLog];
		[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
	}
}
*/

#pragma mark - PushNotification Functions

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
	//  [LinphoneManager.instance setPushNotificationToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
	//  [LinphoneManager.instance setPushNotificationToken:nil];
}

#pragma mark - PushKit Functions

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    NSLog(@"PushKit Token invalidated");
    dispatch_async(dispatch_get_main_queue(), ^{
        //  [LinphoneManager.instance setPushNotificationToken:nil];
    });
}

- (void)pushRegistry:(PKPushRegistry *)registry
	didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
							  forType:(NSString *)type {
    
	NSLog(@"PushKit : incoming voip notfication: %@", payload.dictionaryPayload);
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) { // Call category
		UNNotificationAction *act_ans =
			[UNNotificationAction actionWithIdentifier:@"Answer"
												 title:NSLocalizedString(@"Answer", nil)
											   options:UNNotificationActionOptionForeground];
		UNNotificationAction *act_dec = [UNNotificationAction actionWithIdentifier:@"Decline"
																			 title:NSLocalizedString(@"Decline", nil)
																		   options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_call =
			[UNNotificationCategory categoryWithIdentifier:@"call_cat"
												   actions:[NSArray arrayWithObjects:act_ans, act_dec, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];
		// Msg category
		UNTextInputNotificationAction *act_reply =
			[UNTextInputNotificationAction actionWithIdentifier:@"Reply"
														  title:NSLocalizedString(@"Reply", nil)
														options:UNNotificationActionOptionNone];
		UNNotificationAction *act_seen =
			[UNNotificationAction actionWithIdentifier:@"Seen"
												 title:NSLocalizedString(@"Mark as seen", nil)
											   options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_msg =
			[UNNotificationCategory categoryWithIdentifier:@"msg_cat"
												   actions:[NSArray arrayWithObjects:act_reply, act_seen, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		// Video Request Category
		UNNotificationAction *act_accept =
			[UNNotificationAction actionWithIdentifier:@"Accept"
												 title:NSLocalizedString(@"Accept", nil)
											   options:UNNotificationActionOptionForeground];

		UNNotificationAction *act_refuse = [UNNotificationAction actionWithIdentifier:@"Cancel"
																				title:NSLocalizedString(@"Cancel", nil)
																			  options:UNNotificationActionOptionNone];
		UNNotificationCategory *video_call =
			[UNNotificationCategory categoryWithIdentifier:@"video_request"
												   actions:[NSArray arrayWithObjects:act_accept, act_refuse, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		// ZRTP verification category
		UNNotificationAction *act_confirm = [UNNotificationAction actionWithIdentifier:@"Confirm"
																				 title:NSLocalizedString(@"Accept", nil)
																			   options:UNNotificationActionOptionNone];

		UNNotificationAction *act_deny = [UNNotificationAction actionWithIdentifier:@"Deny"
																			  title:NSLocalizedString(@"Deny", nil)
																			options:UNNotificationActionOptionNone];
		UNNotificationCategory *cat_zrtp =
			[UNNotificationCategory categoryWithIdentifier:@"zrtp_request"
												   actions:[NSArray arrayWithObjects:act_confirm, act_deny, nil]
										 intentIdentifiers:[[NSMutableArray alloc] init]
												   options:UNNotificationCategoryOptionCustomDismissAction];

		[UNUserNotificationCenter currentNotificationCenter].delegate = self;
		[[UNUserNotificationCenter currentNotificationCenter]
			requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
											 UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError *_Nullable error) {
							// Enable or disable features based on authorization.
							if (error) {
								LOGD(error.description);
							}
						  }];
		NSSet *categories = [NSSet setWithObjects:cat_call, cat_msg, video_call, cat_zrtp, nil];
		[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
	}
	[LinphoneManager.instance setupNetworkReachabilityCallback];
	dispatch_async(dispatch_get_main_queue(), ^{
	  [self processRemoteNotification:payload.dictionaryPayload];
	});
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type
{
	NSLog(@"PushKit credentials updated");
	NSLog(@"voip token: %@", (credentials.token));
	dispatch_async(dispatch_get_main_queue(), ^{
        _deviceToken = credentials.token.description;
        _deviceToken = [_deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
        _deviceToken = [_deviceToken stringByReplacingOccurrencesOfString:@"<" withString:@""];
        _deviceToken = [_deviceToken stringByReplacingOccurrencesOfString:@">" withString:@""];
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] _deviceToken = %@", __FUNCTION__, _deviceToken] toFilePath:logFilePath];
        
        //  Cap nhat token cho phan chat
        if (USERNAME != nil && ![USERNAME isEqualToString: @""] && !_updateTokenSuccess) {
            [self updateCustomerTokenIOS];
        }else{
            _updateTokenSuccess = false;
        }
	});
}

#pragma mark - UNUserNotifications Framework

- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionAlert);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    LOGD(@"UN : response received");
    LOGD(response.description);
    
    NSString *callId = (NSString *)[response.notification.request.content.userInfo objectForKey:@"CallId"];
    if (!callId) {
        return;
    }
    LinphoneCall *call = [LinphoneManager.instance callByCallId:callId];
    if (call) {
        LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
        if (data->timer) {
            [data->timer invalidate];
            data->timer = nil;
        }
    }
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] response.actionIdentifier = %@.\nresponse user info = %@", __FUNCTION__, response.actionIdentifier, response.notification.request.content.userInfo] toFilePath:logFilePath];
    
    if ([response.actionIdentifier isEqual:@"Answer"]) {
        // use the standard handler
        [PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
        linphone_core_accept_call(LC, call);
    } else if ([response.actionIdentifier isEqual:@"Decline"]) {
        linphone_core_decline_call(LC, call, LinphoneReasonDeclined);
    } else if ([response.actionIdentifier isEqual:@"Reply"]) {
        LinphoneCore *lc = [LinphoneManager getLc];
        NSString *replyText = [(UNTextInputNotificationResponse *)response userText];
        NSString *from = [response.notification.request.content.userInfo objectForKey:@"from_addr"];
        LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(lc, [from UTF8String]);
        if (room) {
            LinphoneChatMessage *msg = linphone_chat_room_create_message(room, replyText.UTF8String);
            linphone_chat_room_send_chat_message(room, msg);
            
            if (linphone_core_lime_enabled(LC) == LinphoneLimeMandatory && !linphone_chat_room_lime_available(room)) {
                [LinphoneManager.instance alertLIME:room];
            }
            linphone_chat_room_mark_as_read(room);
            TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
                                             getCachedController:NSStringFromClass(TabBarView.class)];
            [tab update:YES];
            [PhoneMainView.instance updateApplicationBadgeNumber];
        }
    } else if ([response.actionIdentifier isEqual:@"Seen"]) {
        NSString *from = [response.notification.request.content.userInfo objectForKey:@"from_addr"];
        LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(LC, [from UTF8String]);
        if (room) {
            linphone_chat_room_mark_as_read(room);
            TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
                                             getCachedController:NSStringFromClass(TabBarView.class)];
            [tab update:YES];
            [PhoneMainView.instance updateApplicationBadgeNumber];
        }
        
    } else if ([response.actionIdentifier isEqual:@"Cancel"]) {
        NSLog(@"User declined video proposal");
        if (call == linphone_core_get_current_call(LC)) {
            LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
            linphone_core_accept_call_update(LC, call, params);
            linphone_call_params_destroy(params);
        }
    } else if ([response.actionIdentifier isEqual:@"Accept"]) {
        NSLog(@"User accept video proposal");
        if (call == linphone_core_get_current_call(LC)) {
            [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
            [PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
            LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
            linphone_call_params_enable_video(params, TRUE);
            linphone_core_accept_call_update(LC, call, params);
            linphone_call_params_destroy(params);
        }
    } else if ([response.actionIdentifier isEqual:@"Confirm"]) {
        if (linphone_core_get_current_call(LC) == call) {
            linphone_call_set_authentication_token_verified(call, YES);
        }
    } else if ([response.actionIdentifier isEqual:@"Deny"]) {
        if (linphone_core_get_current_call(LC) == call) {
            linphone_call_set_authentication_token_verified(call, NO);
        }
    } else if ([response.actionIdentifier isEqual:@"Call"]) {
        
    } else { // in this case the value is : com.apple.UNNotificationDefaultActionIdentifier
        if ([response.notification.request.content.categoryIdentifier isEqual:@"call_cat"]) {
            [PhoneMainView.instance displayIncomingCall:call];
        } else if ([response.notification.request.content.categoryIdentifier isEqual:@"msg_cat"]) {
            [PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
        } else if ([response.notification.request.content.categoryIdentifier isEqual:@"video_request"]) {
            [PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
            NSTimer *videoDismissTimer = nil;
            
            UIConfirmationDialog *sheet =
            [UIConfirmationDialog ShowWithMessage:response.notification.request.content.body
                                    cancelMessage:nil
                                   confirmMessage:NSLocalizedString(@"ACCEPT", nil)
                                    onCancelClick:^() {
                                        NSLog(@"User declined video proposal");
                                        if (call == linphone_core_get_current_call(LC)) {
                                            LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
                                            linphone_core_accept_call_update(LC, call, params);
                                            linphone_call_params_destroy(params);
                                            [videoDismissTimer invalidate];
                                        }
                                    }
                              onConfirmationClick:^() {
                                  NSLog(@"User accept video proposal");
                                  if (call == linphone_core_get_current_call(LC)) {
                                      LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
                                      linphone_call_params_enable_video(params, TRUE);
                                      linphone_core_accept_call_update(LC, call, params);
                                      linphone_call_params_destroy(params);
                                      [videoDismissTimer invalidate];
                                  }
                              }
                                     inController:PhoneMainView.instance];
            
            videoDismissTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                                 target:self
                                                               selector:@selector(dismissVideoActionSheet:)
                                                               userInfo:sheet
                                                                repeats:NO];
        } else if ([response.notification.request.content.categoryIdentifier isEqual:@"zrtp_request"]) {
            NSString *code = [NSString stringWithUTF8String:linphone_call_get_authentication_token(call)];
            NSString *myCode;
            NSString *correspondantCode;
            if (linphone_call_get_dir(call) == LinphoneCallIncoming) {
                myCode = [code substringToIndex:2];
                correspondantCode = [code substringFromIndex:2];
            } else {
                correspondantCode = [code substringToIndex:2];
                myCode = [code substringFromIndex:2];
            }
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with peer:\n"
                                                                             @"Say : %@\n"
                                                                             @"Your correspondant should say : %@",
                                                                             nil),
                                 myCode, correspondantCode];
            [UIConfirmationDialog ShowWithMessage:message
                                    cancelMessage:NSLocalizedString(@"DENY", nil)
                                   confirmMessage:NSLocalizedString(@"ACCEPT", nil)
                                    onCancelClick:^() {
                                        if (linphone_core_get_current_call(LC) == call) {
                                            linphone_call_set_authentication_token_verified(call, NO);
                                        }
                                    }
                              onConfirmationClick:^() {
                                  if (linphone_core_get_current_call(LC) == call) {
                                      linphone_call_set_authentication_token_verified(call, YES);
                                  }
                              }];
        } else if ([response.notification.request.content.categoryIdentifier isEqual:@"lime"]) {
            return;
        } else { // Missed call
            [PhoneMainView.instance changeCurrentView:HistoryListView.compositeViewDescription];
        }
    }
}
/*  Close by Khai Le
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler {
	LOGD(@"UN : response received");
	LOGD(response.description);

	NSString *callId = (NSString *)[response.notification.request.content.userInfo objectForKey:@"CallId"];
	if (!callId) {
		return;
	}
	LinphoneCall *call = [LinphoneManager.instance callByCallId:callId];
	if (call) {
		LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (data->timer) {
			[data->timer invalidate];
			data->timer = nil;
		}
	}

	if ([response.actionIdentifier isEqual:@"Answer"]) {
		// use the standard handler
		[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
		linphone_core_accept_call(LC, call);
	} else if ([response.actionIdentifier isEqual:@"Decline"]) {
		linphone_core_decline_call(LC, call, LinphoneReasonDeclined);
	} else if ([response.actionIdentifier isEqual:@"Reply"]) {
		LinphoneCore *lc = [LinphoneManager getLc];
		NSString *replyText = [(UNTextInputNotificationResponse *)response userText];
		NSString *from = [response.notification.request.content.userInfo objectForKey:@"from_addr"];
		LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(lc, [from UTF8String]);
		if (room) {
			LinphoneChatMessage *msg = linphone_chat_room_create_message(room, replyText.UTF8String);
			linphone_chat_room_send_chat_message(room, msg);

			if (linphone_core_lime_enabled(LC) == LinphoneLimeMandatory && !linphone_chat_room_lime_available(room)) {
				[LinphoneManager.instance alertLIME:room];
			}
			linphone_chat_room_mark_as_read(room);
			TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
				getCachedController:NSStringFromClass(TabBarView.class)];
			[tab update:YES];
			[PhoneMainView.instance updateApplicationBadgeNumber];
		}
	} else if ([response.actionIdentifier isEqual:@"Seen"]) {
		NSString *from = [response.notification.request.content.userInfo objectForKey:@"from_addr"];
		LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(LC, [from UTF8String]);
		if (room) {
			linphone_chat_room_mark_as_read(room);
			TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
				getCachedController:NSStringFromClass(TabBarView.class)];
			[tab update:YES];
			[PhoneMainView.instance updateApplicationBadgeNumber];
		}

	} else if ([response.actionIdentifier isEqual:@"Cancel"]) {
		NSLog(@"User declined video proposal");
		if (call == linphone_core_get_current_call(LC)) {
			LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
			linphone_core_accept_call_update(LC, call, params);
			linphone_call_params_destroy(params);
		}
	} else if ([response.actionIdentifier isEqual:@"Accept"]) {
		NSLog(@"User accept video proposal");
		if (call == linphone_core_get_current_call(LC)) {
			[[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
			[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
			LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
			linphone_call_params_enable_video(params, TRUE);
			linphone_core_accept_call_update(LC, call, params);
			linphone_call_params_destroy(params);
		}
	} else if ([response.actionIdentifier isEqual:@"Confirm"]) {
		if (linphone_core_get_current_call(LC) == call) {
			linphone_call_set_authentication_token_verified(call, YES);
		}
	} else if ([response.actionIdentifier isEqual:@"Deny"]) {
		if (linphone_core_get_current_call(LC) == call) {
			linphone_call_set_authentication_token_verified(call, NO);
		}
	} else if ([response.actionIdentifier isEqual:@"Call"]) {

	} else { // in this case the value is : com.apple.UNNotificationDefaultActionIdentifier
		if ([response.notification.request.content.categoryIdentifier isEqual:@"call_cat"]) {
			[PhoneMainView.instance displayIncomingCall:call];
		} else if ([response.notification.request.content.categoryIdentifier isEqual:@"msg_cat"]) {
			[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
		} else if ([response.notification.request.content.categoryIdentifier isEqual:@"video_request"]) {
			[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
			NSTimer *videoDismissTimer = nil;

			UIConfirmationDialog *sheet =
				[UIConfirmationDialog ShowWithMessage:response.notification.request.content.body
					cancelMessage:nil
					confirmMessage:NSLocalizedString(@"ACCEPT", nil)
					onCancelClick:^() {
					  NSLog(@"User declined video proposal");
					  if (call == linphone_core_get_current_call(LC)) {
						  LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
						  linphone_core_accept_call_update(LC, call, params);
						  linphone_call_params_destroy(params);
						  [videoDismissTimer invalidate];
					  }
					}
					onConfirmationClick:^() {
					  NSLog(@"User accept video proposal");
					  if (call == linphone_core_get_current_call(LC)) {
						  LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
						  linphone_call_params_enable_video(params, TRUE);
						  linphone_core_accept_call_update(LC, call, params);
						  linphone_call_params_destroy(params);
						  [videoDismissTimer invalidate];
					  }
					}
					inController:PhoneMainView.instance];

			videoDismissTimer = [NSTimer scheduledTimerWithTimeInterval:30
																 target:self
															   selector:@selector(dismissVideoActionSheet:)
															   userInfo:sheet
																repeats:NO];
		} else if ([response.notification.request.content.categoryIdentifier isEqual:@"zrtp_request"]) {
			NSString *code = [NSString stringWithUTF8String:linphone_call_get_authentication_token(call)];
			NSString *myCode;
			NSString *correspondantCode;
			if (linphone_call_get_dir(call) == LinphoneCallIncoming) {
				myCode = [code substringToIndex:2];
				correspondantCode = [code substringFromIndex:2];
			} else {
				correspondantCode = [code substringToIndex:2];
				myCode = [code substringFromIndex:2];
			}
			NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with peer:\n"
																			 @"Say : %@\n"
																			 @"Your correspondant should say : %@",
																			 nil),
														   myCode, correspondantCode];
			[UIConfirmationDialog ShowWithMessage:message
				cancelMessage:NSLocalizedString(@"DENY", nil)
				confirmMessage:NSLocalizedString(@"ACCEPT", nil)
				onCancelClick:^() {
				  if (linphone_core_get_current_call(LC) == call) {
					  linphone_call_set_authentication_token_verified(call, NO);
				  }
				}
				onConfirmationClick:^() {
				  if (linphone_core_get_current_call(LC) == call) {
					  linphone_call_set_authentication_token_verified(call, YES);
				  }
				}];
		} else if ([response.notification.request.content.categoryIdentifier isEqual:@"lime"]) {
			return;
		} else { // Missed call
			[PhoneMainView.instance changeCurrentView:HistoryListView.compositeViewDescription];
		}
	}
}   */

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	UIConfirmationDialog *sheet = (UIConfirmationDialog *)timer.userInfo;
	[sheet dismiss];
}

#pragma mark - NSUser notifications

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			 completionHandler:(void (^)())completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call) {
		LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (data->timer) {
			[data->timer invalidate];
			data->timer = nil;
		}
	}
	NSLog(@"%@", NSStringFromSelector(_cmd));
	if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0) {
		NSLog(@"%@", NSStringFromSelector(_cmd));
		if ([notification.category isEqualToString:@"incoming_call"]) {
			if ([identifier isEqualToString:@"answer"]) {
				// use the standard handler
				[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
				linphone_core_accept_call(LC, call);
			} else if ([identifier isEqualToString:@"decline"]) {
				LinphoneCall *call = linphone_core_get_current_call(LC);
				if (call)
					linphone_core_decline_call(LC, call, LinphoneReasonDeclined);
			}
		} else if ([notification.category isEqualToString:@"incoming_msg"]) {
			if ([identifier isEqualToString:@"reply"]) {
				// use the standard handler
				[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
			} else if ([identifier isEqualToString:@"mark_read"]) {
				NSString *from = [notification.userInfo objectForKey:@"from_addr"];
				LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(LC, [from UTF8String]);
				if (room) {
					linphone_chat_room_mark_as_read(room);
					TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
						getCachedController:NSStringFromClass(TabBarView.class)];
					[tab update:YES];
					[PhoneMainView.instance updateApplicationBadgeNumber];
				}
			}
		}
	}
	completionHandler();
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			  withResponseInfo:(NSDictionary *)responseInfo
			 completionHandler:(void (^)())completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call) {
		LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (data->timer) {
			[data->timer invalidate];
			data->timer = nil;
		}
	}
	if ([notification.category isEqualToString:@"incoming_call"]) {
		if ([identifier isEqualToString:@"answer"]) {
			// use the standard handler
			[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
			linphone_core_accept_call(LC, call);
		} else if ([identifier isEqualToString:@"decline"]) {
			LinphoneCall *call = linphone_core_get_current_call(LC);
			if (call)
				linphone_core_decline_call(LC, call, LinphoneReasonDeclined);
		}
	} else if ([notification.category isEqualToString:@"incoming_msg"] &&
			   [identifier isEqualToString:@"reply_inline"]) {
		LinphoneCore *lc = [LinphoneManager getLc];
		NSString *replyText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
		NSString *from = [notification.userInfo objectForKey:@"from_addr"];
		LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(lc, [from UTF8String]);
		if (room) {
			LinphoneChatMessage *msg = linphone_chat_room_create_message(room, replyText.UTF8String);
			linphone_chat_room_send_chat_message(room, msg);

			if (linphone_core_lime_enabled(LC) == LinphoneLimeMandatory && !linphone_chat_room_lime_available(room)) {
				[LinphoneManager.instance alertLIME:room];
			}

			linphone_chat_room_mark_as_read(room);
			[PhoneMainView.instance updateApplicationBadgeNumber];
		}
	}
	completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"%@", notification);
}

#pragma deploymate pop

#pragma mark - Remote configuration Functions (URL Handler)

- (void)ConfigurationStateUpdateEvent:(NSNotification *)notif {
	LinphoneConfiguringState state = [[notif.userInfo objectForKey:@"state"] intValue];
	if (state == LinphoneConfiguringSuccessful) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissViewControllerAnimated:YES completion:nil];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil)
																		 message:NSLocalizedString(@"Remote configuration successfully fetched and applied.", nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[errView addAction:defaultAction];
		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];

		[PhoneMainView.instance startUp];
	}
	if (state == LinphoneConfiguringFailed) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissViewControllerAnimated:YES completion:nil];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failure", nil)
																		 message:NSLocalizedString(@"Failed configuring from the specified URL.", nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[errView addAction:defaultAction];
		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
	}
}

- (void)showWaitingIndicator {
	_waitingIndicator = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Fetching remote configuration...", nil)
															message:@""
													 preferredStyle:UIAlertControllerStyleAlert];
	
	UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
	progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	
	[_waitingIndicator setValue:progress forKey:@"accessoryView"];
	[progress setColor:[UIColor blackColor]];
	
	[progress startAnimating];
	[PhoneMainView.instance presentViewController:_waitingIndicator animated:YES completion:nil];
}

- (void)attemptRemoteConfiguration {

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(ConfigurationStateUpdateEvent:)
											   name:kLinphoneConfiguringStateUpdate
											 object:nil];
	linphone_core_set_provisioning_uri(LC, [configURL UTF8String]);
	[LinphoneManager.instance destroyLinphoneCore];
	[LinphoneManager.instance startLinphoneCore];
}

#pragma mark - Prevent ImagePickerView from rotating

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if (IS_IPHONE || IS_IPOD) {
        return UIInterfaceOrientationMaskPortrait;
        
        if ([[(PhoneMainView*)self.window.rootViewController currentView] equal:CallView.compositeViewDescription] || [[(PhoneMainView*)self.window.rootViewController currentView] equal:OutgoingCallViewController.compositeViewDescription])
        {
            return UIInterfaceOrientationMaskAll;
        }
        return UIInterfaceOrientationMaskPortrait;
    }else{
        return UIInterfaceOrientationMaskAll;
    }
}

#pragma mark - Khai Le functions

- (void)checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"\n[%s] Network status is %d", __FUNCTION__, internetStatus] toFilePath: logFilePath];
    
    switch (internetStatus){
        case NotReachable: {
            internetActive = NO;
            break;
        }
        case ReachableViaWiFi: {
            internetActive = YES;
            break;
        }
        case ReachableViaWWAN: {
            internetActive = YES;
            
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:networkChanged object:nil];
}

#pragma mark - my functions

- (void)getContactsListForFirstLoad
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:logFilePath];
    
    if (listContacts == nil) {
        listContacts = [[NSMutableArray alloc] init];
    }
    [listContacts removeAllObjects];
    
    if (pbxContacts == nil) {
        pbxContacts = [[NSMutableArray alloc] init];
    }
    [pbxContacts removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self getAllIDContactInPhoneBook];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            contactLoaded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:finishLoadContacts
                                                                object:nil];
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] GET PHONE'S CONTACT FINISH. POST EVENT finishLoadContacts", __FUNCTION__] toFilePath:logFilePath];
        });
    });
}

//  Lấy tất cả contact trong phonebook
- (void)getAllIDContactInPhoneBook
{
    addressListBook = ABAddressBookCreate();
    NSArray *arrayOfAllPeople = (__bridge  NSArray *) ABAddressBookCopyArrayOfAllPeople(addressListBook);
    NSUInteger peopleCounter = 0;
    
    for (peopleCounter = 0; peopleCounter < [arrayOfAllPeople count]; peopleCounter++)
    {
        ABRecordRef aPerson = (__bridge ABRecordRef)[arrayOfAllPeople objectAtIndex:peopleCounter];
        int contactId = ABRecordGetRecordID(aPerson);
        
        //  Kiem tra co phai la contact pbx hay ko?
        NSString *sipNumber = (__bridge NSString *)ABRecordCopyValue(aPerson, kABPersonFirstNamePhoneticProperty);
        if (sipNumber != nil && [sipNumber isEqualToString: keySyncPBX])
        {
            NSString *pbxServer = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_SERVER];
            ABMultiValueRef phones = ABRecordCopyValue(aPerson, kABPersonPhoneProperty);
            if (ABMultiValueGetCount(phones) > 0)
            {
                for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
                {
                    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                    CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, j);
                    
                    NSString *phoneStr = (__bridge NSString *)phoneNumberRef;
                    phoneStr = [[phoneStr componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                    
                    NSString *nameStr = (__bridge NSString *)locLabel;
                    
                    if (phoneStr != nil && nameStr != nil) {
                        PBXContact *pbxContact = [[PBXContact alloc] init];
                        pbxContact._name = nameStr;
                        pbxContact._number = phoneStr;
                        
                        NSString *convertName = [AppUtils convertUTF8CharacterToCharacter: nameStr];
                        NSString *nameForSearch = [AppUtils getNameForSearchOfConvertName: convertName];
                        pbxContact._nameForSearch = nameForSearch;
                        pbxContact._convertName = convertName;
                        
                        NSString *avatarStr = @"";
                        if (![AppUtils isNullOrEmpty: pbxServer]) {
                            NSString *avatarName = [NSString stringWithFormat:@"%@_%@.png", pbxServer, phoneStr];
                            NSString *localFile = [NSString stringWithFormat:@"/avatars/%@", avatarName];
                            NSData *avatarData = [AppUtils getFileDataFromDirectoryWithFileName:localFile];
                            if (avatarData != nil) {
                                
                                if ([avatarData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
                                    avatarStr = [avatarData base64EncodedStringWithOptions: 0];
                                } else {
                                    avatarStr = [avatarData base64Encoding];
                                }
                                pbxContact._avatar = avatarStr;
                            }
                        }
                        [pbxContacts addObject: pbxContact];
                        
                        //  [Khai le - 02/11/2018]
                        PhoneObject *phone = [[PhoneObject alloc] init];
                        phone.number = phoneStr;
                        phone.name = nameStr;
                        phone.nameForSearch = nameForSearch;
                        phone.avatar = avatarStr;
                        phone.contactId = contactId;
                        phone.phoneType = ePBXPhone;
                        
                        [listInfoPhoneNumber addObject: phone];
                    }
                }
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:contactId]
                                                      forKey:PBX_ID_CONTACT];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //  Post event to PBXContactViewController to reload pbx contacts list
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Found PBX contact with id = %d. Post event to show pbxContacts", __FUNCTION__, contactId] toFilePath:logFilePath];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:finishGetPBXContacts
                                                                object:[NSNumber numberWithInt:contactId]];
            continue;
        }
        //  [Khai le - 29/10/2018]: Check if contact has phone numbers
        NSString *fullname = [AppUtils getNameOfContact: aPerson];
        if (![AppUtils isNullOrEmpty: fullname])
        {
            NSMutableArray *listPhone = [self getListPhoneOfContactPerson: aPerson withName: fullname];
            if (listPhone != nil && listPhone.count > 0) {
                ContactObject *aContact = [[ContactObject alloc] init];
                aContact.person = aPerson;
                aContact._id_contact = contactId;
                aContact._fullName = fullname;
                NSArray *nameInfo = [AppUtils getFirstNameAndLastNameOfContact: aPerson];
                aContact._firstName = [nameInfo objectAtIndex: 0];
                aContact._lastName = [nameInfo objectAtIndex: 1];
                
                NSString *convertName = [AppUtils convertUTF8CharacterToCharacter: aContact._fullName];
                aContact._nameForSearch = [AppUtils getNameForSearchOfConvertName: convertName];
                
                //  Email
                ABMultiValueRef map = ABRecordCopyValue(aPerson, kABPersonEmailProperty);
                if (map) {
                    for (int i = 0; i < ABMultiValueGetCount(map); ++i) {
                        ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(map, i);
                        NSInteger index = ABMultiValueGetIndexForIdentifier(map, identifier);
                        if (index != -1) {
                            NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(map, index));
                            if (valueRef != NULL && ![valueRef isEqualToString:@""]) {
                                //  just get one email for contact
                                aContact._email = valueRef;
                                break;
                            }
                        }
                    }
                    CFRelease(map);
                }
                
                //  Company
                CFStringRef companyRef  = ABRecordCopyValue(aPerson, kABPersonOrganizationProperty);
                if (companyRef != NULL && companyRef != nil){
                    NSString *company = (__bridge NSString *)companyRef;
                    if (company != nil && ![company isEqualToString:@""]){
                        aContact._company = company;
                    }
                }
                
                aContact._avatar = [self getAvatarOfContact: aPerson];
                aContact._listPhone = listPhone;
                [listContacts addObject: aContact];
                
                //  Added by Khai Le on 09/10/2018
                ContactDetailObj *anItem = [aContact._listPhone firstObject];
                aContact._sipPhone = anItem._valueStr;
                
                //  [Khai le - 02/11/2018]
                for (int i=0; i<listPhone.count; i++) {
                    ContactDetailObj *phoneItem = [listPhone objectAtIndex: i];
                    
                    PhoneObject *phone = [[PhoneObject alloc] init];
                    phone.number = phoneItem._valueStr;
                    phone.name = fullname;
                    phone.nameForSearch = [AppUtils getNameForSearchOfConvertName: convertName];
                    phone.avatar = [self getAvatarOfContact: aPerson];
                    phone.contactId = contactId;
                    phone.phoneType = eNormalPhone;
                    
                    [listInfoPhoneNumber addObject: phone];
                }
            }else{
                NSLog(@"This contact don't have any phone number!!!");
            }
        }
    }
}

- (ContactObject *)getContactInPhoneBookWithIdRecord: (int)idRecord
{
    addressListBook = ABAddressBookCreate();
    ABRecordRef aPerson = ABAddressBookGetPersonWithRecordID(addressListBook, idRecord);
    
    ContactObject *aContact = [[ContactObject alloc] init];
    aContact.person = aPerson;
    aContact._id_contact = idRecord;
    aContact._fullName = [AppUtils getNameOfContact: aPerson];
    NSArray *nameInfo = [AppUtils getFirstNameAndLastNameOfContact: aPerson];
    aContact._firstName = [nameInfo objectAtIndex: 0];
    aContact._lastName = [nameInfo objectAtIndex: 1];
    
    if (![aContact._fullName isEqualToString:@""]) {
        NSString *convertName = [AppUtils convertUTF8CharacterToCharacter: aContact._fullName];
        aContact._nameForSearch = [AppUtils getNameForSearchOfConvertName: convertName];
    }
    
    //  Email
    ABMultiValueRef map = ABRecordCopyValue(aPerson, kABPersonEmailProperty);
    if (map) {
        for (int i = 0; i < ABMultiValueGetCount(map); ++i) {
            ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(map, i);
            NSInteger index = ABMultiValueGetIndexForIdentifier(map, identifier);
            if (index != -1) {
                NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(map, index));
                if (valueRef != NULL && ![valueRef isEqualToString:@""]) {
                    //  just get one email for contact
                    aContact._email = valueRef;
                    break;
                }
            }
        }
        CFRelease(map);
    }
    
    //  Company
    CFStringRef companyRef  = ABRecordCopyValue(aPerson, kABPersonOrganizationProperty);
    if (companyRef != NULL && companyRef != nil){
        NSString *company = (__bridge NSString *)companyRef;
        if (company != nil && ![company isEqualToString:@""]){
            aContact._company = company;
        }
    }
    
    aContact._avatar = [self getAvatarOfContact: aPerson];
    aContact._listPhone = [self getListPhoneOfContactPerson: aPerson withName: aContact._fullName];
    
    if (aContact._listPhone.count > 0) {
        ContactDetailObj *anItem = [aContact._listPhone firstObject];
        aContact._sipPhone = anItem._valueStr;
    }
    return aContact;
}

- (NSMutableArray *)getPBXContactPhone: (int)pbxContactId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    addressListBook = ABAddressBookCreate();
    ABRecordRef aPerson = ABAddressBookGetPersonWithRecordID(addressListBook, pbxContactId);
    
    NSString *pbxServer = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_SERVER];
    ABMultiValueRef phones = ABRecordCopyValue(aPerson, kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phones) > 0)
    {
        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
        {
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
            CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, j);
            
            NSString *phoneStr = (__bridge NSString *)phoneNumberRef;
            phoneStr = [[phoneStr componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
            
            NSString *nameStr = (__bridge NSString *)locLabel;
            
            if (phoneStr != nil && nameStr != nil) {
                PBXContact *pbxContact = [[PBXContact alloc] init];
                pbxContact._name = nameStr;
                pbxContact._number = phoneStr;
                
                NSString *convertName = [AppUtils convertUTF8CharacterToCharacter: nameStr];
                NSString *nameForSearch = [AppUtils getNameForSearchOfConvertName: convertName];
                pbxContact._nameForSearch = nameForSearch;
                
                NSString *avatarStr = @"";
                if (![AppUtils isNullOrEmpty: pbxServer]) {
                    NSString *avatarName = [NSString stringWithFormat:@"%@_%@.png", pbxServer, phoneStr];
                    NSString *localFile = [NSString stringWithFormat:@"/avatars/%@", avatarName];
                    NSData *avatarData = [AppUtils getFileDataFromDirectoryWithFileName:localFile];
                    if (avatarData != nil) {
                        
                        if ([avatarData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
                            avatarStr = [avatarData base64EncodedStringWithOptions: 0];
                        } else {
                            avatarStr = [avatarData base64Encoding];
                        }
                        pbxContact._avatar = avatarStr;
                    }
                }
                [result addObject: pbxContact];
            }
        }
    }
    return result;
}

- (NSMutableArray *)getListPhoneOfContactPerson: (ABRecordRef)aPerson withName: (NSString *)contactName
{
    NSMutableArray *result = nil;
    ABMultiValueRef phones = ABRecordCopyValue(aPerson, kABPersonPhoneProperty);
    NSString *strPhone = [[NSMutableString alloc] init];
    if (ABMultiValueGetCount(phones) > 0)
    {
        result = [[NSMutableArray alloc] init];
        
        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
        {
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
            CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, j);
            
            NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
            phoneNumber = [AppUtils removeAllSpecialInString: phoneNumber];
            
            strPhone = @"";
            if (locLabel == nil) {
                ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                anItem._iconStr = @"btn_contacts_home.png";
                anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Home"];
                anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                anItem._buttonStr = @"contact_detail_icon_call.png";
                anItem._typePhone = type_phone_home;
                [result addObject: anItem];
            }else{
                if (CFStringCompare(locLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_home.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Home"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_home;
                    [result addObject: anItem];
                }else if (CFStringCompare(locLabel, kABWorkLabel, 0) == kCFCompareEqualTo)
                {
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_work.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Work"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_work;
                    [result addObject: anItem];
                }else if (CFStringCompare(locLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo)
                {
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_mobile.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Mobile"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_mobile;
                    [result addObject: anItem];
                }else if (CFStringCompare(locLabel, kABPersonPhoneHomeFAXLabel, 0) == kCFCompareEqualTo)
                {
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_fax.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Fax"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_fax;
                    [result addObject: anItem];
                }else if (CFStringCompare(locLabel, kABOtherLabel, 0) == kCFCompareEqualTo)
                {
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_fax.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Other"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_other;
                    [result addObject: anItem];
                }else{
                    ContactDetailObj *anItem = [[ContactDetailObj alloc] init];
                    anItem._iconStr = @"btn_contacts_mobile.png";
                    anItem._titleStr = [[LanguageUtil sharedInstance] getContent:@"Mobile"];
                    anItem._valueStr = [AppUtils removeAllSpecialInString: phoneNumber];
                    anItem._buttonStr = @"contact_detail_icon_call.png";
                    anItem._typePhone = type_phone_mobile;
                    [result addObject: anItem];
                }
            }
        }
    }
    return result;
}

- (NSString *)getAvatarOfContact: (ABRecordRef)aPerson
{
    NSString *avatar = @"";
    if (aPerson != nil) {
        NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(aPerson);
        if (imgData != nil) {
            UIImage *imageAvatar = [UIImage imageWithData: imgData];
            CGRect rect = CGRectMake(0,0,120,120);
            UIGraphicsBeginImageContext(rect.size );
            [imageAvatar drawInRect:rect];
            UIImage *picture1 = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *tmpImgData = UIImagePNGRepresentation(picture1);
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
                avatar = [tmpImgData base64EncodedStringWithOptions: 0];
            }
        }
    }
    return avatar;
}

// copy database
- (void)copyFileDataToDocument : (NSString *)filename {
    NSArray *arrPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [arrPath objectAtIndex:0];
    NSString *pathString = [documentPath stringByAppendingPathComponent:filename];
    _databasePath = [[NSString alloc] initWithString: pathString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [fileManager setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey] ofItemAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents"] error:NULL];
    
    if (![fileManager fileExistsAtPath:pathString]) {
        NSError *error;
        @try {
            NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
            [fileManager copyItemAtPath:bundlePath toPath:pathString error:&error];
            if (error != nil ) {
                //                @throw [NSException exceptionWithName:@"Error copy file ! " reason:@"Can not copy file to Document" userInfo:nil];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception.description);
        }
    }
}

//- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
//{
//    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] params = %@", __FUNCTION__, userActivity.activityType] toFilePath:logFilePath];
//
//    //  when user click facetime video
//    if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
//        return YES;
//    }
//
//    INInteraction *interaction = userActivity.interaction;
//    if (interaction != nil) {
//        INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
//        if (startAudioCallIntent != nil && startAudioCallIntent.contacts.count > 0) {
//            INPerson *contact = startAudioCallIntent.contacts[0];
//            if (contact != nil) {
//                INPersonHandle *personHandle = contact.personHandle;
//                NSString *phoneNumber = personHandle.value;
//                if (![AppUtils isNullOrEmpty: phoneNumber])
//                {
//                    phoneNumber = [AppUtils removeAllSpecialInString: phoneNumber];
//                    if ([AppUtils isNullOrEmpty: phoneNumber]) {
//                        [self showSplashScreenOnView: NO];
//                    }else{
//                        [self showSplashScreenOnView: YES];
//
//                        [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:UserActivity];
//                        [[NSUserDefaults standardUserDefaults] synchronize];
//                    }
//                }
//            }
//        }
//    }
//    return YES;
//}

- (void)showSplashScreenOnView: (BOOL)show {
    if (splashScreen == nil) {
        UINib *nib = [UINib nibWithNibName:@"LaunchScreen" bundle:nil];
        splashScreen = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self.window addSubview:splashScreen];
    }
    splashScreen.frame = [UIScreen mainScreen].bounds;
    splashScreen.hidden = !show;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    //  when user click facetime video
    if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        return YES;
    }

    INInteraction *interaction = userActivity.interaction;
    if (interaction != nil) {
        INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
        if (startAudioCallIntent != nil && startAudioCallIntent.contacts.count > 0) {
            INPerson *contact = startAudioCallIntent.contacts[0];
            if (contact != nil) {
                INPersonHandle *personHandle = contact.personHandle;
                NSString *phoneNumber = personHandle.value;
                if (![AppUtils isNullOrEmpty: phoneNumber])
                {
                    phoneNumber = [AppUtils removeAllSpecialInString: phoneNumber];

                    if ([AppUtils isNullOrEmpty: phoneNumber]) {
                        [self showSplashScreenOnView: NO];
                    }else{
                        [self showSplashScreenOnView: YES];

                        [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:UserActivity];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
            }
        }
    }
    return YES;
}

#pragma mark - sync contact xmpp

+(LinphoneAppDelegate*) sharedInstance{
    return ((LinphoneAppDelegate*) [[UIApplication sharedApplication] delegate]);
}

#pragma mark - Web services delegate

- (void)updateCustomerTokenIOS {
    NSString *dndMode = [[NSUserDefaults standardUserDefaults] objectForKey:switch_dnd];
    if (USERNAME != nil && ![dndMode isEqualToString:@"YES"]) {
        NSString *destToken = [NSString stringWithFormat:@"ios%@", _deviceToken];
        NSString *params = [NSString stringWithFormat:@"pushtoken=%@&username=%@", destToken, USERNAME];
        [webService callGETWebServiceWithFunction:update_token_func andParams:params];
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] params = %@", __FUNCTION__, params] toFilePath:logFilePath];
    }
}

-(NSDate *) toLocalTime
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: [NSDate date]];
    return [NSDate dateWithTimeInterval: seconds sinceDate: [NSDate date]];
}

-(NSDate *) toGlobalTime
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate: [NSDate date]];
    return [NSDate dateWithTimeInterval: seconds sinceDate: [NSDate date]];
}

- (void)getMissedCallFromServer
{
    NSString *dateFrom = [[NSUserDefaults standardUserDefaults] objectForKey:DATE_FROM];
    
    //  NSDate *localDate = [self toLocalTime];
    //  NSString *dateTo = [NSString stringWithFormat:@"%ld", (long)[localDate timeIntervalSince1970]];
    NSString *dateTo = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSString *params = [NSString stringWithFormat:@"userName=%@&dateFrom=%@&dateTo=%@", USERNAME, dateFrom, dateTo];
    [webService callGETWebServiceWithFunction:get_missedcall_func andParams:params];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] params = %@", __FUNCTION__, params] toFilePath:logFilePath];
    
    [[NSUserDefaults standardUserDefaults] setObject:dateTo forKey:DATE_FROM];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)insertMissedCallToDatabase: (id)data {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"%s: %@", __FUNCTION__, @[data]] toFilePath:logFilePath];
    
    if (data != nil && [data isKindOfClass:[NSArray class]]) {
        for (int i=0; i<[(NSArray *)data count]; i++) {
            NSDictionary *callInfo = [data objectAtIndex: i];
            id createDate = [callInfo objectForKey:@"createDate"];
            NSString *phoneNumberCall = [callInfo objectForKey:@"phoneNumberCall"];
            if (createDate != nil && phoneNumberCall != nil) {
                NSString *callId = [AppUtils randomStringWithLength: 10];
                NSString *date = [AppUtils getDateFromInterval:[createDate doubleValue]];
                NSString *time = [AppUtils getFullTimeStringFromTimeInterval:[createDate doubleValue]];
                
                BOOL exists = [NSDatabase checkMissedCallExistsFromUser: phoneNumberCall withAccount: USERNAME atTime: (int)[createDate intValue]];
                if (!exists) {
                    int callType = [SipUtils getCurrentTypeForCall];
                    [NSDatabase InsertHistory:callId status:missed_call phoneNumber:phoneNumberCall callDirection:incomming_call recordFiles:@"" duration:0 date:date time:time time_int:[createDate doubleValue] callType:callType sipURI:phoneNumberCall MySip:USERNAME kCallId:@"" andFlag:1 andUnread:1];
                }
            }
        }
        //  Post to update notification after inserted missed call into database
        [[NSNotificationCenter defaultCenter] postNotificationName:k11UpdateBarNotifications object:nil];
    }
}

- (void)failedToCallWebService:(NSString *)link andError:(NSString *)error
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, error] toFilePath:logFilePath];
    
    if ([link isEqualToString: update_token_func]) {
        _updateTokenSuccess = false;
        
    }else if ([link isEqualToString: get_didlist_func]) {
        [self.window makeToast:[[LanguageUtil sharedInstance] getContent:@"Can not get DID list"]
                      duration:2.0 position:CSToastPositionCenter];
        [self showPopupToChooseDID: @[]];
    }else if ([link isEqualToString: get_missedcall_func]) {
        NSLog(@"Can not get missed call");
    }
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, @[data]] toFilePath:logFilePath];
    
    if ([link isEqualToString: update_token_func]) {
        _updateTokenSuccess = true;
        
    }else if ([link isEqualToString: get_didlist_func]) {
        [self showPopupToChooseDID: data];
        
    }else if ([link isEqualToString: get_missedcall_func]) {
        [self insertMissedCallToDatabase: data];
        
    }else if ([link isEqualToString: GetServerGroup]) {
        if (data != nil && [data isKindOfClass:[NSArray class]]) {
            [listGroup removeAllObjects];
            [listGroup addObjectsFromArray:(NSArray *)data];
            
            NSData *myData = [NSKeyedArchiver archivedDataWithRootObject: listGroup];
            [[NSUserDefaults standardUserDefaults] setObject:myData forKey:@"group_pbx_list"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

-(void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    
}

//  [Khai le - 25/10/2018]: Add write logs for app
- (void)setupForWriteLogFileForApp
{
    //  [NgnFileUtils createDirectoryAndSubDirectory:@"chats/records"];
    [NgnFileUtils createDirectory:recordsFolderName];
    
    //  create folder to contain log files
    [NgnFileUtils createDirectoryAndSubDirectory: logsFolderName];
    
    //  create folder to contain log files
    [NgnFileUtils createDirectoryAndSubDirectory: recordsFolderName];
    
    return;
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    //  set logs file path
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    
    NSString *logFilePath = [documentsDir stringByAppendingPathComponent:logsFolderName];
    
    DDLogFileManagerDefault *documentsFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logFilePath];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:documentsFileManager];
    
    [fileLogger setMaximumFileSize:(1024 * 2 * 1024)];  //  2MB for each log file
    [fileLogger setRollingFrequency:(3600.0 * 24.0)];  // roll everyday
    [[fileLogger logFileManager] setMaximumNumberOfLogFiles:5];
    [fileLogger setLogFormatter:[[DDLogFileFormatterDefault alloc]init]];
    
    [DDLog addLogger:fileLogger];
}

#pragma mark - Proxy config
- (void)registrationUpdateEvent:(NSNotification *)notif {
    NSString *message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue]
                    forProxy:[[notif.userInfo objectForKeyedSubscript:@"cfg"] pointerValue]
                     message:message];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state forProxy:(LinphoneProxyConfig *)proxy message:(NSString *)message {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] ------> registrationUpdate state is %d", __FUNCTION__, state] toFilePath: logFilePath];
    
    switch (state) {
        case LinphoneRegistrationOk: {
            if (!configPushToken) {
                LinphoneProxyConfig *defaultConfig = linphone_core_get_default_proxy_config(LC);
                if (defaultConfig) {
                    [[LinphoneManager instance] configurePushTokenForProxyConfig:defaultConfig];
                }
                configPushToken = YES;
            }
            
            //  [Khai Le - 15/12/2018]
            if (!splashScreen.hidden) {
                NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey: UserActivity];
                if (![AppUtils isNullOrEmpty: phoneNumber]) {
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Register to SIP okay. Call with UserActivity phone number = %@", phoneNumber] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                    
                    splashScreen.hidden = YES;
                    [SipUtils makeCallWithPhoneNumber: phoneNumber];
                    //  reset value
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserActivity];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                }else{
                    splashScreen.hidden = YES;
                }
            }
            break;
        }
        case LinphoneRegistrationNone:{
            break;
        }
        case LinphoneRegistrationCleared: {
            break;
        }
        case LinphoneRegistrationFailed: {
            break;
        }
        case LinphoneRegistrationProgress: {
            break;
        }
        default:
            break;
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    
    return YES;
}

#pragma mark - UIAlertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        if (buttonIndex == 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserActivity];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            splashScreen.hidden = YES;
        }else if (buttonIndex == 1) {
            LinphoneProxyConfig *defaultConfig = linphone_core_get_default_proxy_config(LC);
            if (defaultConfig != NULL) {
                linphone_proxy_config_enable_register(defaultConfig, YES);
                linphone_proxy_config_refresh_register(defaultConfig);
                linphone_proxy_config_done(defaultConfig);
                
                linphone_core_refresh_registers(LC);
                
                [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] You turned on account with Id = %@", __FUNCTION__, [SipUtils getAccountIdOfDefaultProxyConfig]] toFilePath: logFilePath];
            }
        }
    }
}

- (void)showWaiting: (BOOL)show {
    ipadWaiting.hidden = !show;
    if (show) {
        [ipadWaiting startAnimating];
    }else{
        [ipadWaiting stopAnimating];
    }
}

- (void)startGetDIDListForCall {
    NSString *params = [NSString stringWithFormat:@"username=%@", USERNAME];
    [webService callGETWebServiceWithFunction:get_didlist_func andParams:params];
}

- (void)showPopupToChooseDID: (id)data {
    if ([data isKindOfClass:[NSArray class]]) {
        if (data == nil) {
            data = [[NSArray alloc] init];
        }
        
        float wPopup = 350.0;
        float hCell = 60.0;
        if (IS_IPHONE || IS_IPOD) {
            if (SCREEN_WIDTH <= 320) {
                wPopup = 300.0;
                hCell = 50.0;
            }
        }else{
            wPopup = 420.0;
        }
        
        
        float popupHeight;
        if ([(NSArray *)data count] > 6) {
            popupHeight = hCell + 7*hCell;
        }else{
            popupHeight = hCell + ([(NSArray *)data count] + 1) * hCell;
        }
        
        ChooseDIDPopupView *popupDID = [[ChooseDIDPopupView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-wPopup)/2, (SCREEN_HEIGHT-popupHeight)/2, wPopup, popupHeight)];
        popupDID.delegate = self;
        [popupDID.listDID addObjectsFromArray: data];
        [popupDID.tbDIDList reloadData];
        [popupDID showInView:self.window animated:YES];
    }else{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Can not get data for prefix", __FUNCTION__] toFilePath:logFilePath];
    }
}

-(void)selectDIDForCallWithPrefix:(NSString *)prefix {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] prefix = %@, phoneForCall = %@", __FUNCTION__, prefix, phoneForCall] toFilePath:logFilePath];
    
    NSString *myExt = [SipUtils getAccountIdOfDefaultProxyConfig];
    if (![AppUtils isNullOrEmpty: myExt] && [myExt isEqualToString: phoneForCall]) {
        [self.window makeToast:[[LanguageUtil sharedInstance] getContent:@"Can not make call with yourself!"] duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    if (![AppUtils isNullOrEmpty: phoneForCall]) {
        callPrefix = prefix;
        
        NSString *strToCall = [NSString stringWithFormat:@"%@%@", prefix, phoneForCall];
        [SipUtils makeCallWithPhoneNumber: strToCall];
    }
}

- (void)setupValueForDevice {
    if (IS_IPHONE || IS_IPOD) {
        float wMenu = SCREEN_WIDTH/4;
        CGSize bgMenu = [UIImage imageNamed:@"menu_dialer_def.png"].size;
        _hTabbar = wMenu * bgMenu.height/bgMenu.width;
    }else{
        _hTabbar = 55.0;
    }
    
    _hStatus = [UIApplication sharedApplication].statusBarFrame.size.height;
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        _hRegistrationState = 44.0 + _hStatus;
        _hHeader = 50.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        _hRegistrationState = 44.0 + _hStatus;
        _hHeader = 50.0;
        
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        //  Screen width: 414.000000 - Screen height: 736.000000
        _hRegistrationState = 55.0 + _hStatus;
        _hHeader = 50.0;
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        _hRegistrationState = 44.0 + _hStatus;
        _hHeader = 50.0;
    }else{
        _hRegistrationState = 44.0 + _hStatus;
        _hHeader = 50.0;
    }
}

- (NSArray *)listFileAtPath:(NSString *)path {
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    return directoryContent;
}

- (void)renameFilesToHidden
{
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *files = [self listFileAtPath: documentDir];
    for (int icount=0; icount<(int)files.count; icount++) {
        NSString *fileName = [files objectAtIndex: icount];
        if (![AppUtils isNullOrEmpty: fileName])
        {
            if ([fileName hasPrefix:@"cloudcall"])
            {
                NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                
                NSString *newName = [NSString stringWithFormat:@".%@", fileName];
                BOOL exists = [AppUtils checkFileExistsInDocuments: newName];
                if (exists){
                    //  save path to database file
                    NSString *newPath = [documentDir stringByAppendingPathComponent:newName];
                     _databasePath = [[NSString alloc] initWithString: newPath];
                    //  ----
                    
                    NSString *fileRemovePath = [documentDir stringByAppendingPathComponent:fileName];
                    BOOL removedSuccess = [AppUtils deleteFileWithPath:fileRemovePath];
                    if (removedSuccess) {
                        NSLog(@"Removed file with name %@", fileName);
                    }
                }else{
                    NSString *oldPath = [documentDir stringByAppendingPathComponent:fileName];
                    NSString *newPath = [documentDir stringByAppendingPathComponent:newName];
                    
                    BOOL movedSuccess = [AppUtils moveFileFromSoure:oldPath toDestination:newPath];
                    if (movedSuccess){
                        //  save path to database file
                        _databasePath = [[NSString alloc] initWithString: newPath];
                        //  ----
                        
                        BOOL removed = [AppUtils deleteFileWithPath:oldPath];
                        if (removed) {
                            NSLog(@"Removed file with name %@", fileName);
                        }else{
                            NSLog(@"Fail to remove file with name %@", fileName);
                        }
                        NSLog(@"The file name has been changed.");
                    }
                }
            }
        }
    }
}

- (void)tryToUnRegisterSIP {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@" ------------->[%s]", __FUNCTION__] toFilePath:logFilePath];
    
    linphone_core_clear_proxy_config(LC);
}

- (void)checkToReloginPBX
{
    const MSList *list = linphone_core_get_proxy_config_list(LC);
    if (list == NULL) {
        NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:key_login];
        NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:key_password];
        NSString *domain = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_SERVER];
        NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_PORT];
        
        if (![AppUtils isNullOrEmpty: username] && ![AppUtils isNullOrEmpty: password] && ![AppUtils isNullOrEmpty: domain] && ![AppUtils isNullOrEmpty: port])
        {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:logFilePath];
            
            [SipUtils registerPBXAccount:username password:password ipAddress:domain port:port];
        }
    }
}

@end
