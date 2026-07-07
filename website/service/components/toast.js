// components/toast.js — transient feedback for the Chez service portal.
//
// Contract: toast(message, kind = "info") with kind info | success | error.
// Auto-dismisses after 3 seconds. Stacks bottom-right.

let host = null;

export function toast(message, kind = "info") {
  if (!host || !host.isConnected) {
    host = document.createElement("div");
    host.className = "svc-toasts";
    document.body.appendChild(host);
  }
  const el = document.createElement("div");
  el.className = `svc-toast svc-toast--${kind}`;
  el.setAttribute("role", "status");
  el.textContent = String(message ?? "");
  host.appendChild(el);

  requestAnimationFrame(() => el.classList.add("is-in"));
  setTimeout(() => {
    el.classList.remove("is-in");
    el.classList.add("is-out");
    setTimeout(() => el.remove(), 260);
  }, 3000);
  return el;
}
