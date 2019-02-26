//
//  LanguageUtil.m
//  linphone
//
//  Created by lam quang quan on 2/26/19.
//

#import "LanguageUtil.h"

@implementation LanguageUtil
@synthesize typeLanguage, localization;

+(LanguageUtil *) sharedInstance{
    static LanguageUtil* sInstance = nil;
    
    if(sInstance == nil){
        sInstance = [[LanguageUtil alloc] init];
        sInstance.localization = [[HMLocalization alloc] init];
        sInstance.typeLanguage = eLanguageDevice;
        //  [sInstance setCustomLanguage: key_vi];
    }
    return sInstance;
}

- (void)setCustomLanguage: (NSString *)languageKey {
    if (languageKey == nil || [languageKey isEqualToString:@""]) {
        typeLanguage = eLanguageDevice;
    }else{
        typeLanguage = eLanguageCustom;
        [[NSUserDefaults standardUserDefaults] setObject:languageKey forKey:language_key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [localization setLanguage: languageKey];
    }
}

- (NSString *)getContent: (NSString *)keyContent {
    if (typeLanguage == eLanguageDevice) {
        return NSLocalizedString(keyContent, nil);
    }else{
        return [localization localizedStringForKey: keyContent];
    }
}

@end
