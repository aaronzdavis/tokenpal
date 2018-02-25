class Token
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  slug :sym

  field :name, type: String
  field :sym, type: String
  field :price_usd, type: Float
  field :market_cap_usd, type: Float
  field :available_supply, type: Float
  field :percent_change_24h, type: Float
  field :percent_change_7d, type: Float
  embeds_many :ticks

  validates :name, uniqueness: true, presence: true
  validates :sym, uniqueness: true, presence: true

  def ma_21
    self.ticks.hour.latest.first.moving_average_21
  end

  def ma_21_percent
    ((self.price_usd - self.ma_21) / self.price_usd * 100).round(2)
  end

  def ma_21_opacity
    ((self.price_usd - self.ma_21) / self.price_usd * 10).abs
  end

  def ma_status_21
    if self.price_usd > self.ma_21
      "Above"
    elsif self.price_usd < self.ma_21
      "Below"
    else
      "Inside"
    end
  end

  def ma_50
    self.ticks.hour.latest.first.moving_average_50
  end

  def ma_50_opacity
    ((self.price_usd - self.ma_50) / self.price_usd * 10).abs
  end

  def ma_status_50
    if self.price_usd > self.ma_50
      "Above"
    elsif self.price_usd < self.ma_50
      "Below"
    else
      "Inside"
    end
  end

  def ma_200
    self.ticks.hour.latest.first.moving_average_200
  end

  def ma_200_opacity
    ((self.price_usd - self.ma_200) / self.price_usd * 10).abs
  end

  def ma_status_200
    if self.price_usd > self.ma_200
      "Above"
    elsif self.price_usd < self.ma_200
      "Below"
    else
      "Inside"
    end
  end

  def cloud_status_hour_opacity
    tick = self.ticks.hour.latest.first
    ((self.price_usd - tick.leading_span_a) / self.price_usd * 10).abs
  end

  def cloud_status_hour
    tick = self.ticks.hour.latest.first
    if self.cloud_status_above? tick
      "Above"
    elsif self.cloud_status_below? tick
      "Below"
    else
      "Inside"
    end
  end

  def cloud_status_day_opacity
    tick = self.ticks.day.latest.first
    ((self.price_usd - tick.leading_span_a) / self.price_usd * 10).abs
  end

  def cloud_status_day
    tick = self.ticks.day.latest.first
    if self.cloud_status_above? tick
      "Above"
    elsif self.cloud_status_below? tick
      "Below"
    else
      "Inside"
    end
  end

  def cloud_status_week_opacity
    tick = self.ticks.week.latest.first
    ((self.price_usd - tick.leading_span_a) / self.price_usd * 10).abs
  end

  def cloud_status_week
    tick = self.ticks.week.latest.first
    if self.cloud_status_above? tick
      "Above"
    elsif self.cloud_status_below? tick
      "Below"
    else
      "Inside"
    end
  end

  def cloud_status_above? tick
    self.price_usd > tick.leading_span_a && self.price_usd > tick.leading_span_b
  end

  def cloud_status_below? tick
    self.price_usd < tick.leading_span_a && self.price_usd < tick.leading_span_b
  end

  def get_ticks_hour qty
    p "Get Ticks Hour (#{qty})..."

    d = 60
    h = Cryptocompare::HistoHour.find(self.sym, 'USD', {'limit' => qty})

    create_ticks h['Data'], d

    p 'Done!'
  end

  def get_ticks_day qty
    p "Get Ticks Day (#{qty})..."

    d = 1440
    h = Cryptocompare::HistoDay.find(self.sym, 'USD', {'limit' => qty})

    create_ticks h['Data'], d

    p 'Done!'
  end

  def get_ticks_week qty
    p "Get Ticks Week (#{qty})..."

    d = 10080
    limit = qty * 7
    token_ticks = self.ticks.day
    ticks_set = token_ticks.where(:created_at.lte => Time.now).limit(limit)

    ticks_set.in_groups_of(7, false) do |ticks|
      # ticks = token_ticks.where(:created_at.lte => tick.created_at).limit(7)
      p = {}
      p['time'] = ticks.first.created_at
      p['high'] = ticks.map(&:high).max
      p['low'] = ticks.map(&:low).min
      p['open'] = ticks.map(&:open).sum / ticks.count
      p['close'] = ticks.map(&:close).sum / ticks.count
      self.create_tick p, d
    end

    p 'Done!'
  end

  def create_ticks h, d
    h.each do |p|
      self.create_tick p, d
    end
  end

  def create_tick p, d
    t = self.ticks.find_or_initialize_by(
      duration: d,
      created_at: Time.at(p['time'])
    )
    t.duration = d
    t.created_at = Time.at(p['time'])
    t.high = p['high']
    t.low = p['low']
    t.open = p['open']
    t.close = p['close']
    t.save

    p t.close
  end

end
