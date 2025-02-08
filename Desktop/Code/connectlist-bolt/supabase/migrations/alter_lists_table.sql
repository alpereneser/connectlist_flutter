-- Add new columns to lists table if they don't exist
DO $$ 
BEGIN 
    -- Add category column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lists' AND column_name = 'category') THEN
        ALTER TABLE public.lists ADD COLUMN category text;
    END IF;

    -- Add items column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lists' AND column_name = 'items') THEN
        ALTER TABLE public.lists ADD COLUMN items jsonb DEFAULT '[]'::jsonb;
    END IF;

    -- Add comments_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lists' AND column_name = 'comments_count') THEN
        ALTER TABLE public.lists ADD COLUMN comments_count integer DEFAULT 0;
    END IF;

    -- Add likes_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lists' AND column_name = 'likes_count') THEN
        ALTER TABLE public.lists ADD COLUMN likes_count integer DEFAULT 0;
    END IF;

    -- Add saves_count if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lists' AND column_name = 'saves_count') THEN
        ALTER TABLE public.lists ADD COLUMN saves_count integer DEFAULT 0;
    END IF;
END $$;

-- Create indexes if they don't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'lists_category_idx') THEN
        CREATE INDEX lists_category_idx ON public.lists(category);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'lists_created_at_idx') THEN
        CREATE INDEX lists_created_at_idx ON public.lists(created_at DESC);
    END IF;
END $$;
