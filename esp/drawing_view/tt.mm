#import "esp.h"
#import "cfg.h"
#include "obfusheader.h"
#import "tt.h"
#include <string>
#include <vector>
#include <map>
#import "../../sources/UIView+SecureView.h"

extern volatile bool esp_screenshot_safe;

@interface CustomSliderView : UIView
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, copy) void (^valueChanged)(float newValue);

- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current;
@end

@implementation CustomSliderView {
    UIView *_track;
    UIView *_thumb;
    UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame min:(float)min max:(float)max current:(float)current {
    self = [super initWithFrame:frame];
    if (self) {
        _minValue = min;
        _maxValue = max;
        _value = current;

        _track = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height/2 - 1, frame.size.width, 2)];
        _track.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];

        _thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        _thumb.backgroundColor = [UIColor whiteColor];
        _thumb.layer.cornerRadius = 6;
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        [self updateThumbPosition];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self];
    [self updateValueWithX:pt.x];
}

- (void)handleTap:(UITapGestureRecognizer *)g {
    CGPoint pt = [g locationInView:self];
    [self updateValueWithX:pt.x];
}

- (void)updateValueWithX:(CGFloat)x {
    float percent = x / self.frame.size.width;
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;

    _value = _minValue + (_maxValue - _minValue) * percent;
    [self updateThumbPosition];
    if (self.valueChanged) self.valueChanged(_value);
}

- (void)updateThumbPosition {
    float percent = (_value - _minValue) / (_maxValue - _minValue);
    _thumb.center = CGPointMake(self.frame.size.width * percent, self.frame.size.height/2);
}

- (void)setValue:(float)value {
    _value = value;
    [self updateThumbPosition];
}
@end

@interface CustomSegmentedControl : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void (^valueChanged)(NSInteger newIndex);
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current;
- (void)reloadUI:(NSInteger)idx;
@end

@implementation CustomSegmentedControl {
    NSArray *_items;
    NSMutableArray *_labels;
}
- (instancetype)initWithFrame:(CGRect)frame items:(NSArray *)items current:(NSInteger)current {
    self = [super initWithFrame:frame];
    if (self) {
        _items = items;
        _selectedIndex = current;
        _labels = [NSMutableArray new];
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
        self.layer.cornerRadius = 6;
        self.clipsToBounds = YES;
        
        CGFloat bw = frame.size.width / items.count;
        for (int i = 0; i < items.count; i++) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(i * bw, 0, bw, frame.size.height)];
            l.text = items[i];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont systemFontOfSize:10 weight:(i == current ? UIFontWeightBold : UIFontWeightRegular)];
            l.textColor = (i == current ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1]);
            l.backgroundColor = (i == current ? [UIColor whiteColor] : [UIColor clearColor]);
            [self addSubview:l];
            [_labels addObject:l];
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)reloadUI:(NSInteger)idx {
    if (idx < 0) idx = 0;
    if (idx >= _items.count) idx = _items.count - 1;
    _selectedIndex = idx;
    for (int i = 0; i < _labels.count; i++) {
        UILabel *l = _labels[i];
        BOOL sel = (i == idx);
        l.textColor = sel ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1];
        l.backgroundColor = sel ? [UIColor whiteColor] : [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:10 weight:(sel ? UIFontWeightBold : UIFontWeightRegular)];
    }
}
- (void)handleTap:(UITapGestureRecognizer *)g {
    CGPoint p = [g locationInView:self];
    NSInteger idx = p.x / (self.frame.size.width / _items.count);
    if (idx < 0) idx = 0;
    if (idx >= _items.count) idx = _items.count - 1;
    
    _selectedIndex = idx;
    for (int i = 0; i < _labels.count; i++) {
        UILabel *l = _labels[i];
        BOOL sel = (i == idx);
        l.textColor = sel ? [UIColor blackColor] : [UIColor colorWithWhite:0.7 alpha:1];
        l.backgroundColor = sel ? [UIColor whiteColor] : [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:10 weight:(sel ? UIFontWeightBold : UIFontWeightRegular)];
    }
    if (self.valueChanged) self.valueChanged(idx);
}
@end

