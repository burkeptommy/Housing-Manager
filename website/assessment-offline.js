/* Phase 84.5 G30 — IndexedDB persistence + sync queue for the field app.
 *
 * The handyman captures in basements, attics, and rural areas with poor
 * connectivity. Every edit lands in IndexedDB immediately. A sync queue
 * flushes via update_assessment_draft + add_recommended_task whenever
 * connection returns. Submit (`submit_assessment_data`) is blocked until
 * the queue is empty.
 */
(function (global) {
  'use strict';

  const DB_NAME = 'haven_assessment_offline';
  const DB_VERSION = 1;
  const STORE_DRAFTS = 'drafts';      // captured_* JSONB blob keyed by assessment_id
  const STORE_QUEUE = 'sync_queue';   // pending edge-function calls
  const STORE_RECS = 'recommended_tasks'; // pending recommendation rows

  let dbPromise = null;

  function openDb() {
    if (dbPromise) return dbPromise;
    dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = (e) => {
        const db = e.target.result;
        if (!db.objectStoreNames.contains(STORE_DRAFTS)) {
          db.createObjectStore(STORE_DRAFTS, { keyPath: 'assessment_id' });
        }
        if (!db.objectStoreNames.contains(STORE_QUEUE)) {
          db.createObjectStore(STORE_QUEUE, { keyPath: 'id', autoIncrement: true });
        }
        if (!db.objectStoreNames.contains(STORE_RECS)) {
          db.createObjectStore(STORE_RECS, { keyPath: 'local_id' });
        }
      };
      req.onsuccess = (e) => resolve(e.target.result);
      req.onerror = () => reject(req.error);
    });
    return dbPromise;
  }

  function tx(storeName, mode) {
    return openDb().then((db) => db.transaction(storeName, mode).objectStore(storeName));
  }

  // ============================================================
  // Draft persistence — local mirror of home_assessments.captured_*
  // ============================================================

  global.assessmentSaveDraft = async function (assessmentId, deltas) {
    const store = await tx(STORE_DRAFTS, 'readwrite');
    return new Promise((resolve, reject) => {
      const getReq = store.get(assessmentId);
      getReq.onsuccess = () => {
        const existing = getReq.result || { assessment_id: assessmentId };
        const merged = Object.assign({}, existing, deltas);
        merged.assessment_id = assessmentId;
        merged.updated_at = new Date().toISOString();
        const putReq = store.put(merged);
        putReq.onsuccess = () => resolve(merged);
        putReq.onerror = () => reject(putReq.error);
      };
      getReq.onerror = () => reject(getReq.error);
    });
  };

  global.assessmentLoadDraft = async function (assessmentId) {
    const store = await tx(STORE_DRAFTS, 'readonly');
    return new Promise((resolve, reject) => {
      const req = store.get(assessmentId);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
  };

  // ============================================================
  // Sync queue — flush pending edge-function calls
  // ============================================================

  global.assessmentEnqueueSync = async function (action, body) {
    const store = await tx(STORE_QUEUE, 'readwrite');
    return new Promise((resolve, reject) => {
      const req = store.add({
        action,
        body,
        attempts: 0,
        enqueued_at: new Date().toISOString(),
      });
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  };

  global.assessmentSyncQueueLength = async function () {
    const store = await tx(STORE_QUEUE, 'readonly');
    return new Promise((resolve, reject) => {
      const req = store.count();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  };

  /**
   * Flush all queued items via the provided POST function.
   * `postFn(action, body)` should call the handyman-provider edge function
   * and return a Promise that resolves on success.
   */
  global.assessmentFlushSyncQueue = async function (postFn) {
    const store = await tx(STORE_QUEUE, 'readwrite');
    return new Promise((resolve) => {
      const items = [];
      const cursorReq = store.openCursor();
      cursorReq.onsuccess = (e) => {
        const cursor = e.target.result;
        if (cursor) {
          items.push({ id: cursor.primaryKey, ...cursor.value });
          cursor.continue();
        } else {
          resolve(items);
        }
      };
      cursorReq.onerror = () => resolve([]);
    }).then(async (items) => {
      let flushed = 0;
      for (const item of items) {
        try {
          await postFn(item.action, item.body);
          // delete on success
          const delStore = await tx(STORE_QUEUE, 'readwrite');
          delStore.delete(item.id);
          flushed += 1;
        } catch (e) {
          // Increment attempts. After 5 failures, mark dead — admin can
          // inspect via debug. For now leave in queue.
          const upStore = await tx(STORE_QUEUE, 'readwrite');
          upStore.put({
            id: item.id,
            action: item.action,
            body: item.body,
            attempts: (item.attempts || 0) + 1,
            enqueued_at: item.enqueued_at,
            last_error: e.message || String(e),
          });
        }
      }
      return flushed;
    });
  };

  // ============================================================
  // Recommended-task local cache (so wrap-up screen has them all
  // available even if the server insert hasn't synced yet)
  // ============================================================

  global.assessmentSaveRecommendedTaskLocal = async function (rec) {
    const store = await tx(STORE_RECS, 'readwrite');
    if (!rec.local_id) {
      rec.local_id = 'local_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8);
    }
    rec.updated_at = new Date().toISOString();
    return new Promise((resolve, reject) => {
      const req = store.put(rec);
      req.onsuccess = () => resolve(rec);
      req.onerror = () => reject(req.error);
    });
  };

  global.assessmentLoadRecommendedTasks = async function (assessmentId) {
    const store = await tx(STORE_RECS, 'readonly');
    return new Promise((resolve) => {
      const out = [];
      const cursorReq = store.openCursor();
      cursorReq.onsuccess = (e) => {
        const cursor = e.target.result;
        if (cursor) {
          if (cursor.value.assessment_id === assessmentId) {
            out.push(cursor.value);
          }
          cursor.continue();
        } else {
          resolve(out);
        }
      };
      cursorReq.onerror = () => resolve([]);
    });
  };

  // ============================================================
  // Auto-flush on connection return
  // ============================================================

  global.assessmentInstallOnlineFlush = function (postFn, onFlushed) {
    window.addEventListener('online', async () => {
      console.log('[assessment-offline] Connection returned — flushing queue.');
      const flushed = await global.assessmentFlushSyncQueue(postFn);
      if (flushed > 0 && onFlushed) onFlushed(flushed);
    });
  };
})(window);
