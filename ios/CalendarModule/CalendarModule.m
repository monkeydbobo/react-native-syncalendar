//
//  CalendarModule.m
//  CalendarModule
//
//  Created by 汪浩波 on 2019/6/5.
//  Copyright © 2019 汪浩波. All rights reserved.
//

#import "CalendarModule.h"
#import "RCTLog.h"
#import <EventKit/EventKit.h>   // 系统日历使用


// 无效或空值的字符串
#define kIsStringValue_GtEmpty(msg) (![msg isKindOfClass:[NSString class]] || msg.length <= 0 ? YES : NO)

// 有效且有值的字符串
#define kIsStringValue_GtValid(msg) ([msg isKindOfClass:[NSString class]] && msg.length > 0 ? YES : NO)

#define kUD_CalendarList            @"CalendarList"
#define F_GtCurrentTimeInterval_13 (floor([[NSDate date] timeIntervalSince1970] * 1000))


@implementation CalendarModule
RCT_EXPORT_MODULE(CalendarModule);
// 测试
RCT_EXPORT_METHOD(testPrint:(NSString *)name info:(NSDictionary *)info) {
    RCTLogInfo(@"%@: %@", name, info);
}

// 添加日历
RCT_EXPORT_METHOD(addCalendarEvent:(NSDictionary *) meetingInfo:(RCTResponseSenderBlock)callback) {
    RCTLogInfo(@"meetingInfo ----> %@", meetingInfo);
    NSString * result = [self addMeetingToCalendar:meetingInfo];
    callback(@[result]);
}

+ (NSString*)convertToJSONData:(id)infoDict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //去除掉首尾的空白字符和换行字符
    
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

#pragma mark - 日历事件

- (NSString *)addMeetingToCalendar:(NSDictionary *)meetingInfo {
    
    NSString *meetingId = [meetingInfo objectForKey:@"id"];
    NSString *title = [meetingInfo objectForKey:@"title"];
    NSString *location = [meetingInfo objectForKey:@"location"];
    NSTimeInterval startTime = [[meetingInfo objectForKey:@"startTime"] doubleValue];
    NSTimeInterval endTime = [[meetingInfo objectForKey:@"endTime"] doubleValue];
    NSArray *alarmArray = [meetingInfo objectForKey:@"alarm"];
    
    if (![alarmArray isKindOfClass:[NSArray class]]) {
        alarmArray = nil;
    }
    
    NSString *resultCode = [self createEventCalendarForId: meetingId
                             title:title
                          location:location
                         startTime:startTime
                           endTime:endTime
                            allDay:NO
                        alarmArray:alarmArray];
    return resultCode;
}

- (void)alertForCalendarNotAuthorization {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"请在手机设置中允许抱抱访问您的日历" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        // 不允许使用日历,请在设置中允许此App使用日历
        NSLog(@"不允许使用日历,请在设置中允许此App使用日历");
    }];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
}

