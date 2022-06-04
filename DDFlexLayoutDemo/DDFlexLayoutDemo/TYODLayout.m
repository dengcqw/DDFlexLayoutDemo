//
//  TYODLayout.m
//  OpenMap
//
//  Created by dengjinlong on 10/14/21.
//
//
#import "TYODLayout.h"
#import <objc/runtime.h>

@interface TYODLayoutConstraint : NSLayoutConstraint
@property (nonatomic, strong) id tyod_key;
@end
@implementation TYODLayoutConstraint
@end

@interface TYODLayout()
@property (nonatomic, weak) UIView *view;
@property (nonatomic, assign) BOOL hasBuilt;

@property (nonatomic, strong) NSMutableArray *layoutGuides;
@property (nonatomic, strong) NSArray *includedSubviews;
@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *changableConstraints;
@property (nonatomic, assign) BOOL hasGrowView;
@end

@implementation TYODLayout

- (id)init {
    if (self = [super init]) {
        self.paddingEdgeInsets = UIEdgeInsetsZero;
        self.direction = TYODDirectionUndefined;
        self.mainAxisJustify = TYODJustifyCenter;
        self.crossAxisAlign = TYODAlignCenter;
        self.alignSelf = TYODAlignUndefined;
        self.layoutGuides = [NSMutableArray new];
        self.changableConstraints = [NSMutableArray new];
        self.isIncludedInLayout = true;
    }
    return self;
}

- (BOOL)isColumn {
    return self.direction == TYODDirectionColumn;
}
- (BOOL)isRow {
    return self.direction == TYODDirectionRow;
}
- (BOOL)isMainStart {
    return self.mainAxisJustify == TYODJustifyStart;
}
- (BOOL)isMainEnd {
    return self.mainAxisJustify == TYODJustifyEnd;
}
- (BOOL)isMainWrap {
    return self.mainAxisJustify == TYODJustifyWrap;
}
- (BOOL)isSpaceBetween {
    return self.mainAxisJustify == TYODJustifySpaceBetween;
}

- (BOOL)hasLayoutHeight {
    if (self.height < 0.01 && self.minHeight < 0.01 && self.maxHeight < 0.01) {
        return false;
    } else { return true; }
}

- (BOOL)hasLayoutWidth {
    if (self.width < 0.01 && self.minWidth < 0.01 && self.maxWidth < 0.01) {
        return false;
    } else { return true; }
}

- (BOOL)enableAlignSelf:(UIView *)subview {
    if (subview.od_layout.alignSelf == TYODAlignUndefined) return false;
    return true;
}

- (UIEdgeInsets)getPadding {
    if (!UIEdgeInsetsEqualToEdgeInsets(self.paddingEdgeInsets, UIEdgeInsetsZero)) {
        return self.paddingEdgeInsets;
    } else if (self.padding > 0) {
        return UIEdgeInsetsMake(self.padding, self.padding, self.padding, self.padding);
    } else {
        if (self.paddingHorizontal < 0) self.paddingHorizontal = 0;
        if (self.paddingVertical < 0) self.paddingVertical = 0;
        return UIEdgeInsetsMake(self.paddingVertical, self.paddingHorizontal, self.paddingVertical, self.paddingHorizontal);
    }
}

- (void)clearGuides {
    for (id guide in self.layoutGuides) {
        [self.view removeLayoutGuide:guide];
    }
    [self.layoutGuides removeAllObjects];
}

