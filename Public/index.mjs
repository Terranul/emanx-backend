document.getElementById("register-button").addEventListener("click", registerSubscription);

let worker;
let subscription;
let curVapidKey;

async function initialize() {
    worker = await navigator.serviceWorker.register("sv.mjs", {
        type: "module"
    });
    await createNewSubscription()

    subscription = await worker.pushManager.getSubscription();
}

async function createNewSubscription() {
    try {
        if (subscription == null) {
            curVapidKey = await getVapidPublicKey()
            console.log("curVapidKey" + curVapidKey)
            subscription = await worker.pushManager.subscribe({
                applicationServerKey: curVapidKey,
                userVisibleOnly: true
            }); 
        }
    } catch (error) {
        console.error(error);
    }
}

async function getVapidPublicKey() {
    const result = await fetch("/v1/vapidKey", {
        headers: {
            "Content-Type": "application/json"
        }
    });

    const json = await result.json();
    return json.vapid;
}

async function registerSubscription() {
    await createNewSubscription();
    console.log(subscription.toJSON())
    console.log("Server key:" + subscription.options.applicationServerKey)
    console.log(curVapidKey)
    const subscriptionStatusResponse = await fetch("/v1/subscribe/testing", {
        method: "PUT",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            ...subscription.toJSON(),
            applicationServerKey: curVapidKey
        })
    });
}

function onSignIn(googleUser) {
  var profile = googleUser.getBasicProfile();
  console.log('ID: ' + profile.getId()); // Do not send to your backend! Use an ID token instead.
  console.log('Name: ' + profile.getName());
  console.log('Image URL: ' + profile.getImageUrl());
  console.log('Email: ' + profile.getEmail()); // This is null if the 'email' scope is not present.
}

initialize();