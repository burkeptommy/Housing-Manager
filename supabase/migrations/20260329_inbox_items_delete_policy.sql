-- Add missing DELETE policy for inbox_items.
-- Without this, RLS silently blocks deletes from the mobile app.
CREATE POLICY "Members can delete household inbox items"
    ON inbox_items FOR DELETE
    USING (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );
