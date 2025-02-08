-- Create lists table
create table public.lists (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    description text,
    category text not null,
    items jsonb not null default '[]'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    user_id uuid references auth.users not null,
    comments_count integer default 0,
    likes_count integer default 0,
    saves_count integer default 0
);

-- Set up RLS (Row Level Security)
alter table public.lists enable row level security;

-- Create policies
create policy "Users can view all lists"
    on public.lists for select
    to authenticated
    using (true);

create policy "Users can create their own lists"
    on public.lists for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "Users can update their own lists"
    on public.lists for update
    to authenticated
    using (auth.uid() = user_id);

create policy "Users can delete their own lists"
    on public.lists for delete
    to authenticated
    using (auth.uid() = user_id);

-- Create indexes
create index lists_user_id_idx on public.lists(user_id);
create index lists_category_idx on public.lists(category);
create index lists_created_at_idx on public.lists(created_at desc);
