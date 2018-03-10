class MarketCap
  include Mongoid::Document
  embeds_many :ticks

  def self.instance
    MarketCap.first || MarketCap.create!
  end

  def get_new_tick
    r = HTTParty.get('https://api.coinmarketcap.com/v1/global/')
    p r.parsed_response["total_market_cap_usd"]
    t = self.ticks.new
    t.created_at = Time.at(r.parsed_response["last_updated"])
    t.duration = 60
    t.close = r.parsed_response["total_market_cap_usd"]
    t.open = self.ticks.latest.close
    t.save
  end
end
