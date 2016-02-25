//
//  WebPageSnapshot.m
//  ThoughtsAroundMe
//
//  Created by Vlad Borovtsov on 20.02.16.
//  Copyright © 2016 Mana App Studio Ltd. All rights reserved.
//

#import "WebPageSnapshooter.h"
#import "UIView+Snapshot.h"
#import "HTMLParser.h"

typedef enum {
  WVStateInProgress = 0,
  WVStateLoaded = 1,
  WVStateError = 2
} WVState;

@interface WebPageSnapshooter () <UIWebViewDelegate> {
  BOOL _injectedPageLoadedJS;
  WVState _state;
}
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation WebPageSnapshooter

- (instancetype) init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void) dealloc {
  NSLog(@"Snapshooter has been deallocated");
}

- (void) snapshotOfURL:(NSURL *)url withSize:(CGSize)size completion:(void (^)(UIImage *))completion {
  NSLog(@"Snapshot of URL invoked: %@", [url debugDescription]);
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
  //[req setHTTPMethod:@"HEAD"];
  [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSLog(@"Data task finished");
    if (!error && [(NSHTTPURLResponse*)response statusCode] != 404) {
      NSLog(@"Data task finished SUCCESSFULLY");
      
      //Check for Og:image first
      NSString *htmlStr;
      if (data) {
        htmlStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSError *htmlParserError = nil;
        HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlStr error:&htmlParserError];
        if (!htmlParserError) {
          HTMLNode *head = [parser head];
          for (HTMLNode *inputNode in [head findChildTags:@"meta"]) {
            if ([[[inputNode getAttributeNamed:@"property"] lowercaseString] isEqualToString:@"og:image"]) {
              NSString *ogURL = [inputNode getAttributeNamed:@"content"];
              NSURL *url = [NSURL URLWithString:ogURL];
              if (url) {
                NSData * imageData = [[NSData alloc] initWithContentsOfURL: url];
                if (imageData) {
                  UIImage *img = [UIImage imageWithData:imageData];
                  if (img) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      completion(img);
                    });
                    return;
                  }
                }
              }
            }
          }
        }
      }
      //////////////////////////
      
      NSLog(@"Going to init some UI");
      dispatch_semaphore_t uiSem = dispatch_semaphore_create(0);
      dispatch_async(dispatch_get_main_queue(), ^{
        self.frame = CGRectMake(0, 0, size.width, size.height);
        _injectedPageLoadedJS = NO;
        _state = WVStateInProgress;
        self.webView = [[UIWebView alloc] initWithFrame:self.frame];
        self.webView.delegate = self;
        if (htmlStr) {
          [self.webView loadHTMLString:htmlStr baseURL:url];
        }
        else {
          NSURLRequest *thePageRequest = [NSURLRequest requestWithURL:url];
          [self.webView loadRequest:thePageRequest];
        }
        NSLog(@"UI load done");
        dispatch_semaphore_signal(uiSem);
        NSLog(@"Semaphore signalled");
      });
      dispatch_semaphore_wait(uiSem, DISPATCH_TIME_FOREVER);
      NSLog(@"After UIsem...");
      
      dispatch_semaphore_t sem = dispatch_semaphore_create(0);
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        __block BOOL again = YES;
        while (again) {
          
          __block BOOL loaded = NO;
          dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"Checking UIWebview...");
            //            NSString *evalString = [self.webView stringByEvaluatingJavaScriptFromString:@"window.__myLoad5t4tu5__;"];
            //loaded = [evalString isEqualToString:@"loaded"];
            
            /*
            if ([[self.webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"] && self.webView.request.URL != nil) {
              loaded = YES;
            }
             */
            if (self.webView.isLoading) {
              loaded = NO;
            }
            else {
              if (self.webView.request.URL) {
                loaded = YES;
              }
              else {
                loaded = NO;
              }
            }
            
            if (loaded || _state == WVStateError) {
              if (loaded) {
                _state = WVStateLoaded;
              }
              again = NO;
            }
            else {
              again = YES;
            }
          });
          
          [NSThread sleepForTimeInterval:1.0];
        }
        dispatch_semaphore_signal(sem);
      });
      dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
      
      if (_state == WVStateLoaded) {
        NSLog(@"WEBVIEW HAS LOADED THE PAGE");
        __block UIImage *result = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
          NSLog(@"Webview: %@",  [self.webView.request debugDescription]);
          NSString *jsHeight = [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"];
          CGFloat cheight = (float)[jsHeight integerValue];
          if (cheight < self.webView.frame.size.height) {
            CGRect f = self.webView.frame;
            f.size.height = cheight;
            self.webView.frame = f;
          }
          result = [self.webView tam_takeSnapshotLayer];
          completion(result);
        });
      }
      else {
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(nil);
        });
      }
    }
    else {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Data task finished with error");
        completion(nil);
      });
    }
  }] resume];
  

}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView
{
  /*
  if(!_injectedPageLoadedJS)
  {
    [self.webView stringByEvaluatingJavaScriptFromString:@"window.__myLoad5t4tu5__ = 'notloaded'; window.onload=function() {window.__myLoad5t4tu5__ = 'loaded';}"];
    _injectedPageLoadedJS = YES;
  }
   */
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  //
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  _state = WVStateError;
}

@end