// 等高或等宽的layout guide
- (void)prepareGuides:(NSInteger)number {
    [self clearGuides];

    UILayoutGuide *obj = nil;
    UILayoutGuide *firstGuide;
    for (NSInteger i = 0; i < number; i++) {
        obj = [UILayoutGuide new];
        if (i == 0) firstGuide = obj;
        [self.view addLayoutGuide:obj];
        [self.layoutGuides addObject:obj];
        if (i != 0) {
            if (self.isRow) {
                [obj.widthAnchor constraintEqualToAnchor: firstGuide.widthAnchor].active = true;
                [obj.heightAnchor constraintEqualToConstant:1].active = true;
            } else if (self.isColumn) {
                [obj.heightAnchor constraintEqualToAnchor: firstGuide.heightAnchor].active = true;
                [obj.widthAnchor constraintEqualToConstant:1].active = true;
            }
        } else {
            if (self.isRow) {
                NSLayoutConstraint *con = [obj.widthAnchor constraintGreaterThanOrEqualToConstant:1];
                con.priority = UILayoutPriorityDefaultHigh;
                con.active = true;
            } else if (self.isColumn) {
                NSLayoutConstraint *con = [obj.heightAnchor constraintGreaterThanOrEqualToConstant:1];
                con.priority = UILayoutPriorityDefaultHigh;
                con.active = true;
            }
        }
    }
}

- (void)markDirty {
    self.hasBuilt = false;
}

- (void)buildLayout {
    // 对子view的约束建立好后一般不修改，如果修改了，需要调用markDirty
    // 非UIView 不能做容器使用
    if (self.hasBuilt || ![self.view isKindOfClass:[UIView class]]) {
        // 宽高约束建立在当前view上，可能被修改
        for (id con in self.changableConstraints) {
            [self.view removeConstraint:con];
        }
        [self.changableConstraints removeAllObjects];
        [self layoutWidth];
        [self layoutHeight];
        return;
    }

    // 清除之前添加的约束
    for (id con in [self.view.constraints copy]) {
        if ([con isKindOfClass:[TYODLayoutConstraint class]]) {
            [self.view removeConstraint:con];
        }
    }
    [self.changableConstraints removeAllObjects];
    [self clearGuides];

    [self layoutWidth];
    [self layoutHeight];

    NSMutableArray *arr = [NSMutableArray new];
    for (UIView* view in self.view.subviews) {
        if (view.od_layout.isIncludedInLayout) {
            [arr addObject:view];
        }
    }
    if (arr.count == 0) { self.hasBuilt = true; return; }
    self.includedSubviews = [arr copy];

    self.hasGrowView = false;
    for (UIView *view in self.includedSubviews){
        if (view.od_layout.grow > 0) {
            self.hasGrowView = true;
            break;
        }
    }

    // 主轴布局
    if (self.direction != TYODDirectionUndefined) {
        for (UIView *subview in self.includedSubviews) {
            // 容器的子view默认使用autolayout布局
            subview.translatesAutoresizingMaskIntoConstraints = false;
            [subview.od_layout buildLayout];
        }
    }
    if (self.isRow) {
        switch (self.mainAxisJustify) {
            case TYODJustifyStart:
            case TYODJustifyEnd:
            case TYODJustifyWrap:
            {
                [self layoutRowMargin];
                [self layoutRowPadding];
                if (self.hasGrowView) [self layoutGrow];
                break;
            }
            case TYODJustifyCenter:
            {
                [self layoutRowMargin];
                [self layoutRowCenter];
                break;
            }
            case TYODJustifySpaceBetween:
            {
                [self layoutSpaceBetween];
                break;
            }
            case TYODJustifySpaceEvenly:
            {
                [self layoutSpaceEvenly];
                break;
            }
        };
        // 纵轴布局
        [self layoutCrossAxis];
    } else if (self.isColumn) {
        switch (self.mainAxisJustify) {
            case TYODJustifyStart:
            case TYODJustifyEnd:
            case TYODJustifyWrap:
            {
                [self layoutColumnMargin];
                [self layoutColumnPadding];
                if (self.hasGrowView) [self layoutGrow];
                break;
            }
            case TYODJustifyCenter:
            {
                [self layoutColumnMargin];
                [self layoutColumnCenter];
                break;
            }
            case TYODJustifySpaceBetween:
            {
                [self layoutSpaceBetween];
                break;
            }
            case TYODJustifySpaceEvenly:
            {
                [self layoutSpaceEvenly];
                break;
            }
        };
        // 纵轴布局
        [self layoutCrossAxis];
    }

    self.includedSubviews = nil;
    self.hasBuilt = true;
}

