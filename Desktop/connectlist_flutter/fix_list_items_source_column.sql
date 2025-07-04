-- Migration to add missing 'source' column to list_items table
-- This fixes the error: Could not find the 'source' column of 'list_items' in the schema cache

-- Add the source column to track where content items come from
ALTER TABLE public.list_items 
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';

-- Add a comment to explain the column
COMMENT ON COLUMN public.list_items.source IS 'Source of the content item: tmdb, rawg, google_books, yandex_places, or manual';

-- Create an index for better performance when querying by source
CREATE INDEX IF NOT EXISTS idx_list_items_source ON public.list_items(source);

-- Update any existing records to have 'manual' as default source
UPDATE public.list_items 
SET source = 'manual' 
WHERE source IS NULL;

-- Verify the column exists
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'list_items' AND column_name = 'source';