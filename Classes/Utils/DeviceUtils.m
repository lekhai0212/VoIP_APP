//
//  DeviceUtils.m
//  linphone
//
//  Created by lam quang quan on 10/22/18.
//

#import "DeviceUtils.h"
#import <sys/utsname.h>
#import <AVFoundation/AVFoundation.h>

@implementation DeviceUtils

//  https://www.theiphonewiki.com/wiki/Models
+ (NSString *)getModelsOfCurrentDevice {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *modelType =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return modelType;
}

//  [Khai le - 28/10/2018]
+ (float)getSizeOfKeypadButtonForDevice {
    if (!IS_IPOD && !IS_IPHONE) {
        return 85.0;
    }
    
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        return 62.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        return 70.0;
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        //  Screen width: 414.000000 - Screen height: 736.000000
        return 77.0;
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        return 80.0;
    }else{
        return 62.0;
    }
}

+ (float)getSpaceXBetweenKeypadButtonsForDevice
{
    if (!IS_IPOD && !IS_IPHONE) {
        return 50.0;
    }
    
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return 20.0;
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator])
    {
        return 30.0;
    }else{
        return 28.0;
    }
}
+ (float)getSpaceYBetweenKeypadButtonsForDevice {
    if (!IS_IPOD && !IS_IPHONE) {
        return 40.0;
    }
    
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return 9.0;
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator])
    {
        return 17.0;
    }else{
        return 15.0;
    }
}

+ (BOOL)checkNetworkAvailable {
    NetworkStatus internetStatus = [[LinphoneAppDelegate sharedInstance].internetReachable currentReachabilityStatus];
    if (internetStatus == ReachableViaWiFi || internetStatus == ReachableViaWWAN) {
        return YES;
    }
    return NO;
}

+ (float)getHeightForAddressTextFieldDialerWithDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    
    if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator])
    {
        return 80.0;
    }
    return 60.0;
}

+ (void)cleanLogFolder {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *arr = [WriteLogsUtils getAllFilesInDirectory: logsFolderName];
    for (int i=0; i<arr.count; i++) {
        NSString *fileName = [arr objectAtIndex: i];
        if ([fileName hasPrefix: bundleIdentifier]) {
            NSString *path = [NgnFileUtils getPathOfFileWithSubDir:[NSString stringWithFormat:@"%@/%@", logsFolderName, fileName]];
            [WriteLogsUtils removeFileWithPath: path];
        }
    }
}

+ (NSString *)convertLogFileName: (NSString *)fileName {
    if ([fileName hasPrefix:@"."]) {
        fileName = [fileName substringFromIndex: 1];
    }
    
    if ([fileName hasSuffix:@".txt"]) {
        fileName = [fileName substringToIndex:(fileName.length - 4)];
    }
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
    
    return [NSString stringWithFormat:@"Log_file_%@", fileName];
}

+ (float)getSizeOfIconEndCall {
    float wEndCall = 70.0;
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE]) {
        wEndCall = 60.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2]) {
        wEndCall = 70.0;
    
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2]) {
        wEndCall = 70.0;
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]) {
        wEndCall = 70.0;
        
    }
    return wEndCall;
}

+ (void)testChangeCamera {
    const char *currentCamId = (char *)linphone_core_get_video_device(LC);
    const char **cameras = linphone_core_get_video_devices(LC);
    const char *newCamId = NULL;
    int i;
    //  AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0
    //  AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1
    for (i = 0; cameras[i] != NULL; ++i) {
        if (strcmp(cameras[i], "StaticImage: Static picture") == 0)
            continue;
        if (strcmp(cameras[i], currentCamId) != 0) {
            newCamId = cameras[i];
            break;
        }
    }
    if (newCamId) {
        LOGI(@"Switching from [%s] to [%s]", currentCamId, newCamId);
        linphone_core_set_video_device(LC, newCamId);
        LinphoneCall *call = linphone_core_get_current_call(LC);
        if (call != NULL) {
            linphone_core_update_call(LC, call, NULL);
        }
    }
}

+ (float)getHeightLogoWelcomeForDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        return 40.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        return 73.0;
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        //  Screen width: 414.000000 - Screen height: 736.000000
        return 75.0;
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        return 80.0;
    }else{
        return 62.0;
    }
}

+ (UIEdgeInsets)getEdgeOfVideoCallDialerForDevice
{
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return UIEdgeInsetsMake(7, 7, 7, 7);
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2]){
        return UIEdgeInsetsMake(7, 7, 7, 7);
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        return UIEdgeInsetsMake(10, 10, 10, 10);
    }
    else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator])
    {
        return UIEdgeInsetsMake(10, 10, 10, 10);
    }else{
        return UIEdgeInsetsMake(10, 10, 10, 10);
    }
}

+ (float)getHeightSearchViewContactForDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return 45.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        return 50.0;
    }else{
        //  Screen width: 414.000000 - Screen height: 736.000000
        return 60.0;
    }
}

+ (float)getHeightAvatarSearchViewForDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return 35.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        return 40.0;
    }else{
        //  Screen width: 414.000000 - Screen height: 736.000000
        return 45.0;
    }
}

+ (float)getWidthPoupSearchViewForDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        return 260.0;
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2]){
        return 280.0;
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        return 300.0;
    }
    else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator])
    {
        return 300.0;
    }else{
        return 300.0;
    }
}


+ (BOOL)isAvailableVideo
{
    @autoreleasepool {
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (!captureDevice) {
            return NO;
        }
        
        NSError *error;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        
        if (!deviceInput || error) {
            return NO;
        }
        
        return YES;
    }
}

+ (BOOL)isAvailablePhotos
{
    @autoreleasepool {
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (!captureDevice) {
            return NO;
        }
        
        NSError *error;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        
        if (!deviceInput || error) {
            return NO;
        }
        
        return YES;
    }
}

+ (void)enableProximityMonitoringEnabled: (BOOL)enabled {
    UIDevice* device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled: enabled];
}

+ (BOOL)isConnectedEarPhone {
    NSArray *bluetoothPorts = @[ AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP ];
    
    NSArray *routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription *route in routes) {
        if ([bluetoothPorts containsObject:route.portType]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getNameOfEarPhoneConnected {
    NSArray *bluetoothPorts = @[ AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP ];
    
    NSArray *routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription *route in routes) {
        if ([bluetoothPorts containsObject:route.portType]) {
            return route.portName;
        }
    }
    return @"";
}

//  check current route used bluetooth
+ (TypeOutputRoute)getCurrentRouteForCall {
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *outputs = currentRoute.outputs;
    for (AVAudioSessionPortDescription *route in outputs) {
        if (route.portType == AVAudioSessionPortBuiltInReceiver) {
            return eReceiver;
            
        }else if (route.portType == AVAudioSessionPortBuiltInSpeaker || [[route.portType lowercaseString] containsString:@"speaker"]) {
            return eSpeaker;
            
        }else if (route.portType == AVAudioSessionPortBluetoothHFP || route.portType == AVAudioSessionPortBluetoothLE || route.portType == AVAudioSessionPortBluetoothA2DP) {
            return eEarphone;
        }
    }
    return eReceiver;
}

+ (void)setupFontSizeForDevice {
    NSString *deviceMode = [self getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
    {
        //  Screen width: 320.000000 - Screen height: 667.000000
        [LinphoneAppDelegate sharedInstance].headerFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 17.0];
        [LinphoneAppDelegate sharedInstance].headerFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 17.0];
        
        [LinphoneAppDelegate sharedInstance].contentFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        [LinphoneAppDelegate sharedInstance].contentFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
        
        [LinphoneAppDelegate sharedInstance].descFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 14.0];
        [LinphoneAppDelegate sharedInstance].descFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 14.0];
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        //  Screen width: 375.000000 - Screen height: 667.000000
        [LinphoneAppDelegate sharedInstance].headerFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 19.0];
        [LinphoneAppDelegate sharedInstance].headerFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 19.0];
        
        [LinphoneAppDelegate sharedInstance].contentFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 18.0];
        [LinphoneAppDelegate sharedInstance].contentFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 18.0];
        
        [LinphoneAppDelegate sharedInstance].descFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 15.0];
        [LinphoneAppDelegate sharedInstance].descFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 15.0];
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        //  Screen width: 414.000000 - Screen height: 736.000000
        [LinphoneAppDelegate sharedInstance].headerFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 19.0];
        [LinphoneAppDelegate sharedInstance].headerFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 20.0];
        
        [LinphoneAppDelegate sharedInstance].contentFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 18.0];
        [LinphoneAppDelegate sharedInstance].contentFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 18.0];
        
        [LinphoneAppDelegate sharedInstance].descFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        [LinphoneAppDelegate sharedInstance].descFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
        //  Screen width: 375.000000 - Screen height: 812.000000
        [LinphoneAppDelegate sharedInstance].headerFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 19.0];
        [LinphoneAppDelegate sharedInstance].headerFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 20.0];
        
        [LinphoneAppDelegate sharedInstance].contentFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 18.0];
        [LinphoneAppDelegate sharedInstance].contentFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 18.0];
        
        [LinphoneAppDelegate sharedInstance].descFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        [LinphoneAppDelegate sharedInstance].descFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
        
    }else{
        //  Screen width: 375.000000 - Screen height: 812.000000
        [LinphoneAppDelegate sharedInstance].headerFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 19.0];
        [LinphoneAppDelegate sharedInstance].headerFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 20.0];
        
        [LinphoneAppDelegate sharedInstance].contentFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 18.0];
        [LinphoneAppDelegate sharedInstance].contentFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 18.0];
        
        [LinphoneAppDelegate sharedInstance].descFontBold = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        [LinphoneAppDelegate sharedInstance].descFontNormal = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
    }
}


@end
