//
//  ViewController.m
//  OpenMap
//
//  Created by dengjinlong on 10/14/21.
//

#import "ViewController.h"
#import "TYODLayout.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIView *emptyView1;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UIView *container;

@property (nonatomic, strong) UIView *demoContainer;
@property (nonatomic, strong) UIView *sizeContainer;
@property (nonatomic, assign) NSInteger axisType;
@property (nonatomic, assign) NSInteger mainType;
@property (nonatomic, assign) NSInteger crossType;
@property (nonatomic, assign) NSInteger sizeType;

@property (nonatomic, strong) UIView *topContainer;
@end

@interface AView : UIView
@end

@implementation AView
- (CGSize)intrinsicContentSize {
    return CGSizeMake(25, 25);
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    // 容器的三个基本属性
    self.demoContainer = [UIView new];
    self.demoContainer.clipsToBounds = true;
    self.demoContainer.accessibilityLabel = @"demobtn";
    self.demoContainer.backgroundColor = [UIColor grayColor];
    for (int i = 0; i < 3; i++) {
        UIButton *btn = [self createButton];
        btn.tag = i;
        btn.backgroundColor = [UIColor whiteColor];
        [btn setTitle:@[@"horizontal", @"start", @"start"][i] forState:UIControlStateNormal];
        [self.demoContainer addSubview:btn];
    }
    self.demoContainer.od_layout.
        builder.row().mainSpaceBetween().crossCenter().height(40).padding(10);

    // 容器size变化
    self.sizeContainer = [UIView new];
    self.sizeContainer.clipsToBounds = true;
    self.sizeContainer.accessibilityLabel = @"size";
    self.sizeContainer.backgroundColor = [UIColor whiteColor];
    UILabel *sizeLabel = [UILabel new];
    sizeLabel.text = @"ContainerSize: ";
    [self.sizeContainer addSubview:sizeLabel];
    UIButton *sizeBtn = [self createButton];
    sizeBtn.tag = 4;
    sizeBtn.backgroundColor = [UIColor grayColor];
    [sizeBtn setTitle:@"w=300,h=200" forState:UIControlStateNormal];
    [self.sizeContainer addSubview:sizeBtn];
    self.sizeContainer.od_layout
        .builder.row().mainStart().crossCenter().height(40);

    self.container = [UIView new];
    self.container.clipsToBounds = true;
    self.container.backgroundColor = [UIColor grayColor];
    self.emptyView = [AView new];
    self.emptyView1 = [UIView new];
    [self.container addSubview: self.button];
    //[self.button setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.container addSubview: self.emptyView];
    //[self.emptyView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    self.emptyView.backgroundColor = [UIColor redColor];
    [self.container addSubview: self.button1];
//    [self.container addSubview: self.emptyView1];
//    [self.container addSubview: self.button2];

    [self layoutContainer];
    [self layoutView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.topContainer.frame = self.view.bounds;
}

- (void)layoutView {
    UIView *topContainer = [UIView new];
    topContainer.backgroundColor = [UIColor blueColor];
    [topContainer addSubview:self.demoContainer];
    [topContainer addSubview:self.sizeContainer];
    [topContainer addSubview:self.container];

    [self.view addSubview:topContainer];

    self.container.od_layout.top = 50;
    self.container.od_layout.bottom = 5;
    self.container.od_layout.height = 200;

    topContainer.od_layout.builder
        .column().mainStart().crossStretch();
    [topContainer.od_layout buildLayout];

    self.topContainer = topContainer;
}

- (void)layoutContainer {
    if (self.sizeType == 0) {
        self.container.od_layout.width = 300;
        self.container.od_layout.height = 200;
    } else if (self.sizeType == 1) {
        self.container.od_layout.width = 300;
        self.container.od_layout.height = 0;
    } else if (self.sizeType == 2) {
        self.container.od_layout.width = 0;
        self.container.od_layout.height = 200;
    }
    [self layoutContainerSubviews];
}

- (void)layoutContainerSubviews {
    // 需要测试一个子view的情况
    self.container.od_layout.direction = self.axisType;
    self.container.od_layout.builder.mainAxis(self.mainType).crossAxis(self.crossType);
    //self.container.od_layout.padding = 10;


    //self.emptyView.od_layout.width = 10;
//    self.emptyView.od_layout.height = 10;
    //self.emptyView1.od_layout.width = 10;
    //self.emptyView1.od_layout.height = 10;
    //self.emptyView.od_layout.alignSelf = TYODAlignCenter;

    self.button.od_layout.width = 100;
    //self.button.od_layout.height = 10;
//    self.button.od_layout.grow = 2;
    self.emptyView.od_layout.grow = 1;
    self.button.od_layout.left = 10;
    self.button.od_layout.right = 10;
    //self.button.od_layout.bottom = 10;
    //self.button.od_layout.top = 10;

    //self.button1.od_layout.minWidth = 100;
    self.button1.od_layout.left = 10;
    self.button1.od_layout.right = 10;
    //self.button1.od_layout.bottom = 10;
    //self.button1.od_layout.top = 10;

    //self.button2.od_layout.left = 10;
//    self.button2.od_layout.right = 50;
//    self.button2.od_layout.top = 20;
//    self.button2.od_layout.bottom = 20;

    [self.container.od_layout markDirty];
    [self.container.od_layout buildLayout];
}

- (UIButton *)button {
    if (nil == _button) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [button.titleLabel setFont:[UIFont fontWithName:@"iconfont" size:24]];
        [button setTitle:@"button" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button.exclusiveTouch = YES;
        self.button = button;
    }
    return _button;
}
- (UIButton *)button1 {
    if (nil == _button1) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [button.titleLabel setFont:[UIFont fontWithName:@"iconfont" size:24]];
        [button setTitle:@"button 1" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button.exclusiveTouch = YES;
        self.button1 = button;
    }
    return _button1;
}
- (UIButton *)button2 {
    if (nil == _button2) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [button.titleLabel setFont:[UIFont fontWithName:@"iconfont" size:24]];
        [button setTitle:@"button2" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button.exclusiveTouch = YES;
        self.button2 = button;
    }
    return _button2;
}

- (void)xxxButtonAction:(UIButton *)sender {
    if (sender.tag == 0) {
        self.axisType++;
        if (self.axisType == 2) {
            self.axisType = 0;
        }
        [sender setTitle:@[@"horizontal", @"vertical"][self.axisType] forState:UIControlStateNormal];
    } else if (sender.tag == 1) {
        NSArray *arr =@[@"start", @"center", @"end", @"wrap", @"SpaceBetween", @"SpaceEvenly"];
        self.mainType++;
        if (self.mainType == arr.count) {
            self.mainType = 0;
        }
        [sender setTitle:arr[self.mainType] forState:UIControlStateNormal];
    } else if (sender.tag == 2) {
        NSArray *arr = @[@"start", @"center", @"end", @"stretch"];
        self.crossType++;
        if (self.crossType == arr.count) {
            self.crossType = 0;
        }
        [sender setTitle:arr[self.crossType] forState:UIControlStateNormal];
    } else if (sender.tag == 4) {
        NSArray *sizeTypeArr = @[@"w=300,h=200", @"w=300", @"h=200", @"undefined"];
        self.sizeType++;
        if (self.sizeType == sizeTypeArr.count) {
            self.sizeType = 0;
        }
        [sender setTitle:sizeTypeArr[self.sizeType] forState:UIControlStateNormal];
    }
    [self layoutContainer];
}

- (UIButton *)createButton {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button.titleLabel setFont:[UIFont fontWithName:@"iconfont" size:24]];
    [button setTitle:@"---" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.exclusiveTouch = YES;
    [button addTarget:self action:@selector(xxxButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
