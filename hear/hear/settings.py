# -*- coding: utf-8 -*-

# MediaWiki URL for recent changes
SSE_URL = 'https://stream.wikimedia.org/v2/stream/recentchange'

# dockerized PG connection
DB_URL = "postgresql:///clutter"

# events table
SCHEMA = "clutter_raw"
EVENTS = "events"
