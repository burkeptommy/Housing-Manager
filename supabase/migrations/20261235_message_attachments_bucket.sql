-- Wave T: storage bucket for inline photo attachments on
-- handyman_request_messages. Path convention enforced by the
-- upload_message_attachment edge function action:
--   <household_id>/<request_id>/<random>.<ext>
--
-- Bucket is private. Reads happen via signed URL minted on upload
-- and re-minted by the messages reader (homeowner iOS, contractor SPA)
-- each time the thread is fetched. We don't need bucket-level RLS for
-- read because the path is opaque and the signed URL is bounded.
-- Service role can write under any prefix; contractor and homeowner
-- both go through edge function helpers that already gate workspace +
-- request access.

INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Service role policy is implicit. We don't expose authenticated-role
-- policies — uploads always flow through the edge function which uses
-- service role to upload after asserting workspace access on the
-- calling user.