- (NSString *)createEventCalendarForId:(NSString *)meetingId
                           title:(NSString *)title
                        location:(NSString *)location
                       startTime:(NSTimeInterval)startTime
                         endTime:(NSTimeInterval)endTime
                          allDay:(BOOL)allDay
                      alarmArray:(NSArray *)alarmArray {
    
    NSString *resultCode = @"200";
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    if (![eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        // 系统版本太低，不支持设置日历
        resultCode = @"101";
    }
    
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                // 日历打开失败，请稍后重试
                NSLog(@"[error] %@ : %@", NSStringFromSelector(_cmd), error.description);
            }
            
            if (!granted){
                [self alertForCalendarNotAuthorization];
            }
            
            BOOL isUpdateOld = NO;
            
            EKEvent *event = nil;
            NSString *calendarId = [self getCalendarIdForMeetingId:meetingId];
            if (kIsStringValue_GtValid(calendarId)) {
                event = [eventStore eventWithIdentifier:calendarId];
                if ([event isKindOfClass:[EKEvent class]]) {
                    if ([title isEqualToString:event.title] &&
                        [location isEqualToString:event.location] &&
                        startTime/1000 == event.startDate.timeIntervalSince1970 &&
                        endTime/1000 == event.endDate.timeIntervalSince1970) {
                        // 已经存在 并 属性没有变化
                    }
                    
                    // 已经存在 并 属性发生变化
                    isUpdateOld = YES;
                }
            }
            
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startTime/1000];
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endTime/1000];
            
            if (!event) {
                event = [EKEvent eventWithEventStore:eventStore];
            }
            
            event.title     = title;            // 事件标题 -- 这里是标题
            event.location  = location;         // 事件位置 -- 这里可以添加位置,也可以其他想显示的内容(系统日历中是地址)
            event.startDate = startDate;        // 开始时间 -- 事件的开始日期和系统日历设置事件开始事件对应
            event.endDate   = endDate;          // 结束时间 -- 事件的结束日期和系统日历设置事件开始事件对应
            event.allDay    = allDay;           // 是否全天 -- 和系统设置全天一致
            
            // 移除提醒
            for (EKAlarm *subAlarm in event.alarms) {
                [event removeAlarm:subAlarm];
            }
            
            // 添加提醒
            if ([alarmArray isKindOfClass:[NSArray class]] && alarmArray.count > 0) {
                for (NSNumber *alarmTime in alarmArray) {
                    [event addAlarm:[EKAlarm alarmWithRelativeOffset:-[alarmTime integerValue]*60]];
                }
            }
            
            [event setCalendar:[eventStore defaultCalendarForNewEvents]];
            NSError *err;
            BOOL isRes = [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
            
            if (err || isRes == NO) {
                // 不允许使用日历,请在设置中允许此App使用日历
                NSLog(@"[error] %@ : %@", NSStringFromSelector(_cmd), err ?err.description :@"");
            }
            
            NSLog(@"日程ID：%@", event.eventIdentifier);
            
            [self addOrUpdateCalendarId:event.eventIdentifier toMeetingId:meetingId andEndTime:endTime];
        });
    }];
    return resultCode;
}
#pragma mark - 日程id和会议id关联处理

// 日程Id 存储和读取
- (void)addOrUpdateCalendarId:(NSString *)calendarId toMeetingId:(NSString *)meetingId andEndTime:(NSTimeInterval)endTime {
    NSMutableArray *calendarList = [[[NSUserDefaults standardUserDefaults] objectForKey:kUD_CalendarList] mutableCopy];
    if (![calendarList isKindOfClass:[NSArray class]]) {
        calendarList = [NSMutableArray array];
    }
    
    NSTimeInterval nowtime = F_GtCurrentTimeInterval_13;
    BOOL isFind = NO;
    for (int i = 0; i < calendarList.count; i++) {
        NSMutableDictionary *subInfo = [calendarList[i] mutableCopy];
        NSTimeInterval time = [subInfo[@"endTime"] doubleValue];
        if (time < nowtime) {
            [calendarList removeObjectAtIndex:i];
            i--;
            continue;
        }
        
        // 会议Id已存在, 更新数据
        if ([meetingId isEqualToString:subInfo[@"mtId"]]) {
            isFind = YES;
            subInfo[@"caId"] = calendarId;
            subInfo[@"endTime"] = [NSNumber numberWithDouble:endTime];
            [calendarList replaceObjectAtIndex:i withObject:subInfo];
        }
    }
    
    if (isFind == NO) {
        NSMutableDictionary *subInfo = [NSMutableDictionary dictionary];
        subInfo[@"caId"] = calendarId;
        subInfo[@"endTime"] = [NSNumber numberWithDouble:endTime];
        subInfo[@"mtId"] = meetingId;
        [calendarList addObject:subInfo];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:calendarList forKey:kUD_CalendarList];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 查找日程Id
- (NSString *)getCalendarIdForMeetingId:(NSString *)meetingId {
    NSArray *calendarList = [[NSUserDefaults standardUserDefaults] objectForKey:kUD_CalendarList];
    if (![calendarList isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSString *calendarId = nil;
    for (NSDictionary *subInfo in calendarList) {
        // 会议Id存在, 更新数据
        if ([meetingId isEqualToString:subInfo[@"mtId"]]) {
            calendarId = subInfo[@"caId"];
            break;
        }
    }
    
    if (kIsStringValue_GtValid(calendarId)) {
        return calendarId;
    }
    
    return nil;
}


@end