@interface VerticalOnlyPanGestureRecognizer : UIPanGestureRecognizer
@end
@implementation VerticalOnlyPanGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    UIView *v = touch.view;
    while (v) {
        if ([v isKindOfClass:[CustomSegmentedControl class]] || 
            [v isKindOfClass:[CustomSliderView class]]) {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
        v = v.superview;
    }
    [super touchesBegan:touches withEvent:event];
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateBegan) {
        CGPoint vel = [self velocityInView:self.view];
        if (fabs(vel.x) > fabs(vel.y)) {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
}
@end

@interface MenuView () <UIGestureRecognizerDelegate>
@end

@implementation MenuView {
    UIVisualEffectView *_blurView;
    UIView *_headerView;
    UILabel *_headerLabel;

    UIView *_contentView;
    UIView *_leftBarView;
    UIView *_aimContainer;
    UIView *_visualContainer;
    UIView *_otherContainer;
    UIView *_aimContent;
    UIView *_visualContent;
    UIView *_otherContent;
    UIView *_innerContent;
    NSMutableArray<UILabel *> *_tabLabels;

    CGPoint _initialTouchPoint;
    BOOL _collapsed;
    CAShapeLayer *_arrowLayer;

    CAShapeLayer *_boxCheckmark;
    CAShapeLayer *_boxOutlineCheckmark;
    CAShapeLayer *_boxFillCheckmark;
    CAShapeLayer *_boxCornerCheckmark;
    CAShapeLayer *_box3DCheckmark;
    CAShapeLayer *_lineCheckmark;
    CAShapeLayer *_lineOutlineCheckmark;
    CAShapeLayer *_teamCheckmark;
    CAShapeLayer *_nameCheckmark;
    CAShapeLayer *_nameOutlineCheckmark;
    CAShapeLayer *_invisibleCheckmark;
    CAShapeLayer *_addscoreCheckmark;
    CAShapeLayer *_infAmmoCheckmark;
    CAShapeLayer *_noSpreadCheckmark;
    CAShapeLayer *_airJumpCheckmark;
    CAShapeLayer *_fastKnifeCheckmark;
    CAShapeLayer *_bunnyHopCheckmark;
    CAShapeLayer *_wallshotCheckmark;
    CAShapeLayer *_fireRateCheckmark;
    CAShapeLayer *_healthCheckmark;
    CAShapeLayer *_healthBarCheckmark;
    CAShapeLayer *_healthBarOutlineCheckmark;
    CAShapeLayer *_weaponCheckmark;
    CAShapeLayer *_weaponIconCheckmark;
    CAShapeLayer *_platformCheckmark;
    CAShapeLayer *_avatarCheckmark;
    CAShapeLayer *_skeletonCheckmark;
    CAShapeLayer *_screenshotSafeCheckmark;
    CAShapeLayer *_triggerbotCheckmark;
    CAShapeLayer *_aimbotCheckmark;
    CAShapeLayer *_aimbotFovVisibleCheckmark;
    CAShapeLayer *_visibleCheckCheckmark;
    CAShapeLayer *_shootingCheckCheckmark;
    CAShapeLayer *_knifeBotCheckmark;
    CAShapeLayer *_aimbotTeamCheckmark;
    CAShapeLayer *_rcsCheckmark;
    CAShapeLayer *_aimbotXOnlyCheckmark;
    CAShapeLayer *_aimbot360Checkmark;
    CustomSegmentedControl *_boneSelector;
    UILabel *_fovValueLabel;
    UILabel *_smoothValueLabel;
    UILabel *_triggerDelayValueLabel;

    CustomSliderView *_fovSlider;
    CustomSliderView *_smoothSlider;
    CustomSliderView *_triggerDelaySlider;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 12.0;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.frame = self.bounds;
        _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _blurView.userInteractionEnabled = NO;
        [self addSubview:_blurView];

        CGFloat headerHeight = 35.0;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, headerHeight)];
        _headerView.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.40];
        _headerView.userInteractionEnabled = YES;
        [self addSubview:_headerView];

        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, frame.size.width - 50, headerHeight)];
        _headerLabel.text = @(OBF("yonahack"));
        _headerLabel.textAlignment = NSTextAlignmentLeft;
        _headerLabel.textColor = [UIColor whiteColor];
        _headerLabel.font = [UIFont boldSystemFontOfSize:14];
        [_headerView addSubview:_headerLabel];

        UIView *arrowContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 45, 0, 45, 35)];
        arrowContainer.userInteractionEnabled = YES;
        [_headerView addSubview:arrowContainer];

        _arrowLayer = [CAShapeLayer layer];
        _arrowLayer.strokeColor = [UIColor whiteColor].CGColor;
        _arrowLayer.fillColor = [UIColor clearColor].CGColor;
        _arrowLayer.lineWidth = 2.0f;
        _arrowLayer.lineCap = kCALineCapRound;
        _arrowLayer.lineJoin = kCALineJoinRound;
        UIBezierPath *arrowPath = [UIBezierPath bezierPath];
        [arrowPath moveToPoint:CGPointMake(12, 13)];
        [arrowPath addLineToPoint:CGPointMake(19, 21)];
        [arrowPath addLineToPoint:CGPointMake(26, 13)];
        _arrowLayer.path = arrowPath.CGPath;
        _arrowLayer.frame = arrowContainer.bounds;
        [arrowContainer.layer addSublayer:_arrowLayer];

        UITapGestureRecognizer *tapCollapse = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCollapse)];
        [arrowContainer addGestureRecognizer:tapCollapse];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.cancelsTouchesInView = NO;
        [_headerView addGestureRecognizer:panGesture];

        CGFloat leftBarWidth = 70.0;
        
        _leftBarView = [[UIView alloc] initWithFrame:CGRectMake(0, headerHeight, leftBarWidth, frame.size.height - headerHeight)];
        _leftBarView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.15];
        _leftBarView.userInteractionEnabled = YES;
        [self addSubview:_leftBarView];
        
        NSArray *tabs = @[@(OBF("AIM")), @(OBF("ESP")), @(OBF("OTHER"))];
        _tabLabels = [NSMutableArray new];
        for (int i=0; i<3; i++) {
            UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(0, i * 40, leftBarWidth, 40)];
            tl.text = tabs[i];
            tl.textAlignment = NSTextAlignmentCenter;
            tl.font = [UIFont systemFontOfSize:11 weight:(i==0 ? UIFontWeightBold : UIFontWeightRegular)];
            tl.textColor = (i==0 ? [UIColor whiteColor] : [UIColor colorWithWhite:0.7 alpha:1]);
            tl.userInteractionEnabled = YES;
            [_leftBarView addSubview:tl];
            [_tabLabels addObject:tl];
            
            tl.tag = i;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabTapped:)];
            [tl addGestureRecognizer:tap];
        }

        _contentView = [[UIView alloc] initWithFrame:CGRectMake(leftBarWidth, headerHeight, frame.size.width - leftBarWidth, frame.size.height - headerHeight)];
        _contentView.clipsToBounds = YES;
        _contentView.userInteractionEnabled = YES;
        [self addSubview:_contentView];

        _aimContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _visualContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        _otherContainer = [[UIView alloc] initWithFrame:_contentView.bounds];
        
        _visualContainer.hidden = YES;
        _otherContainer.hidden = YES;

        _aimContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 580)];
        _aimContent.userInteractionEnabled = YES;
        [_aimContainer addSubview:_aimContent];

        _visualContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 600)];
        _visualContent.userInteractionEnabled = YES;
        [_visualContainer addSubview:_visualContent];

        _otherContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.bounds.size.width, 300)];
        _otherContent.userInteractionEnabled = YES;
        [_otherContainer addSubview:_otherContent];





        [_contentView addSubview:_aimContainer];
        [_contentView addSubview:_visualContainer];
        [_contentView addSubview:_otherContainer];

        VerticalOnlyPanGestureRecognizer *scrollPan = [[VerticalOnlyPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollPan:)];
        scrollPan.cancelsTouchesInView = YES;
        scrollPan.delaysTouchesBegan = NO;   
        scrollPan.delaysTouchesEnded = NO;   
        scrollPan.delegate = self;
        [_contentView addGestureRecognizer:scrollPan];

        _innerContent = _aimContent; 

        CGFloat yOffset = 4;

        [self addSectionHeader:@(OBF("AIMBOT")) atY:yOffset];
        yOffset += 26;
        _aimbotCheckmark = [self addToggle:@(OBF("Aimbot")) atY:yOffset action:@selector(aimbotTapped) enabled:aimbot_enabled];
        yOffset += 32;
        _triggerbotCheckmark = [self addToggle:@(OBF("Triggerbot")) atY:yOffset action:@selector(triggerbotTapped) enabled:aimbot_triggerbot];
        yOffset += 32;
        _aimbotFovVisibleCheckmark = [self addToggle:@(OBF("FOV Check")) atY:yOffset action:@selector(aimbotFovTapped) enabled:aimbot_fov_visible];
        yOffset += 32;
        _visibleCheckCheckmark  = [self addToggle:@(OBF("Visible Check"))  atY:yOffset action:@selector(visibleCheckTapped)  enabled:aimbot_visible_check];  
        yOffset += 32;
        _shootingCheckCheckmark = [self addToggle:@(OBF("Fire Check"))     atY:yOffset action:@selector(shootingCheckTapped) enabled:aimbot_shooting_check]; 
        yOffset += 32;
        _knifeBotCheckmark      = [self addToggle:@(OBF("Knife Bot"))      atY:yOffset action:@selector(knifeBotTapped)      enabled:aimbot_knife_bot];       
        yOffset += 32;
        _aimbotTeamCheckmark = [self addToggle:@(OBF("Team Check")) atY:yOffset action:@selector(aimbotTeamTapped) enabled:aimbot_team_check];
        yOffset += 32;
        _aimbotXOnlyCheckmark = [self addToggle:@(OBF("Aim X Only")) atY:yOffset action:@selector(aimbotXOnlyTapped) enabled:aimbot_x_only];
        yOffset += 32;
        _aimbot360Checkmark = [self addToggle:@(OBF("Aim 360°")) atY:yOffset action:@selector(aimbot360Tapped) enabled:aimbot_360];
        yOffset += 32;

        [self addSectionHeader:@(OBF("Smooth")) atY:yOffset]; yOffset += 26;
        [self addSmoothSliderAtY:yOffset]; yOffset += 45;



        [self addSectionHeader:@(OBF("FOV")) atY:yOffset]; yOffset += 26;
        [self addFovSliderAtY:yOffset]; yOffset += 45;

        [self addSectionHeader:@(OBF("Trigger Delay")) atY:yOffset]; yOffset += 26;
        [self addTriggerDelaySliderAtY:yOffset]; yOffset += 45;

        [self addSectionHeader:@(OBF("Bone")) atY:yOffset]; yOffset += 26;
        [self addBoneSelectorAtY:yOffset]; yOffset += 36;

        CGRect aimContentFrame = _aimContent.frame;
        aimContentFrame.size.height = yOffset + 10;
        _aimContent.frame = aimContentFrame;


        _innerContent = _visualContent; // ESP TAB
        yOffset = 4;
        [self addSectionHeader:@(OBF("ESP")) atY:yOffset];
        yOffset += 26;
        _boxCheckmark  = [self addToggle:@(OBF("Box 2D"))  atY:yOffset action:@selector(boxTapped)  enabled:esp_box_enabled];
        yOffset += 32;
        _boxOutlineCheckmark = [self addToggle:@(OBF("Box Outline")) atY:yOffset action:@selector(boxOutlineTapped) enabled:esp_box_outline];
        yOffset += 32;
        _boxFillCheckmark = [self addToggle:@(OBF("Box Fill")) atY:yOffset action:@selector(boxFillTapped) enabled:esp_box_fill];
        yOffset += 32;
        _boxCornerCheckmark = [self addToggle:@(OBF("Box Corner")) atY:yOffset action:@selector(boxCornerTapped) enabled:esp_box_corner];
        yOffset += 32;
        _box3DCheckmark = [self addToggle:@(OBF("Box 3D")) atY:yOffset action:@selector(box3DTapped) enabled:esp_box_3d];
        yOffset += 32;
        _lineCheckmark = [self addToggle:@(OBF("Line")) atY:yOffset action:@selector(lineTapped) enabled:esp_line_enabled];
        yOffset += 32;
        _lineOutlineCheckmark = [self addToggle:@(OBF("Line Outline")) atY:yOffset action:@selector(lineOutlineTapped) enabled:esp_line_outline];
        yOffset += 32;
        _teamCheckmark = [self addToggle:@(OBF("Team Check")) atY:yOffset action:@selector(teamTapped) enabled:esp_team_check];
        yOffset += 32;

        _nameCheckmark = [self addToggle:@(OBF("Name")) atY:yOffset action:@selector(nameTapped) enabled:esp_name_enabled];
        yOffset += 32;
        _healthCheckmark = [self addToggle:@(OBF("HP")) atY:yOffset action:@selector(healthTapped) enabled:esp_health_enabled];
        yOffset += 32;
        _healthBarCheckmark = [self addToggle:@(OBF("Health Bar")) atY:yOffset action:@selector(healthBarTapped) enabled:esp_health_bar_enabled];
        yOffset += 32;
        _healthBarOutlineCheckmark = [self addToggle:@(OBF("Bar Outline")) atY:yOffset action:@selector(healthBarOutlineTapped) enabled:esp_health_bar_outline];
        yOffset += 32;
        _weaponCheckmark = [self addToggle:@(OBF("Weapon")) atY:yOffset action:@selector(weaponTapped) enabled:esp_weapon_enabled];
        yOffset += 32;
        _weaponIconCheckmark = [self addToggle:@(OBF("Weapon Icon")) atY:yOffset action:@selector(weaponIconTapped) enabled:esp_weapon_icon_enabled];
        yOffset += 32;
        _platformCheckmark = [self addToggle:@(OBF("Platform")) atY:yOffset action:@selector(platformTapped) enabled:esp_platform_enabled];
        yOffset += 32;
        _avatarCheckmark = [self addToggle:@(OBF("Avatars")) atY:yOffset action:@selector(avatarTapped) enabled:esp_avatar_enabled];
        yOffset += 32;

        CGRect visualContentFrame = _visualContent.frame;
        visualContentFrame.size.height = yOffset + 10;
        _visualContent.frame = visualContentFrame;

        _innerContent = _otherContent;
        yOffset = 4;
        [self addSectionHeader:@(OBF("OTHER")) atY:yOffset];
        yOffset += 26;
        _screenshotSafeCheckmark = [self addToggle:@(OBF("Overlay")) atY:yOffset action:@selector(screenshotSafeTapped) enabled:esp_screenshot_safe];
        yOffset += 32;

        CGRect otherFrame = _otherContent.frame;
        otherFrame.size.height = yOffset + 10;
        _otherContent.frame = otherFrame;

        _innerContent = nil;

        [self showViewForCapture];
    }
    return self;
}

