//
//  HRAddressPickerView.m
//  HRAddressPickerViewDemo
//
//  Created by Zer0 on 2017/6/2.
//  Copyright © 2017年 Zer0. All rights reserved.
//

#import "HRAddressPickerView.h"

#define kScreen_Width [UIScreen mainScreen].bounds.size.width
#define kScreen_Height [UIScreen mainScreen].bounds.size.height

static const CGFloat kContentViewHeight = 215.f;        ///< 内容视图高度
static const CGFloat kButtonHeight = 40.f;     ///< 按钮高度
static const CGFloat kButtonWidth = 75.f;      ///< 按钮宽度

@interface HRAddressPickerView ()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic,copy) NSString *tencentMapKey;         ///< 腾讯地图上申请的key

@property (nonatomic,copy) NSString *areaId;        ///< 区id
@property (nonatomic,assign,getter=isShowStreet) BOOL showStreet;       ///< 是否展示的是街道
@property (nonatomic,strong) NSArray *streetsArray;         ///< 街道数组
@property (nonatomic,strong) NSMutableDictionary *allStreet;        ///< 所有街道字典

@property (nonatomic,strong) UIActivityIndicatorView *activityIndicatorView;         ///< 菊花加载图

@property (nonatomic ,strong) UIView   * contentView;    ///< 内容视图
@property (nonatomic ,strong) UIButton * cancelBtutton;///< 取消按钮
@property (nonatomic, strong) UIButton * confirmButton;///< 完成按钮

@property (nonatomic ,strong) UIPickerView   * addressPickerView;///< 选择器
@property (nonatomic ,strong) NSDictionary   * dataDict;///< 省市区数据源字典
@property (nonatomic ,strong) NSMutableArray * provincesArr;///< 省份名称数组
@property (nonatomic ,strong) NSDictionary   * citysDict;///< 所有城市的字典
@property (nonatomic ,strong) NSDictionary   * areasDict;///< 所有地区的字典

@property (nonatomic,copy) NSArray *addressSource;  ///< 地址选择器数据源,装省份模型,每个省份模型内包含城市模型


///// 回调Block
@property (nonatomic,copy) void(^completedAddressHandleBlock)(NSDictionary *province,NSDictionary *city,NSDictionary *area);        ///< 选择地址（省市区）回调
@property (nonatomic,copy) void(^completedStreetHandleBlock)(NSDictionary *street);         ///< 选择街道回调


@end

@implementation HRAddressPickerView


#pragma mark - Publish API

+ (void)showDefaultAddressPickerViewInContainerView:(UIView *)containerView tencentMapKey:(NSString *)key completedHandle:(void(^)(NSDictionary *province,NSDictionary *city,NSDictionary *area))completedHandle {
    
    HRAddressPickerView *addressPickerView = [[HRAddressPickerView alloc] initWithTencentMapKey:key completedHandle:completedHandle];
    
    [containerView addSubview:addressPickerView];
    [addressPickerView show];
}

/// 街道 http://apis.map.qq.com/ws/district/v1/getchildren?key=WJ3BZ-GVJ2F-HP2J7-JRJ7H-BANXJ-F5B46&id=130208
+ (void)showStreetAddressPickerViewInContainerView:(UIView *)containerView tencentMapKey:(NSString *)key areaId:(NSString *)areaId completedHandle:(void(^)(NSDictionary *street))completedHandle {

    HRAddressPickerView *addressPickerView = [[HRAddressPickerView alloc] initWithTencentMapKey:key areaId:areaId completedHandle:completedHandle];
    
    [containerView addSubview:addressPickerView];
    
    [addressPickerView show];
}

#pragma mark - Initialize Methods
- (instancetype)initWithTencentMapKey:(NSString *)key completedHandle:(void(^)(NSDictionary *province,NSDictionary *city,NSDictionary *area))completedHandle {
    if (self = [super init]) {
        
        self.showStreet = NO;
 
        self.tencentMapKey = key;
        self.completedAddressHandleBlock = completedHandle;
        [self configView];
    }
    
    return self;
}

