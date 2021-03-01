---
page_type: sample
languages:
- tsql
- sql
- csharp
products:
- azure-sql-database
- azure
- dotnet
- dotnet-core
- azure-web-app
description: "Real-Time Serverless GeoSpatial Public Transportation GeoFencing Solution"
urlFragment: "azure-sql-db-serverless-geospatial"
---

# Dynamic Schema Management With Azure SQL

<!-- 
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

![License](https://img.shields.io/badge/license-MIT-green.svg)

A sample project that shows how to deal with dynamic schema in Azure SQL, using the native JSON support and then three options

- The "Classic" Table 
- An Hybrid Table with some well-known columns an "Extension" column to hold arbitrary JSON data
- A full "Document" approach where data is fully stored as JSON document

