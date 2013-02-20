//
//  AURosetteItem.m
//
//  Created by Emil Wojtaszek on 22.06.2012.
//

#import "AURosetteItem.h"

@implementation AURosetteItem

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNormalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage target:(id)target action:(SEL)action {
    self = [super init];
    if (self) {
        _action = action;
        _target = target;
        _normalImage = normalImage;
        _highlightedImage = highlightedImage;
    }
    return self;
}

@end
