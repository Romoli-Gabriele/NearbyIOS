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
const start = message => {
  if (isAndroid) {
    NativeModules.MyNativeModule.start();
    NativeModules.MyNativeModule.startActivity(message);
  } else if (isIos) {
    NativeModules.GoogleNearbyMessages.subscribe();
    NativeModules.GoogleNearbyMessages.publish(message);
  }
};

/**
 * Interrompe l'attività di pubblicazione e scanning
 */
const stop = () => {
  if (isAndroid) NativeModules.MyNativeModule.stop();
  else if (isIos) {
    NativeModules.GoogleNearbyMessages.stop();
    console.log("Disconnetti");
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

/**
 * Inizzializza nearby e i permessi
 */
const init = () => {
  if (isAndroid) {
    return new Promise(resolve => {
      PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
        PermissionsAndroid.PERMISSIONS.ACCESS_BACKGROUND_LOCATION,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE,
        PermissionsAndroid.PERMISSIONS.NEARBY_WIFI_DEVICES,
      ]).then(result => {
        const isGranted =
          result['android.permission.BLUETOOTH_CONNECT'] ===
          PermissionsAndroid.RESULTS.GRANTED &&
          result['android.permission.BLUETOOTH_SCAN'] ===
          PermissionsAndroid.RESULTS.GRANTED &&
          result['android.permission.ACCESS_FINE_LOCATION'] ===
          PermissionsAndroid.RESULTS.GRANTED;

        console.log({
          isGranted
        });

        NativeModules.MyNativeModule.initNearby(isPlayServicesAvailable => {
          console.log({
            isPlayServicesAvailable
          });
          if (isPlayServicesAvailable) {
            resolve(true);
            return;
          } else {
            resolve(false);
          }
        });
      });
    });
  } else if (isIos) {
    return new Promise(resolve => {
      const apiKey = 'AIzaSyCyw0Zkd-uA-NlF3Tk4DVVtBk7OvgA_E98';
      const discoveryModes = ['broadcast', 'scan'];
      const discoveryMediums = ['ble'];
      try {
        NativeModules.GoogleNearbyMessages.connect(apiKey, discoveryModes, discoveryMediums);
        NativeModules.GoogleNearbyMessages.subscribe();
        resolve(true)
      } catch (error) {
        resolve(false);
      }
    })
  }
};

const registerToEvents = (
  onMessageFound,
  onMessageLost,
  onActivityStart,
  onActivityStop,
) => {
  const emitters = [];

  let eventEmitter;
  if (isAndroid) {
    eventEmitter = new NativeEventEmitter()
    emitters.push(
      eventEmitter.addListener('onMessageFound', onMessageFound),
      eventEmitter.addListener('onMessageLost', onMessageLost),
    );
  } else if (isIos) {
    eventEmitter = new NativeEventEmitter(NativeModules.GoogleNearbyMessages)
    emitters.push(
      eventEmitter.addListener('MESSAGE_FOUND', onMessageFound),
      eventEmitter.addListener('MESSAGE_LOST', onMessageLost),
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

const background = message => {
  if (isIos) {
    NativeModules.GoogleNearbyMessages.unsubscribe();
    NativeModules.GoogleNearbyMessages.backgroundHandler(message);
  }
}

const stopBackground = (message)=>{
  if(isIos){
    NativeModules.GoogleNearbyMessages.stopBackground();
    NativeModules.GoogleNearbyMessages.subscribe();
    NativeModules.GoogleNearbyMessages.publish(message);
  }
}

export default {
  init,
  start,
  stop,
  isActive,
  registerToEvents,
  background,
  stopBackground,
};