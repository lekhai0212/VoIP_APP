//
//  DeviceUtils.h
//  linphone
//
//  Created by lam quang quan on 10/22/18.
//

#import <Foundation/Foundation.h>

typedef enum {
    eReceiver = 1,
    eSpeaker,
    eEarphone,
}TypeOutputRoute;

@interface DeviceUtils : NSObject

+ (NSString *)getModelsOfCurrentDevice;
//  [Khai le - 28/10/2018]
+ (float)getSizeOfKeypadButtonForDevice: (NSString *)deviceMode;
+ (float)getSpaceXBetweenKeypadButtonsForDevice: (NSString *)deviceMode;
+ (float)getSpaceYBetweenKeypadButtonsForDevice: (NSString *)deviceMode;
+ (BOOL)checkNetworkAvailable;
+ (float)getHeightForAddressTextFieldDialerWithDevice: (NSString *)deviceMode;
+ (void)cleanLogFolder;
+ (NSString *)convertLogFileName: (NSString *)fileName;
+ (float)getSizeOfIconEndCall;
+ (void)testChangeCamera;
+ (float)getHeightLogoWelcomeForDevice;
+ (UIEdgeInsets)getEdgeOfVideoCallDialerForDevice;
+ (float)getHeightSearchViewContactForDevice;
+ (BOOL)isAvailableVideo;
+ (BOOL)isAvailablePhotos;
+ (void)enableProximityMonitoringEnabled: (BOOL)enabled;

//  Check device connected to bluetooth earphone
+ (BOOL)isConnectedEarPhone;
+ (NSString *)getNameOfEarPhoneConnected;

//  check current route used bluetooth
+ (TypeOutputRoute)getCurrentRouteForCall;
@end
