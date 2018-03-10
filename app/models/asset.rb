class Asset
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

  index({
    'ticks.duration': 1,
    'ticks.created_at': -1 }, { unique: true })

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

  def get_tick_for time
    case time
    when 1.hour
      type = "1 Hour"
      limit = 60
      ticks = self.ticks.minute
    when 1.day
      type = "1 Day"
      limit = 24
      ticks = self.ticks.hour
    when 1.week
      type = "1 Week"
      limit = 7
      ticks = self.ticks.day
    end

    p ticks.first.created_at

    p "Get Tick for #{type}..."

    # # Check the last day tick that was created
    if ticks.first.created_at <= Time.now - time
      ticks = ticks.limit(limit)
      t = {}
      t['time'] = ticks.first.created_at.to_i
      t['high'] = ticks.map(&:high).max
      t['low'] = ticks.map(&:low).min
      t['open'] = ticks.map(&:open).sum / ticks.count
      t['close'] = ticks.map(&:close).sum / ticks.count
      self.create_tick t, time.to_i
      p 'Done!'
    else
      p 'Up to date... Please wait...'
    end
  end

  def create_ticks h, d
    h.each do |t|
      self.create_tick t, d
    end
  end

  def create_tick data, d
    t = self.ticks.find_or_initialize_by(
      duration: d,
      created_at: Time.at(data['time'])
    )
    t.duration = d
    t.created_at = Time.at(data['time'])
    t.high = data['high']
    t.low = data['low']
    t.open = data['open']
    t.close = data['close']
    t.save

    p t.close
  end

  def get_percent_change_24h
    ticks = self.ticks.day.limit(2)
    (ticks[0].close - ticks[1].close) / ticks[0].close
  end

  def get_percent_change_7d
    ticks = self.ticks.day.limit(7)
    (ticks[0].close - ticks[6].close) / ticks[0].close
  end
end