- (void)addSectionHeader:(NSString *)title atY:(CGFloat)y {
    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(12, y, _innerContent.bounds.size.width - 24, 22)];
    h.text = title;
    h.textColor = [UIColor colorWithWhite:1.0f alpha:0.45f];
    h.font = [UIFont boldSystemFontOfSize:11];
    h.userInteractionEnabled = NO;
    [_innerContent addSubview:h];
}

- (CAShapeLayer *)addToggle:(NSString *)name atY:(CGFloat)y action:(SEL)action enabled:(BOOL)enabled {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, _innerContent.bounds.size.width, 30)];
    row.userInteractionEnabled = YES;
    [_innerContent addSubview:row];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 100, 30)];
    label.text = name;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.userInteractionEnabled = NO;
    [row addSubview:label];

    UIView *checkbox = [[UIView alloc] initWithFrame:CGRectMake(_innerContent.bounds.size.width - 37, 4, 22, 22)];
    checkbox.layer.borderWidth = 2.0;
    checkbox.layer.borderColor = [UIColor whiteColor].CGColor;
    checkbox.layer.cornerRadius = 4.0;
    checkbox.userInteractionEnabled = NO;
    [row addSubview:checkbox];

    CAShapeLayer *checkmark = [self createCheckmarkLayer:checkbox.bounds];
    checkmark.opacity = enabled ? 1.0 : 0.0;
    [checkbox.layer addSublayer:checkmark];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    tap.cancelsTouchesInView = NO;
    [row addGestureRecognizer:tap];

    return checkmark;
}

