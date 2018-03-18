class Token < Asset

  def get_ticks_minute qty
    p "Get minute Tick (#{qty})..."

    t = Cryptocompare::HistoMinute.find(self.sym, 'USD', {'limit' => qty})['Data']
    d = 1.minute.to_i

    create_ticks t, d

    p 'Done!'
  end

  def get_ticks_hour qty
    p "Get Ticks Hour (#{qty})..."

    d = 1.hour.to_i
    h = Cryptocompare::HistoHour.find(self.sym, 'USD', {'limit' => qty})

    p h['Data']

    create_ticks h['Data'], d

    p 'Done!'
  end

  def get_ticks_day qty
    p "Get Ticks Day (#{qty})..."

    t = Cryptocompare::HistoDay.find(self.sym, 'USD', {'limit' => qty})
    create_ticks t['Data'], 1.day.to_i

    p 'Done!'
  end

  def set_fixed_values
    cc = Cryptocompare::Price.full(self.sym, 'USD')
    cc = cc["RAW"][self.sym]["USD"]
    self.price_usd = cc['PRICE']
    self.market_cap_usd = cc['MKTCAP']
    self.available_supply = cc['SUPPLY']
    self.percent_change_24h = self.get_percent_change_24h(self.price_usd)
    self.percent_change_7d = self.get_percent_change_7d(self.price_usd)
    self.save
  end
end