- (void)layoutAlignSelfVertical:(UIView *)subview {
    switch (subview.od_layout.alignSelf) {
        case TYODAlignStart:
        {
            [self constraintWithItem:subview attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTopMargin offset:subview.od_layout.top];
            break;
        }
        case TYODAlignCenter:
        {
            [self constraintWithItem:subview attr:NSLayoutAttributeCenterY toItem:self.view attr:NSLayoutAttributeCenterY offset:0];
            break;
        }
        case TYODAlignEnd:
        {
            [self constraintWithItem:subview attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-subview.od_layout.bottom];
            break;
        }
        case TYODAlignStretch:
        {
            [self constraintWithItem:subview attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTopMargin offset:subview.od_layout.top];
            [self constraintWithItem:subview attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-subview.od_layout.bottom];
            break;
        }
        case TYODAlignUndefined: { break; }
    }
}

- (void)layoutAlignSelfHorizontal:(UIView *)subview {
    switch (subview.od_layout.alignSelf) {
        case TYODAlignStart:
            {
                [self constraintWithItem:subview attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:subview.od_layout.left];
                break;
            }
        case TYODAlignCenter:
            {
                [self constraintWithItem:subview attr:NSLayoutAttributeCenterX toItem:self.view attr:NSLayoutAttributeCenterX offset:0];
                break;
            }
        case TYODAlignEnd:
            {
                [self constraintWithItem:subview attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-subview.od_layout.right];
                break;
            }
        case TYODAlignStretch:
            {
                [self constraintWithItem:subview attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:subview.od_layout.left];
                [self constraintWithItem:subview attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-subview.od_layout.right];
                break;
            }
        case TYODAlignUndefined: { break; }
    }
}

// 纵轴的布局：start对齐，居中对齐，end对齐
// start对齐和end对齐，如果没有约束宽高，则自动wrap子view
- (void)layoutCrossAxis {
    switch (self.crossAxisAlign) {
        case TYODAlignStart:
        {
            for (UIView *view in [self includedSubviews]) {
                if (self.isRow) {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfVertical:view];
                    } else {
                        if (![self hasLayoutHeight]) {
                            [self constraintWithItem:view attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-view.od_layout.bottom];
                        }
                        [self constraintWithItem:view attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTopMargin offset:view.od_layout.top];
                    }
                } else {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfHorizontal:view];
                    } else {
                        if (![self hasLayoutWidth]) {
                            [self constraintWithItem:view attr:NSLayoutAttributeRight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.view attr:NSLayoutAttributeRightMargin offset:-view.od_layout.right];
                        }
                        [self constraintWithItem:view attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:view.od_layout.left];
                    }
                }
            }
            break;
        }
        case TYODAlignCenter:
        {
            for (UIView *view in [self includedSubviews]) {
                if (self.isRow) {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfVertical:view];
                    } else {
                        [self constraintWithItem:view attr:NSLayoutAttributeCenterY toItem:self.view attr:NSLayoutAttributeCenterY offset:0];
                    }
                } else {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfHorizontal:view];
                    } else {
                        [self constraintWithItem:view attr:NSLayoutAttributeCenterX toItem:self.view attr:NSLayoutAttributeCenterX offset:0];
                    }
                }
            }
            break;
        }
        case TYODAlignEnd:
        {
            for (UIView *view in [self includedSubviews]) {
                if (self.isRow) {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfVertical:view];
                    } else {
                        if (![self hasLayoutHeight]) {
                            [self constraintWithItem:view attr:NSLayoutAttributeTop relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attr:NSLayoutAttributeTopMargin offset:view.od_layout.top];
                        }
                        [self constraintWithItem:view attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-view.od_layout.bottom];
                    }
                } else {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfHorizontal:view];
                    } else {
                        if (![self hasLayoutWidth]) {
                            [self constraintWithItem:view attr:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attr:NSLayoutAttributeLeftMargin offset:view.od_layout.left];
                        }
                        [self constraintWithItem:view attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-view.od_layout.right];
                    }
                }
            }
            break;
        }
        case TYODAlignStretch:
        {
            for (UIView *view in [self includedSubviews]) {
                if (self.isRow) {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfVertical:view];
                    } else {
                        [self constraintWithItem:view attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTopMargin offset:view.od_layout.top];
                        [self constraintWithItem:view attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-view.od_layout.bottom];
                    }
                } else {
                    if ([self enableAlignSelf:view]) {
                        [self layoutAlignSelfHorizontal:view];
                    } else {
                        [self constraintWithItem:view attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:view.od_layout.left];
                        [self constraintWithItem:view attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-view.od_layout.right];
                    }
                }
            }
            break;
        }
        case TYODAlignUndefined:
        { NSAssert(false, @"as a view container, crossAxisAlign can't be undefined"); break; }
    };
}

