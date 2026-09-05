//document.getElementById("register-button").addEventListener("click", registerSubscription);

window.onload = function () {

    google.accounts.id.initialize({
        client_id: "902542881032-o3dv7vu8ksd8sub5cjrloknjs6rmbcpa.apps.googleusercontent.com",
        callback: handleGoogleLogin
    });

    google.accounts.id.renderButton(
        document.getElementById("google-signin-button"),
        {
            theme: "outline",
            size: "large"
        }
    );
};

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

async function registerSubscription(email) {
    await createNewSubscription();
    console.log(subscription.toJSON())
    console.log("Server key:" + subscription.options.applicationServerKey)
    console.log(curVapidKey)
    const subscriptionStatusResponse = await fetch(`/v1/subscribe/${email}`, {
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

async function handleGoogleLogin(response) {
    const credential = response.credential;
    const payload = credential.split(".")[1];
    const decoded = JSON.parse(
        atob(
            payload
                .replace(/-/g, "+")
                .replace(/_/g, "/"))
    );
    let email = decoded.email
    console.log(email)
    await registerSubscription(email)
}

initialize();