// QunarBypass v6.0 - Full device spoofing
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL isJB(NSString *path) {
    if(!path)return NO;
    NSString *l=[path lowercaseString];
    if([l hasPrefix:@"/var/jb"]||[l hasPrefix:@"/etc/apt"]||[l hasPrefix:@"/var/lib/dpkg"])return YES;
    if([l containsString:@"cydia.app"]||[l containsString:@"sileo.app"]||[l containsString:@"dopamine.app"])return YES;
    if([l containsString:@"/.bootstrapped"]||[l containsString:@"/usr/sbin/sshd"]||[l containsString:@"/bin/bash"])return YES;
    return NO;
}
static BOOL (*orig_fep)(id,SEL,NSString*);
static BOOL hook_fep(id s,SEL c,NSString*p){return isJB(p)?NO:orig_fep(s,c,p);}
static BOOL (*orig_fepd)(id,SEL,NSString*,BOOL*);
static BOOL hook_fepd(id s,SEL c,NSString*p,BOOL*d){if(isJB(p)){if(d)*d=NO;return NO;}return orig_fepd(s,c,p,d);}

static NSDictionary* (*orig_env)(id,SEL);
static NSDictionary* hook_env(id s,SEL c){NSDictionary*e=orig_env(s,c);NSMutableDictionary*m=[e mutableCopy];[m removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];[m removeObjectForKey:@"DYLD_LIBRARY_PATH"];return m;}

static BOOL badH(NSString*f){NSString*l=[f lowercaseString];return[l containsString:@"jail"]||[l containsString:@"root"]||[l containsString:@"tamper"];}
static void (*orig_svh)(id,SEL,NSString*,NSString*);
static void hook_svh(id s,SEL c,NSString*v,NSString*f){if(!badH(f))orig_svh(s,c,v,f);}
static void (*orig_av)(id,SEL,NSString*,NSString*);
static void hook_av(id s,SEL c,NSString*v,NSString*f){if(!badH(f))orig_av(s,c,v,f);}
static NSDictionary*(*orig_ahf)(id,SEL);
static NSDictionary* hook_ahf(id s,SEL c){NSDictionary*d=orig_ahf(s,c);NSMutableDictionary*m=[d mutableCopy];for(NSString*k in d)if(badH(k))[m removeObjectForKey:k];return m;}

static NSString*(*orig_idfv)(id,SEL);
static NSString* hook_idfv(id s,SEL c){return[[NSUUID UUID]UUIDString];}
static NSString*(*orig_name)(id,SEL);
static NSString* hook_name(id s,SEL c){return@"iPhone";}
static NSString*(*orig_model)(id,SEL);
static NSString* hook_model(id s,SEL c){return@"iPhone";}

static CGRect (*orig_bounds)(id,SEL);
static CGRect hook_bounds(id s,SEL c){return CGRectMake(0,0,390,844);}
static CGFloat (*orig_scale)(id,SEL);
static CGFloat hook_scale(id s,SEL c){return 3.0;}

static NSDictionary*(*orig_fsa)(id,SEL,NSString*);
static NSDictionary* hook_fsa(id s,SEL c,NSString*p){NSDictionary*d=orig_fsa(s,c,p);NSMutableDictionary*m=[d mutableCopy];m[NSFileSystemFreeSize]=@(100000000000LL);m[NSFileSystemSize]=@(256000000000LL);return m;}

__attribute__((constructor))
static void init(){@autoreleasepool{
    Class NSFM=NSClassFromString(@"NSFileManager");
    if(NSFM){
        Method m=class_getInstanceMethod(NSFM,@selector(fileExistsAtPath:));
        if(m){orig_fep=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fep);}
        m=class_getInstanceMethod(NSFM,@selector(fileExistsAtPath:isDirectory:));
        if(m){orig_fepd=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fepd);}
        m=class_getInstanceMethod(NSFM,@selector(attributesOfFileSystemForPath:error:));
        if(m){orig_fsa=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_fsa);}
    }
    Class NSPI=NSClassFromString(@"NSProcessInfo");
    if(NSPI){
        Method m=class_getInstanceMethod(NSPI,@selector(environment));
        if(m){orig_env=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_env);}
    }
    Class MUR=NSClassFromString(@"NSMutableURLRequest");
    if(MUR){
        Method m=class_getInstanceMethod(MUR,@selector(setValue:forHTTPHeaderField:));
        if(m){orig_svh=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_svh);}
        m=class_getInstanceMethod(MUR,@selector(addValue:forHTTPHeaderField:));
        if(m){orig_av=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_av);}
    }
    Class UR=NSClassFromString(@"NSURLRequest");
    if(UR){
        Method m=class_getInstanceMethod(UR,@selector(allHTTPHeaderFields));
        if(m){orig_ahf=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_ahf);}
    }
    Class UD=NSClassFromString(@"UIDevice");
    if(UD){
        Method m=class_getInstanceMethod(UD,@selector(identifierForVendor));
        if(m){orig_idfv=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_idfv);}
        m=class_getInstanceMethod(UD,@selector(name));
        if(m){orig_name=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_name);}
        m=class_getInstanceMethod(UD,@selector(model));
        if(m){orig_model=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_model);}
    }
    Class US=NSClassFromString(@"UIScreen");
    if(US){
        Method m=class_getInstanceMethod(US,@selector(bounds));
        if(m){orig_bounds=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_bounds);}
        m=class_getInstanceMethod(US,@selector(scale));
        if(m){orig_scale=(void*)method_getImplementation(m);method_setImplementation(m,(IMP)hook_scale);}
    }
}}