- (instancetype)initWithTencentMapKey:(NSString *)key areaId:(NSString *)areaId completedHandle:(void(^)(NSDictionary *street))completedHandle {
    if (self = [super init]) {
        
        self.showStreet = YES;
        
        self.areaId = areaId;
        self.tencentMapKey = key;
        self.completedStreetHandleBlock = completedHandle;
        [self configView];
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"HRAddressPickerView 释放了");
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //    [super touchesEnded:touches withEvent:event];
    // 不能传递下去，否则有可能会出现 刚消失下去再会出现（重现：你在上层的touches事件中写有此view的弹出方法就会出现）
    
    [self hide];
    
}


#pragma mark ############### Setter & Getter ###############
- (NSMutableDictionary *)allStreet {
    if (!_allStreet) {
        _allStreet = @{}.mutableCopy;
    }
    return _allStreet;
}

- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreen_Height, kScreen_Width, kContentViewHeight)];
        _contentView.backgroundColor = [UIColor grayColor];
        
        [_contentView addSubview:self.cancelBtutton];
        [_contentView addSubview:self.confirmButton];
        [_contentView addSubview:self.addressPickerView];
        [_contentView addSubview:self.activityIndicatorView];
    }
    return _contentView;
}

- (UIButton *)cancelBtutton{
    if (!_cancelBtutton) {
        _cancelBtutton = [[UIButton alloc]initWithFrame:
                      CGRectMake(0, 0, kButtonWidth, kButtonHeight)];
        [_cancelBtutton setTitle:@"取消"
                    forState:UIControlStateNormal];
        [_cancelBtutton setTitleColor:[UIColor blueColor]
                         forState:UIControlStateNormal];
        [_cancelBtutton addTarget:self
                       action:@selector(hide)
             forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtutton;
}

- (UIButton *)confirmButton{
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc]initWithFrame:
                    CGRectMake(kScreen_Width - kButtonWidth, 0, kButtonWidth, kButtonHeight)];
        [_confirmButton setTitle:@"完成"
                  forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor blueColor]
                       forState:UIControlStateNormal];
        [_confirmButton addTarget:self
                     action:@selector(onDidClickConfirmButton)
           forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIPickerView *)addressPickerView{
    if (!_addressPickerView) {
        _addressPickerView = [[UIPickerView alloc]initWithFrame:
                              CGRectMake(0, kButtonHeight, kScreen_Width, kContentViewHeight-kButtonHeight)];
        _addressPickerView.backgroundColor = [UIColor colorWithRed:239/255.f
                                                             green:239/255.f
                                                              blue:244.0/255.f
                                                             alpha:1.0];
        _addressPickerView.delegate = self;
        _addressPickerView.dataSource = self;
    }
    return _addressPickerView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
        _activityIndicatorView.color = [UIColor grayColor];
        _activityIndicatorView.center = self.addressPickerView.center;
        [_activityIndicatorView startAnimating];
    }
    return _activityIndicatorView;
}

#pragma mark - Custom Methods

- (void)configView {
    
    [self loadData];
    
    [self creatUI];
}

- (void)creatUI {
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.contentView];
}

- (void)stopActivityIndicatorView {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.activityIndicatorView.isAnimating) {
            [_activityIndicatorView stopAnimating];
            [_activityIndicatorView removeFromSuperview];
        }
        
        [self.addressPickerView reloadAllComponents];
    });
    
}