- (CAShapeLayer *)createCheckmarkLayer:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(rect.size.width * 0.20, rect.size.height * 0.50)];
    [path addLineToPoint:CGPointMake(rect.size.width * 0.42, rect.size.height * 0.72)];
    [path addLineToPoint:CGPointMake(rect.size.width * 0.80, rect.size.height * 0.28)];

    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 2.5;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    return layer;
}

- (void)animateCheckmark:(CAShapeLayer *)checkmark show:(BOOL)show {
    if (show) {
        checkmark.opacity = 1.0;
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        anim.fromValue = @0.0;
        anim.toValue = @1.0;
        anim.duration = 0.25;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        checkmark.strokeEnd = 1.0;
        [checkmark addAnimation:anim forKey:@"drawCheckmark"];
    } else {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        anim.fromValue = @1.0;
        anim.toValue = @0.0;
        anim.duration = 0.15;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        checkmark.opacity = 0.0;
        [checkmark addAnimation:anim forKey:@"hideCheckmark"];
    }
}

- (void)boxTapped {
    esp_box_enabled = !esp_box_enabled;
    [self animateCheckmark:_boxCheckmark show:esp_box_enabled];
    if (!esp_box_enabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ESPClearBoxes" object:nil];
    }
}

- (void)lineTapped {
    esp_line_enabled = !esp_line_enabled;
    [self animateCheckmark:_lineCheckmark show:esp_line_enabled];
}

