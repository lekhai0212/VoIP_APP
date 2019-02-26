//
//  LanguageUtil.h
//  linphone
//
//  Created by lam quang quan on 2/26/19.
//

#import <Foundation/Foundation.h>

typedef enum LanguageType{
    eLanguageDevice,
    eLanguageCustom,
}LanguageType;

@interface LanguageUtil : NSObject

+(LanguageUtil *) sharedInstance;
@property (nonatomic, assign) LanguageType typeLanguage;
@property (nonatomic, strong) HMLocalization *localization;

- (void)setCustomLanguage: (NSString *)languageKey;
- (NSString *)getContent: (NSString *)keyContent;

@end
