-- Family events table for calendar sync and email-parsed events
CREATE TABLE family_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  all_day BOOLEAN DEFAULT false,
  location TEXT,
  notes TEXT,
  -- Calendar sync fields
  source TEXT NOT NULL DEFAULT 'manual', -- 'ios_calendar', 'email_invite', 'email_parsed', 'manual'
  external_calendar_id TEXT, -- iOS calendar identifier (EKCalendar.calendarIdentifier)
  external_event_id TEXT, -- iOS event identifier (EKEvent.eventIdentifier)
  -- Email source tracking
  source_inbox_item_id UUID REFERENCES inbox_items(id) ON DELETE SET NULL,
  -- Family member associations
  tagged_member_ids UUID[] DEFAULT '{}',
  -- Metadata
  recurrence_rule TEXT, -- iCal RRULE string for recurring events
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_family_events_household ON family_events(household_id);
CREATE INDEX idx_family_events_dates ON family_events(household_id, start_date) WHERE start_date IS NOT NULL;
CREATE INDEX idx_family_events_external ON family_events(household_id, external_calendar_id, external_event_id);

-- RLS
ALTER TABLE family_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their household events"
  ON family_events FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert events for their household"
  ON family_events FOR INSERT
  WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update their household events"
  ON family_events FOR UPDATE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete their household events"
  ON family_events FOR DELETE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- Synced calendars table — tracks which iOS calendars a user has linked
CREATE TABLE synced_calendars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  calendar_identifier TEXT NOT NULL, -- EKCalendar.calendarIdentifier
  calendar_title TEXT NOT NULL,
  calendar_color TEXT, -- hex color from iOS
  is_active BOOLEAN DEFAULT true, -- user can pause sync without removing
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(household_id, user_id, calendar_identifier)
);

ALTER TABLE synced_calendars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their synced calendars"
  ON synced_calendars FOR ALL
  USING (user_id = auth.uid());
