import React, {useRef, useEffect, useState} from 'react';
import {AppState, Button, SafeAreaView, View, Text, ScrollView} from 'react-native';
import Nearby from './Nearby';

import {getDeviceName} from 'react-native-device-info';

const App = () => {
  const [deviceName, setDeviceName] = useState('');
  const [devices, setDevices] = useState([]);
  const [isRunning, setIsRunning] = useState(false);
  const appState = useRef(AppState.currentState);
  const [appStateVisible, setAppStateVisible] = useState(appState.current);

  useEffect(() => {
    Nearby.isActive().then(res => setIsRunning(res));
  }, []);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (
        appState.current.match(/inactive|background/) &&
        nextAppState === 'active'
      ) {
        Nearby.stopBackground("deviceName");
      }else if(
        appState.current.match(/inactive|active/) &&
        nextAppState === 'background'
      ){
        Nearby.background("deviceName");
      }

      appState.current = nextAppState;
      setAppStateVisible(appState.current);
      console.log('AppState', appState.current);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    getDeviceName().then(setDeviceName);
    // Eventi:
    const removeEvents = Nearby.registerToEvents(
      // MESSAGE FOUND
      event => {
        console.log(event);
        setDevices(d => [...d, event]);
      },
      // MESSAGE LOST
      // ACTIVITY START
      () => setIsRunning(true),
      // ACTIVITY STOP
      () => setIsRunning(false),
    );

    return () => removeEvents();
  }, []);

  function onPressStart() {
    Nearby.start(deviceName);
    setIsRunning(true);
  }

  const onPressStop = () => {
    Nearby.stop();
    setDevices([]);
  };

  return (
    <SafeAreaView style={{flex: 1}}>
      <Text
        style={{
          fontSize: 30,
          backgroundColor: 'green',
          margin: 20,
          padding: 10,
        }}>
        Nome del dispositivo: {deviceName}
        App state: {appStateVisible}
      </Text>
      <View style={{marginVertical: 10}}>
        <Button
          title={isRunning ? 'Stop' : 'Start'}
          onPress={isRunning ? onPressStop : onPressStart}
        />
      </View>
      <ScrollView style={{marginTop: 60}}>
        {devices.map((x, i) => {
          return (
            <View key={i} style={{backgroundColor: 'blue', marginVertical: 10}}>
              <Text style={{fontSize: 30}}>{x}</Text>
            </View>
          );
        })}
      </ScrollView>
    </SafeAreaView>
  );
};

export default App;