//
//  ContactCell.m
//  linphone
//
//  Created by user on 13/5/14.
//
//

#import "ContactCell.h"
#import "Utils.h"

@implementation ContactCell
@synthesize name, phone, image, strCallnexId, avatarStr, _lbSepa, icCall;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    float marginLeft;
    float marginRight;
    
    if (IS_IPHONE || IS_IPOD) {
        marginRight = 15.0;
        marginLeft = 15.0;
        icCall.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    }else{
        marginRight = 15.0;
        marginLeft = 15.0;
        icCall.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    
    image.clipsToBounds = YES;
    image.layer.cornerRadius = 45.0/2;
    [image mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(self).offset(marginLeft);
        make.width.height.mas_equalTo(45.0);
    }];
    
    icCall.backgroundColor = UIColor.clearColor;
    [icCall setTitleColor:UIColor.clearColor forState:UIControlStateNormal];
    [icCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.right.equalTo(self).offset(-marginRight);
        make.width.height.mas_equalTo(40.0);
    }];
    
    name.backgroundColor = UIColor.clearColor;
    name.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
    name.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(image);
        make.left.equalTo(image.mas_right).offset(10.0);
        make.right.equalTo(icCall).offset(-10.0);
        make.bottom.equalTo(image.mas_centerY);
    }];
    
    phone.backgroundColor = UIColor.clearColor;
    phone.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    phone.textColor = UIColor.darkGrayColor;
    [phone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom);
        make.left.right.equalTo(name);
        make.bottom.equalTo(image.mas_bottom);
    }];
    
    _lbSepa.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0)
                                               blue:(235/255.0) alpha:1.0];
    [_lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(1.0);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (!IS_IPHONE && !IS_IPOD) {
        if (selected) {
            self.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0)
                                                    blue:(230/255.0) alpha:1.0];
        }else{
            self.backgroundColor = UIColor.whiteColor;
        }
    }
    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0)
                                                blue:(245/255.0) alpha:1.0];
    }else{
        if (IS_IPHONE || IS_IPOD) {
            self.backgroundColor = UIColor.clearColor;
        }else{
            self.backgroundColor = UIColor.whiteColor;
        }
    }
}

- (void)setContact:(Contact *)acontact {
    _contact = acontact;
    if(_contact) {
        [ContactDisplay setDisplayNameLabel:name forContact:_contact];
    }
}

- (void)dealloc {
}

@end
