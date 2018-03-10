class Tick
  include Mongoid::Document
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

  field :created_at, type: DateTime
  embedded_in :token

  validates :created_at, presence: true
  validates :duration, presence: true

  default_scope -> { order(created_at: -1) }
  scope :reverse, -> { order(created_at: 1) }
  scope :hour, -> { where(duration: 1.hour.to_i) }
  scope :day, -> { where(duration: 1.day.to_i) }
  scope :week, -> { where(duration: 1.week.to_i) }
  scope :latest, -> { where(:created_at.lte => Time.now).limit(1) }

  # after_create :set_additional_fields
  def set_additional_fields
    p "Setting additional fields..."
    # self.set_moving_average_21
    # self.set_moving_average_50
    # self.set_moving_average_200
    # self.set_conversion_line
    # self.set_base_line
    # self.set_leading_span_a
    # self.set_leading_span_b
    return "Done!"
  end

  def set_moving_average_21
    # Average of the last 21 period closes

    if self.close?
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at
      ).limit(21)

      if ticks.count == 21
        self.moving_average_21 = ticks.map(&:close).sum / 21
        self.save
        p "#{self.created_at} – Moving Average 21: #{self.moving_average_21}"
      end
    end
  end

  def set_moving_average_50

    if self.close?
      # Average of the last 50 period closes
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at)
      .limit(50)

      if ticks.count == 50
        self.moving_average_50 = ticks.map(&:close).sum / 50
        self.save
        p "#{self.created_at} – Moving Average 50: #{self.moving_average_50}"
      end
    end
  end

  def set_moving_average_200
    # Average of the last 200 period closes

    if self.close?
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at
      ).limit(200)

      if ticks.count == 200
        self.moving_average_200 = ticks.map(&:close).sum / 200
        self.save
        p "#{self.created_at} – Moving Average 200: #{self.moving_average_200}"
      end
    end
  end

  def set_conversion_line
    # Red Line
    # Tenkan-Sen (Conversion Line). It’s the midpoint of the last nine price bars:
    # [(9-period high + 9-period low)/2].

    if self.high?
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at
      ).limit(9)

      if ticks.count == 9
        conversion_line_high = ticks.map(&:high).max
        conversion_line_low = ticks.map(&:low).min
        self.conversion_line = (conversion_line_high + conversion_line_low) / 2
        self.save

        p "#{self.created_at} – Conversion Line: #{self.conversion_line}"
      end
    end
  end

  def set_base_line
    # White Line
    # Kijun-sen (Base Line). It’s the midpoint of the last 26 price bars:
    # [(26-period high + 26-period low)/2].

    if self.high?
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at
      ).limit(26)

      if ticks.count == 26
        base_line_high = ticks.map(&:high).max
        base_line_low = ticks.map(&:low).min
        self.base_line = (base_line_high + base_line_low) / 2
        self.save

        p "#{self.created_at} – Base Line: #{self.base_line}"
      end
    end
  end

  def add_time
    case self.duration
    when 60
      26.hours
    when 1440
      26.days
    when 10080
      26.weeks
    end
  end

  def set_leading_span_a
    # Yellow Line
    # Senkou Span A (Leading Span A). It’s the midpoint of the above two lines:
    # [(Conversion Line + Base Line)/2].
    # This value is plotted 26 periods into the future.

    if self.base_line?
      date = self.created_at + self.add_time

      t = self.token.ticks.find_or_initialize_by(
        duration: self.duration,
        created_at: date
      )

      t.leading_span_a = (self.conversion_line + self.base_line) / 2
      t.save

      p "#{self.created_at} – Leading Span A: #{t.leading_span_a}"
    end
  end

  def set_leading_span_b
    # Blue Line
    # Senkou Span B (Leading Span B). It’s the midpoint of the last 52 price bars:
    # [(52-period high + 52-period low)/2].
    # This value is plotted 26 periods into the future.

    if self.base_line?
      ticks = self.token.ticks.where(
        duration: self.duration,
        :created_at.lte => self.created_at
      ).limit(52)

      if ticks.count == 52
        leading_span_b_high = ticks.map(&:high).max
        leading_span_b_low = ticks.map(&:low).min
        date = self.created_at + self.add_time

        t = self.token.ticks.find_or_initialize_by(
          duration: self.duration,
          created_at: date
        )

        t.leading_span_b = (leading_span_b_high + leading_span_b_low) / 2
        t.save

        p "#{self.created_at} – Leading Span B: #{t.leading_span_b}"
      end
    end
  end
end
