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
    return [UIFont fontWithDescriptor:self.fontDescriptor size:self.pointSize/2];
}

- (UIFont *)changeSizeFont:(int)fontSizeStep
{
    return [UIFont fontWithDescriptor:self.fontDescriptor size:self.pointSize + fontSizeStep];
}

- (UIFont *)bold
{
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits: self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold] size:self.pointSize];
}

- (UIFont *)italic
{
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic] size:self.pointSize];
}

@end
