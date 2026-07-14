// ================================================================
//  去哪儿 Qunar 越狱屏蔽 Tweak v5.0
//  [文件层] NSFileManager 隐藏越狱路径
//  [网络层] NSURLSession 拦截 Q-* 请求头
//  不干扰任何注入模块
// ================================================================

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ================================================================
// 文件层: 隐藏越狱独有路径
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
// 环境变量清理
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
// 网络层: 拦截 Q-* 请求头 (检测上报)
// ================================================================

// 已知的 Qunar 自定义 Header 前缀 (182处)
// Q-W-*, Q-R-*, Q-Device-*, Q-Env-* 等可能包含越狱标记
static NSArray *suspiciousHeaderPrefixes(void) {
    return @[@"Q-Device", @"Q-Env", @"Q-Root", @"Q-Jail", @"Q-Tamper",
             @"Q-Sign", @"Q-Secure", @"Q-Verify", @"Q-Check", @"Q-Detect",
             @"Q-Risk", @"Q-Trust"];
}

static BOOL isSuspiciousHeader(NSString *field) {
    for (NSString *prefix in suspiciousHeaderPrefixes()) {
        if ([field hasPrefix:prefix] || [field caseInsensitiveCompare:prefix] == NSOrderedSame) {
            return YES;
        }
    }
    // 也检查包含 jail/root/tamper 的任意 header
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
        return; // 不设置这个 header
    }
    orig_setValue_forHTTPHeaderField(self, _cmd, value, field);
}

// Hook NSURLRequest allHTTPHeaderFields (只读返回时过滤)
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
// 初始化
// ================================================================
%ctor {
    @autoreleasepool {
        NSLog(@"[QNBypass] v5.0 已激活: 文件+网络双屏蔽");
        
        // --- 文件层 ---
        Class NSFM = NSClassFromString(@"NSFileManager");
        if (NSFM) {
            Method m1 = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:));
            if (m1) { orig_fileExistsAtPath = (void*)method_getImplementation(m1);
                      method_setImplementation(m1, (IMP)hook_fileExistsAtPath); }
            Method m2 = class_getInstanceMethod(NSFM, @selector(fileExistsAtPath:isDirectory:));
            if (m2) { orig_fileExistsAtPathIsDir = (void*)method_getImplementation(m2);
                      method_setImplementation(m2, (IMP)hook_fileExistsAtPathIsDir); }
        }
        
        // --- 环境变量 ---
        Class NSPI = NSClassFromString(@"NSProcessInfo");
        if (NSPI) {
            Method m = class_getInstanceMethod(NSPI, @selector(environment));
            if (m) { orig_environment = (void*)method_getImplementation(m);
                     method_setImplementation(m, (IMP)hook_environment); }
        }
        
        // --- 网络层 ---
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
