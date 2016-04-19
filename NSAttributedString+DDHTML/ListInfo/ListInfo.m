//
//  ListInfo.m
//  Pods
//
//  Created by Marc Desharnais on 2016-04-19.
//
//

#import "ListInfo.h"

@implementation ListInfo

- (id)initWithListType:(ListType)type {
    self = [super init];
    if (self) {
        _listType = type;
        _orderedIndex = 0;
    }
    return self;
}

@end