- (void)loadData {
    /// 加载数据
    NSString *requestStreetUrlPath = [NSString stringWithFormat:@"http://apis.map.qq.com/ws/district/v1/getchildren?key=%@&id=%@",self.tencentMapKey,self.areaId];
    
    NSString *requestAddressUrlPath = [NSString stringWithFormat:@"http://apis.map.qq.com/ws/district/v1/list?key=%@",self.tencentMapKey];
    
    NSString *urlPath = _showStreet ? requestStreetUrlPath : requestAddressUrlPath ;
    
    
    NSString *localPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    
    //获取文件的完整路径
    NSString *componentPath = _showStreet ? @"street.plist" : @"address.plist";
    
    NSString *filePath = [localPath stringByAppendingPathComponent:componentPath];
    
    NSLog(@"文件保存地址：%@  \n url: %@",filePath,urlPath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // 有缓存直接走缓存
        
        if (_showStreet) {
            
            NSDictionary *allStreet = [NSDictionary dictionaryWithContentsOfFile:filePath];
            
            [self.allStreet addEntriesFromDictionary:allStreet];
            
            NSArray *resultArray = [allStreet objectForKey:self.areaId];
            
            if (!resultArray) {
                /// 没有则发起网络请求
                [self requestDataWithURLPath:urlPath filePath:filePath];
            } else {
                _streetsArray = resultArray.firstObject;
                [self stopActivityIndicatorView];
            }
            
        } else {
            _addressSource = [NSArray arrayWithContentsOfFile:filePath];
            [self stopActivityIndicatorView];
        }
        
    } else {
        /// 没有则发起网络请求
        [self requestDataWithURLPath:urlPath filePath:filePath];
    }
    
}

- (void)requestDataWithURLPath:(NSString *)urlPath filePath:(NSString *)filePath {
//    // 1.创建一个网络路径
    NSURL *url = [NSURL URLWithString:urlPath];
    // 2.创建一个网络请求
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    // 3.获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    // 4.根据会话对象，创建一个Task任务：
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"从服务器获取到数据");
        /*
         对从服务器获取到的数据data进行相应的处理：
         */
        if (error) {
            return ;
        }
        
        NSDictionary *addressDict = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableLeaves) error:nil];
        
        
        if (_showStreet) {
            
            NSArray *allStreet = [addressDict objectForKey:@"result"];
            if (allStreet && allStreet.count>0 && self.areaId) {
                
                self.streetsArray = allStreet.firstObject;
                
                NSDictionary *streetItem = @{self.areaId:self.streetsArray};
                
                [self.allStreet addEntriesFromDictionary:streetItem];
                
                [_allStreet writeToFile:filePath atomically:YES];
                [self stopActivityIndicatorView];
            }
            
        } else {
            // 写入文件
            [self sortingData:addressDict filePath:filePath];
        }
        
        
    }];
    // 5.最后一步，执行任务（resume也是继续执行）:
    [sessionDataTask resume];
}

/// 整理数据
- (void)sortingData:(NSDictionary *)dataDict filePath:(NSString *)filePath {
    
    NSArray *allAddress = [dataDict objectForKey:@"result"];
    // 省下面加上一个市数组   市后面加上一个区数组
    
    if (!allAddress || allAddress.count!=3 ) return;
    
    /// 市下操作
    // 全部市
    NSArray *allCities = allAddress[1];
    // 全部区
    NSArray *allBurgs = allAddress[2];
    NSMutableArray *newCities = @[].mutableCopy;
    for (NSDictionary *tempCity in allCities) {
        
        NSMutableDictionary *newCity = tempCity.mutableCopy;
        // 子区
        NSMutableArray *subBurgs = @[].mutableCopy;
        
        for (NSDictionary *tempBurg in allBurgs) {
            if ([tempBurg[@"id"] integerValue]/100 == [tempCity[@"id"] integerValue]/100) {
                [subBurgs addObject:tempBurg];
            }
        }
        [newCity setObject:subBurgs forKey:@"burgs"];
        
        [newCities addObject:newCity];
    }
    
    
    /// 省级操作
    // 全部省
    NSArray *allProvinces = allAddress[0];
    NSMutableArray *newProvinces = @[].mutableCopy;
    for (NSDictionary *tempProvices in allProvinces) {
        
        NSMutableDictionary *newProvice = tempProvices.mutableCopy;
        // 子区
        NSMutableArray *subCities = @[].mutableCopy;
        
        for (NSDictionary *tempCity in newCities) {
            if ([tempCity[@"id"] integerValue]/10000 == [tempProvices[@"id"] integerValue]/10000) {
                [subCities addObject:tempCity];
            }
        }
        [newProvice setObject:subCities forKey:@"cities"];
        
        [newProvinces addObject:newProvice];
    }
    
    
    _addressSource = newProvinces;
    
    [_addressSource writeToFile:filePath atomically:YES];
    
    NSLog(@"%@----- %@",filePath,newProvinces);
    
    [self stopActivityIndicatorView];
    
}