- (void)infAmmoTapped   { esp_inf_ammo   = !esp_inf_ammo;   [self animateCheckmark:_infAmmoCheckmark   show:esp_inf_ammo];   }
- (void)noSpreadTapped  { esp_no_spread  = !esp_no_spread;  [self animateCheckmark:_noSpreadCheckmark  show:esp_no_spread];  }
- (void)airJumpTapped   { esp_air_jump   = !esp_air_jump;   [self animateCheckmark:_airJumpCheckmark   show:esp_air_jump];   }
- (void)fastKnifeTapped { esp_fast_knife = !esp_fast_knife; [self animateCheckmark:_fastKnifeCheckmark show:esp_fast_knife]; }
- (void)bunnyHopTapped  { esp_bunny_hop  = !esp_bunny_hop;  [self animateCheckmark:_bunnyHopCheckmark  show:esp_bunny_hop];  }
- (void)wallshotTapped  { esp_wallshot   = !esp_wallshot;   [self animateCheckmark:_wallshotCheckmark  show:esp_wallshot];   }
- (void)fireRateTapped  { esp_fire_rate  = !esp_fire_rate;  [self animateCheckmark:_fireRateCheckmark  show:esp_fire_rate];  }

- (void)addskoreTapped {
    esp_addscore = !esp_addscore;
    [self animateCheckmark:_addscoreCheckmark show:esp_addscore];
}

