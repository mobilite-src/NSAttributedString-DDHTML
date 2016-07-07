//
//  NSAttributedString+HTML.m
//
//  Created by Derek Bowen <dbowen@demiurgic.co>
//  Copyright (c) 2012-2015, Deloitte Digital
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of the <organization> nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSAttributedString+DDHTML.h"
#import "ListInfo.h"
#import "UIFont+Resize.h"
#include <libxml/HTMLparser.h>

@implementation NSAttributedString (DDHTML)

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString
{
    UIFont *preferredBodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    return [self attributedStringFromHTML:htmlString
                               normalFont:preferredBodyFont
                                 boldFont:[UIFont boldSystemFontOfSize:preferredBodyFont.pointSize]
                               italicFont:[UIFont italicSystemFontOfSize:preferredBodyFont.pointSize]];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont
{
    return [self attributedStringFromHTML:htmlString
                               normalFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                 boldFont:boldFont
                               italicFont:italicFont];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString normalFont:(UIFont *)normalFont boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont
{
    return [self attributedStringFromHTML:htmlString
                               normalFont:normalFont
                                 boldFont:boldFont
                               italicFont:italicFont
                                 imageMap:@{}];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString normalFont:(UIFont *)normalFont fontColor:(UIColor*)fontColor customLinkAttributes:(NSDictionary<NSString *, id> *)customLinkAttributes
{
    UIFont *preferredBodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    return [self attributedStringFromHTML:htmlString
                               normalFont:normalFont
                                 boldFont:[UIFont boldSystemFontOfSize:preferredBodyFont.pointSize]
                               italicFont:[UIFont italicSystemFontOfSize:preferredBodyFont.pointSize]
                                fontColor:fontColor
                                 imageMap:@{}
                     customLinkAttributes:customLinkAttributes];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString normalFont:(UIFont *)normalFont boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont fontColor:(UIColor*)fontColor customLinkAttributes:(NSDictionary<NSString *, id> *)customLinkAttributes
{
    return [self attributedStringFromHTML:htmlString
                               normalFont:normalFont
                                 boldFont:boldFont
                               italicFont:italicFont
                                fontColor:fontColor
                                 imageMap:@{}
                     customLinkAttributes:customLinkAttributes];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString normalFont:(UIFont *)normalFont boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont imageMap:(NSDictionary<NSString *, UIImage *> *)imageMap
{
    return [self attributedStringFromHTML:htmlString
                               normalFont:normalFont
                                 boldFont:boldFont
                               italicFont:italicFont
                                fontColor:[UIColor blackColor]
                                 imageMap:@{}
                     customLinkAttributes:@{}];
}

+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString normalFont:(UIFont *)normalFont boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont fontColor:(UIColor*)fontColor imageMap:(NSDictionary<NSString *, UIImage *> *)imageMap customLinkAttributes:(NSDictionary<NSString *, id> *)customLinkAttributes
{
    // Parse HTML string as XML document using UTF-8 encoding
    NSData *documentData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    xmlDoc *document = htmlReadMemory(documentData.bytes, (int)documentData.length, nil, "UTF-8", HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
    
    if (document == NULL) {
        return [[NSAttributedString alloc] initWithString:htmlString attributes:nil];
    }
    
    NSMutableAttributedString *finalAttributedString = [[NSMutableAttributedString alloc] init];
    
    xmlNodePtr currentNode = document->children;
    while (currentNode != NULL) {
        NSAttributedString *childString = [self attributedStringFromNode:currentNode normalFont:normalFont boldFont:boldFont italicFont:italicFont fontColor:fontColor imageMap:imageMap parentNodeListType:[self getListInfoFromNode:currentNode] customLinkAttributes:customLinkAttributes];
        [finalAttributedString appendAttributedString:childString];
        
        currentNode = currentNode->next;
    }
    
    xmlFreeDoc(document);
    
    return finalAttributedString;
}


+ (ListType)getListTypeFromNode:(xmlNodePtr)xmlNode {
    if (xmlNode->type == XML_ELEMENT_NODE) {
        if (strncmp("ul", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            return ListTypeUnordered;
        } else if (strncmp("ol", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            return ListTypeOrdered;
        }
    }
    return ListTypeNone;
}

+ (int)getListElementCountFromListNode:(xmlNodePtr)xmlNode {
    uint listElementCount = 0;
    if (xmlNode->children) {
        xmlNodePtr currentChild = xmlNode->children;
        while (currentChild) {
            if (xmlNode->type == XML_ELEMENT_NODE) {
                if (strncmp("li", (const char *)currentChild->name, strlen((const char *)currentChild->name)) == 0) {
                    listElementCount++;
                }
            }
            currentChild = currentChild->next;
        }
    }
    return listElementCount;
}

+ (NSAttributedString *)attributedStringFromNode:(xmlNodePtr)xmlNode normalFont:(UIFont *)normalFont boldFont:(UIFont *)boldFont italicFont:(UIFont *)italicFont fontColor:(UIColor*)fontColor imageMap:(NSDictionary<NSString *, UIImage *> *)imageMap parentNodeListType:(ListInfo *)parentNodeListInfo customLinkAttributes:(NSDictionary<NSString *, id> *)customLinkAttributes
{
    NSMutableAttributedString *nodeAttributedString = [[NSMutableAttributedString alloc] init];
    
    if ((xmlNode->type != XML_ENTITY_REF_NODE) && ((xmlNode->type != XML_ELEMENT_NODE) && xmlNode->content != NULL)) {
        NSAttributedString *normalAttributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithCString:(const char *)xmlNode->content encoding:NSUTF8StringEncoding] attributes:@{NSFontAttributeName : normalFont}];
        [nodeAttributedString appendAttributedString:normalAttributedString];
    }
    
    ListInfo *currentNodeListInfo = [self getListInfoFromNode:xmlNode];
    
    // Handle children
    xmlNodePtr currentNode = xmlNode->children;
    while (currentNode != NULL) {
        NSAttributedString *childString = [self attributedStringFromNode:currentNode normalFont:normalFont boldFont:boldFont italicFont:italicFont fontColor:fontColor imageMap:imageMap parentNodeListType:currentNodeListInfo customLinkAttributes:customLinkAttributes];
        [nodeAttributedString appendAttributedString:childString];
        
        currentNode = currentNode->next;
    }
    
    if (xmlNode->type == XML_ELEMENT_NODE) {
        
        UIColor *foregroundColor = fontColor;
        NSRange nodeAttributedStringRange = NSMakeRange(0, nodeAttributedString.length);
        
        // Build dictionary to store attributes
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        if (xmlNode->properties != NULL) {
            xmlAttrPtr attribute = xmlNode->properties;
            
            while (attribute != NULL) {
                NSString *attributeValue = @"";
                
                if (attribute->children != NULL) {
                    attributeValue = [NSString stringWithCString:(const char *)attribute->children->content encoding:NSUTF8StringEncoding];
                }
                NSString *attributeName = [[NSString stringWithCString:(const char*)attribute->name encoding:NSUTF8StringEncoding] lowercaseString];
                [attributeDictionary setObject:attributeValue forKey:attributeName];
                
                attribute = attribute->next;
            }
        }
        
        // Bold Tag
        if (strncmp("b", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0 ||
            strncmp("strong", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            if (boldFont) {
                if (![NSAttributedString applyBoldItalicToAttributedString:nodeAttributedString ifMatchFontIsPresent:italicFont forRange:nodeAttributedStringRange]) {
                    [nodeAttributedString addAttribute:NSFontAttributeName value:boldFont range:nodeAttributedStringRange];
                }
            }
        }
        
        // Italic Tag
        else if (strncmp("i", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0 ||
                 strncmp("em", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            if (italicFont) {
                if (![NSAttributedString applyBoldItalicToAttributedString:nodeAttributedString ifMatchFontIsPresent:boldFont forRange:nodeAttributedStringRange]) {
                    [nodeAttributedString addAttribute:NSFontAttributeName value:italicFont range:nodeAttributedStringRange];
                }
            }
        }
        
        // Underline Tag
        else if (strncmp("u", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:nodeAttributedStringRange];
        }
        
        // Stike Tag
        else if (strncmp("strike", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSStrikethroughStyleAttributeName value:@(YES) range:nodeAttributedStringRange];
        }
        
        // Stoke Tag
        else if (strncmp("stroke", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            UIColor *strokeColor = [UIColor purpleColor];
            NSNumber *strokeWidth = @(1.0);
            
            if (attributeDictionary[@"color"]) {
                strokeColor = [self colorFromHexString:attributeDictionary[@"color"]];
            }
            if (attributeDictionary[@"width"]) {
                strokeWidth = @(fabs([attributeDictionary[@"width"] doubleValue]));
            }
            if (!attributeDictionary[@"nofill"]) {
                strokeWidth = @(-fabs([strokeWidth doubleValue]));
            }
            
            [nodeAttributedString addAttribute:NSStrokeColorAttributeName value:strokeColor range:nodeAttributedStringRange];
            [nodeAttributedString addAttribute:NSStrokeWidthAttributeName value:strokeWidth range:nodeAttributedStringRange];
        }
        
        // Shadow Tag
        else if (strncmp("shadow", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            #if __has_include(<UIKit/NSShadow.h>)
                NSShadow *shadow = [[NSShadow alloc] init];
                shadow.shadowOffset = CGSizeMake(0, 0);
                shadow.shadowBlurRadius = 2.0;
                shadow.shadowColor = [UIColor blackColor];
                
                if (attributeDictionary[@"offset"]) {
                    shadow.shadowOffset = CGSizeFromString(attributeDictionary[@"offset"]);
                }
                if (attributeDictionary[@"blurradius"]) {
                    shadow.shadowBlurRadius = [attributeDictionary[@"blurradius"] doubleValue];
                }
                if (attributeDictionary[@"color"]) {
                    shadow.shadowColor = [self colorFromHexString:attributeDictionary[@"color"]];
                }
            
                [nodeAttributedString addAttribute:NSShadowAttributeName value:shadow range:nodeAttributedStringRange];
            #endif
        }
        
        // Font Tag
        else if (strncmp("font", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            NSString *fontName = nil;
            NSNumber *fontSize = nil;
            UIColor *backgroundColor = nil;
            
            if (attributeDictionary[@"face"]) {
                fontName = attributeDictionary[@"face"];
            }
            if (attributeDictionary[@"size"]) {
                fontSize = @([attributeDictionary[@"size"] doubleValue]);
            }
            if (attributeDictionary[@"color"]) {
                foregroundColor = [self colorFromHexString:attributeDictionary[@"color"]];
            }
            if (attributeDictionary[@"backgroundcolor"]) {
                backgroundColor = [self colorFromHexString:attributeDictionary[@"backgroundcolor"]];
            }
    
            if (fontName == nil && fontSize != nil) {
                [nodeAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[fontSize doubleValue]] range:nodeAttributedStringRange];
            }
            else if (fontName != nil && fontSize == nil) {
                [nodeAttributedString addAttribute:NSFontAttributeName value:[self fontOrSystemFontForName:fontName size:normalFont.pointSize] range:nodeAttributedStringRange];
            }
            else if (fontName != nil && fontSize != nil) {
                [nodeAttributedString addAttribute:NSFontAttributeName value:[self fontOrSystemFontForName:fontName size:fontSize.floatValue] range:nodeAttributedStringRange];
            }

            if (backgroundColor) {
                [nodeAttributedString addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:nodeAttributedStringRange];
            }
        }
        
        // Paragraph Tag
        else if (strncmp("p", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

            if ([attributeDictionary objectForKey:@"align"]) {
                NSString *alignString = [attributeDictionary[@"align"] lowercaseString];
                
                if ([alignString isEqualToString:@"left"]) {
                    paragraphStyle.alignment = NSTextAlignmentLeft;
                }
                else if ([alignString isEqualToString:@"center"]) {
                    paragraphStyle.alignment = NSTextAlignmentCenter;
                }
                else if ([alignString isEqualToString:@"right"]) {
                    paragraphStyle.alignment = NSTextAlignmentRight;
                }
                else if ([alignString isEqualToString:@"justify"]) {
                    paragraphStyle.alignment = NSTextAlignmentJustified;
                }
            }
            if ([attributeDictionary objectForKey:@"linebreakmode"]) {
                NSString *lineBreakModeString = [attributeDictionary[@"linebreakmode"] lowercaseString];
                
                if ([lineBreakModeString isEqualToString:@"wordwrapping"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
                }
                else if ([lineBreakModeString isEqualToString:@"charwrapping"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
                }
                else if ([lineBreakModeString isEqualToString:@"clipping"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
                }
                else if ([lineBreakModeString isEqualToString:@"truncatinghead"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
                }
                else if ([lineBreakModeString isEqualToString:@"truncatingtail"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
                }
                else if ([lineBreakModeString isEqualToString:@"truncatingmiddle"]) {
                    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
                }
            }
            
            if ([attributeDictionary objectForKey:@"firstlineheadindent"]) {
                paragraphStyle.firstLineHeadIndent = [attributeDictionary[@"firstlineheadindent"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"headindent"]) {
                paragraphStyle.headIndent = [attributeDictionary[@"headindent"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"hyphenationfactor"]) {
                paragraphStyle.hyphenationFactor = [attributeDictionary[@"hyphenationfactor"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"lineheightmultiple"]) {
                paragraphStyle.lineHeightMultiple = [attributeDictionary[@"lineheightmultiple"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"linespacing"]) {
                paragraphStyle.lineSpacing = [attributeDictionary[@"linespacing"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"maximumlineheight"]) {
                paragraphStyle.maximumLineHeight = [attributeDictionary[@"maximumlineheight"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"minimumlineheight"]) {
                paragraphStyle.minimumLineHeight = [attributeDictionary[@"minimumlineheight"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"paragraphspacing"]) {
                paragraphStyle.paragraphSpacing = [attributeDictionary[@"paragraphspacing"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"paragraphspacingbefore"]) {
                paragraphStyle.paragraphSpacingBefore = [attributeDictionary[@"paragraphspacingbefore"] doubleValue];
            }
            if ([attributeDictionary objectForKey:@"tailindent"]) {
                paragraphStyle.tailIndent = [attributeDictionary[@"tailindent"] doubleValue];
            }
            
            [nodeAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:nodeAttributedStringRange];
			
			// MR - For some reason they are not adding the paragraph space when parsing the <p> tag
			[nodeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }


        // Links
        else if (strncmp("a href", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            
            xmlChar *value = xmlNodeListGetString(xmlNode->doc, xmlNode->xmlChildrenNode, 1);
            if (value)
            {
                NSString *link = attributeDictionary[@"href"];
                
                for (NSString *key in customLinkAttributes.allKeys) {
                    if ([key isEqualToString:NSLinkAttributeName]) {
                        [nodeAttributedString addAttribute:customLinkAttributes[key] value:[NSURL URLWithString:link] range:NSMakeRange(0, nodeAttributedString.length)];
                    } else {
                        [nodeAttributedString addAttribute:key value:customLinkAttributes[key] range:NSMakeRange(0, nodeAttributedString.length)];
                    }
                }
                [nodeAttributedString addAttribute:NSLinkAttributeName value:link range:NSMakeRange(0, nodeAttributedString.length)];
            }
        }
        
        // New Lines
        else if (strncmp("br", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        
        else if (strncmp("h2", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSFontAttributeName value:boldFont range:nodeAttributedStringRange];
        }
        
        else if (strncmp("h3", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSFontAttributeName value:[boldFont changeSizeFont:-2] range:nodeAttributedStringRange];
        }
        
        else if (strncmp("h4", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSFontAttributeName value:[boldFont changeSizeFont:-4] range:nodeAttributedStringRange];
        }
        
        // Images
        else if (strncmp("img", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            #if __has_include(<UIKit/NSTextAttachment.h>)
                NSString *src = attributeDictionary[@"src"];
                NSString *width = attributeDictionary[@"width"];
                NSString *height = attributeDictionary[@"height"];
        
                if (src != nil) {
                    UIImage *image = imageMap[src];
                    if (image == nil) {
                        image = [UIImage imageNamed:src];
                    }
                    
                    if (image != nil) {
                        NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
                        imageAttachment.image = image;
                        if (width != nil && height != nil) {
                            imageAttachment.bounds = CGRectMake(0, 0, [width integerValue] / 2, [height integerValue] / 2);
                        }
                        NSAttributedString *imageAttributeString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
                        [nodeAttributedString appendAttributedString:imageAttributeString];
                    }
                }
            #endif
        }
        
        // list elements
        else if (strncmp("li", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            
            if (parentNodeListInfo.listType == ListTypeUnordered) {
                NSMutableAttributedString *attributedUnorderedListPrefix = [[NSMutableAttributedString alloc] initWithString:@"\u2022\t"];
                if (boldFont) {
                    [attributedUnorderedListPrefix addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0, attributedUnorderedListPrefix.length)];
                }
                [nodeAttributedString insertAttributedString:attributedUnorderedListPrefix atIndex:0];
                parentNodeListInfo.orderedIndex++;
            } else if (parentNodeListInfo.listType == ListTypeOrdered) {
                NSString *orderedListPrefix = [NSString stringWithFormat:@"%i.\t", parentNodeListInfo.orderedIndex];
                NSMutableAttributedString *attributedOrderedListPrefix = [[NSMutableAttributedString alloc] initWithString:orderedListPrefix];
                [attributedOrderedListPrefix addAttribute:NSFontAttributeName value:normalFont range:NSMakeRange(0, attributedOrderedListPrefix.length)];
                [nodeAttributedString insertAttributedString:attributedOrderedListPrefix atIndex:0];
                parentNodeListInfo.orderedIndex++;
            }
            
            // Adjust paragraph style of the bullet list lines so that the text is vertically aligned with the first line
            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            
            NSString *stringWithGlyph = [NSString stringWithUTF8String:"\t"];
            CGSize glyphSize = [stringWithGlyph sizeWithAttributes:[NSDictionary dictionaryWithObject:normalFont forKey:NSFontAttributeName]];
            
            paragraphStyle.headIndent = glyphSize.width;
            
            if (parentNodeListInfo.orderedIndex <= parentNodeListInfo.elementCount) {
                paragraphStyle.paragraphSpacing = normalFont.pointSize;
            }
            [nodeAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, nodeAttributedString.length)];
            
        } else if (strncmp("sup", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSBaselineOffsetAttributeName value:@(normalFont.pointSize/2) range:nodeAttributedStringRange];
            [nodeAttributedString addAttribute:NSFontAttributeName value:[normalFont halfSizeFont] range:nodeAttributedStringRange];
            
        } else if (strncmp("sub", (const char *)xmlNode->name, strlen((const char *)xmlNode->name)) == 0) {
            [nodeAttributedString addAttribute:NSBaselineOffsetAttributeName value:@(-normalFont.pointSize/4) range:nodeAttributedStringRange];
            [nodeAttributedString addAttribute:NSFontAttributeName value:[normalFont halfSizeFont] range:nodeAttributedStringRange];
        }
        
        if (foregroundColor) {
            NSMutableArray *ranges = [NSMutableArray new];
            NSMutableArray *colors = [NSMutableArray new];

            [nodeAttributedString enumerateAttributesInRange:nodeAttributedStringRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {

                if (attributes[NSForegroundColorAttributeName] != nil) {
                    // Take note of all the ranges containing a foreground color attribute
                    [ranges addObject:[NSValue valueWithRange:range]];
                    [colors addObject:attributes[NSForegroundColorAttributeName]];
                    }
                }
                ];
            
            // Apply foreground color to all the string by default
            [nodeAttributedString addAttribute:NSForegroundColorAttributeName value:foregroundColor range:nodeAttributedStringRange];

            
            // Restore colors set by children nodes
            for (int i = 0; i < ranges.count; i++) {
                NSRange range = [[ranges objectAtIndex:i] rangeValue];
                [nodeAttributedString removeAttribute:NSForegroundColorAttributeName range:range];
                [nodeAttributedString addAttribute:NSForegroundColorAttributeName value:[colors objectAtIndex:i] range:range];
            }
        }
        
        // If some custom link attributes are specified, assign the link color according to
        if ([customLinkAttributes.allKeys containsObject:NSLinkAttributeName] &&
            [customLinkAttributes.allKeys containsObject:NSForegroundColorAttributeName]) {
            
            NSMutableArray *ranges = [NSMutableArray new];
            
            [nodeAttributedString enumerateAttributesInRange:nodeAttributedStringRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {
                    // Take note of all the ranges containing a link attribute
                    if (attributes[customLinkAttributes[NSLinkAttributeName]] != nil) {
                        [ranges addObject:[NSValue valueWithRange:range]];
                    }
                }
             ];

            // Assign the custom link color to the ranges
            for (int i = 0; i < ranges.count; i++) {
                NSRange range = [[ranges objectAtIndex:i] rangeValue];
                [nodeAttributedString removeAttribute:NSForegroundColorAttributeName range:range];
                [nodeAttributedString addAttribute:NSForegroundColorAttributeName value:customLinkAttributes[NSForegroundColorAttributeName] range:range];
            }
        }
    }
    
    return nodeAttributedString;
}

+ (UIFont *)fontOrSystemFontForName:(NSString *)fontName size:(CGFloat)fontSize {
    UIFont * font = [UIFont fontWithName:fontName size:fontSize];
    if(font) {
        return font;
    }
    return [UIFont systemFontOfSize:fontSize];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    if (hexString == nil)
        return nil;
    
    hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    char *p;
    NSUInteger hexValue = strtoul([hexString cStringUsingEncoding:NSUTF8StringEncoding], &p, 16);

    return [UIColor colorWithRed:((hexValue & 0xff0000) >> 16) / 255.0 green:((hexValue & 0xff00) >> 8) / 255.0 blue:(hexValue & 0xff) / 255.0 alpha:1.0];
}

+ (ListInfo *)getListInfoFromNode:(xmlNodePtr)xmlNode {
    
    ListType listType = [self getListTypeFromNode:xmlNode];

    uint listElementCount = 0;
    if (listType != ListTypeNone) {
        listElementCount = [self getListElementCountFromListNode:xmlNode];
    }
    return [[ListInfo alloc] initWithListType:listType withListElementCount:listElementCount];
}

+ (BOOL)applyBoldItalicToAttributedString:(NSMutableAttributedString *)attributedString ifMatchFontIsPresent:(UIFont *)matchFont forRange:(NSRange)range {
    __block BOOL wasChanged = NO;
    
    [attributedString enumerateAttribute:NSFontAttributeName inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *currentFont = (UIFont *)value;
            
            if (currentFont == matchFont) {
                stop = YES;
                wasChanged = YES;
                UIFontDescriptor *fontD = [currentFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:fontD size:currentFont.pointSize] range:range];
            }
        }
    }];
    
    return wasChanged;
}

@end
