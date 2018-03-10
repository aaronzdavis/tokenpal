desc "This task is called by the Heroku scheduler add-on"

task :update_tokens_hourly => :environment do
  p "Updating Tokens..."

  Token.all.each do |t|
    t.get_ticks_hour 1
    t.get_tick_for 1.day
    t.get_tick_for 1.week
    t.set_fixed_values
  end

  p "done."
end

task :update_market_cap_hourly => :environment do
  p "Updating Market Cap Hourly..."

  MarketCap.instance.get_new_tick

  p "done."
end
