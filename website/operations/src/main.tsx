import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles/operations.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    {/*
      Vite's `base: "/operations/"` config means every hashed asset URL
      lives under /operations/. React Router's basename mirrors that so
      `/operations/dispatch` becomes the relative `/dispatch` route
      inside the app.
    */}
    <BrowserRouter basename="/operations">
      <App />
    </BrowserRouter>
  </React.StrictMode>
);