- (void)show{
    [self showOrHide:YES];
}

- (void)hide{
    [self showOrHide:NO];
}

- (void)showOrHide:(BOOL)isShow {
    
    CGFloat selfY = _contentView.frame.origin.y;
    __block CGFloat selfkY = selfY;

    [UIView animateWithDuration:0.5 animations:^{
        [UIView beginAnimations:@"move" context:nil];
        [UIView setAnimationDuration:0.75];
        [UIView setAnimationDelegate:self];
        //改变它的frame的x,y的值
        
        if (isShow) {
            selfkY = kScreen_Height - kContentViewHeight;
        }
        else {
            selfkY = kScreen_Height;
        }
        _contentView.frame = CGRectMake(0,selfkY,kScreen_Width,kContentViewHeight);
        
        [UIView commitAnimations];
    } completion:^(BOOL finished) {
        if (finished && !isShow) {
            self.completedAddressHandleBlock = nil;
            self.completedStreetHandleBlock = nil;
            [self removeFromSuperview];
        }
    }];
}


/**
 产生的场景是在实现使用pickerView级联选取地址信息，并且在pickerView上部有工具栏辅助选取，在第一次选完地址再次修改地址时，快速滑动秒选确定按钮，地址显示不对的问题，解决办法为在点选确定辅助按钮的时候判断当时的pickerView是否正在滚动，如果在滚动则不允许触发点选确定后的其他操作。
 解决办法为下面的方法：
 */
- (BOOL)anySubViewScrolling:(UIView *)view {
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        if (scrollView.dragging || scrollView.decelerating) {
            return YES;
        }
    }
    for (UIView *theSubView in view.subviews) {
        if ([self anySubViewScrolling:theSubView]) {
            return YES;
        }
    }
    return NO;
}
#pragma mark ############### Action Methods ###############
- (void)onDidClickConfirmButton {
    // 判断滚动停止（否则会出现地址不正确）
    if ([self anySubViewScrolling:self.addressPickerView]) {
        return;
    }
    
    [self hide];
    
    if (_showStreet) {
        if (self.completedStreetHandleBlock) {
            NSInteger selectedStreetIndex = [self.addressPickerView selectedRowInComponent:0];
            
            NSDictionary *selectedStreet =  (_streetsArray && _streetsArray.count>selectedStreetIndex) ?_addressSource[selectedStreetIndex] : nil;
            
            self.completedStreetHandleBlock(selectedStreet);
        }
    } else {
        
        if (self.completedAddressHandleBlock) {
            NSInteger selectProvinceIndex = [self.addressPickerView selectedRowInComponent:0];
            NSInteger selectCityIndex     = [self.addressPickerView selectedRowInComponent:1];
            NSInteger selectAreaIndex     = [self.addressPickerView selectedRowInComponent:2];
            
            NSDictionary *selectProvince =  (_addressSource && _addressSource.count>selectProvinceIndex) ?_addressSource[selectProvinceIndex] : nil;
            
            NSArray *cities = [selectProvince objectForKey:@"cities"];
            NSDictionary *selectCity = (cities && cities.count>selectCityIndex) ? cities[selectCityIndex] : nil;
            
            NSArray *area = [selectCity objectForKey:@"burgs"];
            NSDictionary *selectArea = (area && area.count>selectAreaIndex) ? area[selectAreaIndex] : nil;
            
            self.completedAddressHandleBlock(selectProvince,selectCity,selectArea);
        }
    }
}

