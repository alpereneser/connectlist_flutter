import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://flsjfuxmhlsmsyfpswox.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsc2pmdXhtaGxzbXN5ZnBzd294Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2NjAzNzQsImV4cCI6MjA1NDIzNjM3NH0.cGL_09L47FDhFXbgHg7vZT44pX2rPirSHl8fMag0ltI'

export const supabase = createClient(supabaseUrl, supabaseKey)