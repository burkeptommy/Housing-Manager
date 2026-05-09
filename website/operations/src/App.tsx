import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { useEffect } from "react";
import { Sidebar } from "./components/chrome/Sidebar";
import { Topbar } from "./components/chrome/Topbar";
import { WorkspaceProvider, useWorkspace } from "./lib/workspace-context";
import OverviewScreen from "./screens/Overview";
import VisitsScreen from "./screens/Visits";
import VisitDetailScreen from "./screens/VisitDetail";
import CalendarScreen from "./screens/Calendar";
import RoutesScreen from "./screens/Routes";
import TasksScreen from "./screens/Tasks";
import CrewScreen from "./screens/Crew";
import HomesScreen from "./screens/Homes";
import HomeDetailScreen from "./screens/HomeDetail";
import QuotesScreen from "./screens/Quotes";
import InvoicesScreen from "./screens/Invoices";
import InvoiceDetailScreen from "./screens/InvoiceDetail";
import InvoicePrintScreen from "./screens/InvoicePrint";
import MessagesScreen from "./screens/Messages";
import SettingsScreen from "./screens/Settings";
import { CommandPalette } from "./components/CommandPalette";
import { NewQuoteModal, NewQuoteProvider, useNewQuoteModal } from "./components/NewQuoteModal";
import { NewInvoiceModal, NewInvoiceProvider } from "./components/NewInvoiceModal";
import { AddClientModal } from "./components/AddClientModal";
import { InviteTeammateSheet } from "./components/InviteTeammateSheet";

export default function App() {
  return (
    <WorkspaceProvider>
      <NewQuoteProvider>
        <NewInvoiceProvider>
          <MobileInterstitial />
          <Shell />
          <NewQuoteModal />
          <NewInvoiceModal />
          <AddClientModal />
          <InviteTeammateSheet />
          <CommandPalette />
        </NewInvoiceProvider>
      </NewQuoteProvider>
    </WorkspaceProvider>
  );
}

function Shell() {
  const { session, isLoading, mode } = useWorkspace();
  const location = useLocation();

  // Auth gate. If we're not loading and there's no session, kick the user
  // to the marketing/auth page. Preserve the deep link in `?next=` so a
  // post-login redirect can land them where they wanted to go.
  // The router base is `/operations`, so `location.pathname` here is the
  // path *inside* the SPA (e.g. `/homes/{id}`). handyman.js validates that
  // `next` starts with `/operations`, so we must prepend that prefix.
  useEffect(() => {
    if (!isLoading && !session) {
      const fullPath = `/operations${location.pathname}${location.search}`;
      const next = encodeURIComponent(fullPath);
      window.location.assign(`/handyman.html?next=${next}`);
    }
  }, [isLoading, session, location]);

  if (isLoading) {
    return (
      <div style={{ padding: 48, fontSize: 14, color: "var(--text-muted)" }}>
        Loading your workspace…
      </div>
    );
  }
  if (!session) return null;

  return (
    <div className={`ops-shell ${mode === "sole" ? "is-sole" : ""}`}>
      <Sidebar />
      <main className="ops-main">
        <Topbar />
        <div className="ops-content">
          <Routes>
            <Route path="/" element={<OverviewScreen />} />
            <Route path="/visits" element={<VisitsScreen />} />
            <Route path="/visits/:requestId" element={<VisitDetailScreen />} />
            <Route path="/dispatch" element={<Navigate to="/visits" replace />} />
            <Route path="/calendar" element={<CalendarScreen />} />
            <Route path="/routes" element={<RoutesScreen />} />
            <Route path="/tasks" element={<TasksScreen />} />
            <Route path="/crew" element={<CrewScreen />} />
            <Route path="/homes" element={<HomesScreen />} />
            <Route path="/homes/:propertyId" element={<HomeDetailScreen />} />
            <Route path="/quotes" element={<QuotesScreen />} />
            <Route path="/invoices" element={<InvoicesScreen />} />
            <Route path="/invoices/:invoiceId" element={<InvoiceDetailScreen />} />
            <Route path="/invoices/:invoiceId/print" element={<InvoicePrintScreen />} />
            <Route path="/messages" element={<MessagesScreen />} />
            <Route path="/settings" element={<SettingsScreen />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </main>
    </div>
  );
}

function MobileInterstitial() {
  return (
    <div className="ops-mobile-interstitial">
      <div className="ops-mobile-interstitial__title">
        Operations Desk is desktop-only
      </div>
      <p className="ops-mobile-interstitial__body">
        Open this page on a desktop or tablet to dispatch the field team.
        Install Chez Field on your iPhone for in-truck field work.
      </p>
      <a
        className="ops-mobile-interstitial__cta"
        href="https://testflight.apple.com/join/sw4xWsTA"
      >
        Get Chez Field on iOS
      </a>
    </div>
  );
}
