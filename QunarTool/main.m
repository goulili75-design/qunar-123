#import <UIKit/UIKit.h>

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
@property (strong) UITextView *logView;
@end

@implementation MainVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat y = 80, w = self.view.bounds.size.width - 40;
    
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(20, 280, w, self.view.bounds.size.height - 320)];
    self.logView.font = [UIFont systemFontOfSize:12];
    self.logView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.logView.editable = NO;
    [self.view addSubview:self.logView];
    
    NSArray *btns = @[@[@"Clear App Data", @"clearData"],@[@"Clear Keychain", @"clearKeychain"],@[@"Full Reset", @"fullReset"],@[@"Check Status", @"checkStatus"]];
    for (NSArray *b in btns) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, y, w, 44);
        [btn setTitle:b[0] forState:UIControlStateNormal];
        [btn addTarget:self action:NSSelectorFromString(b[1]) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        y += 52;
    }
}

- (void)log:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{ self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text ?: @"", msg]; });
}

- (NSString *)sh:(NSString *)cmd {
    FILE *f = popen([[NSString stringWithFormat:@"%@ 2>&1", cmd] UTF8String], "r");
    if (!f) return @"error";
    char buf[4096];
    NSMutableString *r = [NSMutableString string];
    while (fgets(buf, sizeof(buf), f)) [r appendString:@(buf)];
    pclose(f);
    return r.length ? r : @"done";
}

- (void)clearData {
    [self log:@"Clearing data..."];
    [self sh:@"find /var/mobile/Containers/Data/Application -name '*.metadata.plist' | xargs grep -l 'qunar' 2>/dev/null | head -1 | sed 's|/.com.apple.*||' | xargs rm -rf 2>/dev/null; echo ok"];
    [self sh:@"killall -9 QunariPhone_Cook_CM 2>/dev/null"];
    [self log:@"Done - app reset to fresh state"];
}

- (void)clearKeychain {
    [self log:@"Clearing keychain..."];
    [self sh:@"sqlite3 /var/keybags/backup.db 2>/dev/null 'DELETE FROM cert WHERE labl LIKE \"%qunar%\" OR agrp LIKE \"%qunar%\";'"];
    [self log:@"Done"];
}

- (void)fullReset {
    [self clearData];
    [self clearKeychain];
    [self log:@"Full reset complete"];
}

- (void)checkStatus {
    [self log:[NSString stringWithFormat:@"Tweak: %@", [[self sh:@"ls /var/jb/Library/MobileSubstrate/DynamicLibraries/QunarJBBypass* 2>/dev/null | wc -l"] intValue] > 0 ? @"Installed" : @"NOT INSTALLED"]];
    [self log:[NSString stringWithFormat:@"Qunar App: %@", [[self sh:@"ls /var/containers/Bundle/Application/*/QunariPhone_Cook_CM.app 2>/dev/null | wc -l"] intValue] > 0 ? @"Installed" : @"NOT INSTALLED"]];
}

@end

int main(int argc, char *argv[]) {
    return UIApplicationMain(argc, argv, nil, @"AppDelegate");
}
