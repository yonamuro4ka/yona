//
//  RootViewController.mm
//  shzq
//

#import <notify.h>
#import <QuartzCore/QuartzCore.h>

#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"
#import "../esp/drawing_view/obfusheader.h"

@implementation RootViewController {
    UIButton          *mainButton;
    UIImageView       *iconImageView;
    UILabel           *titleLabel;
    UILabel           *subtitleLabel;
    UILabel           *versionLabel;
    UIView            *cardView;
    CAGradientLayer   *bgGradient;
    NSLayoutConstraint *mainButtonCenterYConstraint;
    BOOL               isRemoteHUDActive;
}

- (BOOL)isHUDEnabled  { return IsHUDEnabled(); }
- (void)setHUDEnabled:(BOOL)enabled { SetHUDEnabled(enabled); }

- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:bounds];

    // ── Dark gradient background ──────────────────────────────────────────
    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundView];

    bgGradient = [CAGradientLayer layer];
    bgGradient.frame  = bounds;
    bgGradient.colors = @[
        (id)[UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.08 green:0.04 blue:0.16 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.03 green:0.03 blue:0.08 alpha:1].CGColor,
    ];
    bgGradient.locations  = @[@0.0, @0.5, @1.0];
    bgGradient.startPoint = CGPointMake(0, 0);
    bgGradient.endPoint   = CGPointMake(1, 1);
    [self.backgroundView.layer addSublayer:bgGradient];

    // ── Decorative blurred circle (glow) ─────────────────────────────────
    UIView *glowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 280)];
    glowView.backgroundColor = [UIColor colorWithRed:0.45 green:0.10 blue:0.85 alpha:0.18];
    glowView.layer.cornerRadius = 140;
    glowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:glowView];

    UIView *glowView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    glowView2.backgroundColor = [UIColor colorWithRed:0.20 green:0.10 blue:0.60 alpha:0.15];
    glowView2.layer.cornerRadius = 100;
    glowView2.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:glowView2];

    // ── Card ──────────────────────────────────────────────────────────────
    cardView = [[UIView alloc] init];
    cardView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
    cardView.layer.cornerRadius  = 28;
    cardView.layer.borderWidth   = 1.0;
    cardView.layer.borderColor   = [UIColor colorWithWhite:1 alpha:0.10].CGColor;
    cardView.layer.masksToBounds = NO;
    // subtle shadow
    cardView.layer.shadowColor   = [UIColor colorWithRed:0.4 green:0.1 blue:0.8 alpha:0.5].CGColor;
    cardView.layer.shadowRadius  = 30;
    cardView.layer.shadowOpacity = 0.6;
    cardView.layer.shadowOffset  = CGSizeMake(0, 8);
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:cardView];

    // ── App icon ──────────────────────────────────────────────────────────
    iconImageView = [[UIImageView alloc] init];
    iconImageView.contentMode        = UIViewContentModeScaleAspectFill;
    iconImageView.layer.cornerRadius = 22;
    iconImageView.layer.masksToBounds = YES;
    iconImageView.layer.borderWidth  = 2;
    iconImageView.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    iconImageView.image = [UIImage imageNamed:@"icon.png"];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:iconImageView];

    // ── Title label ───────────────────────────────────────────────────────
    titleLabel = [[UILabel alloc] init];
    titleLabel.text          = @"shzq";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font          = [UIFont boldSystemFontOfSize:34];
    titleLabel.textColor     = [UIColor whiteColor];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:titleLabel];

    // ── Subtitle ──────────────────────────────────────────────────────────
    subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text          = @(OBF("yonahack"));
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font          = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    subtitleLabel.textColor     = [UIColor colorWithRed:0.70 green:0.55 blue:1.0 alpha:1];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:subtitleLabel];

    // ── Version label ─────────────────────────────────────────────────────
    versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"iOS %@ • v0.38.2",
                         [[UIDevice currentDevice] systemVersion]];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    versionLabel.textColor = [UIColor colorWithWhite:1 alpha:0.35];
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:versionLabel];

    // ── Main button ───────────────────────────────────────────────────────
    mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainButton.layer.cornerRadius = 16;
    mainButton.layer.masksToBounds = YES;
    mainButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [mainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [mainButton addTarget:self action:@selector(tapMainButton:)
         forControlEvents:UIControlEventTouchUpInside];

    // Gradient button layer
    CAGradientLayer *btnGrad = [CAGradientLayer layer];
    btnGrad.colors = @[
        (id)[UIColor colorWithRed:0.55 green:0.15 blue:1.0 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.30 green:0.08 blue:0.75 alpha:1].CGColor,
    ];
    btnGrad.startPoint = CGPointMake(0, 0);
    btnGrad.endPoint   = CGPointMake(1, 1);
    btnGrad.cornerRadius = 16;
    btnGrad.name = @"btnGrad";
    [mainButton.layer insertSublayer:btnGrad atIndex:0];

    mainButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:mainButton];

    // ── Separator line ────────────────────────────────────────────────────
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:sep];

    // ── Layout ────────────────────────────────────────────────────────────
    UILayoutGuide *safe = self.backgroundView.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        // glow 1 — top-right area
        [glowView.centerXAnchor constraintEqualToAnchor:self.backgroundView.trailingAnchor constant:-40],
        [glowView.centerYAnchor constraintEqualToAnchor:self.backgroundView.topAnchor constant:120],
        [glowView.widthAnchor  constraintEqualToConstant:280],
        [glowView.heightAnchor constraintEqualToConstant:280],

        // glow 2 — bottom-left
        [glowView2.centerXAnchor constraintEqualToAnchor:self.backgroundView.leadingAnchor constant:40],
        [glowView2.centerYAnchor constraintEqualToAnchor:self.backgroundView.bottomAnchor constant:-140],
        [glowView2.widthAnchor  constraintEqualToConstant:200],
        [glowView2.heightAnchor constraintEqualToConstant:200],

        // card — centered, fixed width
        [cardView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [cardView.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],
        [cardView.widthAnchor   constraintEqualToConstant:280],

        // icon
        [iconImageView.topAnchor     constraintEqualToAnchor:cardView.topAnchor    constant:32],
        [iconImageView.centerXAnchor constraintEqualToAnchor:cardView.centerXAnchor],
        [iconImageView.widthAnchor   constraintEqualToConstant:80],
        [iconImageView.heightAnchor  constraintEqualToConstant:80],

        // title
        [titleLabel.topAnchor     constraintEqualToAnchor:iconImageView.bottomAnchor constant:16],
        [titleLabel.leadingAnchor  constraintEqualToAnchor:cardView.leadingAnchor   constant:16],
        [titleLabel.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor  constant:-16],

        // subtitle
        [subtitleLabel.topAnchor     constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
        [subtitleLabel.leadingAnchor  constraintEqualToAnchor:cardView.leadingAnchor  constant:16],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-16],

        // separator
        [sep.topAnchor     constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:20],
        [sep.leadingAnchor  constraintEqualToAnchor:cardView.leadingAnchor   constant:20],
        [sep.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor  constant:-20],
        [sep.heightAnchor   constraintEqualToConstant:1],

        // version
        [versionLabel.topAnchor     constraintEqualToAnchor:sep.bottomAnchor   constant:14],
        [versionLabel.leadingAnchor  constraintEqualToAnchor:cardView.leadingAnchor  constant:16],
        [versionLabel.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-16],

        // button
        [mainButton.topAnchor     constraintEqualToAnchor:versionLabel.bottomAnchor constant:20],
        [mainButton.leadingAnchor  constraintEqualToAnchor:cardView.leadingAnchor   constant:24],
        [mainButton.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor  constant:-24],
        [mainButton.heightAnchor   constraintEqualToConstant:52],
        [mainButton.bottomAnchor   constraintEqualToAnchor:cardView.bottomAnchor    constant:-28],
    ]];

    [self reloadMainButtonState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    bgGradient.frame = self.backgroundView.bounds;
    // Resize gradient button layer
    for (CALayer *l in mainButton.layer.sublayers) {
        if ([l.name isEqualToString:@"btnGrad"]) {
            l.frame = mainButton.bounds;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Subtle pulse on the card
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    pulse.fromValue  = @30;
    pulse.toValue    = @50;
    pulse.duration   = 2.5;
    pulse.autoreverses = YES;
    pulse.repeatCount  = HUGE_VALF;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [cardView.layer addAnimation:pulse forKey:@"shadowPulse"];
}

- (void)reloadMainButtonState {
    isRemoteHUDActive = [self isHUDEnabled];
    NSString *title = isRemoteHUDActive ? @"■  Stop" : @"▶  Run";
    [mainButton setTitle:title forState:UIControlStateNormal];

    // Update button gradient color
    for (CALayer *l in mainButton.layer.sublayers) {
        if ([l.name isEqualToString:@"btnGrad"]) {
            CAGradientLayer *g = (CAGradientLayer *)l;
            if (isRemoteHUDActive) {
                g.colors = @[
                    (id)[UIColor colorWithRed:0.80 green:0.10 blue:0.30 alpha:1].CGColor,
                    (id)[UIColor colorWithRed:0.55 green:0.05 blue:0.18 alpha:1].CGColor,
                ];
            } else {
                g.colors = @[
                    (id)[UIColor colorWithRed:0.55 green:0.15 blue:1.0 alpha:1].CGColor,
                    (id)[UIColor colorWithRed:0.30 green:0.08 blue:0.75 alpha:1].CGColor,
                ];
            }
        }
    }
}

- (void)tapMainButton:(UIButton *)sender {
    // Press animation
    [UIView animateWithDuration:0.08 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL done) {
        [UIView animateWithDuration:0.12 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];

    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled) {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    } else {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // no-op
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end
