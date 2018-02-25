desc "This task is called by the Heroku scheduler add-on"

task :update_tokens_hourly => :environment do
  p "Updating Tokens..."

  r = HTTParty.get('https://api.coinmarketcap.com/v1/ticker/?limit=10')

  r.each do |token|
    t = Token.find_by(sym: token['symbol'])
    p t.name
    t.update!(
      price_usd: token['price_usd'],
      market_cap_usd: token['market_cap_usd'],
      available_supply: token['available_supply'],
      percent_change_24h: token['percent_change_24h'],
      percent_change_7d: token['percent_change_7d']
    )

    p "Get Ticks Hour (1)..."
    t.get_ticks_hour 1

    t.get_ticks_day 1

    t.get_ticks_week 1
  end

  p "done."
end

task :update_market_cap_hourly => :environment do
  p "Updating Market Cap Hourly..."

  MarketCap.instance.get_hourly

  p "done."
end