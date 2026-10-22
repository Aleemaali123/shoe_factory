export function createNoticeService(store) {
  return {
    list(device) {
      return store.noticesFor(device);
    },
    markAllRead(device) {
      store.markNoticesRead(device);
      return store.noticesFor(device);
    },
  };
}
