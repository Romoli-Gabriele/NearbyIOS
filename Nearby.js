import {
  NativeModules,
  Platform,
  PermissionsAndroid,
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
    NativeModules.MyNativeModule.start();
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

/**
 * Verifica se il servizizio di pubblicazione/scanning è attivo
 * @returns Restituisce una promessa
 */
const isActive = () => {
  return new Promise((resolve, reject) => {
    if (isAndroid) {
      NativeModules.MyNativeModule.isActivityRunning(res => {
        resolve(res);
      });
    } else {
      resolve(false);
    }
  });
};

const registerToEvents = (
  onMessageFound,
  onActivityStart,
  onActivityStop,
) => {
  const emitters = [];

  let eventEmitter;
  if (isAndroid) {
    eventEmitter = new NativeEventEmitter()
    emitters.push(
      eventEmitter.addListener('onMessageFound', onMessageFound),
    );
  } else if (isIos) {
    eventEmitter = new NativeEventEmitter(NativeModules.GoogleNearbyMessages)
    emitters.push(
      eventEmitter.addListener('deviceFound', onMessageFound),
    );
    emitters.push(
      eventEmitter.addListener('onActivityStart', onActivityStart),
      eventEmitter.addListener('onActivityStop', onActivityStop),
    );
  }


  return () => {
    emitters.forEach(emitter => emitter.remove());
  };
}

export default {
  start,
  stop,
  isActive,
  registerToEvents,
};