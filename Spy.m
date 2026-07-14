// Qunar Spy - Log ALL device parameters collected by the app
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Log every call to these functions
#define SPY(func, args...) NSLog(@"[SPY] " func, ##args)

// UIDevice - log all getters
static id (*orig_uid)(id, SEL);
static id hook_uid(id self, SEL _cmd) {
    id r = orig_uid(self, _cmd);
    SPY(@"UIDevice.%@ = %@", NSStringFromSelector(_cmd), r);
    return r;
}

// NSProcessInfo
static id (*orig_pi)(id, SEL);
static id hook_pi(id self, SEL _cmd) {
    id r = orig_pi(self, _cmd);
    SPY(@"NSProcessInfo.%@ = %@", NSStringFromSelector(_cmd), r);
    return r;
}

// CTTelephonyNetworkInfo
static id (*orig_ct)(id, SEL);
static id hook_ct(id self, SEL _cmd) {
    id r = orig_ct(self, _cmd);
    SPY(@"CTTelephony.%@ = %@", NSStringFromSelector(_cmd), r);
    return r;
}

// NSFileManager
static BOOL (*orig_fep)(id, SEL, NSString*);
static BOOL hook_fep(id self, SEL _cmd, NSString *p) {
    BOOL r = orig_fep(self, _cmd, p);
    if ([p containsString:@"/var"] || [p containsString:@"Cydia"] || [p containsString:@"apt"] || [p containsString:@"bin/"]) {
        SPY(@"fileExists: %@ = %d", p, r);
    }
    return r;
}

// NSHTTPURLResponse + request
static void (*orig_setHeader)(id, SEL, NSString*, NSString*);
static void hook_setHeader(id self, SEL _cmd, NSString *v, NSString *f) {
    if ([f hasPrefix:@"Q-"] || [f hasPrefix:@"X-"] || [f hasPrefix:@"L-"] || [f containsString:@"Cookie"]) {
        SPY(@"Header: %@ = %@", f, v);
    }
    orig_setHeader(self, _cmd, v, f);
}

// NSUserDefaults
static id (*orig_ud)(id, SEL);
static id hook_ud(id self, SEL _cmd) {
    id r = orig_ud(self, _cmd);
    SPY(@"UserDefaults[%@] = %@", NSStringFromSelector(_cmd), r ?: @"nil");
    return r;
}

// Keychain
static OSStatus (*orig_secCopy)(CFDictionaryRef, CFTypeRef*);
static OSStatus hook_secCopy(CFDictionaryRef query, CFTypeRef *result) {
    OSStatus s = orig_secCopy(query, result);
    if (s == 0 && result && *result) {
        SPY(@"Keychain read OK");
    }
    return s;
}

__attribute__((constructor))
static void init() {
    @autoreleasepool {
        SPY(@"===== SPY MODE ACTIVE - logging all device params =====");
        
        // Hook UIDevice ALL getters
        Class c = NSClassFromString(@"UIDevice");
        unsigned int count;
        Method *methods = class_copyMethodList(object_getClass(c), &count);
        for (int i = 0; i < count; i++) {
            SEL sel = method_getName(methods[i]);
            NSString *name = NSStringFromSelector(sel);
            if ([name hasPrefix:@"current"] || [name containsString:@"identifier"] || [name containsString:@"name"] || [name containsString:@"model"]) {
                Method m = class_getInstanceMethod(c, sel);
                if (m) {
                    IMP imp = method_getImplementation(m);
                    if (!strstr((char*)imp, "hook_uid")) {
                        orig_uid = (void*)imp;
                        method_setImplementation(m, (IMP)hook_uid);
                    }
                }
            }
        }
        free(methods);
        
        // Hook NSFileManager
        Class nsfm = NSClassFromString(@"NSFileManager");
        Method m = class_getInstanceMethod(nsfm, @selector(fileExistsAtPath:));
        if(m){orig_fep=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_fep);}
        
        // Hook NSMutableURLRequest headers
        Class mur = NSClassFromString(@"NSMutableURLRequest");
        m = class_getInstanceMethod(mur, @selector(setValue:forHTTPHeaderField:));
        if(m){orig_setHeader=(void*)method_getImplementation(m); method_setImplementation(m,(IMP)hook_setHeader);}
        
        SPY(@"===== SPY READY =====");
    }
}
