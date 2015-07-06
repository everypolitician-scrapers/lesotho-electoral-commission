#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def constituency_list(url)
  noko = noko_for(url)
  noko.css('ul#nav a[href*="?"]')
end

def scrape_candidates(url, district_id)
  # warn "Getting #{url}"
  noko = noko_for(url)
  table = noko.css('table')

  district = table.xpath('.//tr/td[contains(.,"DISTRICT")]').text.sub(/DISTRICT:?/,'').gsub(/[[:space:]]+/, ' ').strip
  binding.pry if district.empty?

  added = 0
  table.xpath('tr').each do |tr|
    tds = tr.css('td')
    next unless tds[4].text.include? district_id.to_s
    id = tds[0].text.strip.to_i 

    data = { 
      id: "#{district}-#{id}",
      family_name: tds[1].text.strip,
      given_name: tds[2].text.strip,
      party: tds[3].text.strip,
      district: district,
      area: tds[4].text.strip,
      area_id: district_id,
      gender: tds[6].text.include?('1') ? 'male' : tds[7].text.include?('1') ? 'female' : '',
      age: tds[8].text.strip,
      source: url.to_s,
    }
    # puts data
    added += 1
    ScraperWiki.save_sqlite([:id], data)
  end
  puts "Added #{added} candidates for district #{district_id}"
  binding.pry if added == 0
end

@BASE = 'http://candidates.iec.org.ls/index.php?id=tele'
constituency_list(@BASE).each do |a|
  url = URI.join @BASE, a.attr('href')
  id = a.text[/#\s*(\d+)/, 1].to_i
  begin
    scrape_candidates(url, id)
  rescue => e
    warn e
  end
end

