import * as functions from 'firebase-functions';

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

import * as admin from 'firebase-admin';

admin.initializeApp();

//const db = admin.firestore();
const fcm = admin.messaging();


export const sendMessage = functions.firestore
    .document('messages/{messagesId}')
    .onCreate(async snapshot => {
        const message = snapshot.data();
        const payload: admin.messaging.MessagingPayload = {
            notification: {
                title: message["author"],
                body: message["text"],
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
            }
        };

        return fcm.sendToDevice(message['receiver'], payload);
    });