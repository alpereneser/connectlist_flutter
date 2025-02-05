export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          role: string
          username: string
          full_name: string | null
          avatar_url: string | null
          website: string | null
          location: string | null
          bio: string | null
          referral_code: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          role?: string
          username: string
          full_name?: string | null
          avatar_url?: string | null
          website?: string | null
          location?: string | null
          bio?: string | null
          referral_code: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          role?: string
          username?: string
          full_name?: string | null
          avatar_url?: string | null
          website?: string | null
          location?: string | null
          bio?: string | null
          referral_code?: string
          created_at?: string
          updated_at?: string
        }
      }
      roles: {
        Row: {
          id: string
          description: string
          created_at: string
        }
        Insert: {
          id: string
          description: string
          created_at?: string
        }
        Update: {
          id?: string
          description?: string
          created_at?: string
        }
      }
      referral_codes: {
        Row: {
          code: string
          used_by: string | null
          used_at: string | null
          created_at: string
        }
        Insert: {
          code: string
          used_by?: string | null
          used_at?: string | null
          created_at?: string
        }
        Update: {
          code?: string
          used_by?: string | null
          used_at?: string | null
          created_at?: string
        }
      }
      books: {
        Row: {
          id: string
          title: string
          original_title: string | null
          description: string | null
          isbn: string | null
          publication_date: string | null
          publisher: string | null
          genres: string[]
          language: string | null
          page_count: number | null
          cover_image_url: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          original_title?: string | null
          description?: string | null
          isbn?: string | null
          publication_date?: string | null
          publisher?: string | null
          genres?: string[]
          language?: string | null
          page_count?: number | null
          cover_image_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          original_title?: string | null
          description?: string | null
          isbn?: string | null
          publication_date?: string | null
          publisher?: string | null
          genres?: string[]
          language?: string | null
          page_count?: number | null
          cover_image_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      companies: {
        Row: {
          id: string
          name: string
          description: string | null
          founding_date: string | null
          website: string | null
          headquarters_address: string | null
          logo_url: string | null
          company_type: string[]
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          founding_date?: string | null
          website?: string | null
          headquarters_address?: string | null
          logo_url?: string | null
          company_type?: string[]
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          founding_date?: string | null
          website?: string | null
          headquarters_address?: string | null
          logo_url?: string | null
          company_type?: string[]
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      games: {
        Row: {
          id: string
          title: string
          description: string | null
          release_date: string | null
          genres: string[]
          platforms: string[]
          developer: string | null
          publisher: string | null
          website: string | null
          cover_image_url: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          description?: string | null
          release_date?: string | null
          genres?: string[]
          platforms?: string[]
          developer?: string | null
          publisher?: string | null
          website?: string | null
          cover_image_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          description?: string | null
          release_date?: string | null
          genres?: string[]
          platforms?: string[]
          developer?: string | null
          publisher?: string | null
          website?: string | null
          cover_image_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      movies: {
        Row: {
          id: string
          title: string
          original_title: string | null
          tagline: string | null
          overview: string | null
          release_date: string | null
          runtime: number | null
          budget: number | null
          revenue: number | null
          genres: string[]
          poster_path: string | null
          backdrop_path: string | null
          tmdb_id: number | null
          imdb_id: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          original_title?: string | null
          tagline?: string | null
          overview?: string | null
          release_date?: string | null
          runtime?: number | null
          budget?: number | null
          revenue?: number | null
          genres?: string[]
          poster_path?: string | null
          backdrop_path?: string | null
          tmdb_id?: number | null
          imdb_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          original_title?: string | null
          tagline?: string | null
          overview?: string | null
          release_date?: string | null
          runtime?: number | null
          budget?: number | null
          revenue?: number | null
          genres?: string[]
          poster_path?: string | null
          backdrop_path?: string | null
          tmdb_id?: number | null
          imdb_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      musics: {
        Row: {
          id: string
          title: string
          album: string | null
          release_date: string | null
          duration: { minutes: number; seconds: number } | null
          genres: string[]
          lyrics: string | null
          cover_art_url: string | null
          spotify_id: string | null
          apple_music_id: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          album?: string | null
          release_date?: string | null
          duration?: { minutes: number; seconds: number } | null
          genres?: string[]
          lyrics?: string | null
          cover_art_url?: string | null
          spotify_id?: string | null
          apple_music_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          album?: string | null
          release_date?: string | null
          duration?: { minutes: number; seconds: number } | null
          genres?: string[]
          lyrics?: string | null
          cover_art_url?: string | null
          spotify_id?: string | null
          apple_music_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      people: {
        Row: {
          id: string
          full_name: string
          biography: string | null
          birth_date: string | null
          death_date: string | null
          nationality: string | null
          website: string | null
          social_media: Json | null
          profile_image_url: string | null
          content_types: string[]
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          full_name: string
          biography?: string | null
          birth_date?: string | null
          death_date?: string | null
          nationality?: string | null
          website?: string | null
          social_media?: Json | null
          profile_image_url?: string | null
          content_types?: string[]
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          full_name?: string
          biography?: string | null
          birth_date?: string | null
          death_date?: string | null
          nationality?: string | null
          website?: string | null
          social_media?: Json | null
          profile_image_url?: string | null
          content_types?: string[]
          created_at?: string
          updated_at?: string
        }
      }
      places: {
        Row: {
          id: string
          name: string
          description: string | null
          address: string | null
          city: string | null
          country: string | null
          latitude: number | null
          longitude: number | null
          categories: string[]
          website: string | null
          phone: string | null
          photos: string[]
          google_place_id: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          address?: string | null
          city?: string | null
          country?: string | null
          latitude?: number | null
          longitude?: number | null
          categories?: string[]
          website?: string | null
          phone?: string | null
          photos?: string[]
          google_place_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          address?: string | null
          city?: string | null
          country?: string | null
          latitude?: number | null
          longitude?: number | null
          categories?: string[]
          website?: string | null
          phone?: string | null
          photos?: string[]
          google_place_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      series: {
        Row: {
          id: string
          title: string
          original_title: string | null
          tagline: string | null
          overview: string | null
          first_air_date: string | null
          last_air_date: string | null
          number_of_seasons: number | null
          number_of_episodes: number | null
          episode_runtime: number[]
          genres: string[]
          poster_path: string | null
          backdrop_path: string | null
          tmdb_id: number | null
          imdb_id: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          original_title?: string | null
          tagline?: string | null
          overview?: string | null
          first_air_date?: string | null
          last_air_date?: string | null
          number_of_seasons?: number | null
          number_of_episodes?: number | null
          episode_runtime?: number[]
          genres?: string[]
          poster_path?: string | null
          backdrop_path?: string | null
          tmdb_id?: number | null
          imdb_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          original_title?: string | null
          tagline?: string | null
          overview?: string | null
          first_air_date?: string | null
          last_air_date?: string | null
          number_of_seasons?: number | null
          number_of_episodes?: number | null
          episode_runtime?: number[]
          genres?: string[]
          poster_path?: string | null
          backdrop_path?: string | null
          tmdb_id?: number | null
          imdb_id?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      softwares: {
        Row: {
          id: string
          name: string
          description: string | null
          version: string | null
          release_date: string | null
          category: string | null
          platforms: string[]
          website: string | null
          repository_url: string | null
          logo_url: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          version?: string | null
          release_date?: string | null
          category?: string | null
          platforms?: string[]
          website?: string | null
          repository_url?: string | null
          logo_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          version?: string | null
          release_date?: string | null
          category?: string | null
          platforms?: string[]
          website?: string | null
          repository_url?: string | null
          logo_url?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
    }
    Functions: {
      search_profiles: {
        Args: { search_query: string }
        Returns: Database['public']['Tables']['profiles']['Row'][]
      }
      get_follower_count: {
        Args: { profile_id: string }
        Returns: number
      }
      get_following_count: {
        Args: { profile_id: string }
        Returns: number
      }
      check_if_follows: {
        Args: { follower: string; following: string }
        Returns: boolean
      }
    }
  }
}