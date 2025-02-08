import axios from 'axios'

// Base API configurations
const tmdb = axios.create({
  baseURL: 'https://api.themoviedb.org/3',
  headers: {
    'Authorization': `Bearer ${import.meta.env.VITE_TMDB_ACCESS_TOKEN}`,
    'Content-Type': 'application/json'
  }
})

const rawg = axios.create({
  baseURL: 'https://api.rawg.io/api',
  params: {
    key: import.meta.env.VITE_RAWG_API_KEY
  }
})

const googleBooks = axios.create({
  baseURL: 'https://www.googleapis.com/books/v1',
  params: {
    key: import.meta.env.VITE_GOOGLE_BOOKS_API_KEY
  }
})

const youtube = axios.create({
  baseURL: 'https://www.googleapis.com/youtube/v3',
  params: {
    key: import.meta.env.VITE_YOUTUBE_API_KEY
  }
})

export const api = {
  // TMDB API endpoints
  tmdb: {
    searchMovies: (query: string) => 
      tmdb.get('/search/movie', { params: { query } }),
    searchSeries: (query: string) => 
      tmdb.get('/search/tv', { params: { query } }),
    searchPeople: (query: string) => 
      tmdb.get('/search/person', { params: { query } }),
    getMovie: (id: number) => 
      tmdb.get(`/movie/${id}`, { params: { append_to_response: 'credits,images' } }),
    getSeries: (id: number) => 
      tmdb.get(`/tv/${id}`, { params: { append_to_response: 'credits,images' } }),
    getPerson: (id: number) => 
      tmdb.get(`/person/${id}`, { params: { append_to_response: 'combined_credits' } }),
    getMovieCredits: (id: number) => 
      tmdb.get(`/movie/${id}/credits`),
    getSeriesCredits: (id: number) => 
      tmdb.get(`/tv/${id}/credits`),
    getMovieScreenshots: (id: number) => 
      tmdb.get(`/movie/${id}/images`),
    getSeriesScreenshots: (id: number) => 
      tmdb.get(`/tv/${id}/images`),
    getSeasonDetails: (id: number, seasonNumber: number) => 
      tmdb.get(`/tv/${id}/season/${seasonNumber}`),
    get: (url: string) => tmdb.get(url)
  },

  // RAWG API endpoints
  games: {
    search: (query: string) => 
      rawg.get('/games', { 
        params: { 
          search: query,
          page_size: 10
        } 
      }),
    getGame: (id: number) => 
      rawg.get(`/games/${id}`, { params: { append_to_response: 'screenshots' } }),
    getGameScreenshots: (id: number) => 
      rawg.get(`/games/${id}/screenshots`),
    get: (url: string) => rawg.get(url)
  },

  // Google Books API endpoints
  books: {
    search: (query: string) => 
      googleBooks.get('/volumes', { 
        params: { 
          q: query,
          maxResults: 10
        } 
      }),
    getBook: (id: string) => 
      googleBooks.get(`/volumes/${id}`)
  },

  // YouTube API endpoints
  youtube: {
    search: (query: string) =>
      youtube.get('/search', {
        params: {
          part: 'snippet',
          q: query,
          type: 'video',
          maxResults: 10
        }
      }),
    getVideoDetails: (id: string) =>
      youtube.get('/videos', {
        params: {
          part: 'snippet,contentDetails,statistics',
          id
        }
      })
  }
}

// Cache helper functions
export const cacheApi = {
  set: async (key: string, data: any) => {
    try {
      const { error } = await supabase
        .from('api_cache')
        .insert({
          api_name: key.split(':')[0],
          endpoint: key.split(':')[1],
          params: key.split(':')[2] ? JSON.parse(key.split(':')[2]) : {},
          response: data,
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours cache
        })
      if (error) throw error
    } catch (err) {
      console.error('Error caching API response:', err)
    }
  },

  get: async (key: string) => {
    try {
      const { data, error } = await supabase
        .from('api_cache')
        .select('response')
        .eq('api_name', key.split(':')[0])
        .eq('endpoint', key.split(':')[1])
        .eq('params', key.split(':')[2] ? JSON.parse(key.split(':')[2]) : {})
        .gt('expires_at', new Date().toISOString())
        .single()

      if (error) return null
      return data?.response
    } catch (err) {
      console.error('Error getting cached API response:', err)
      return null
    }
  }
}
