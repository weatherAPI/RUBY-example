require 'sinatra'
require 'uri'
require 'open-uri'
require 'json'
require 'geocoder'

enable :logging

Geocoder.configure do |config|
  config.lookup = :freegeoip
  config.timeout = 1000
  config.units = :mi
end

get '/' do
  @location = Weather::Location.from_request(request)
  @weather = Weather::Request.for(@location.lat, @location.long)
  @observation = @weather[:conditions][:data][:observation]
  <<-EOF
  <html>
  <body>
      <h2>Remember to add your API key to weather_or_not.rb</h2>
      <div id="weather">
        <ul id="icon">
          <li><img src="http://icons.wunderground.com/graphics/autobrand/sfgate2012/current_icons/<%= @observation[:icon_code] %>.png" /></li>
      </ul>
      <ul class="delete">
        <li id='temp'><%= @observation[:imperial][:temp]</li>
        <li id='location'><%=@observation[:phrase_32char]</li>
        <li id='cond'><%=@location.city %></li>
      </ul>
    </div>
    <style>
    body {
      background-color: #82cafa
    }

    div#weather ul {
      list-style: none;
      padding:0;
    }

    div#weather ul li {
      color:#efefef;
      font-size:40px;
      font-family:"Courier New", Courier, monospace;
    }

    div#weather ul#icon {
      float:left;
      list-style: none;
      margin:0 10px 0 0;
    }

    div#weather ul#icon img {
      height:200px;
    }
    </style>    
  </body>
  EOF
end

module Weather
  API_KEY = 'bffed78868b0ca3dc6ff86f123f317e6'
  
  class Location
    attr_accessor :lat, :long, :city, :ip
    alias :latitude :lat
    alias :longitude :long
    
    def Location.from_request(request)
      location = Location.new
      if request && request.location
        location.lat = request.location.latitude
        location.long = request.location.longitude
        location.city = request.location.city if request.location.city
        return location
      else
        return nil
      end
      request.ip = request.ip
    end
    
  end
  
  class Request
    attr_accessor :base_url, :api_key, :unit_preference, :language_preference
        
    def initializer(args = {})
      @base_url = args[:base_url] || 'http://api.weather.com/v2'
      @api_key = args[:api_key] || Weather::API_KEY
      @unit_preference = args[:unit_preference] || 'e'
      @language_preference = args[:language_preference] || 'en'
    end

    def build_geocode_url_for(lat, long)
      self.build_weather_url_for("/geocode/#{lat}/#{long}/aggregate.json")
    end

    def build_weather_url_for(fragment)
      return URI.parse("#{@base_url}#{fragment}")
    end

    def querystring_for_weather_request
      "api_Key=#{@api_key}&units=#{@unit_preference}&language=#{@language_preference}&products=conditions"
    end

    def weather_request(uri_object, params = {})
      uri_object.query = querystring_for_weather_request
      puts "-----"
      puts uri_object.to_s
      
      weather = open uri_object.to_s
      if weather.is_a? Net::HTTPSuccess    
        response_hash = JSON.parse(weather.body, { :symbolize_names => true })
        return response_hash
      else
        return nil
      end
    end
    
    def Request.for(lat, long)
      request = Weather::Request.new
      url = request.build_geocode_url_for(lat, long)
      response = request.weather_request(url)
    end
    
  end
end