- (void)invisibleTapped {
    esp_invisible = !esp_invisible;
    [self animateCheckmark:_invisibleCheckmark show:esp_invisible];
}

- (void)boxOutlineTapped {
    esp_box_outline = !esp_box_outline;
    [self animateCheckmark:_boxOutlineCheckmark show:esp_box_outline];
}

- (void)boxFillTapped {
    esp_box_fill = !esp_box_fill;
    [self animateCheckmark:_boxFillCheckmark show:esp_box_fill];
}

- (void)boxCornerTapped {
    esp_box_corner = !esp_box_corner;
    [self animateCheckmark:_boxCornerCheckmark show:esp_box_corner];
}

- (void)box3DTapped {
    esp_box_3d = !esp_box_3d;
    [self animateCheckmark:_box3DCheckmark show:esp_box_3d];
}


- (void)lineOutlineTapped {
    esp_line_outline = !esp_line_outline;
    [self animateCheckmark:_lineOutlineCheckmark show:esp_line_outline];
}

- (void)nameTapped {
    esp_name_enabled = !esp_name_enabled;
    [self animateCheckmark:_nameCheckmark show:esp_name_enabled];
}

- (void)nameOutlineTapped {
    esp_name_outline = !esp_name_outline;
    [self animateCheckmark:_nameOutlineCheckmark show:esp_name_outline];
}

- (void)addBoneSelectorAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;
    NSArray *items = @[@"Head", @"Neck", @"Spine", @"Hip"];
    _boneSelector = [[CustomSegmentedControl alloc] initWithFrame:CGRectMake(10, y, w - 20, 28) items:items current:aimbot_bone_index];
    _boneSelector.valueChanged = ^(NSInteger newIndex) {
        aimbot_bone_index = (int)newIndex;
    };
    [_innerContent addSubview:_boneSelector];
}

- (void)addFovSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _fovValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _fovValueLabel.textColor = [UIColor whiteColor];
    _fovValueLabel.font = [UIFont systemFontOfSize:11];
    _fovValueLabel.textAlignment = NSTextAlignmentRight;
    _fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
    [_innerContent addSubview:_fovValueLabel];

    _fovSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:10.0f max:180.0f current:aimbot_fov];
    __weak MenuView *weakSelf = self;
    _fovSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_fov = newValue;
            strongSelf->_fovValueLabel.text = [NSString stringWithFormat:@"%.0f", aimbot_fov];
        }
    };
    [_innerContent addSubview:_fovSlider];
}

- (void)addSmoothSliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _smoothValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _smoothValueLabel.textColor = [UIColor whiteColor];
    _smoothValueLabel.font = [UIFont systemFontOfSize:11];
    _smoothValueLabel.textAlignment = NSTextAlignmentRight;
    _smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
    [_innerContent addSubview:_smoothValueLabel];

    _smoothSlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.0f max:20.0f current:aimbot_smooth];
    __weak MenuView *weakSelf = self;
    _smoothSlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_smooth = newValue;
            strongSelf->_smoothValueLabel.text = [NSString stringWithFormat:@"%.1f", aimbot_smooth];
        }
    };
    [_innerContent addSubview:_smoothSlider];
}

