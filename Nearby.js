import {
  NativeModules,
  Platform,
  NativeEventEmitter,
} from 'react-native';

const isAndroid = Platform.OS == 'android'
const isIos = Platform.OS == "ios";


/**
 * Inizia la pubblicazione (anche in background per Android) e lo scanning dei messaggi
 * @param {string} message
 */
const start = () => {
  if (isAndroid) {
    NativeModules.MyNativeModule.start("Hello World");
  } else if (isIos) {
    NativeModules.GoogleNearbyMessages.start();
  }
};

/**
 * Interrompe l'attività di pubblicazione e scanning
 */
const stop = () => {
  if (isAndroid) NativeModules.MyNativeModule.stop();
  else if (isIos) {
    NativeModules.GoogleNearbyMessages.stop();
  }
};

const registerToEvents = (
  onMessageFound,
) => {
  const emitters = [];

  let eventEmitter;
  if (isAndroid) {
    eventEmitter = new NativeEventEmitter(MyNativeModule)
    emitters.push(
      eventEmitter.addListener('onMessageFound', onMessageFound),
    );
  } else if (isIos) {
    eventEmitter = new NativeEventEmitter(NativeModules.GoogleNearbyMessages)
    emitters.push(
      eventEmitter.addListener('deviceFound', onMessageFound),
    );
  }


  return () => {
    emitters.forEach(emitter => emitter.remove());
  };
}

export default {
  start,
  stop,
  registerToEvents,
};