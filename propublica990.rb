#!/usr/bin/env ruby
#
module Propublica990
  DESCRIPTION = <<-HEREDOC
  Propublica990: Fetch/parse IRS 990 data from ProPublica API v2:
    https://projects.propublica.org/nonprofits/api
    Utilities used for fossfoundation.info and fossfunding.com
    See also: https://github.com/ShaneCurcuru/irs990
  HEREDOC
  module_function
  require 'json'
  require 'open-uri'

  # Constants related to ProPublica API v2
  PROPUBLICA_APIV2 = 'https://projects.propublica.org/nonprofits/api/v2/organizations/'
  PROPUBLICA_APIV2_JSON = '.json'

  # Fetch an org's data from ProPublica
  def fetch_org(ein)
    org = JSON.load_file(URI.open(PROPUBLICA_APIV2 + ein + PROPUBLICA_APIV2_JSON))
    return org
  end

  # Cache org's data in local directory
  # @return true if we updated the file because any newer filing data found
  def cache_org(ein, dir)
    org = fetch_org(ein)
    fn = File.join(dir, "#{ein}.json")

    newerdata = true
    if File.exist?(fn)
      cache = JSON.load_file(fn)
      newdate = org["filings_with_data"].map { |i| DateTime.parse(i["updated"]) }.max
      cachedate = cache["filings_with_data"].map { |i| DateTime.parse(i["updated"]) }.max
      newerdata = newdate > cachedate
    end
    if newerdata
      File.write(File.join(dir, "#{ein}.json"), JSON.pretty_generate(org))
      return true
    else
      return false
    end
  end

  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    path = File.join(Dir.pwd, '_data')
    ein = '470825376'
    puts "DEBUG: #{ein}, #{path}"
    puts cache_org(ein, path)
  end
end
