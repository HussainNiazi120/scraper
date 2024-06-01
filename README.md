# Web Scraper

This application is built with **Ruby v3.3.1** and **Rails 7.1.3.3**. It scrapes data from webpages based on meta tag names and CSS selectors.

## Features

- Uses [Nokogiri](https://nokogiri.org/) to parse and scrape HTML.
- Caches HTML into Redis cache store for faster subsequent requests.
- Uses [Hotwire](https://hotwire.dev/) turbostreams and [Stimulus.js](https://stimulus.hotwire.dev/) for UI.
- Supports JSON requests to endpoint `POST /scraper/scrape`.

## Usage

Send a POST request to `/scraper/scrape` with the following JSON parameters:

```json
{
    "url": "https://www.alza.cz/aeg-7000-prosteam-lfr73964cc-d7635493.htm",
    "fields": {
        "meta": ["keywords", "twitter:image"],
        "price": ".price-box__price",
        "rating_count": ".ratingCount",
        "rating_value": ".ratingValue"
    }
}
```

The response will look like this:

```json
{
    "price": "18290,-",
    "rating_value": "4,9",
    "rating_count": "7 hodnocení",
    "meta": {
        "keywords": "Parní pračka AEG 7000 ProSteam® LFR73964CC na www.alza.cz. ✅ Bezpečný nákup. ✅ Veškeré informace o produktu. ✅ Vhodné příslušenství. ✅ Hodnocení a recenze AEG...",
        "twitter:image": "https://image.alza.cz/products/AEGPR065/AEGPR065.jpg?width=360&height=360"
    }
}
```

## Live Demo

A working example can be seen at https://scraper.niazi.pl/.