// 子view间隔相等布局，两端会和父view建立约束
- (void)layoutSpaceBetween {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    if (subviews.count == 1) {
        if (self.isRow) {
            [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterX toItem:self.view attr:NSLayoutAttributeCenterX offset:0];
        } else if (self.isColumn) {
            [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterY toItem:self.view attr:NSLayoutAttributeCenterY offset:0];
        }
        return;
    }

    // 两端view
    if (self.isRow) {
        [self layoutRowPadding];
    } else if (self.isColumn) {
        [self layoutColumnPadding];
    }
    // 两端元素靠近父view，不需要guide
    if (subviews.count == 2) {
        return;
    }

    [self prepareGuides:subviews.count - 1];
    UILayoutGuide *guide = nil;
    for (NSInteger i = 0; i < self.layoutGuides.count; i++) {
        guide = self.layoutGuides[i];
        if (self.isRow) {
            [guide.leftAnchor constraintEqualToAnchor:subviews[i].rightAnchor].active = true;
            [guide.rightAnchor constraintEqualToAnchor:subviews[i+1].leftAnchor].active = true;
        } else if (self.isColumn) {
            [guide.topAnchor constraintEqualToAnchor:subviews[i].bottomAnchor].active = true;
            [guide.bottomAnchor constraintEqualToAnchor:subviews[i+1].topAnchor].active = true;
        }
    }
}

