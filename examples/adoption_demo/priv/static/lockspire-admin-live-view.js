(() => {
  if (window.liveSocket || !window.Phoenix?.Socket || !window.LiveView?.LiveSocket) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (!csrfToken) return;

  const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
    params: { _csrf_token: csrfToken }
  });

  liveSocket.connect();
  window.liveSocket = liveSocket;
})();
