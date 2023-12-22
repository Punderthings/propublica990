# Propublica990 Ruby utility modules

Ruby utility modules using Propublica's V2 API to get basic 990 financials easily.

## Timeline of 990 data publication by IRS

The IRS' publication of 990 data forms has changed over the years, sometimes significantly.  Many older 990 code projects were designed for either earlier data structures or ways to get the 990 data (from AWS, from IRS, or elsewhere).  Caution is advised when evaluating code!

## More useful IRS 990 analysis tools

[IRSx](http://www.irsx.info/) is a [comprehensive Python toolkit and database](https://github.com/jsfenfen/990-xml-reader/) for grabbing, parsing, and manipulating the full 990 XML structures.

Nonprofit Open Data Collective's [irs990efile](https://github.com/Nonprofit-Open-Data-Collective/irs990efile) R project includes a great [data dictionary mapping fields](https://nonprofit-open-data-collective.github.io/irs990efile/data-dictionary/data-dictionary.html) across 990, EZ, and PF forms. A prior version was called [irs-990-efiler-database](https://github.com/Nonprofit-Open-Data-Collective/irs-990-efiler-database).

Open Data Collective also has an [overview of other 990 resources](https://github.com/Nonprofit-Open-Data-Collective/irs-990-data-issue-tracker), and some [R tools for compensation and director/officer name scanning](https://github.com/Nonprofit-Open-Data-Collective/irs-990-compensation-data).

TechByOrg's [irs-990-api](https://github.com/techbyorg/irs-990-api) uses GraphQL to build and analyze databases of 990 data.

[CharityNavigator's (archived) 990_long](https://github.com/CharityNavigator/990_long) R/python code and analysis of 990 forms was built on top of the [(obsolete) irs_990 Python/SQL tools](https://github.com/CharityNavigator/irs990).

For 990PF Private Foundation tools, [Grantmakers](https://www.grantmakers.io/) has code and databases to help.

For ad hoc research, Guidestar and Foundation Center have merged into [Candid](https://beta.candid.org/), a more comprehensive nonprofit search website.
