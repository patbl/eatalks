# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Bridgetown-based static site for EA Talks, a podcast featuring presentations and discussions on Effective Altruism. The site dynamically generates individual episode pages from podcast data stored in YAML format.

## Build Commands

### Development
```bash
# Start development server on localhost:4000
bin/bridgetown start

# Watch frontend assets during development
npm run esbuild-dev
```

### Production
```bash
# Full production build (includes frontend assets)
bin/bridgetown deploy

# Or use rake
rake deploy
```

### Other Commands
```bash
# Clean build artifacts
bin/bridgetown clean
# or: rake clean

# Open Ruby console with site context
bin/bridgetown console

# Build frontend assets only
npm run esbuild

# Test build
rake test
```

## Architecture

### Podcast Data Pipeline

The site uses a custom builder system to transform podcast data into episode pages:

1. **Data Source**: `src/_data/episodes.yml` contains podcast metadata and all episode information (titles, descriptions, summaries, slugs, durations, publication dates)

2. **RSS Parser Builder**: `plugins/builders/rss_parser.rb` runs at build time via the `:site, :pre_render` hook to:
   - Load podcast data from YAML
   - Store podcast metadata in `site.data[:podcast]`
   - Parse episodes and generate S3 audio URLs from slugs
   - Store processed episodes in `site.data[:episodes]`
   - Dynamically create individual episode pages using `add_resource :episodes`

3. **Episode Pages**: Each episode gets its own page at `/1755269/episodes/{slug}/` using the `episode` layout

### URL Structure

The site maintains compatibility with Buzzsprout's URL structure:
- Episode list: `/1755269/episodes/`
- Individual episodes: `/1755269/episodes/{slug}/`

### Templates

- Template engine: ERB (configured in `config/initializers.rb`)
- Layouts: `src/_layouts/`
  - `default.erb`: Base layout
  - `episode.erb`: Individual episode pages with audio player and navigation
- Partials: `src/_partials/`
- Episode pages use `site.data.episodes` to access episode data

### Frontend Assets

- JavaScript: `frontend/javascript/index.js`
- CSS: `frontend/styles/` (index.css, podcast.css, syntax-highlighting.css)
- Build tool: esbuild (configured in `esbuild.config.js` and `config/esbuild.defaults.js`)
- PostCSS: Configured with preset-env for CSS processing

### GitHub Pages Deployment

- Production URL: `https://patbl.github.io/eatalks2`
- Base path: `/eatalks2` (configured in `config/initializers.rb` for production only)
- Workflow: `.github/workflows/gh-pages.yml` runs `bin/bridgetown deploy` on push to main

## Key Configuration Files

- `config/initializers.rb`: Site configuration including production URL and base path
- `esbuild.config.js`: Frontend build configuration with production public path
- `Gemfile`: Ruby dependencies (Bridgetown ~> 2.0.5)
- `package.json`: Node dependencies (esbuild, PostCSS)
- `Rakefile`: Build tasks

## Working with Episodes

To add or modify episodes, update `src/_data/episodes.yml`. The builder will automatically:
- Generate the audio URL from the slug
- Create episode pages
- Update the episode list

Audio files are hosted on S3 at: `https://eatalks.s3.us-east-2.amazonaws.com/audio/{slug}.mp3`
