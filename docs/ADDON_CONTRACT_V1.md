# Addon Contract v1

## SavedVariables
`WowLogsAddonDB`

### Shape
- `meta.version`: addon data schema version
- `rankings.updatedAt`: unix timestamp
- `rankings.players`: map keyed by normalized player key (`name-realm` lowercased)

### Ranking Row
- `playerName`: string
- `realm`: string
- `server`: string
- `playerClass`: string
- `overallRank`: number
- `points`: number

Native uploader writes this payload. Addon reads and displays it.
