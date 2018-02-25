Token.all.destroy

r = HTTParty.get('https://api.coinmarketcap.com/v1/ticker/?limit=5')

r.each do |token|
  p "Creating Tokens..."
  Token.create(
    name: token['name'],
    sym: token['symbol'],
    price_usd: token['price_usd'],
    market_cap_usd: token['market_cap_usd'],
    available_supply: token['available_supply'],
    percent_change_24h: token['percent_change_24h'],
    percent_change_7d: token['percent_change_7d']
  )
  p token['name']
end

Token.all.each do |token|
  token.get_ticks_hour 400
  token.get_ticks_day 400
  token.get_ticks_week 400

  all_ticks = [token.ticks.hour, token.ticks.day, token.ticks.week]

  all_ticks.each do |at|

    at.each_with_index do |t, i|

      ticks = at[i..i+20]
      t.moving_average_21 = ticks.map(&:close).sum / ticks.count

      p "#{t.created_at} – Moving Average 21: #{t.moving_average_21}"

      ticks = at[i..i+49]
      t.moving_average_50 = ticks.map(&:close).sum / ticks.count

      p "#{t.created_at} – Moving Average 21: #{t.moving_average_50}"

      ticks = at[i..i+199]
      t.moving_average_200 = ticks.map(&:close).sum / ticks.count

      p "#{t.created_at} – Moving Average 21: #{t.moving_average_200}"


      ticks = at[i..i+8]
      conversion_line_high = ticks.map(&:high).max
      conversion_line_low = ticks.map(&:low).min
      t.conversion_line = (conversion_line_high + conversion_line_low) / 2

      p "#{t.created_at} – Conversion Line: #{t.conversion_line}"


      ticks = at[i..i+25]
      base_line_high = ticks.map(&:high).max
      base_line_low = ticks.map(&:low).min
      t.base_line = (base_line_high + base_line_low) / 2

      p "#{t.created_at} – Base Line: #{t.base_line}"

      t.save

    end

    at.each_with_index do |t, i|

      tick = at[i+25]

      if tick
        t.leading_span_a = (tick.conversion_line + tick.base_line) / 2

        p "#{t.created_at} – Leading Span A: #{t.leading_span_a}"
      end


      tick = at[i+25]

      if tick
        ticks = at[i+25..i+77]
        leading_span_b_high = ticks.map(&:high).max
        leading_span_b_low = ticks.map(&:low).min
        t.leading_span_b = (leading_span_b_high + leading_span_b_low) / 2

        p "#{t.created_at} – Leading Span B: #{t.leading_span_b}"
      end

      t.save

    end

  end
end
