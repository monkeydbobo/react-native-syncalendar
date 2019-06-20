/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, { Component } from 'react';
import { Platform, StyleSheet, Text, View, NativeModules, Button } from 'react-native';

const instructions = Platform.select({
  ios: 'Press Cmd+R to reload,\n' + 'Cmd+D or shake for dev menu',
  android:
    'Double tap R on your keyboard to reload,\n' +
    'Shake or press menu button for dev menu',
});

type Props = {};
var calendarUtils = NativeModules.CalendarModule;

export default class App extends Component<Props> {
  addCalendar() {

    calendarUtils.addCalendarEvent({
      id: '666',
      title: 'test',
      location: 'location',
      startTime: '1559647910000',
      endTime: '1559647910000',
      alarm: [10, 20]
    }, (result) => {
      alert(result)
    })
  }
  testPrint() {
    calendarUtils.addCalendarEvent({
      height: '1.78m',
      weight: '7kg'
    }, (res) => {
      alert(res)
    });
  }
  render() {
    return (
      <View style={styles.container}>
        <Button title="testPrint" onPress={this.testPrint}></Button>
        <Button title="addcalendar" onPress={this.addCalendar}></Button>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
