#import <Foundation/Foundation.h>
__attribute__((constructor)) static void t() { NSLog(@"test"); }