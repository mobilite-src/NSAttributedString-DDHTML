//
//  ListInfo.h
//  Pods
//
//  Created by Marc Desharnais on 2016-04-19.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ListType) {
    ListTypeNone,
    ListTypeOrdered,
    ListTypeUnordered
};


@interface ListInfo : NSObject {
}

- (id)initWithListType:(ListType)type withListElementCount:(uint)elementCount;

@property ListType listType;
@property int orderedIndex;
@property int elementCount;

@end