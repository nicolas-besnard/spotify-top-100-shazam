require 'dotenv/load'
require 'rspotify'
require 'byebug'
require 'httparty'

class ShazamClient
  include HTTParty
  base_uri 'https://www.shazam.com/shazam/v2/en-US/FR/web/-/tracks'
  # debug_output

  def self.top(listid:)
    response = self.get("/#{listid}?pageSize=100&startFrom=0")

    response.parsed_response['chart'].map do |song|
      uri = song.dig('streams', 'spotify', 'actions', 0, 'uri')
      title = song['heading']['title']
      author = song['heading']['subtitle']

      spotify_id =
        if uri
          "spotify:track:" + uri.split('?')[0].split('/').last
        else
          spotify_song = RSpotify::Track.search("#{author} #{title}")
          sleep 10

          if spotify_song.first
            spotify_song[0].uri
          else
            puts "Could not find #{author} #{title}"
            nil
          end
        end

      if spotify_id.nil?
        next
      end

      {
        title: title,
        author: author,
        image: song['images']['default'],
        spotify_id: spotify_id
      }
    end
      .compact
  end
end

# ShazamClient.top(country: 'france')

RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])

me = RSpotify::User.new('id' => ENV['SPOTIFY_USER_ID'], 'credentials' => { 'token' => ENV['SPOTIFY_USER_TOKEN'], 'refresh_token' => ENV['SPOTIFY_USER_REFRESH_TOKEN'] })

class Playlist
  attr_reader :me
  DEFAULT_SUFFIX = 'Shazam - Top 100 - '.freeze

  def initialize(me:)
    @me = me
  end

  def remove_all_tracks(playlist:)
    tracks_to_remove = []
    offset = 0
    limit = 100

    loop do
      tracks = playlist.tracks(limit: limit, offset: offset)

      if tracks.empty?
        break
      end

      tracks_to_remove += tracks
      offset += tracks.size

      if tracks.size < limit
        break
      end
    end

    playlist.remove_tracks!(tracks_to_remove)
  end

  def find_or_create(country:)
    find(country: country) || create(country: country)
  end

  private

  def create(country:)
    playlist_name = playlist_name_for_country(country: country)
    me.create_playlist!(playlist_name)
  end

  def find(country:)
    offset = 0
    limit = 50
    playlist_name = playlist_name_for_country(country: country)

    loop do
      playlists = me.playlists(limit: limit, offset: 0)

      return nil if playlists.empty?

      found = playlists.find { |p| p.name == playlist_name }

      return found if found
      return nil if playlists.size < limit

      offset += playlists.size
    end
  end

  def playlist_name_for_country(country:)
    DEFAULT_SUFFIX + country
  end

  def self.countries
    [
      { code: "WRLD", name: "World", listid: 'world-chart-world'},
      { code: "US", name: "United States", listid: "country-chart-US" },
      { code: "RU", name: "Russia", listid: "country-chart-RU" },
      { code: "FR", name: "France", listid: "country-chart-FR" },
      { code: "IT", name: "Italy", listid: "country-chart-IT" },
      { code: "DE", name: "Germany", listid: "country-chart-DE" },
      { code: "GB", name: "United Kingdom", listid: "country-chart-GB" },
      { code: "ES", name: "Spain", listid: "country-chart-ES" },
      { code: "AU", name: "Australia", listid: "country-chart-AU" },
      { code: "MX", name: "Mexico", listid: "country-chart-MX" },
      { code: "BR", name: "Brasil", listid: "country-chart-BR" },
      { code: "TR", name: "Turkey", listid: "country-chart-TR" },
      { code: "CA", name: "Canada", listid: "country-chart-CA" },
      { code: "UA", name: "Ukraine", listid: "country-chart-UA" },
      { code: "IN", name: "India", listid: "country-chart-IN" },
      { code: "JP", name: "Japan", listid: "country-chart-JP" },
      { code: "NL", name: "Netherlands", listid: "country-chart-NL" },
      { code: "PL", name: "Poland", listid: "country-chart-PL" },
      { code: "ZA", name: "South Africa", listid: "country-chart-ZA" },
      { code: "BE", name: "Belgium", listid: "country-chart-BE" },
      { code: "KZ", name: "Kazhastan", listid: "country-chart-KZ" },
      { code: "CH", name: "Switzerland", listid: "country-chart-CH" },
      { code: "RO", name: "Romania", listid: "country-chart-RO" },
      { code: "CO", name: "Colombia", listid: "country-chart-CO" },
      { code: "CL", name: "Chile", listid: "country-chart-CL" },
      { code: "AR", name: "Argentina", listid: "country-chart-AR" },
      { code: "IL", name: "Israel", listid: "country-chart-IL" },
      { code: "CN", name: "China", listid: "country-chart-CN" },
      { code: "GR", name: "Greece", listid: "country-chart-GR" },
      { code: "ID", name: "Indonesia", listid: "country-chart-ID" },
      { code: "AT", name: "Austria", listid: "country-chart-AT" },
      { code: "TW", name: "Taiwan", listid: "country-chart-TW" },
      { code: "HU", name: "Hungary", listid: "country-chart-HU" },
      { code: "SE", name: "Sweden", listid: "country-chart-SE" },
      { code: "SA", name: "Saudi Arabia", listid: "country-chart-SA" },
      { code: "CZ", name: "Czeck Republic", listid: "country-chart-CZ" },
      { code: "PT", name: "Portugal", listid: "country-chart-PT" },
      { code: "BY", name: "Belarus", listid: "country-chart-BY" },
      { code: "PE", name: "Peru", listid: "country-chart-PE" },
      { code: "BG", name: "Bulgaria", listid: "country-chart-BG" },
      { code: "KR", name: "Korea", listid: "country-chart-KR" },
      { code: "IR", name: "Iran", listid: "country-chart-IR" },
      { code: "EG", name: "Egypt", listid: "country-chart-EG" },
      { code: "TH", name: "Thailand", listid: "country-chart-TH" },
      { code: "DK", name: "Denmark", listid: "country-chart-DK" },
      { code: "IE", name: "Ireland", listid: "country-chart-IE" },
      { code: "MA", name: "Morroco", listid: "country-chart-MA" },
      { code: "NO", name: "Norway", listid: "country-chart-NO" },
      { code: "MY", name: "Malaysia", listid: "country-chart-MY" },
      { code: "CR", name: "Costa Rica", listid: "country-chart-CR" },
      { code: "FI", name: "Finland", listid: "country-chart-FI" },
      { code: "NZ", name: "New Zealand", listid: "country-chart-NZ" },
      { code: "SG", name: "Singapore", listid: "country-chart-SG" },
      { code: "HR", name: "Croatia", listid: "country-chart-HR" },
      { code: "VE", name: "Venezuela", listid: "country-chart-VE" },
      { code: "UY", name: "Uruguay", listid: "country-chart-UY" },
    ]
  end
end

class Track
  attr_reader :me

  def initialize(me:)
    @me = me
  end
end

p = Playlist.new(me: me)

Playlist.countries.each do |country|
  puts "Find or create playlist for #{country[:name]}"
  playlist = p.find_or_create(country: country[:name])

  puts "Remove tracks"
  p.remove_all_tracks(playlist: playlist)

  puts "Fetch songs from Shazam"
  songs = ShazamClient.top(listid: country[:listid]).map { |s| s[:spotify_id] }

  puts "Add songs to playlist #{songs.size}"
  playlist.add_tracks!(songs)
  sleep 20
end

