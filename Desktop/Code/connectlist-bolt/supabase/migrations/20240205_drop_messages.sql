-- Drop existing objects
DROP FUNCTION IF EXISTS soft_delete_message;
DROP FUNCTION IF EXISTS get_unread_messages_count;
DROP VIEW IF EXISTS messages_participants;
DROP TABLE IF EXISTS messages CASCADE;

-- Remove from realtime publication if table exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE messages;
  END IF;
END $$;
