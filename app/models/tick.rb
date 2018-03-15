class Tick
  include Mongoid::Document
  field :created_at, type: DateTime
  field :duration, type: Integer
  field :high, type: Float
  field :low, type: Float
  field :open, type: Float
  field :close, type: Float

  # Moving Aveage
  field :moving_average_21, type: Float
  field :moving_average_50, type: Float
  field :moving_average_200, type: Float

  # Ichimoku Cloud
  field :conversion_line, type: Float
  field :base_line, type: Float
  field :leading_span_a, type: Float
  field :leading_span_b, type: Float

  embedded_in :token

  validates :created_at, presence: true
  validates :duration, presence: true

  validates_uniqueness_of :created_at, scope: :duration

  default_scope -> { order(created_at: -1) }
  scope :reverse, -> { order(created_at: 1) }
  scope :hour, -> { where(duration: 1.hour.to_i) }
  scope :day, -> { where(duration: 1.day.to_i) }
  scope :week, -> { where(duration: 1.week.to_i) }
  scope :latest, -> { where(:created_at.lte => Time.now).limit(1) }

  before_create :set_additional_fields
  def set_additional_fields
    p "Setting additional fields..."

    case self.duration
    when 1.hour.to_i
      all_ticks = self._parent.ticks.hour.limit(200)
    when 1.day.to_i
      all_ticks = self._parent.ticks.day.limit(200)
    when 1.week.to_i
      all_ticks = self._parent.ticks.week.limit(200)
    end

    self.set_moving_averages all_ticks
    self.set_ichimoku_cloud all_ticks
  end

  def set_moving_averages all_ticks
    ticks = all_ticks[0..20]
    self.moving_average_21 = ticks.map(&:close).sum / ticks.count

    p "#{self.created_at} – Moving Average 21: #{self.moving_average_21}"

    ticks = all_ticks[0..49]
    self.moving_average_50 = ticks.map(&:close).sum / ticks.count

    p "#{self.created_at} – Moving Average 21: #{self.moving_average_50}"

    ticks = all_ticks[0..199]
    self.moving_average_200 = ticks.map(&:close).sum / ticks.count

    p "#{self.created_at} – Moving Average 21: #{self.moving_average_200}"
  end

  def set_ichimoku_cloud all_ticks
    ticks = all_ticks[0..8]
    conversion_line_high = ticks.map(&:high).max
    conversion_line_low = ticks.map(&:low).min
    self.conversion_line = (conversion_line_high + conversion_line_low) / 2

    p "#{self.created_at} – Conversion Line: #{self.conversion_line}"

    ticks = all_ticks[0..25]
    base_line_high = ticks.map(&:high).max
    base_line_low = ticks.map(&:low).min
    self.base_line = (base_line_high + base_line_low) / 2

    p "#{self.created_at} – Base Line: #{self.base_line}"

    tick = all_ticks[25]

    if tick
      self.leading_span_a = (tick.conversion_line + tick.base_line) / 2

      p "#{self.created_at} – Leading Span A: #{self.leading_span_a}"

      ticks = all_ticks[25..77]
      leading_span_b_high = ticks.map(&:high).max
      leading_span_b_low = ticks.map(&:low).min
      self.leading_span_b = (leading_span_b_high + leading_span_b_low) / 2

      p "#{self.created_at} – Leading Span B: #{self.leading_span_b}"
    end
  end
end
