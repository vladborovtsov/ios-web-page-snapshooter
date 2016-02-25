//
//  UIView+Snapshot.h
//  ThoughtsAroundMe
//
//  Created by Vladislav Kartashov on 13/07/15.
//  Copyright (c) 2015 Mana App Studio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Snapshot)
- (UIImage *)tam_takeSnapshot;
- (UIImage *) tam_takeSnapshotLayer;
- (UIImage *)snapshotInRect:(CGRect)rect scale:(CGFloat)scale;
@end