#pragma mark - Delegate
#pragma mark ############### UIPickerViewDataSource ###############

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return self.isShowStreet ? 1 : 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    if (_showStreet) {
        return _streetsArray.count;
    } else {
        if (0 == component) {
            return _addressSource.count;
        }
        else if (1 == component){
            NSInteger selectProvince = [pickerView selectedRowInComponent:0];
            NSDictionary *tempProvice          = _addressSource[selectProvince];
            NSArray *cities = [tempProvice objectForKey:@"cities"];
            return cities.count;
        }
        else if (2 == component){
            NSInteger selectProvince = [pickerView selectedRowInComponent:0];
            NSInteger selectCity     = [pickerView selectedRowInComponent:1];
            NSDictionary *tempProvice          = _addressSource[selectProvince];
            NSArray *cities = [tempProvice objectForKey:@"cities"];
            
            
            if (cities.count==0 || selectCity > cities.count - 1) {
                return 0;
            }
            
            NSDictionary *tempCity          = cities[selectCity];
            NSArray *burgs = [tempCity objectForKey:@"burgs"];
            
            return burgs.count;
        }
        
        return 0;
    }
    
    return 0;
}
#pragma mark ############### UIPickerViewDelegate ###############
/// 填充文字
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    
    if (_showStreet) {
        
        NSDictionary *tempProvice  = _streetsArray[row];
        
        return [tempProvice objectForKey:@"fullname"];
        
    } else {
        if (0 == component) {
            
            NSDictionary *tempProvice  = _addressSource[row];
            
            return [tempProvice objectForKey:@"fullname"];
        }
        else if (1 == component) {
            
            NSDictionary *selectProvice  = _addressSource[[pickerView selectedRowInComponent:0]];
            
            NSArray *cities = [selectProvice objectForKey:@"cities"];
            
            if (cities.count==0 || row > cities.count - 1) {
                return nil;
            }
            return [cities[row] objectForKey:@"fullname"];
        }
        else if (2 == component) {
            
            NSDictionary *selectProvice  = _addressSource[[pickerView selectedRowInComponent:0]];
            NSArray *cities = [selectProvice objectForKey:@"cities"];
            NSInteger selectIndex     = [pickerView selectedRowInComponent:1];
            
            if (cities.count==0 || selectIndex > cities.count - 1) {
                return nil;
            }
            
            NSDictionary *selectCity = cities[selectIndex];
            NSArray *burgs = [selectCity objectForKey:@"burgs"];
            
            if (burgs.count==0 || row > burgs.count -1 ) {
                return nil;
            }
            return [burgs[row] objectForKey:@"fullname"];
        }
        return nil;
    }
    
    return nil;
}

/// pickerView被选中
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    if (_showStreet) {
        
        // 选择回调
        
    } else {
        
        if (0 == component) {
            NSInteger selectCity = [pickerView selectedRowInComponent:1];
            NSInteger selectArea = [pickerView selectedRowInComponent:2];
            [pickerView reloadComponent:1];
            [pickerView selectRow:selectCity inComponent:1 animated:YES];
            [pickerView reloadComponent:2];
            [pickerView selectRow:selectArea inComponent:2 animated:YES];
            
        }
        else if (1 == component){
            NSInteger selectArea = [pickerView selectedRowInComponent:2];
            [pickerView reloadComponent:2];
            [pickerView selectRow:selectArea inComponent:2 animated:YES];
            
        }
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view{
    
    UILabel* pickerLabel = (UILabel*)view;
    
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.textColor = [UIColor colorWithRed:51.0/255
                                                green:51.0/255
                                                 blue:51.0/255
                                                alpha:1.0];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:15]];
    }
    
    pickerLabel.text = [self pickerView:pickerView
                            titleForRow:row
                           forComponent:component];
    return pickerLabel;
}


@end
