// ================================================================
//  鍘诲摢鍎?Qunar 瓒婄嫳灞忚斀 Tweak v5.0
//  [鏂囦欢灞俔 NSFileManager 闅愯棌瓒婄嫳璺緞
//  [缃戠粶灞俔 NSURLSession 鎷︽埅 Q-* 璇锋眰澶?//  涓嶅共鎵颁换浣曟敞鍏ユā鍧?// ================================================================

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ================================================================
// 鏂囦欢灞? 闅愯棌瓒婄嫳鐙湁璺緞
// ================================================================
static BOOL isJailbreakPath(NSString *path) {
    if (!path) return NO;
    NSString *lower = [path lowercaseString];
    if ([lower hasPrefix:@"/var/jb"]) return YES;
    if ([lower hasPrefix:@"/etc/apt"]) return YES;
    if ([lower hasPrefix:@"/var/lib/dpkg"]) return YES;
    if ([lower hasPrefix:@"/var/lib/apt"]) return YES;
    if ([lower hasPrefix:@"/library/mobilesubstrate"]) return YES;
    if ([lower hasPrefix:@"/library/tweakinject"]) return YES;
    if ([lower containsString:@"cydia.app"]) return YES;
    if ([lower containsString:@"sileo.app"]) return YES;
    if ([lower containsString:@"dopamine.app"]) return YES;
    if ([lower containsString:@"zebra.app"]) return YES;
    if ([lower containsString:@"/.bootstrapped"]) return YES;
    if ([lower containsString:@"/.cydia_no_stash"]) return YES;
    if ([lower containsString:@"/.installed_dopamine"]) return YES;
    if ([lower containsString:@"/usr/sbin/sshd"]) return YES;
    if ([lower containsString:@"/bin/bash"]) return YES;
    return NO;
}

static BOOL (*orig_fileExistsAtPath)(id, SEL, NSString*);
static BOOL hook_fileExistsAtPath(id self, SEL _cmd, NSString *path) {
    if (isJailbreakPath(path)) return NO;
    return orig_fileExistsAtPath(self, _cmd, path);
}

static BOOL (*orig_fileExistsAtPathIsDir)(id, SEL, NSString*, BOOL*);
static BOOL hook_fileExistsAtPathIsDir(id self, SEL _cmd, NSString *path, BOOL *isDir) {
    if (isJailbreakPath(path)) { if (isDir) *isDir = NO; return NO; }
    return orig_fileExistsAtPathIsDir(self, _cmd, path, isDir);
}

// ================================================================
// 鐜鍙橀噺娓呯悊
// ================================================================
static NSDictionary* (*orig_environment)(id, SEL);
static NSDictionary* hook_environment(id self, SEL _cmd) {
    NSDictionary *env = orig_environment(self, _cmd);
    if (!env) return env;
    NSMutableDictionary *m = [env mutableCopy];
    [m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];
    [m removeObjectForKey:@"DYLD_LIBRARY_PATH"];
    return m;
}

// ================================================================
// 缃戠粶灞? 鎷︽埅 Q-* 璇锋眰澶?(妫€娴嬩笂鎶?
// ================================================================

// Known Qunar custom header prefixes (~182 instances)
// Q-Device-*, Q-Env-* etc may contain jailbreak markers
static NSArray *suspiciousHeaderPrefixes(void) {
    return [NSArray arrayWithObjects:
            @"Q-Device", @"Q-Env", @"Q-Root", @"Q-Jail", @"Q-Tamper",
            @"Q-Sign", @"Q-Secure", @"Q-Verify", @"Q-Check", @"Q-Detect",
            @"Q-Risk", @"Q-Trust", nil];
}

static BOOL isSuspiciousHeader(NSString *field) {
    for (NSString *prefix in suspiciousHeaderPrefixes()) {
        if ([field hasPrefix:prefix] || [field caseInsensitiveCompare:prefix] == NSOrderedSame) {
            return YES;
        }
    }
    // 涔熸鏌ュ寘鍚?jail/root/tamper 鐨勪换鎰?header
    NSString *lower = [field lowercaseString];
    if ([lower containsString:@"jail"] || [lower containsString:@"root"] ||
        [lower containsString:@"tamper"] || [lower containsString:@"inject"]) {
        return YES;
    }
    return NO;
}

