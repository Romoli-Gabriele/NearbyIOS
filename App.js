import React, {useRef, useEffect, useState} from 'react';
import {AppState, Button, SafeAreaView, View, Text, ScrollView} from 'react-native';
import Nearby from './Nearby';

import {getDeviceName} from 'react-native-device-info';

const App = () => {
  const [deviceName, setDeviceName] = useState('');
  const [devices, setDevices] = useState([]);
  const [isRunning, setIsRunning] = useState(false);

  useEffect(() => {
    Nearby.isActive().then(res => setIsRunning(res));
  }, []);

  useEffect(() =>{
    getDeviceName().then(setDeviceName);
    // Eventi:
    const removeEvents = Nearby.registerToEvents(
      // MESSAGE FOUND
      event => {
        console.log(event)
        if(event.contains("SPOTLIVE:")){
          event = event.replace("SPOTLIVE:","");
          if(!devices.includes(event) && event != ""){
            //mettere chiamata per vedere se esiste ancora il dispositivo o se è stato fermato
            setDevices(d => [...d, event]);
          }
        }
      },
      // MESSAGE LOST
      // ACTIVITY START
      () => setIsRunning(true),
      // ACTIVITY STOP
      () => setIsRunning(false),
    );

    return () => removeEvents();
  }, [devices]);

  function onPressStart() {
    Nearby.start();
    setIsRunning(true);
  }

  const onPressStop = () => {
    Nearby.stop();
    setIsRunning(false);
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