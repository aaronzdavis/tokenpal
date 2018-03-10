class Token < Asset
  def get_ticks_minute qty
    p "Get minute Tick (#{qty})..."

    t = Cryptocompare::HistoMinute.find(self.sym, 'USD', {'limit' => qty})['Data']
    d = 1.minute.to_i

    if qty == 1
      self.create_tick t.first, d
    else
      create_ticks t, d
    end

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

  def get_ticks_week qty
    p "Get Ticks Week (#{qty})..."

    d = 1.week.to_i
    limit = qty * 7
    token_ticks = self.ticks.day
    ticks_set = token_ticks.where(:created_at.lte => Time.now).limit(limit)

    ticks_set.in_groups_of(7, false) do |ticks|
      t = {}
      t['time'] = ticks.first.created_at.to_i
      t['high'] = ticks.map(&:high).max
      t['low'] = ticks.map(&:low).min
      t['open'] = ticks.map(&:open).sum / ticks.count
      t['close'] = ticks.map(&:close).sum / ticks.count
      self.create_tick t, d
    end

    p 'Done!'
  end

  def set_fixed_values
    cc = Cryptocompare::Price.full(self.sym, 'USD')
    cc = cc["RAW"][self.sym]["USD"]
    self.price_usd = cc['PRICE']
    self.market_cap_usd = cc['MKTCAP']
    self.available_supply = cc['SUPPLY']
    self.percent_change_24h = self.get_percent_change_24h
    self.percent_change_7d = self.get_percent_change_7d
    self.save
  end
end