- (void)addTriggerDelaySliderAtY:(CGFloat)y {
    CGFloat w = _innerContent.bounds.size.width;

    _triggerDelayValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y - 24, 50, 20)];
    _triggerDelayValueLabel.textColor = [UIColor whiteColor];
    _triggerDelayValueLabel.font = [UIFont systemFontOfSize:11];
    _triggerDelayValueLabel.textAlignment = NSTextAlignmentRight;
    _triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.2f", aimbot_trigger_delay];
    [_innerContent addSubview:_triggerDelayValueLabel];

    _triggerDelaySlider = [[CustomSliderView alloc] initWithFrame:CGRectMake(15, y, w - 30, 30) min:0.01f max:1.0f current:aimbot_trigger_delay];
    __weak MenuView *weakSelf = self;
    _triggerDelaySlider.valueChanged = ^(float newValue) {
        __strong MenuView *strongSelf = weakSelf;
        if (strongSelf) {
            aimbot_trigger_delay = newValue;
            strongSelf->_triggerDelayValueLabel.text = [NSString stringWithFormat:@"%.2f", aimbot_trigger_delay];
        }
    };
    [_innerContent addSubview:_triggerDelaySlider];
}

- (void)refreshConfigList {
    // Config tab removed
}

- (void)selectConfigLbl:(UITapGestureRecognizer *)sender {
    // Config tab removed
}

static __attribute__((unused)) std::string readUnityString(uintptr_t str_ptr, task_t task) {
    if (!str_ptr) return "";
    int length = Read<int>(str_ptr + 0x10, task);
    if (length <= 0 || length > 256) return "";
    std::string result;
    result.reserve(length);
    for (int i = 0; i < length; i++) {
        char16_t c = Read<char16_t>(str_ptr + 0x14 + i * 2, task);
        if (c < 128) result += (char)c;
        else result += '?';
    }
    return result;
}

- (void)refreshSkinList {
    // Skins tab removed
}

- (void)ownedSkinTapped:(UITapGestureRecognizer *)g { }
- (void)replaceSkinTapped:(UITapGestureRecognizer *)g { }
- (void)tryApplySkinPair { }

- (void)createConfigFlow { }
- (void)deleteConfigFlow { }

- (void)loadConfigFlow { }




- (void)visibleCheckTapped  { aimbot_visible_check  = !aimbot_visible_check;  [self animateCheckmark:_visibleCheckCheckmark  show:aimbot_visible_check];  }
- (void)shootingCheckTapped { aimbot_shooting_check = !aimbot_shooting_check; [self animateCheckmark:_shootingCheckCheckmark show:aimbot_shooting_check]; }
- (void)knifeBotTapped      { aimbot_knife_bot      = !aimbot_knife_bot;      [self animateCheckmark:_knifeBotCheckmark      show:aimbot_knife_bot];      }
- (void)rcsTapped           { }


- (void)aimbotTapped {
    aimbot_enabled = !aimbot_enabled;
    [self animateCheckmark:_aimbotCheckmark show:aimbot_enabled];
}

- (void)triggerbotTapped {
    aimbot_triggerbot = !aimbot_triggerbot;
    [self animateCheckmark:_triggerbotCheckmark show:aimbot_triggerbot];
}

- (void)aimbotFovTapped {
    aimbot_fov_visible = !aimbot_fov_visible;
    [self animateCheckmark:_aimbotFovVisibleCheckmark show:aimbot_fov_visible];
}

- (void)teamTapped {
    esp_team_check = !esp_team_check;
    [self animateCheckmark:_teamCheckmark show:esp_team_check];
}

- (void)healthTapped {
    esp_health_enabled = !esp_health_enabled;
    [self animateCheckmark:_healthCheckmark show:esp_health_enabled];
}


- (void)healthBarTapped {
    esp_health_bar_enabled = !esp_health_bar_enabled;
    [self animateCheckmark:_healthBarCheckmark show:esp_health_bar_enabled];
}

- (void)healthBarOutlineTapped {
    esp_health_bar_outline = !esp_health_bar_outline;
    [self animateCheckmark:_healthBarOutlineCheckmark show:esp_health_bar_outline];
}

