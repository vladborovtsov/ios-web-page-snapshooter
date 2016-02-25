//
//  WebPageSnapshot.h
//  ThoughtsAroundMe
//
//  Created by Vlad Borovtsov on 20.02.16.
//  Copyright © 2016 Mana App Studio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WebPageSnapshooter : UIView

- (instancetype) init;
- (void) snapshotOfURL:(NSURL *) url withSize:(CGSize) size completion:(void (^)(UIImage *))completion;

@end
