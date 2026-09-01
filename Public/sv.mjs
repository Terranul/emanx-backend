self.addEventListener('push', function(event) {
    const data = event.data?.json() ?? {};
    event.waitUntil((async () => {
        const notification = data?.notification ?? {}
        const title = notification.title ?? "Your App Name";
        const body = notification.body ?? "New Content Available!";
        
        await self.registration.showNotification(title, { 
            body,
            requireInteraction: notification.require_interaction ?? false,
            ...notification,
        });
    })());
});