- (void)weaponTapped {
    esp_weapon_enabled = !esp_weapon_enabled;
    [self animateCheckmark:_weaponCheckmark show:esp_weapon_enabled];
}

- (void)weaponIconTapped {
    esp_weapon_icon_enabled = !esp_weapon_icon_enabled;
    [self animateCheckmark:_weaponIconCheckmark show:esp_weapon_icon_enabled];
}

- (void)platformTapped {
    esp_platform_enabled = !esp_platform_enabled;
    [self animateCheckmark:_platformCheckmark show:esp_platform_enabled];
}

- (void)avatarTapped {
    esp_avatar_enabled = !esp_avatar_enabled;
    [self animateCheckmark:_avatarCheckmark show:esp_avatar_enabled];
}

- (void)screenshotSafeTapped {
    esp_screenshot_safe = !esp_screenshot_safe;
    [self animateCheckmark:_screenshotSafeCheckmark show:esp_screenshot_safe];
    
    if (self.superview) {
        [self.superview hideViewFromCapture:esp_screenshot_safe];
    } else {
        [self hideViewFromCapture:esp_screenshot_safe];
    }
}

- (void)aimbotTeamTapped {
    aimbot_team_check = !aimbot_team_check;
    [self animateCheckmark:_aimbotTeamCheckmark show:aimbot_team_check];
}

- (void)aimbotXOnlyTapped {
    aimbot_x_only = !aimbot_x_only;
    [self animateCheckmark:_aimbotXOnlyCheckmark show:aimbot_x_only];
}

- (void)aimbot360Tapped {
    aimbot_360 = !aimbot_360;
    [self animateCheckmark:_aimbot360Checkmark show:aimbot_360];
}

- (void)tabTapped:(UITapGestureRecognizer *)gesture {
    NSInteger tag = gesture.view.tag;
    for (int i=0; i<_tabLabels.count; i++) {
        UILabel *l = _tabLabels[i];
        if (i == tag) {
            l.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
            l.textColor = [UIColor whiteColor];
        } else {
            l.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
            l.textColor = [UIColor colorWithWhite:0.7 alpha:1];
        }
    }
    _aimContainer.hidden    = (tag != 0);
    _visualContainer.hidden = (tag != 1);
    _otherContainer.hidden  = (tag != 2);
}

- (void)toggleCollapse {
    _collapsed = !_collapsed;

    CGAffineTransform rot = _collapsed
        ? CGAffineTransformMakeRotation(M_PI)
        : CGAffineTransformIdentity;

    [UIView animateWithDuration:0.2 animations:^{
        _arrowLayer.affineTransform = rot;
        _contentView.alpha = _collapsed ? 0.0f : 1.0f;
    }];

    CGFloat headerH = 35.0f;
    CGRect f = self.frame;
    f.size.height = _collapsed ? headerH : (headerH + _contentView.frame.size.height);
    [UIView animateWithDuration:0.2 animations:^{
        self.frame = f;
    }];
}

- (void)handleScrollPan:(UIPanGestureRecognizer *)g {
    UIView *target = nil;
    if (!_aimContainer.hidden) target = _aimContent;
    else if (!_visualContainer.hidden) target = _visualContent;
    else if (!_otherContainer.hidden) target = _otherContent;

    if (!target) return;

    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [g translationInView:_contentView];
        CGRect f = target.frame;
        f.origin.y += translation.y;
        if (f.origin.y > 0) f.origin.y = 0;
        CGFloat minY = _contentView.frame.size.height - f.size.height;
        if (minY > 0) minY = 0;
        if (f.origin.y < minY) f.origin.y = minY;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        target.frame = f;
        [CATransaction commit];
        [g setTranslation:CGPointZero inView:_contentView];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *v = touch.view;
    while (v) {
        if ([v isKindOfClass:[CustomSegmentedControl class]] || 
            [v isKindOfClass:[CustomSliderView class]]) {
            return NO;
        }
        v = v.superview;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.superview];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _initialTouchPoint = touchPoint;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = touchPoint.x - _initialTouchPoint.x;
        CGFloat deltaY = touchPoint.y - _initialTouchPoint.y;
        self.center = CGPointMake(self.center.x + deltaX, self.center.y + deltaY);
        _initialTouchPoint = touchPoint;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self centerMenu];
}

- (void)centerMenu {
    if (self.superview) {
        self.center = CGPointMake(self.superview.bounds.size.width / 2,
                                  self.superview.bounds.size.height / 2);
    }
}

- (void)dealloc {
}

@end
