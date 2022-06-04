//
//  TYODLayout.h
//  OpenMap
//
//  Created by dengjinlong on 10/14/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 我的Autolayout总结
// 父view优先级高于子view

// 如果有子view没有约束宽高，同时需要自动改变某个子view宽高时，按subviews顺序来改变

// 父view包含一个autolayout布局子view时， 父view按frame布局，translatesAutoresizingMaskIntoConstraints 设为false
// 建立约束时，以子view为调用方法的一方。约束建立在子view上。在使用UITableViewCell 要注意

// 父子约束，firstView 需为子view, 但需要对superView设置constraint，不是对View设置constraint

// 注意layoutMargins, padding 会修改layoutMargins
// For other subviews in your view hierarchy, the default layout margins are normally 8 points on each side


typedef enum : NSUInteger {
    TYODDirectionRow, /// 水平布局
    TYODDirectionColumn, /// 垂直布局
    TYODDirectionUndefined /// 当前view非容器
} TYODDirection;

typedef enum : NSUInteger {
    TYODJustifyStart,  /// 从主轴开始位置布局, 对父view宽/高无影响
    TYODJustifyCenter, /// 在主轴上居中布局, 忽略padding，对父view宽/高无影响
    TYODJustifyEnd,  /// 从主轴结束位置布局, 对父view宽/高无影响
    TYODJustifyWrap, /// 在主轴上两端view和父view约束，自动计算父view宽/高，不同于Yoga的wrap
    TYODJustifySpaceBetween, /// 子view等距布局, 两端子view与父view无间距，至少两个子view
    TYODJustifySpaceEvenly, /// 子view之间，子view与父view之间等距布局, 忽略padding
} TYODJustify; ///  主轴布局类型

typedef enum : NSUInteger {
    TYODAlignStart, /// 纵轴方向上开始位置对齐
    TYODAlignCenter, /// 纵轴方向上居中对齐
    TYODAlignEnd, /// 纵轴方向上结束位置对齐
    TYODAlignStretch, /// 需要确保当前view是固定宽或高的, 子view未定义纵轴上的宽高时，宽或高跟随当前view，同时依据max宽高
    TYODAlignUndefined /// alignSelf使用
} TYODAlign; /// 纵轴布局类型

// 如果容器纵轴没有宽高设置，会自动wrap 子view，这是autolayout的特点，也是一种布局需要
@class TYODLayoutBuilder;
@interface TYODLayout: NSObject

// 当前view的子view的布局方向，当前view是一个布局容器
@property (nonatomic, assign) TYODDirection direction;

// 子view在布局方向上的布局方式
@property (nonatomic, assign) TYODJustify mainAxisJustify;

// 子view在布局方向的垂直方向上的布局方式
@property (nonatomic, assign) TYODAlign crossAxisAlign;

// 当前view做为子view可以在纵轴上自定义布局方式
@property (nonatomic, assign) TYODAlign alignSelf;

// 当前view的宽高约束
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property(nonatomic, assign) CGFloat minWidth;
@property(nonatomic, assign) CGFloat minHeight;
@property(nonatomic, assign) CGFloat maxWidth;
@property(nonatomic, assign) CGFloat maxHeight;

// 当前view的layoutMargin约束，会修改layoutMargin，并使用layoutMarginGuide约束
@property(nonatomic, assign) CGFloat padding;
@property(nonatomic, assign) CGFloat paddingHorizontal;
@property(nonatomic, assign) CGFloat paddingVertical;
@property(nonatomic, assign) UIEdgeInsets paddingEdgeInsets;

// 如果axisType是vertical，则使用 top/bottom布局相邻兄弟view
// 如果axisType是horizontal，则使用 left/right布局相邻兄弟view
// 相邻兄弟view 设置了同一个属性，则把两值相加，下面属性取正值，忽略负值
// SpaceBetween布局会忽略下面属性
// 对于大于小于某个值的约束，使用一个空view并设置min/max-widht/height
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat right;

// start，end，wrap 布局下才支持grow属性
// 子view在主轴上的占比, 0使用子view的默认大小
@property (nonatomic, assign) NSUInteger grow;

// 默认是true，设为false时会使用当前view不参与布局
@property(nonatomic, assign) BOOL isIncludedInLayout;

// 创建autolayout布局
- (void)buildLayout;

// 标记布局无效，再次调用buildLayout时才会更新布局约束
- (void)markDirty;

// 创建一个链式构建器
- (TYODLayoutBuilder *)builder;

@end


#define TYODLayoutMethodDef(ODName)  - (TYODLayoutBuilder * (^)(void))ODName;
#define TYODLayoutDef(ODName)  - (TYODLayoutBuilder * (^)(CGFloat))ODName;

@interface TYODLayoutBuilder: NSObject
@property (nonatomic, strong) TYODLayout *layout;

TYODLayoutMethodDef(row)
TYODLayoutMethodDef(column)

- (TYODLayoutBuilder * (^)(TYODJustify))mainAxis;
TYODLayoutMethodDef(mainStart)
TYODLayoutMethodDef(mainCenter)
TYODLayoutMethodDef(mainEnd)
TYODLayoutMethodDef(mainSpaceBetween)
TYODLayoutMethodDef(mainSpaceEvenly)
TYODLayoutMethodDef(mainWrap)

- (TYODLayoutBuilder * (^)(TYODAlign))crossAxis;
TYODLayoutMethodDef(crossStart)
TYODLayoutMethodDef(crossCenter)
TYODLayoutMethodDef(crossEnd)
TYODLayoutMethodDef(crossStretch)

- (TYODLayoutBuilder * (^)(UIEdgeInsets))paddingEdgeInsets;

TYODLayoutDef(left)
TYODLayoutDef(right)
TYODLayoutDef(top)
TYODLayoutDef(bottom)
TYODLayoutDef(padding)
TYODLayoutDef(paddingHorizontal)
TYODLayoutDef(paddingVertical)
TYODLayoutDef(width)
TYODLayoutDef(height)
TYODLayoutDef(minWidth)
TYODLayoutDef(minHeight)
TYODLayoutDef(maxWidth)
TYODLayoutDef(maxHeight)
TYODLayoutDef(grow)

@end

@interface UIView (TYODLayout)
@property(nonatomic, readonly, strong) TYODLayout* od_layout;
//@property(nonatomic, readonly, assign) BOOL isOdLayoutEnabled;
@end



NS_ASSUME_NONNULL_END
