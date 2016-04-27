//
//  UIFont+Resize.h
//  HTMLToAttributedString
//
//  Created by Marc Desharnais on 2016-04-19.
//  Copyright © 2016 Deloitte Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIFont (Resize)
- (UIFont *)halfSizeFont;
- (UIFont *)changeSizeFont:(int)fontSizeStep;
@end
