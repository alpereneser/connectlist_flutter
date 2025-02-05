-- Create messages table
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE,
  deleted_by UUID[] DEFAULT ARRAY[]::UUID[],
  FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (receiver_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Enable realtime after table creation
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Create messages_participants view for easier querying
CREATE VIEW messages_participants AS
WITH latest_message AS (
  SELECT DISTINCT ON (
    LEAST(sender_id, receiver_id),
    GREATEST(sender_id, receiver_id)
  )
    id,
    sender_id,
    receiver_id,
    content,
    created_at,
    is_read,
    deleted_by
  FROM messages
  ORDER BY 
    LEAST(sender_id, receiver_id),
    GREATEST(sender_id, receiver_id),
    created_at DESC
)
SELECT 
  m.*,
  s.username as sender_username,
  s.full_name as sender_full_name,
  s.avatar_url as sender_avatar_url,
  r.username as receiver_username,
  r.full_name as receiver_full_name,
  r.avatar_url as receiver_avatar_url
FROM latest_message m
JOIN profiles s ON m.sender_id = s.id
JOIN profiles r ON m.receiver_id = r.id;

-- Create function to get unread messages count
CREATE OR REPLACE FUNCTION get_unread_messages_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM messages
    WHERE 
      receiver_id = user_id 
      AND is_read = false
      AND NOT (user_id = ANY(deleted_by))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RLS policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policy for inserting messages
CREATE POLICY "Users can insert messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Policy for viewing messages
CREATE POLICY "Users can view their own messages" ON messages
  FOR SELECT USING (
    auth.uid() IN (sender_id, receiver_id)
    AND NOT (auth.uid() = ANY(deleted_by))
  );

-- Policy for updating messages (marking as read)
CREATE POLICY "Users can update their received messages" ON messages
  FOR UPDATE USING (
    auth.uid() = receiver_id
    AND NOT (auth.uid() = ANY(deleted_by))
  )
  WITH CHECK (
    auth.uid() = receiver_id
    AND NOT (auth.uid() = ANY(deleted_by))
  );

-- Policy for deleting messages (soft delete)
CREATE POLICY "Users can soft delete their messages" ON messages
  FOR UPDATE USING (
    auth.uid() IN (sender_id, receiver_id)
    AND NOT (auth.uid() = ANY(deleted_by))
  )
  WITH CHECK (
    auth.uid() IN (sender_id, receiver_id)
    AND NOT (auth.uid() = ANY(deleted_by))
  );

-- Create function to soft delete messages
CREATE OR REPLACE FUNCTION soft_delete_message(message_id UUID, user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE messages
  SET deleted_by = array_append(deleted_by, user_id)
  WHERE id = message_id
  AND user_id IN (sender_id, receiver_id)
  AND NOT (user_id = ANY(deleted_by));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
