/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React,{useState} from 'react';
import {NativeModules, NativeEventEmitter} from 'react-native';
import {
  SafeAreaView,
  Button,
  Text
} from 'react-native';

import {
  NearbyConfig,
  connect,
  disconnect,
  unsubscribe,
  subscribe,
  publish,
  startBackground,
  //removeListener,
  checkBluetoothPermission,
} from './Nearby.ts';


function App(): JSX.Element {

  const [messages, setMessages] = useState<any>([]);
  async function onStart() {
    try{
      const config : NearbyConfig = {
        "apiKey": 'AIzaSyCyw0Zkd-uA-NlF3Tk4DVVtBk7OvgA_E98',
      }
      const disconnect = await connect(config);
      const unsubscribe = await subscribe(
        (m) => {
          setMessages((s:any) => [...s,m]);
          console.log(`new message found: ${m}`);
          console.log(messages);
        },
        (m) => {
          console.log(`message lost: ${m}`);
        });
        console.log(await checkBluetoothPermission());
    }catch(e){
      console.log("ERRORE PERMESSI");
    }
  }
  async function onStop() {
    //removeListener();
    unsubscribe();
    disconnect();
  }
  async function onSend() {
    publish('Gabbo');
  }
  async function onBack() {
    startBackground();
  }
  return (
    <SafeAreaView style={{flex: 1}}>
      <Button title="Start Scanning" onPress={onStart} />
      <Button title='Stop' onPress={onStop}></Button>
      <Button title='Send' onPress={onSend}></Button>
      <Button title='Back' onPress={onBack}></Button>
      {messages.map((message:any) => <Text style={{color: 'white'}}>{message}</Text>)}
    </SafeAreaView>
  );
}


export default App;
