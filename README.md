# Propublica990 Ruby utility modules

Ruby utility modules wrapping Propublica's Nonprofit Explorer V2 API to get key nonprofit tax data from IRS 990 or 990-EZ forms simply.

## Functions provided

Propublica990 is designed to quickly get good enough data for a list of EINs to compare any filed 990/990EZ forms that Propublica has imported and parsed.  Given that many charities file late, and it takes a while for forms to come from the IRS and get scanned by Propublica, expect a year or more delay in the data.

This module provides simple wrappers to get lists of organizations and filings, cache the JSON data structures returned in a local directory (be kind to Propublica servers), and then create some simple flattened CSV views of key tax financials.

Used in [FOSS Foundations](https://github.com/Punderthings/fossfoundation) and [Arlington MA Data](https://github.com/ArlingtonMA/arlingtonma.info/).

## Timeline of 990 data publication by IRS

The IRS' publication of 990 data forms has changed over the years, sometimes significantly.  Many older 990 code projects were designed for either earlier data structures or ways to get the 990 data (from AWS, from IRS, or elsewhere).  Caution is advised when evaluating any projects that gather or manipulate IRS 990 forms!

## Credits

As noted in the [ProPublica Nonprofit Explorer API docs](https://www.propublica.org/datastore/api/nonprofit-explorer-api), this makes use of their excellent tools and data sources:

> ProPublica Nonprofit Explorer API: https://projects.propublica.org/nonprofits/api/
> IRS Exempt Organizations Business Master File Extract (EO BMF): https://www.irs.gov/charities-non-profits/exempt-organizations-business-master-file-extract-eo-bmf
> IRS Annual Extract of Tax-Exempt Organization Financial Data: https://www.irs.gov/uac/soi-tax-stats-annual-extract-of-tax-exempt-organization-financial-data

## More useful IRS 990 analysis tools

[IRSx](http://www.irsx.info/) is a [comprehensive Python toolkit and database](https://github.com/jsfenfen/990-xml-reader/) for grabbing, parsing, and manipulating the full 990 XML structures.

Nonprofit Open Data Collective's [irs990efile](https://github.com/Nonprofit-Open-Data-Collective/irs990efile) R project includes a great [data dictionary mapping fields](https://nonprofit-open-data-collective.github.io/irs990efile/data-dictionary/data-dictionary.html) across 990, EZ, and PF forms. A prior version was called [irs-990-efiler-database](https://github.com/Nonprofit-Open-Data-Collective/irs-990-efiler-database).

Open Data Collective also has an [overview of other 990 resources](https://github.com/Nonprofit-Open-Data-Collective/irs-990-data-issue-tracker), and some [R tools for compensation and director/officer name scanning](https://github.com/Nonprofit-Open-Data-Collective/irs-990-compensation-data).

TechByOrg's [irs-990-api](https://github.com/techbyorg/irs-990-api) uses GraphQL to build and analyze databases of 990 data.

[CharityNavigator's (archived) 990_long](https://github.com/CharityNavigator/990_long) R/python code and analysis of 990 forms was built on top of the [(obsolete) irs_990 Python/SQL tools](https://github.com/CharityNavigator/irs990).

For 990PF Private Foundation tools, [Grantmakers](https://www.grantmakers.io/) has code and databases to help.

For ad hoc research, Guidestar and Foundation Center have merged into [Candid](https://beta.candid.org/), a more comprehensive nonprofit search website.
