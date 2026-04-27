import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Built artifact lives at /operations/ behind nginx. The base path is
// critical so all hashed asset URLs in the manifest resolve correctly.
export default defineConfig({
  base: "/operations/",
  plugins: [react()],
  build: {
    outDir: "dist",
    sourcemap: true,
    target: "es2020",
  },
  server: {
    port: 5173,
    // Proxy /handyman.html (and the rest of the static site) to whatever
    // serves the marketing pages locally. For most local-dev usage,
    // running `python3 -m http.server 8000` from `website/` and visiting
    // `localhost:5173/operations/` is sufficient — this proxy is for
    // when you also want to test the full auth flow.
    proxy: {
      "^/(handyman|handymen|handyman-quote|handyman-visit|index|chez|styles|verify|terms|privacy|security)\\.(html|css|js)$": {
        target: "http://localhost:8000",
        changeOrigin: true,
      },
      "^/(favicon|chez-logo|chez-handyman-logo|og-image)\\.(svg|png)$": {
        target: "http://localhost:8000",
        changeOrigin: true,
      },
    },
  },
});
