//
//  UIView+Snapshot.m
//  ThoughtsAroundMe
//
//  Created by Vladislav Kartashov on 13/07/15.
//  Copyright (c) 2015 Mana App Studio Ltd. All rights reserved.
//

#import "UIView+Snapshot.h"

@implementation UIView (Snapshot)

- (UIImage *)tam_takeSnapshot {
  UIGraphicsBeginImageContext(self.bounds.size);
  [self.layer.presentationLayer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return snapshot;
}

- (UIImage *) tam_takeSnapshotLayer {
  UIGraphicsBeginImageContext(self.bounds.size);
  [self.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return snapshot;
}

- (UIImage *)snapshotInRect:(CGRect)rect scale:(CGFloat)scale  {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, scale);
  
  [self drawViewHierarchyInRect:rect afterScreenUpdates:YES];
  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return snapshot;
}
@end
