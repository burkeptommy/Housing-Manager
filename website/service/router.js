// router.js — tiny hash router for the Chez service portal.
//
// Contract (SERVICE_PORTAL_CONTRACT.md):
//   start(routes, notFound)  — routes: [{ pattern: "#/case/:id", enter(params), leave() }]
//   navigate(hash)           — sets location.hash
//   currentRoute()           — { pattern, params, hash } | null
//
// Default route is #/today (an empty hash is rewritten via replaceState so
// the back button doesn't collect a junk entry). The ?case=<id> boot shim is
// applied by main.js BEFORE start() so the initial dispatch already sees the
// translated hash.

let table = [];
let notFoundFn = null;
let active = null; // { route, params, hash }
let listening = false;

function compile(pattern) {
  const names = [];
  const source = pattern
    .split("/")
    .map((seg) => {
      if (seg.startsWith(":")) {
        names.push(seg.slice(1));
        return "([^/]+)";
      }
      return seg.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    })
    .join("/");
  return { rx: new RegExp(`^${source}$`), names };
}

export function start(routes, notFound) {
  table = (routes || []).map((r) => ({ ...r, ...compile(r.pattern) }));
  notFoundFn = typeof notFound === "function" ? notFound : null;
  if (!listening) {
    listening = true;
    window.addEventListener("hashchange", handleChange);
  }
  if (!location.hash) {
    history.replaceState(null, "", `${location.pathname}${location.search}#/today`);
  }
  handleChange();
}

export function navigate(hash) {
  if (location.hash === hash) return;
  location.hash = hash;
}

export function currentRoute() {
  return active
    ? { pattern: active.route.pattern, params: { ...active.params }, hash: active.hash }
    : null;
}

function handleChange() {
  const hash = location.hash || "#/today";
  if (active && active.hash === hash) return;

  let matched = null;
  let params = null;
  for (const route of table) {
    const m = hash.match(route.rx);
    if (m) {
      matched = route;
      params = {};
      route.names.forEach((name, i) => {
        try {
          params[name] = decodeURIComponent(m[i + 1]);
        } catch {
          params[name] = m[i + 1];
        }
      });
      break;
    }
  }

  if (active) {
    try {
      active.route.leave?.();
    } catch (err) {
      console.error("[router] leave() failed", err);
    }
    active = null;
  }

  if (!matched) {
    if (notFoundFn) notFoundFn(hash);
    return;
  }

  active = { route: matched, params, hash };
  try {
    const out = matched.enter?.(params);
    if (out && typeof out.catch === "function") {
      out.catch((err) => console.error("[router] enter() failed", err));
    }
  } catch (err) {
    console.error("[router] enter() failed", err);
  }
}
