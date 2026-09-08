# Third-party data

## GeoNames

The offline worldwide city search is built from the GeoNames `cities5000` dump and `countryInfo.txt`.

- Source: GeoNames geographical database
- License: Creative Commons Attribution 4.0 (CC BY 4.0)
- Project: https://www.geonames.org/

The build process keeps only the fields needed for local city lookup, prayer-time coordinates and timezone selection. The raw GeoNames dump is not shipped unchanged.

## OpenStreetMap / Nominatim

The optional **Search online** fallback uses the public OpenStreetMap Nominatim service only after an explicit user action. Requests are rate-limited, identify the application with a User-Agent, and repeated identical queries are cached in memory for the app session.

Search results are attributed to OpenStreetMap contributors in the city picker UI.
