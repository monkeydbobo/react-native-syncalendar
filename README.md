# react-native-syncalendar
React 调用原生日历组件添加事件到系统日历

同步事件到手机系统自带日历，支持iOS Android



在package.json 中添加

```json
 "react-native-syncalendar": "git://github.com/monkeydbobo/react-native-syncalendar"
```

或

```json
 "react-native-syncalendar": "1.0.0"
```


npm install 

```
react-native link react-native-syncalendar
```



#### iOS需要在info.plist中添加日历权限

```xml
<!-- 日历 --> 
<key>NSCalendarsUsageDescription</key> 
<string>App需要您的同意,才能访问日历</string> 
```



### EXAMPLE


```javascript
import CalendarModule from 'react-native-syncalendar' 

CalendarModule.addCalendarEvent({
      id: '666', // 事件id, 事件唯一值
      title: 'test', // 事件标题
      location: 'location', // 会议地点
      startTime: '1559647910000', //起始时间 (unix / ms)
      endTime: '1559647910000', //结束事件
      alarm: [10, 20] //提前多久提醒
    }, (result) => {
      alert(result) // result为同步到的日历的错误码,200为成功
    })
```