// Hook NSMutableURLRequest setValue:forHTTPHeaderField:
static void (*orig_setValue_forHTTPHeaderField)(id, SEL, NSString*, NSString*);
static void hook_setValue_forHTTPHeaderField(id self, SEL _cmd, NSString *value, NSString *field) {
    if (isSuspiciousHeader(field)) {
        NSLog(@"[QNBypass] Dropped header: %@", field);
        return; // 涓嶈缃繖涓?header
    }
    orig_setValue_forHTTPHeaderField(self, _cmd, value, field);
}

// Hook NSURLRequest allHTTPHeaderFields (鍙杩斿洖鏃惰繃婊?
static NSDictionary* (*orig_allHTTPHeaderFields)(id, SEL);
static NSDictionary* hook_allHTTPHeaderFields(id self, SEL _cmd) {
    NSDictionary *headers = orig_allHTTPHeaderFields(self, _cmd);
    if (!headers) return headers;
    NSMutableDictionary *filtered = [headers mutableCopy];
    for (NSString *key in headers) {
        if (isSuspiciousHeader(key)) {
            [filtered removeObjectForKey:key];
            NSLog(@"[QNBypass] Filtered from response: %@", key);
        }
    }
    return filtered;
}

// Hook NSMutableURLRequest addValue:forHTTPHeaderField:
static void (*orig_addValue)(id, SEL, NSString*, NSString*);
static void hook_addValue(id self, SEL _cmd, NSString *value, NSString *field) {
    if (isSuspiciousHeader(field)) {
        NSLog(@"[QNBypass] Dropped addValue: %@", field);
        return;
    }
    orig_addValue(self, _cmd, value, field);
}

// ================================================================
// 鍒濆鍖?// ================================================================
__attribute__((constructor))
static void init() {
    @autoreleasepool {
        NSLog(@"[QNBypass] v5.0 active: file + network shield");
        
        // --- 鏂囦欢灞?---
        Class NSFM = NSClassFromString(@"NSFileManager");
        if (NSFM) {
            Method m1 = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:));
            if (m1) { orig_fileExistsAtPath = (void*)method_getImplementation(m1);
                      method_setImplementation(m1, (IMP)hook_fileExistsAtPath); }
            Method m2 = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:isDirectory:));
            if (m2) { orig_fileExistsAtPathIsDir = (void*)method_getImplementation(m2);
                      method_setImplementation(m2, (IMP)hook_fileExistsAtPathIsDir); }
        }
        
        // --- 鐜鍙橀噺 ---
        Class NSPI = NSClassFromString(@"NSProcessInfo");
        if (NSPI) {
            Method m = class_getInstanceMethod(NSPI, @selector(environment));
            if (m) { orig_environment = (void*)method_getImplementation(m);
                     method_setImplementation(m, (IMP)hook_environment); }
        }
        
        // --- 缃戠粶灞?---
        Class NSMUR = NSClassFromString(@"NSMutableURLRequest");
        if (NSMUR) {
            Method sm = class_getInstanceMethod(NSMUR, @selector(setValue:forHTTPHeaderField:));
            if (sm) { orig_setValue_forHTTPHeaderField = (void*)method_getImplementation(sm);
                      method_setImplementation(sm, (IMP)hook_setValue_forHTTPHeaderField); }
            Method am = class_getInstanceMethod(NSMUR, @selector(addValue:forHTTPHeaderField:));
            if (am) { orig_addValue = (void*)method_getImplementation(am);
                      method_setImplementation(am, (IMP)hook_addValue); }
        }
        
        Class NSUR = NSClassFromString(@"NSURLRequest");
        if (NSUR) {
            Method hm = class_getInstanceMethod(NSUR, @selector(allHTTPHeaderFields));
            if (hm) { orig_allHTTPHeaderFields = (void*)method_getImplementation(hm);
                      method_setImplementation(hm, (IMP)hook_allHTTPHeaderFields); }
        }
        
        NSLog(@"[QNBypass] Ready");
    }
}
