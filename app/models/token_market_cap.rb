class TokenMarketCap < Asset
  def self.instance
    TokenMarketCap.first || TokenMarketCap.create!(
      name: 'Token Market Cap',
      sym: 'TOKENMC'
    )
  end

  def get_new_tick
    r = HTTParty.get('https://api.coinmarketcap.com/v1/global/')

    data = {}
    data['time'] = r.parsed_response["last_updated"]
    data['close'] = r.parsed_response["total_market_cap_usd"]
    data['open'] = self.ticks.latest.first.close
    data['high'] = [data['close'], data['open']].max
    data['low'] = [data['close'], data['open']].min

    self.create_tick data, 1.hour.to_i
  end

  def create_tick data, d
    t = self.ticks.find_or_initialize_by(
      duration: d,
      created_at: Time.at(data['time'])
    )
    created_at = Time.at(data['time'])
    t.high = data['high']
    t.low = data['low']
    t.open = data['open']
    t.close = data['close']
    t.save

    p t
  end
end
