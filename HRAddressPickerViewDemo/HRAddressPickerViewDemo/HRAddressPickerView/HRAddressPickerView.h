//
//  HRAddressPickerView.h
//  HRAddressPickerViewDemo
//
//  Created by Zer0 on 2017/6/2.
//  Copyright © 2017年 Zer0. All rights reserved.
//

//TODO: 使用时，一定要打开ATS 或者 将 http://apis.map.qq.com/ 这个域名排除


#import <UIKit/UIKit.h>

@interface HRAddressPickerView : UIView

+ (void)showDefaultAddressPickerViewInContainerView:(UIView *)containerView tencentMapKey:(NSString *)key completedHandle:(void(^)(NSDictionary *province,NSDictionary *city,NSDictionary *area))completedHandle;

/// 街道 http://apis.map.qq.com/ws/district/v1/getchildren?key=WJ3BZ-GVJ2F-HP2J7-JRJ7H-BANXJ-F5B46&id=130208
+ (void)showStreetAddressPickerViewInContainerView:(UIView *)containerView tencentMapKey:(NSString *)key areaId:(NSString *)areaId completedHandle:(void(^)(NSDictionary *street))completedHandle;


@end