- (void)layoutSpaceEvenly {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    if (subviews.count == 1) {
        if (self.isRow) {
            [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterX toItem:self.view attr:NSLayoutAttributeCenterX offset:0];
        } else if (self.isColumn) {
            [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterY toItem:self.view attr:NSLayoutAttributeCenterY offset:0];
        }
        return;
    }

    [self prepareGuides:subviews.count + 1];
    UILayoutGuide *guide = nil;
    // 先处理第一个Guide和最后一个Guide
    guide = self.layoutGuides.firstObject;
    if (self.isRow) {
        [guide.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = true;
        [guide.rightAnchor constraintEqualToAnchor:subviews[0].leftAnchor].active = true;
    } else {
        [guide.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = true;
        [guide.bottomAnchor constraintEqualToAnchor:subviews[0].topAnchor].active = true;
    }
    guide = self.layoutGuides.lastObject;
    if (self.isRow) {
        [guide.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = true;
        [guide.leftAnchor constraintEqualToAnchor:subviews.lastObject.rightAnchor].active = true;
    } else {
        [guide.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = true;
        [guide.topAnchor constraintEqualToAnchor:subviews.lastObject.bottomAnchor].active = true;
    }

    for (NSInteger i = 1; i < self.layoutGuides.count - 1; i++) {
        guide = self.layoutGuides[i];
        if (self.isRow) {
            [guide.leftAnchor constraintEqualToAnchor:subviews[i-1].rightAnchor].active = true;
            [guide.rightAnchor constraintEqualToAnchor:subviews[i].leftAnchor].active = true;
        } else if (self.isColumn) {
            [guide.topAnchor constraintEqualToAnchor:subviews[i-1].bottomAnchor].active = true;
            [guide.bottomAnchor constraintEqualToAnchor:subviews[i].topAnchor].active = true;
        }
    }
}

// 子view主轴水平居中
- (void)layoutRowCenter {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    if (subviews.count == 1) {
        [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterX toItem:self.view attr:NSLayoutAttributeCenterX offset:0];
        return;
    }

    [self clearGuides];
    UILayoutGuide *centerGuide = [UILayoutGuide new];
    [self.layoutGuides addObject:centerGuide];
    [self.view addLayoutGuide:centerGuide];

    [centerGuide.heightAnchor constraintEqualToConstant:1].active = true;
    [centerGuide.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = true;
    [centerGuide.leftAnchor constraintEqualToAnchor:subviews.firstObject.leftAnchor].active = true;
    [centerGuide.rightAnchor constraintEqualToAnchor:subviews.lastObject.rightAnchor].active = true;
    [centerGuide.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
}

// 子view主轴垂直居中
- (void)layoutColumnCenter {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    if (subviews.count == 1) {
        [self constraintWithItem:subviews[0] attr:NSLayoutAttributeCenterY toItem:self.view attr:NSLayoutAttributeCenterY offset:0];
        return;
    }

    [self clearGuides];
    UILayoutGuide *centerGuide = [UILayoutGuide new];
    [self.layoutGuides addObject:centerGuide];
    [self.view addLayoutGuide:centerGuide];

    [centerGuide.widthAnchor constraintEqualToConstant:1].active = true;
    [centerGuide.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = true;
    [centerGuide.topAnchor constraintEqualToAnchor:subviews.firstObject.topAnchor].active = true;
    [centerGuide.bottomAnchor constraintEqualToAnchor:subviews.lastObject.bottomAnchor].active = true;
    [centerGuide.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = true;
}

// 当前view 水平方向内部间距
- (void)layoutRowPadding {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    UIView *firstView = subviews.firstObject;
    UIView *lastView = subviews.lastObject;

    self.view.layoutMargins = [self getPadding];

    if (self.isMainStart && !self.hasGrowView) {
        [self constraintWithItem:firstView attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:firstView.od_layout.left];
    } else if (self.isMainEnd && !self.hasGrowView) {
        [self constraintWithItem:lastView attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-lastView.od_layout.right];
    } else {
        [self constraintWithItem:firstView attr:NSLayoutAttributeLeft toItem:self.view attr:NSLayoutAttributeLeftMargin offset:firstView.od_layout.left];
        [self constraintWithItem:lastView attr:NSLayoutAttributeRight toItem:self.view attr:NSLayoutAttributeRightMargin offset:-lastView.od_layout.right];
    }
}

// 当前view 垂直方向内部间距
- (void)layoutColumnPadding {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}
    UIView *firstView = subviews.firstObject;
    UIView *lastView = subviews.lastObject;

    self.view.layoutMargins = [self getPadding];

    if (self.isMainStart && !self.hasGrowView) {
        [self constraintWithItem:firstView attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTop offset:firstView.od_layout.top];
    } else if (self.isMainEnd && !self.hasGrowView) {
        [self constraintWithItem:lastView attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-lastView.od_layout.bottom];
    } else {
        [self constraintWithItem:firstView attr:NSLayoutAttributeTop toItem:self.view attr:NSLayoutAttributeTopMargin offset:firstView.od_layout.top];
        [self constraintWithItem:lastView attr:NSLayoutAttributeBottom toItem:self.view attr:NSLayoutAttributeBottomMargin offset:-lastView.od_layout.bottom];
    }
}

// 水平方向使用left/right约束子view, 不约束当前view
- (void)layoutRowMargin {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}

    // 从第一个元素开始, 与前一元素关联
    for (NSInteger i = 1; i < subviews.count; i++) {
        CGFloat left = subviews[i].od_layout.left;
        CGFloat right = subviews[i-1].od_layout.right;
        [self constraintWithItem:subviews[i] attr:NSLayoutAttributeLeft toItem:subviews[i-1] attr:NSLayoutAttributeRight offset:left+right];
    }
}

// 垂直方向使用top/bottom约束子view
- (void)layoutColumnMargin {
    NSArray<UIView *> *subviews = [self includedSubviews];
    if (subviews.count == 0) {return;}

    // 从第2个元素开始, 与前一元素关联
    for (NSInteger i = 1; i < subviews.count; i++) {
        CGFloat top = subviews[i].od_layout.top;
        CGFloat bottom = subviews[i-1].od_layout.bottom;
        [self constraintWithItem:subviews[i] attr:NSLayoutAttributeTop toItem:subviews[i-1] attr:NSLayoutAttributeBottom offset:top+bottom];
    }
}

// 当前view宽度
- (void)layoutWidth {
    NSLayoutConstraint *con;
    if (self.width > 0) {
        con = [self constraintWithItem:self.view attr:NSLayoutAttributeWidth toItem:nil offset:self.width];
    } else {
        if (self.minWidth > 0) {
            con = [self constraintWithItem:self.view attr:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attr:NSLayoutAttributeNotAnAttribute offset:self.minWidth];
        }
        if (self.maxWidth > 0) {
            con = [self constraintWithItem:self.view attr:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attr:NSLayoutAttributeNotAnAttribute offset:self.maxWidth];
        }
    }
    if (con) [self.changableConstraints addObject:con];
}

// 当前view高度
- (void)layoutHeight {
    NSLayoutConstraint *con;
    if (self.height > 0) {
        con = [self constraintWithItem:self.view attr:NSLayoutAttributeHeight toItem:nil offset:self.height];
    } else {
        if (self.minHeight > 0) {
            con = [self constraintWithItem:self.view attr:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attr:NSLayoutAttributeNotAnAttribute offset:self.minHeight];
        }
        if (self.maxHeight > 0) {
            con = [self constraintWithItem:self.view attr:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attr:NSLayoutAttributeNotAnAttribute offset:self.maxHeight];
        }
    }

    if (con) [self.changableConstraints addObject:con];
}

// 根据grow值设置宽高比例
// stretch 会修改width, 不能直接使用宽高
- (void)layoutGrow {
    NSMutableArray *growViews = [NSMutableArray array];
    for (UIView *view in self.includedSubviews) {
        if (view.od_layout.grow > 0) {
            [growViews addObject:view];
            [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                  forAxis:self.isRow ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical];
        } else {
            [view setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                    forAxis:self.isRow ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical];
        }
    }

    UIView *firstView = growViews.firstObject;
    for (UIView *view in growViews) {
        if (view != firstView) {
            NSLayoutAttribute attr = self.isRow ? NSLayoutAttributeWidth : NSLayoutAttributeHeight;
            NSLayoutConstraint *con = [self constraintWithItem:firstView
                                attr:attr
                           relatedBy:NSLayoutRelationEqual
                              toItem:view
                                attr:attr
                          multiplier: (CGFloat)firstView.od_layout.grow / (CGFloat)view.od_layout.grow
                          offset:0];
            con.priority = UILayoutPriorityDefaultHigh;
        }
    }
}

- (TYODLayoutBuilder *)builder {
    TYODLayoutBuilder *builder = [TYODLayoutBuilder new];
    builder.layout = self;
    return builder;
}

- (NSLayoutConstraint *)constraintWithItem:(id)view1
                      attr:(NSLayoutAttribute)attr
                    toItem:(id)view2
                    offset:(CGFloat)offset
{
    return [self constraintWithItem:view1 attr:attr relatedBy:NSLayoutRelationEqual toItem:view2 attr:attr offset:offset];
}

- (NSLayoutConstraint *)constraintWithItem:(id)view1
                 attr:(NSLayoutAttribute)attr1
                    toItem:(id)view2
                 attr:(NSLayoutAttribute)attr2
                  offset:(CGFloat)offset
{
    return [self constraintWithItem:view1 attr:attr1 relatedBy:NSLayoutRelationEqual toItem:view2 attr:attr2 offset:offset];
}

- (NSLayoutConstraint *)constraintWithItem:(id)view1
                 attr:(NSLayoutAttribute)attr1
                 relatedBy:(NSLayoutRelation)relation
                    toItem:(id)view2
                 attr:(NSLayoutAttribute)attr2
               offset:(CGFloat)offset
{
    return [self constraintWithItem:view1 attr:attr1 relatedBy:NSLayoutRelationEqual toItem:view2 attr:attr2 multiplier:1 offset:offset];
}

- (NSLayoutConstraint *)constraintWithItem:(id)view1
                 attr:(NSLayoutAttribute)attr1
                 relatedBy:(NSLayoutRelation)relation
                    toItem:(id)view2
                 attr:(NSLayoutAttribute)attr2
           multiplier:(CGFloat)multiplier
                  offset:(CGFloat)offset
{
    TYODLayoutConstraint *constraint =
        [TYODLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:offset];
    // 需要对superView设置constraint，不是对View设置constraint
    [self.view addConstraint:constraint];
    [constraint setActive:true];
    return constraint;
}

@end

#define TYODLayoutMethodImp(ODName, property, value) \
- (TYODLayoutBuilder * (^)(void))ODName { \
    return ^id() { \
        self.layout.property = value; \
        return self; \
    }; \
}

#define TYODLayoutImp(ODName) \
- (TYODLayoutBuilder * (^)(CGFloat))ODName { \
    return ^id(CGFloat attribute) { \
        self.layout.ODName = attribute; \
        return self; \
    }; \
}
@implementation TYODLayoutBuilder

TYODLayoutMethodImp(row, direction, TYODDirectionRow)
TYODLayoutMethodImp(column, direction, TYODDirectionColumn)

- (TYODLayoutBuilder * (^)(TYODJustify))mainAxis {
    return ^id(TYODJustify attribute) { self.layout.mainAxisJustify = attribute; return self; };
}

TYODLayoutMethodImp(mainStart, mainAxisJustify, TYODJustifyStart)
TYODLayoutMethodImp(mainCenter, mainAxisJustify, TYODJustifyCenter)
TYODLayoutMethodImp(mainEnd, mainAxisJustify, TYODJustifyEnd)
TYODLayoutMethodImp(mainSpaceBetween, mainAxisJustify, TYODJustifySpaceBetween)
TYODLayoutMethodImp(mainSpaceEvenly, mainAxisJustify, TYODJustifySpaceEvenly)
TYODLayoutMethodImp(mainWrap, mainAxisJustify, TYODJustifyWrap)

- (TYODLayoutBuilder * (^)(TYODAlign))crossAxis {
    return ^id(TYODAlign attribute) { self.layout.crossAxisAlign = attribute; return self; };
}
TYODLayoutMethodImp(crossStart, crossAxisAlign, TYODAlignStart)
TYODLayoutMethodImp(crossCenter, crossAxisAlign, TYODAlignCenter)
TYODLayoutMethodImp(crossEnd, crossAxisAlign, TYODAlignEnd)
TYODLayoutMethodImp(crossStretch, crossAxisAlign, TYODAlignStretch)

- (TYODLayoutBuilder * (^)(UIEdgeInsets))paddingEdgeInsets {
    return ^id(UIEdgeInsets insets) { self.layout.paddingEdgeInsets = insets; return self; };
}

TYODLayoutImp(left)
TYODLayoutImp(right)
TYODLayoutImp(top)
TYODLayoutImp(bottom)
TYODLayoutImp(padding)
TYODLayoutImp(paddingHorizontal)
TYODLayoutImp(paddingVertical)
TYODLayoutImp(width)
TYODLayoutImp(height)
TYODLayoutImp(minWidth)
TYODLayoutImp(minHeight)
TYODLayoutImp(maxWidth)
TYODLayoutImp(maxHeight)
TYODLayoutImp(grow)

@end

static const void* kYGYogaAssociatedKey = &kYGYogaAssociatedKey;
@implementation UIView (YogaKit)
- (TYODLayout*)od_layout {
    TYODLayout* yoga = objc_getAssociatedObject(self, kYGYogaAssociatedKey);
    if (!yoga) {
        yoga = [[TYODLayout alloc] init];
        yoga.view = self;
        objc_setAssociatedObject( self, kYGYogaAssociatedKey, yoga, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return yoga;
}

//- (BOOL)isOdLayoutEnabled {
    //return nil != objc_getAssociatedObject(self, kYGYogaAssociatedKey);
//}

@end

