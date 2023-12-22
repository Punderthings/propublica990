#!/usr/bin/env ruby
module Propublica990
  DESCRIPTION = <<-HEREDOC
  Propublica990: Fetch/parse IRS 990 data from ProPublica API v2:
    https://projects.propublica.org/nonprofits/api
    Utilities used for fossfoundation.info and fossfunding.com
    See also deprecated: https://github.com/ShaneCurcuru/irs990
  HEREDOC
  module_function
  require 'json'
  require 'csv'
  require 'open-uri'
  require './fieldmap990'

  # Constants related to ProPublica API v2
  PROPUBLICA_APIV2 = 'https://projects.propublica.org/nonprofits/api/v2/organizations/'
  PROPUBLICA_APIV2_JSON = '.json'
  ORGANIZATION = 'organization'
  FILINGS = 'filings_with_data'

  # Newspaper nonprofits to analyze in New England
  LOCAL_NEWS = %w[871248884	460777549	237246801	874640985	843780597	862407296	834616910	882367192	863807140	920697644	882058638]
  # FOSS Foundation nonprofits: https://github.com/Punderthings/fossfoundation/tree/main/_foundations taxID field (when is an EIN)

  # Fetch an org's data from ProPublica as json hash
  def fetch_org(ein)
    return JSON.load(URI.open(PROPUBLICA_APIV2 + ein + PROPUBLICA_APIV2_JSON))
  end

  # Cache org's data in local file
  # @return true if we updated the file because any newer filing data found
  def cache_org(ein, file)
    org = fetch_org(ein)
    newerdata = true
    if File.exist?(file)
      cache = JSON.load_file(file)
      newdate = org["filings_with_data"].map { |i| DateTime.parse(i["updated"]) }.max
      if newdate.nil?
        newerdata = false # FIXME validate what we want here; maybe check vs. org.updated_at?
      else
        cachedate = cache["filings_with_data"].map { |i| DateTime.parse(i["updated"]) }.max
        newerdata = newdate > cachedate unless cachedate.nil?
      end
    end
    if newerdata
      File.write(file, JSON.pretty_generate(org))
    end
    return newerdata
  end

  # Get an org's data
  # @param ein as string of entire EIN without dash
  # @param dir as local directory to cache "#{ein}.json" files into
  # @param refresh if true, force a lookup from Propublica for any newer data
  # @return hash of Propublica Organization object
  def get_org(ein, dir, refresh = false)
    file = File.join(dir, "#{ein}.json")
    if refresh or !File.exist?(file)
      unused = cache_org(ein, file)
    end
    return JSON.load_file(file)
  end

  # Get and cache an array of eins as orgs
  # @return array of orgs (as hashes); any org with an error returns as a string
  def get_orgs(eins, dir, refresh = false)
    orgs = []
    eins.each do |ein|
      org = get_org(ein, dir, refresh)
      if org.nil? || org.empty?
        orgs << "ERROR: #{ein} returned nil or empty data"
      else
        orgs << org
      end
    end
    return orgs
  end

  # Emit a simple string describing the org and recent filings available
  # TODO Decide on minimal fields useful for comparisons
  def report_org(ein, dir)
    o = get_org(ein, dir)
    org = o[ORGANIZATION]
    report = {'name' => org['name']}
    %w(state subsection_code ruling_date tax_period ntee_code classification_codes).each do |field|
      report[field] = org[field]
    end
    return report
  end

  # Return flattened version of a single filing's fields
  # @param filing single filings_with_data hash
  # @param fields, fieldname mapping
  # @return array of values from that filing
  def flatten_filing(filing, fields)
    flat = []
    fields.each do |field,displayname|
      flat << filing[field]
    end
    return flat
  end

  # Return flattened list of filings_with_data from an org
  def flatten_filings(org, fields)
    rows = []
    filings = org[FILINGS]
    filings.each do |filing|
      rows << flatten_filing(filing, fields)
    end
    return rows
  end

  # Transform an array of orgs into a simple csv by ein,year across available data
  def orgs2csv(orgs, fields, file)
    rows = []
    orgs.each do |org|
      orgfilings = flatten_filings(org, fields)
      orgfilings.each do |orgfiling|
        rows << orgfiling
      end
    end
    CSV.open(file, "w") do |csv|
      csv << fields.values
      rows.each do |r|
        csv << r
      end
    end
  end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  dir = File.join(Dir.pwd, '_data')

  # ein = '874640985'
  # org = Propublica990.get_org(ein, dir, true)
  # puts Propublica990.report_org(ein, dir)

  orgs = Propublica990.get_orgs(Propublica990::LOCAL_NEWS, dir)
  csvfile = File.join(dir, "report-allnews.csv")
  Propublica990.orgs2csv(orgs, FieldMap990::MAP_COMMON, csvfile)
end
