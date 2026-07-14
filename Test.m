#import <Foundation/Foundation.h>
__attribute__((constructor))
static void test(){
    // Write a marker file to prove injection
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/QUNAR_TWEAK_LOADED" contents:nil attributes:nil];
}
