-- Phase 67: Handyman visit bundle children.
--
-- No schema changes. The ~20 new child templates in MaintenanceTemplates.swift
-- are materialized at task-creation time by MaintenanceTaskReconciler.reconcile
-- — bundle parents AND bundle children now both land as maintenance_tasks
-- rows, with children carrying the child's own templateId and assigned_route
-- defaulting to "handyman".
--
-- For existing TestFlight users whose Handyman:spring / Handyman:fall parent
-- tasks were created BEFORE this phase (children-as-prose-only), a Swift-side
-- one-time migration — `MaintenanceTaskReconciler.materializeHandymanBundleChildrenOnceIfNeeded`
-- — walks every property and creates the missing child rows.
--
-- Gated via UserDefaults `hasRunPhase67BundleChildBackfill_v1` so it only runs
-- once per install. Idempotent: the reconciler's templateKey-based dedup
-- short-circuits if a child already exists. Safe to re-run.
--
-- This SQL file exists as the marker for the migration sequence.

SELECT 1 AS phase_67_applied;
