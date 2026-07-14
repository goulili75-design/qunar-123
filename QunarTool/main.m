// QunarTool App - 鍘诲摢鍎胯秺鐙卞睆钄界鐞嗗伐鍏?#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opt {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[NSClassFromString(@"MainVC") alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

@interface MainVC : UIViewController
@property (nonatomic, strong) UITextView *logView;
@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"QunarBypass";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    CGFloat y = 80, w = self.view.bounds.size.width - 40;
    
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(20, y, w, 40)];
    t.text = @"Qunar Bypass v2.0";
    t.font = [UIFont boldSystemFontOfSize:18];
    t.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:t];
    y += 50;
    
    NSArray *btns = @[
        @[@"馃棏 娓呴櫎App鏁版嵁", @"clearData"],
        @[@"馃攽 娓呴櫎Keychain", @"clearKeychain"],
        @[@"馃攧 閲嶇疆涓哄垰瀹夎鐘舵€?, @"fullReset"],
        @[@"馃攳 妫€鏌ョ姸鎬?, @"checkStatus"],
    ];
    
    for (NSArray *b in btns) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, y, w, 44);
        [btn setTitle:b[0] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor systemBlueColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 8;
        [btn addTarget:self action:NSSelectorFromString(b[1]) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        y += 52;
    }
    
    y += 10;
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(20, y, w, self.view.bounds.size.height - y - 40)];
    self.logView.editable = NO;
    self.logView.font = [UIFont systemFontOfSize:11];
    self.logView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.logView.layer.cornerRadius = 8;
    [self.view addSubview:self.logView];
    [self checkStatus];
}

- (void)log:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text ?: @"", msg];
    });
}

- (NSString *)sh:(NSString *)cmd {
    // Run shell command via system()
    NSString *full = [NSString stringWithFormat:@"%@ 2>&1", cmd];
    FILE *f = popen([full UTF8String], "r");
    if (!f) return @"popen failed";
    char buf[4096];
    NSMutableString *r = [NSMutableString string];
    while (fgets(buf, sizeof(buf), f)) [r appendString:@(buf)];
    pclose(f);
    return r;
}

- (void)clearData {
    [self log:@"[娓呴櫎鏁版嵁]"];
    [self sh:@"rm -rf /var/mobile/Containers/Data/Application/*/Library 2>/dev/null"];
    NSString *r = [self sh:@"find /var/mobile/Containers/Data/Application -name '*.com.apple.mobile_container_manager.metadata.plist' 2>/dev/null | xargs grep -l 'qunar' 2>/dev/null | xargs dirname | xargs rm -rf 2>/dev/null; echo ok"];
    [self log:[NSString stringWithFormat:@"缁撴灉: %@", r]];
    [self sh:@"killall -9 QunariPhone_Cook_CM 2>/dev/null"];
    [self log:@"鉁?涓嬫鎵撳紑鍘诲摢鍎?= 鏂拌澶?];
}

- (void)clearKeychain {
    [self log:@"[娓呴櫎Keychain]"];
    [self sh:@"sqlite3 /var/keybags/backup.db \"DELETE FROM cert WHERE labl LIKE '%qunar%' OR agrp LIKE '%qunar%';\" 2>/dev/null"];
    [self log:@"鉁?Keychain宸叉竻闄?];
}

- (void)fullReset {
    [self log:@"[瀹屽叏閲嶇疆]"];
    [self clearData];
    [self clearKeychain];
    [self log:@"鉁?鍘诲摢鍎?= 鍏ㄦ柊瀹夎鐘舵€?];
}

- (void)checkStatus {
    [self log:@"[鐘舵€佹鏌"];
    NSString *tw = [self sh:@"ls -la /var/jb/Library/MobileSubstrate/DynamicLibraries/QunarJBBypass* 2>/dev/null"];
    [self log:[NSString stringWithFormat:@"Tweak: %@", tw.length > 5 ? @"宸插畨瑁?鉁? : @"鏈畨瑁?鉂?]];
    NSString *app = [self sh:@"ls /var/containers/Bundle/Application/*/QunariPhone_Cook_CM.app 2>/dev/null"];
    [self log:[NSString stringWithFormat:@"鍘诲摢鍎? %@", app.length > 5 ? @"宸插畨瑁?鉁? : @"鏈畨瑁?鉂?]];
    NSString *ps = [self sh:@"ps aux | grep QunariPhone | grep -v grep | wc -l"];
    [self log:[NSString stringWithFormat:@"杩愯鐘舵€? %@杩涚▼", [ps stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
