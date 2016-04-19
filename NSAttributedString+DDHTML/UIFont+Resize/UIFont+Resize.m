//
//  UIFont+Resize.m
//  HTMLToAttributedString
//
//  Created by Marc Desharnais on 2016-04-19.
//  Copyright © 2016 Deloitte Digital. All rights reserved.
//

#import "UIFont+Resize.h"

@implementation UIFont (Resize)

- (UIFont *)halfSizeFont
{
    UIFontDescriptor *fontDescriptor = [self fontDescriptor];
    return [UIFont fontWithDescriptor:fontDescriptor size:self.pointSize/2];
}

@end
