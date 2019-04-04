//
//  CustomAvatarImageView.m
//  linphone
//
//  Created by admin on 4/4/19.
//

#import "CustomAvatarImageView.h"

@implementation CustomAvatarImageView

-(void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
