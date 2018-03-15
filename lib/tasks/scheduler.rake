desc "This task is called by the Heroku scheduler add-on"

task :update_hourly => :environment do
  p "Get ticks..."

  Token.all.each do |t|
    t.get_ticks_hour 1
    t.get_tick_for 1.day.to_i
    t.get_tick_for 1.week.to_i
    t.set_fixed_values
  end

  p "Get Market Cap tick..."

  tmc = TokenMarketCap.instance
  tmc.get_new_tick
  tmc.get_tick_for 1.day.to_i
  tmc.get_tick_for 1.week.to_i

  p "done."
end
