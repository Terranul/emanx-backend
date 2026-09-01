let worker = await navigator.serviceWorker.register("sv.mjs", { type: "module" })
let subscription = await registration?.pushManager?.getSubscription();

async function createNewSubscription() {
    try {
        if (subscription == null) {
            // register for the first time
            worker.pushManager.subscribe({ applicationServerKey: await getVapidPublicKey(), userVisibleOnly: true })

        }
    } catch {

    }
}

async function getVapidPublicKey() {
    let result = await fetch("https://emanx-backend.onrender.com/vapidKey", {
        headers: {
            "Content-Type": "application/json"
        }
    })
    let json = await result.json()
    return json.vapid
}

async function registerSubscription() {
    
}
