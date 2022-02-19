class PagesController < ApplicationController
  def index
    ip_data = Excon.get('https://ip-fast.com/api/ip/?format=json&location=True')
    while (ip_data.status != 200)
      puts 'ip error'
      ip_data = Excon.get('https://ip-fast.com/api/ip/?format=json&location=True')
    end
    ip_results = JSON.parse(ip_data.body)
    
    geocode_uri = URI('https://geocode.xyz')
    geocode_params = {
      locate: ''.concat(ip_results['city']).concat(', ').concat(ip_results['country']),
      geoit: 'json'
    }
    geocode_uri.query = URI.encode_www_form(geocode_params)
    geocode_data = Excon.get(geocode_uri.to_s)
    while (geocode_data.status != 200)
      puts 'geocode error'
      geocode_data = Excon.get(geocode_uri.to_s)
    end
    geocode_results = JSON.parse(geocode_data.body)

    weather_uri = URI('https://api.open-meteo.com/v1/forecast')
    weather_params = {
      latitude: geocode_results['latt'],
      longitude: geocode_results['longt'],
      temperature_unit: 'fahrenheit',
      timezone: 'America/New_York'
    }
    weather_uri.query = URI.encode_www_form(weather_params).concat('&daily=temperature_2m_max,temperature_2m_min')
    weather_data = Excon.get(weather_uri.to_s)
    while (weather_data.status != 200)
      puts 'weather error'
      weather_data = Excon.get(weather_uri.to_s)
    end
    weather_results = JSON.parse(weather_data.body)

    @chart_uri = URI('https://image-charts.com/chart')
    chxl = '0:'
    chd = 't:'
    chd2 = '|'
    chl = ''
    chl2 = ''
    weather_results['daily']['time'].each_with_index do |date, i|
      if i < 2
        chxl.concat(%w(|Today |Tomorrow)[i])
      else
        chxl.concat('|').concat(Date.parse(date).strftime('%A'))
      end
      chd.concat(weather_results['daily']['temperature_2m_min'][i].round.to_s).concat(',')
      chd2.concat((weather_results['daily']['temperature_2m_max'][i].round-weather_results['daily']['temperature_2m_min'][i].round).to_s).concat(',')
      chl.concat(weather_results['daily']['temperature_2m_min'][i].round.to_s).concat('°|')
      chl2.concat(weather_results['daily']['temperature_2m_max'][i].round.to_s).concat('°|')
    end
    chd.delete_suffix!(',').concat(chd2.delete_suffix(','))
    chl.concat(chl2.delete_suffix('|'))
    puts chxl
    puts chd
    puts chl
    chart_params = {
      chf: 'b0,s,1b67ad|b1,s,37b426|bg,s,f5f5f5',
      chma: '0,0,10,10',
      chs: '700x450',
      cht: 'bvs',
      chxt: 'x,y',
      chtt: '7 Day Forecast for '.concat(ip_results['city']).concat(', ').concat(ip_results['country']),
      chxl: chxl,
      chxs: '1N*f2*°,000000',
      chbr: '8',
      chd: chd,
      chl: chl,
      chlps: 'anchor,end|align,top|offset,0',
      chts: '000000,24'
    }
    @chart_uri.query = URI.encode_www_form(chart_params)
  end

end
