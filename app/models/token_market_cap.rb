class TokenMarketCap < Asset
  def self.instance
    TokenMarketCap.first || TokenMarketCap.create!(
      name: 'Token Market Cap',
      sym: 'TOKENMC'
    )
  end

  def get_new_tick
    r = HTTParty.get('https://api.coinmarketcap.com/v1/global/')
    p r.parsed_response["total_market_cap_usd"]
    t = self.ticks.new
    t.created_at = Time.at(r.parsed_response["last_updated"])
    t.duration = 1.hour.to_i
    t.close = r.parsed_response["total_market_cap_usd"]
    t.open = self.ticks.latest.close
    t.save
  end
end
