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
  noko.css('ul#nav a[href*="?"]/@href').map(&:text)
end

def scrape_candidates(url)
  warn "Getting #{url}"
  noko = noko_for(url)
  table = noko.css('table')

  district = table.xpath('.//tr/td[contains(.,"DISTRICT")]').text.sub('DISTRICT:','').gsub(/[[:space:]]+/, ' ').strip
  binding.pry if district.empty?

  table.xpath('tr[contains(.,"Surname")]/following-sibling::tr').each do |tr|
    tds = tr.css('td')
    next if tds[4].text.gsub(/[[:space:]]+/,' ').strip.empty?
    id = tds[0].text.strip.to_i 

    data = { 
      id: "#{district}-#{id}",
      family_name: tds[1].text.strip,
      given_name: tds[2].text.strip,
      party: tds[3].text.strip,
      district: district,
      area: tds[4].text.strip,
      area_id: tds[4].text.strip[/#\s*(\d+)/, 1],
      gender: tds[6].text.include?('1') ? 'male' : tds[7].text.include?('1') ? 'female' : '',
      age: tds[8].text.strip,
      source: url.to_s,
    }
    puts data
    ScraperWiki.save_sqlite([:id], data)
  end
end

@BASE = 'http://candidates.iec.org.ls/index.php?id=tele'
constituency_list(@BASE).each do |link|
  url = URI.join @BASE, link
  scrape_candidates(url)
end

