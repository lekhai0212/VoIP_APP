//
//  PBXContact.h
//  linphone
//
//  Created by Apple on 5/12/17.
//
//

#import <Foundation/Foundation.h>

@interface PBXContact : NSObject

@property (nonatomic, strong) NSString *_name;
@property (nonatomic, strong) NSString *_number;
@property (nonatomic, strong) NSString *_nameForSearch;
@property (nonatomic, assign) int _idContact;
@property (nonatomic, strong) NSString *_avatar;

@end
