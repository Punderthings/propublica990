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
  require_relative 'fieldmap990'

  # Constants related to ProPublica API v2
  PROPUBLICA_APIV2 = 'https://projects.propublica.org/nonprofits/api/v2/organizations/'
  PROPUBLICA_APIV2_JSON = '.json'
  ORGANIZATION = 'organization'
  ORG_NAME = 'name'
  FILINGS = 'filings_with_data'

  # Fetch an org's data from ProPublica as json hash
  def fetch_org(ein)
    begin
      return JSON.load(URI.open(PROPUBLICA_APIV2 + ein + PROPUBLICA_APIV2_JSON))
    rescue OpenURI::HTTPError => e
      puts "HTTPError: fetching #{ein} (possibly bad EIN) threw: #{e.message}"
      return nil
    end
  end

  # Cache org's data in local file
  # @return true if we updated the file because any newer filing data found
  def cache_org(ein, file)
    org = fetch_org(ein)
    if org.nil?
      # NOTE there's nothing we can do here; Propublica doesn't have any data
      return false
    end
    newerdata = true
    if File.exist?(file)
      cache = JSON.load_file(file)
      newdate = org[FILINGS].map { |i| DateTime.parse(i["updated"]) }.max
      if newdate.nil?
        newerdata = false # FIXME validate what we want here; maybe check vs. org.updated_at?
      else
        cachedate = cache[FILINGS].map { |i| DateTime.parse(i["updated"]) }.max
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
  # @return hash of Propublica Organization object; nil if errors
  def get_org(ein, dir, refresh = false)
    file = File.join(dir, "#{ein}.json")
    if refresh or !File.exist?(file)
      Dir.mkdir(dir) unless Dir.exist?(dir)
      unused = cache_org(ein, file)
    end
    if File.exist?(file)
      return JSON.load_file(file)
    else
      puts "ERROR: get_org(#{ein}) Bad EIN or No such file or directory #{file}"
      return nil
    end
  end

  # Get and cache an array of eins as orgs
  # @return hash of { ein => { orghash }, ... } where any org with an error returns orghash as a string
  def get_orgs(eins, dir, refresh = false)
    orgs = {}
    eins.each do |ein|
      org = get_org(ein, dir, refresh)
      if org.nil? || org.empty?
        orgs[ein] = "ERROR: get_orgs(#{ein}...) returned nil or empty data"
      else
        orgs[ein] = org
      end
    end
    return orgs
  end

  # Emit a simple hash describing the org and recent filings available
  # TODO Decide on minimal fields useful for comparisons
  def report_org(ein, dir)
    o = get_org(ein, dir)
    org = o[ORGANIZATION]
    report = {ORG_NAME => org[ORG_NAME]}
    %w(state subsection_code ruling_date tax_period ntee_code classification_codes).each do |field|
      report[field] = org[field]
    end
    return report
  end

  # Return flattened version of a single filing's fields
  # @param filing single filings_with_data hash
  # @param fields, fieldname mapping
  # @param id, to use as first value in row (presumably name)
  # @return array of values only matching the fields map
  def flatten_filing(filing, fields, id)
    flat = [id]
    fields.each do |field, displayname|
      flat << filing[field]
    end
   return flat
  end

  # Return flattened list of filings_with_data from an org, plus the name
  # @param org to process
  # @param map of fieldnames to process
  # @return array of arrays of flattened data just for fieldnames
  def flatten_filings(org, fields)
    rows = []
    filings = org[FILINGS]
    if filings.size > 0
      filings.each do |filing|
        rows << flatten_filing(filing, fields, org[ORGANIZATION][ORG_NAME])
      end
    else
      puts "WARNING: flatten_filings(#{org[ORGANIZATION][EIN]}, #{org[ORGANIZATION][ORG_NAME]}) no filings_with_data found."
    end
    return rows
  end

  # Transform an array of orgs into a simple csv by ein,year across available data
  # @param file to write csv to
  def orgs2csv(orgs, fields, file)
    rows = []
    orgs.each do |org|
      if org.is_a?(Hash) # Note get_orgs may return error conditions as a String
        orgfilings = flatten_filings(org, fields)
        orgfilings.each do |orgfiling|
          rows << orgfiling
        end
      end
    end
    CSV.open(file, "w", force_quotes: true) do |csv|
      csv << ['Name', *fields.values]
      rows.each do |r|
        csv << r
      end
    end
  end

  # Return flattened version of a single filing's fields, common only
  #   NOTE: not all common fields are exact same; does not handle PF currently
  # @param filing one filings_with_data hash
  # @param org object of the organization itself
  # @return array of values from that filing
  def flatten_filing_common(filing, org)
    flat = [org[ORG_NAME], org['city'], org['state']]
    form = filing[FieldMap990::FORMTYPE]
    mapping = FieldMap990::MAP_FORMTYPE_COMMON[form]
    if mapping
      mapping.each do |field, displayname|
        flat << filing[field]
      end
    else
      # FIXME: how should we report this error?
      flat << "ERROR: flatten_filing_common(#{flat}) formtype #{form}) not supported."
    end
   return flat
  end

  # Return flattened list of filings_with_data common fields from an org, plus the name
  def flatten_filings_common(org)
    rows = []
    filings = org[FILINGS]
    if filings.size > 0
      filings.each do |filing|
        rows << flatten_filing_common(filing, org[ORGANIZATION])
      end
    else
      puts "WARNING: flatten_filings_common(... #{org[ORGANIZATION]['ein']})  no filings_with_data found."
    end
    return rows
  end

  # Return latest filing object, or attempt fallback if data not available
  def get_latest_filing(org, backups)
    filings = org[FILINGS]
    filing = filings.first
    if filing
      return flatten_filing_common(filing, org[ORGANIZATION])
    elsif backups
      row = []
      # Return whatever data is available from backups instead (i.e. manually collected)
      row << org[ORGANIZATION][ORG_NAME]
      row << org[ORGANIZATION]['city']
      row << org[ORGANIZATION]['state']
      FieldMap990::MAP_990_COMMON.each do | field, noop |
        row << (backups[field] ? backups[field] : '')
      end
      return row
    else
      return nil
    end
  end

  # Transform hash of orghashes into a simple csv by ein,year across PC-EZ normalized common data (approximate)
  def orgs2csv_common(orgs, file)
    rows = []
    orgs.each do |ein, org|
      if org.is_a?(Hash) # Note get_orgs may return error conditions as a String
        orgfilings = flatten_filings_common(org)
        orgfilings.each do |orgfiling|
          rows << orgfiling
        end
      else
        puts "#{org}"
      end
    end
    CSV.open(file, "w", force_quotes: true) do |csv|
      csv << ['Name', 'City', 'State', *FieldMap990::MAP_990_COMMON.values]
      rows.each do |r|
        csv << r
      end
    end
  end
end

# ### #### ##### ######
# Main method for command line use
if __FILE__ == $PROGRAM_NAME
  dir = File.join(Dir.pwd, '_data')
  ein = '460777549' # Bedford Citizen
  # org = Propublica990.get_org(ein, dir, true)
  # puts Propublica990.report_org(ein, dir)
  # csvfile = File.join(dir, "report-news-common.csv")
  # Propublica990.orgs2csv_common(orgs, csvfile)
  backups = {
    'ein' => ein,
    'tax_prd_yr' => 'Tax Year',
    'tax_prd' => 'Tax Period End',
    'formtype' => 'HACKED data',
    'totcntrbgfts' => '1234',
    'invstmntinc' => 0,
    #'totprgmrevnue' => 'Program Service Revenue',
    'totrevenue' => '234',
    'totfuncexpns' => 234,
    'totassetsend' => '111',
    'totliabend' => '222',
    'totnetassetend' => '333'
  }
  ein = '920697644'
  org = Propublica990.get_org(ein, dir, true)
  filing = Propublica990.get_latest_filing(org, backups)
  puts JSON.pretty_generate(filing)

end
