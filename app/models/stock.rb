class Stock < Asset

  def get_tick_hour
    p "Get Tick Hour..."

    d = 1.hour.to_i
    h = HTTParty.get("https://api.iextrading.com/1.0/stock/#{self.sym}/quote")

    data = {}
    data['time'] = Time.at(h['latestUpdate'] / 1000)
    data['high'] = h['high']
    data['low'] = h['low']
    data['open'] = h['open']
    data['close'] = h['close']
    self.create_tick data, d

    p 'Done!'
  end

  def set_fixed_values
    h = HTTParty.get("https://api.iextrading.com/1.0/stock/#{self.sym}/quote")
    self.price_usd = h['latestPrice']
    self.market_cap_usd = h['marketCap']
    self.available_supply = self.market_cap_usd / self.price_usd
    self.percent_change_24h = self.get_percent_change_24h(self.price_usd)
    self.percent_change_7d = self.get_percent_change_7d(self.price_usd)
    self.save
  end

end
