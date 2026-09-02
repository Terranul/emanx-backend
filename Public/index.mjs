document.getElementById("register-button").addEventListener("click", registerSubscription);

let worker;
let subscription;

async function initialize() {
    worker = await navigator.serviceWorker.register("sv.mjs", {
        type: "module"
    });

    subscription = await worker.pushManager.getSubscription();
}

async function createNewSubscription() {
    try {
        if (subscription == null) {
            subscription = await worker.pushManager.subscribe({
                applicationServerKey: await getVapidPublicKey(),
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
    console.log(subscription.options.applicationServerKey)
    const subscriptionStatusResponse = await fetch("/v1/subscribe", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "gmail": "Testing"
        },
        body: JSON.stringify({
            ...subscription.toJSON(),
            applicationServerKey: ""
        })
    });
}

initialize();