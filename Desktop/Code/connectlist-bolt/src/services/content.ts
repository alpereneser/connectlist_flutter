import { supabase } from '../lib/supabase'
import { api } from './api'

interface SearchCache {
  query: string
  type: string
  results: any
  timestamp: number
}

const CACHE_DURATION = 5 * 60 * 1000 // 5 minutes
const searchCache: SearchCache[] = []

export const contentService = {
  // Search across all content types
  async search(query: string, type: string) {
    // Check cache first
    const cachedResult = searchCache.find(
      cache => 
        cache.query === query && 
        cache.type === type && 
        (Date.now() - cache.timestamp) < CACHE_DURATION
    )
    
    if (cachedResult) {
      return cachedResult.results
    }

    try {
      let results

      switch (type) {
        case 'movies':
          const movieResponse = await api.tmdb.searchMovies(query)
          results = movieResponse.data
          break

        case 'series':
          const seriesResponse = await api.tmdb.searchSeries(query)
          results = seriesResponse.data
          break

        case 'people':
          const peopleResponse = await api.tmdb.searchPeople(query)
          results = peopleResponse.data
          break

        case 'games':
          const gamesResponse = await api.games.search(query)
          results = gamesResponse.data
          break

        case 'books':
          const booksResponse = await api.books.search(query)
          results = booksResponse.data
          break

        case 'videos':
          // For videos, we might want to search YouTube
          const videosResponse = await api.youtube.search(query)
          results = videosResponse.data
          break

        default:
          throw new Error(`Invalid content type: ${type}`)
      }

      // Cache the results
      searchCache.push({
        query,
        type,
        results,
        timestamp: Date.now()
      })

      // Clean up old cache entries
      const now = Date.now()
      while (searchCache.length > 100 || 
             (searchCache.length > 0 && now - searchCache[0].timestamp > CACHE_DURATION)) {
        searchCache.shift()
      }

      return results
    } catch (error) {
      console.error(`Error searching ${type}:`, error)
      return null
    }
  },

  // Get movie details
  async getMovieDetails(id: string) {
    try {
      const response = await api.tmdb.getMovie(Number(id))
      return response.data
    } catch (error) {
      console.error('Error fetching movie details:', error)
      throw error
    }
  },

  // Get series details
  async getSeriesDetails(id: string) {
    try {
      const response = await api.tmdb.getSeries(Number(id))
      const seriesData = response.data

      // Get season details
      const seasonsPromises = seriesData.seasons.map(async (season: any) => {
        const seasonResponse = await api.tmdb.getSeasonDetails(Number(id), season.season_number)
        return seasonResponse.data
      })
      const seasonDetails = await Promise.all(seasonsPromises)
      seriesData.seasons = seasonDetails

      return seriesData
    } catch (error) {
      console.error('Error fetching series details:', error)
      throw error
    }
  },

  // Get book details
  async getBookDetails(id: string) {
    try {
      const response = await api.books.getBook(id)
      return response.data
    } catch (error) {
      console.error('Error fetching book details:', error)
      throw error
    }
  },

  // Get game details
  async getGameDetails(id: string) {
    try {
      const response = await api.games.getGame(Number(id))
      return response.data
    } catch (error) {
      console.error('Error fetching game details:', error)
      throw error
    }
  },

  // Get person details
  async getPersonDetails(id: string) {
    try {
      const response = await api.tmdb.getPerson(Number(id))
      return response.data
    } catch (error) {
      console.error('Error fetching person details:', error)
      throw error
    }
  },

  // Save content to database
  async saveContent(type: string, data: any) {
    try {
      let content
      switch (type) {
        case 'movies':
          content = await this.saveMovie(data)
          break
        case 'series':
          content = await this.saveSeries(data)
          break
        case 'books':
          content = await this.saveBook(data)
          break
        case 'games':
          content = await this.saveGame(data)
          break
        case 'people':
          content = await this.savePerson(data)
          break
        case 'videos':
          content = await this.saveVideo(data)
          break
      }
      return content
    } catch (err) {
      console.error('Error saving content:', err)
      throw err
    }
  },

  // Save specific content types
  async saveMovie(data: any) {
    const { data: movie, error } = await supabase
      .from('movies')
      .upsert({
        title: data.title,
        original_title: data.original_title,
        overview: data.overview,
        release_date: data.release_date,
        runtime: data.runtime,
        tmdb_id: data.id.toString(),
        poster_path: data.poster_path,
        backdrop_path: data.backdrop_path,
        api_data: data
      })
      .select()
      .single()

    if (error) throw error
    return movie
  },

  async saveSeries(data: any) {
    const { data: series, error } = await supabase
      .from('series')
      .upsert({
        title: data.name,
        original_title: data.original_name,
        overview: data.overview,
        first_air_date: data.first_air_date,
        last_air_date: data.last_air_date,
        number_of_seasons: data.number_of_seasons,
        number_of_episodes: data.number_of_episodes,
        tmdb_id: data.id.toString(),
        poster_path: data.poster_path,
        backdrop_path: data.backdrop_path,
        api_data: data
      })
      .select()
      .single()

    if (error) throw error
    return series
  },

  async saveBook(data: any) {
    const { data: book, error } = await supabase
      .from('books')
      .upsert({
        title: data.volumeInfo.title,
        original_title: data.volumeInfo.subtitle,
        description: data.volumeInfo.description,
        isbn: data.volumeInfo.industryIdentifiers?.[0]?.identifier,
        publication_date: data.volumeInfo.publishedDate,
        publisher: data.volumeInfo.publisher,
        page_count: data.volumeInfo.pageCount,
        google_books_id: data.id,
        cover_image_url: data.volumeInfo.imageLinks?.thumbnail,
        api_data: data
      })
      .select()
      .single()

    if (error) throw error
    return book
  },

  async saveGame(data: any) {
    const { data: game, error } = await supabase
      .from('games')
      .upsert({
        title: data.name,
        description: data.description_raw,
        release_date: data.released,
        rawg_id: data.id.toString(),
        genres: data.genres.map((g: any) => g.name),
        platforms: data.platforms.map((p: any) => p.platform.name),
        developer: data.developers?.[0]?.name,
        publisher: data.publishers?.[0]?.name,
        website: data.website,
        api_data: data
      })
      .select()
      .single()

    if (error) throw error
    return game
  },

  async savePerson(data: any) {
    const { data: person, error } = await supabase
      .from('people')
      .upsert({
        full_name: data.name,
        biography: data.biography,
        birth_date: data.birthday,
        death_date: data.deathday,
        tmdb_id: data.id.toString(),
        profile_image_url: data.profile_path,
        api_data: data
      })
      .select()
      .single()

    if (error) throw error
    return person
  },

  async saveVideo(url: string) {
    // Extract video ID from YouTube URL
    const videoId = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/)?.[1]
    if (!videoId) throw new Error('Invalid YouTube URL')

    // Get video details from YouTube API
    const response = await api.youtube.getVideoDetails(videoId)
    const videoData = response.data.items[0]

    const { data: video, error } = await supabase
      .from('videos')
      .upsert({
        title: videoData.snippet.title,
        description: videoData.snippet.description,
        youtube_id: videoId,
        youtube_url: url,
        thumbnail_url: videoData.snippet.thumbnails.high.url,
        duration: videoData.contentDetails.duration,
        channel_title: videoData.snippet.channelTitle,
        channel_id: videoData.snippet.channelId,
        view_count: videoData.statistics.viewCount,
        like_count: videoData.statistics.likeCount,
        published_at: videoData.snippet.publishedAt,
        api_data: videoData
      })
      .select()
      .single()

    if (error) throw error
    return video
  }
}
