//
//  ViewController.m
//  HRAddressPickerViewDemo
//
//  Created by Zer0 on 2017/6/7.
//  Copyright © 2017年 Zer0. All rights reserved.
//

#import "ViewController.h"

#import "HRAddressPickerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onClickButton:(id)sender {
    
    //    [HRAddressPickerView showDefaultAddressPickerViewInContainerView:self.view tencentMapKey:@"" completedHandle:^(NSDictionary *province, NSDictionary *city, NSDictionary *area) {
    //
    //    }];
    
    //    http://apis.map.qq.com/ws/district/v1/getchildren?key=WJ3BZ-GVJ2F-HP2J7-JRJ7H-BANXJ-F5B46&id=130208
    
    //    [HRAddressPickerView showStreetAddressPickerViewInContainerView:self.view tencentMapKey:@"WJ3BZ-GVJ2F-HP2J7-JRJ7H-BANXJ-F5B46" areaId:@"130208" completedHandle:^(NSDictionary *street) {
    //
    //    }];
    
    [HRAddressPickerView showDefaultAddressPickerViewInContainerView:self.view tencentMapKey:@"WJ3BZ-GVJ2F-HP2J7-JRJ7H-BANXJ-F5B46" completedHandle:^(NSDictionary *province, NSDictionary *city, NSDictionary *area) {
        
    }];
    
}

@end
