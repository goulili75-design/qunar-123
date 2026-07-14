// Minimal test dylib - just NSLog
#import <Foundation/Foundation.h>
__attribute__((constructor))
static void test(){NSLog(@"[TEST] Qunar dylib LOADED OK");}
