local function now()
  return time()
end

local function ensureDb()
  WowLogsAddonDB = WowLogsAddonDB or {}
  WowLogsAddonDB.meta = WowLogsAddonDB.meta or {}
  WowLogsAddonDB.rankings = WowLogsAddonDB.rankings or { players = {}, updatedAt = 0 }

  if not WowLogsAddonDB.rankings.players then
    WowLogsAddonDB.rankings.players = {}
  end

  if not WowLogsAddonDB.meta.version then
    WowLogsAddonDB.meta.version = WowLogsConfig.SCHEMA_VERSION
  end
end

--- Native Uploader writes full rankings to WowLogsRankingsPayload (RankingsPayload.lua under the addon folder).
--- SavedVariables cannot be refreshed cleanly from disk on /reload while WoW is running; this table can.
local function getRankings()
  ensureDb()
  local p = rawget(_G, "WowLogsRankingsPayload")
  if type(p) == "table" and (p.updatedAt or 0) > 0 then
    return p
  end
  return WowLogsAddonDB.rankings
end

WowLogsDataStore = {}

-- Filters used when slicing is done in the Native Uploader; in-game we show the full export.
WowLogsDataStore.OPEN_FILTERS = {
  raidId = "ALL",
  bossId = "ALL",
  bossVariant = "ALL",
  difficulty = "ALL",
  className = "ALL",
  spec = "ALL",
  role = "ALL",
  ladder = "ALL",
}

-- Getter functions for compressed data
local function getDict(id)
  local rk = getRankings()
  local dict = rk and rk.dict
  if not dict or not id then return id end
  local numId = tonumber(id)
  if numId and dict[numId] then return dict[numId] end
  return dict[id] or id
end

function WowLogsDataStore.GetKey(r) return r.key or r.k end
function WowLogsDataStore.GetPlayerName(r) return r.playerName or r.n end
function WowLogsDataStore.GetPlayerClass(r) return r.playerClass or getDict(r.c) end
function WowLogsDataStore.GetPlayerSpec(r) return r.playerSpec or getDict(r.s) end
function WowLogsDataStore.GetRaidId(r) return r.raidId or r.ri end
function WowLogsDataStore.GetRaidName(r) return r.raidName or getDict(r.rn) end
function WowLogsDataStore.GetBossId(r) return r.bossId or r.bi end
function WowLogsDataStore.GetBossName(r) return r.bossName or getDict(r.bn) end
function WowLogsDataStore.GetDifficulty(r) return r.difficulty or getDict(r.d) end
function WowLogsDataStore.GetPoints(r) return r.points or r.p end
function WowLogsDataStore.GetPercentile(r) return r.percentile or r.pc end
function WowLogsDataStore.GetCategoryRank(r) return r.categoryRank or r.cr end
function WowLogsDataStore.GetV2SpecPct(r) return r.sp end
function WowLogsDataStore.GetV2ClassPct(r) return r.cp end
function WowLogsDataStore.GetV2RolePct(r) return r.rp end
function WowLogsDataStore.GetRole(r) return r.role or getDict(r.ro) end
function WowLogsDataStore.GetLadder(r) return r.ladder or getDict(r.l) end
function WowLogsDataStore.GetAmount(r) return r.amount or r.a end
function WowLogsDataStore.GetTrend(r) return r.trend or r.t end
function WowLogsDataStore.GetLatestDate(r) return r.latestDate or r.ld end
function WowLogsDataStore.GetIsFollowed(r)
  if type(r.isFollowed) ~= "nil" then return r.isFollowed end
  return r.f
end

function WowLogsDataStore.Init()
  ensureDb()
end

function WowLogsDataStore.GetDb()
  ensureDb()
  return WowLogsAddonDB
end

function WowLogsDataStore.GetRankings()
  return getRankings()
end

-- CSV Lazy String Parser
function WowLogsDataStore.Query(isPerf, filters)
  local out = {}
  local rk = getRankings()
  local source = isPerf and (rk and rk.performanceRows) or (rk and rk.rows)
  if not source then return out end

  local dict = rk and rk.dict or {}
  local pointsV2 = rk and rk.pointsV2
  
  local function getReverseDictId(val)
    if not val or val == "ALL" then return nil end
    for id, str in pairs(dict) do
      if str == val then return tostring(id) end
    end
    return tostring(val)
  end

  local fRaidId = filters.raidId ~= "ALL" and tostring(filters.raidId) or nil
  local fBossId = filters.bossId ~= "ALL" and tostring(filters.bossId) or nil
  local fDifficulty = getReverseDictId(filters.difficulty)
  local fClass = getReverseDictId(filters.className)
  local fSpec = getReverseDictId(filters.spec)
  local fRole = getReverseDictId(filters.role)
  local fLadder = getReverseDictId(filters.ladder)

  for i = 1, #source do
    local rowStr = source[i]
    if type(rowStr) == "string" then
      if isPerf then
        -- key,playerName,classID,specID,roleID,ladderID,raidId,raidNameID,bossId,bossNameID,difficultyID,amount,percentile,categoryRank,isFollowed,trend,latestDate
        local k, n, c, s, ro, l, ri, rn, bi, bn, d, a, pc, cr, f, t, ld = strsplit(",", rowStr)
        
        local pass = true
        if pass and fRaidId and ri ~= fRaidId then pass = false end
        if pass and fBossId and bi ~= fBossId then pass = false end
        if pass and fDifficulty and d ~= fDifficulty then pass = false end
        if pass and fClass and c ~= fClass then pass = false end
        if pass and fSpec and s ~= fSpec then pass = false end
        if pass and fRole and ro ~= fRole then pass = false end
        if pass and fLadder and l ~= fLadder then pass = false end

        if pass then
          table.insert(out, { k=k, n=n, c=c, s=s, ro=ro, l=l, ri=ri, rn=rn, bi=bi, bn=bn, d=d, a=tonumber(a), pc=tonumber(pc), cr=cr, f=(f=="true"), t=tonumber(t), ld=(ld=="nil" and nil or ld) })
        end
      else
        if pointsV2 then
          -- V2: key,playerName,classID,specID,roleID,points,specPct,classPct,rolePct,categoryRank,isFollowed
          local k, n, c, s, ro, p, sp, cp, rp, cr, f = strsplit(",", rowStr)
          local pass = true
          if pass and fClass and c ~= fClass then pass = false end
          if pass and fSpec and s ~= fSpec then pass = false end
          if pass and fRole and ro ~= fRole then pass = false end
          if pass then
            table.insert(out, {
              k = k, n = n, c = c, s = s, ro = ro,
              p = tonumber(p), sp = tonumber(sp), cp = tonumber(cp), rp = tonumber(rp),
              cr = cr, f = (f == "true"),
            })
          end
        else
        -- key,playerName,classID,specID,raidId,raidNameID,bossId,bossNameID,difficultyID,points,percentile,categoryRank,isFollowed
        local k, n, c, s, ri, rn, bi, bn, d, p, pc, cr, f = strsplit(",", rowStr)

        local pass = true
        if pass and fRaidId and ri ~= fRaidId then pass = false end
        if pass and fBossId and bi ~= fBossId then pass = false end
        if pass and fDifficulty and d ~= fDifficulty then pass = false end
        if pass and fClass and c ~= fClass then pass = false end
        if pass and fSpec and s ~= fSpec then pass = false end

        if pass then
          table.insert(out, { k=k, n=n, c=c, s=s, ri=ri, rn=rn, bi=bi, bn=bn, d=d, p=tonumber(p), pc=tonumber(pc), cr=cr, f=(f=="true") })
        end
        end
      end
    else
      table.insert(out, rowStr)
    end
  end
  return out
end

--- All rows for the active export (no in-game filter UI), optionally narrowed by player name.
function WowLogsDataStore.QueryWithSearch(isPerf, searchText)
  local all = WowLogsDataStore.Query(isPerf, WowLogsDataStore.OPEN_FILTERS)
  if not searchText or searchText == "" then
    return all
  end
  local needle = string.lower(searchText)
  local out = {}
  for i = 1, #all do
    local entry = all[i]
    local name = WowLogsDataStore.GetPlayerName(entry) or ""
    if string.find(string.lower(name), needle, 1, true) then
      table.insert(out, entry)
    end
  end
  return out
end

function WowLogsDataStore.QueryBosses(isPerf, fRaidId, fDifficultyText)
  local rk = getRankings()
  local source = isPerf and (rk and rk.performanceRows) or (rk and rk.rows)
  if not source then return {} end

  local dict = rk and rk.dict or {}
  local function getReverseDictId(val)
    if not val or val == "ALL" then return nil end
    for id, str in pairs(dict) do
      if str == val then return tostring(id) end
    end
    return tostring(val)
  end

  local fDifficulty = getReverseDictId(fDifficultyText)
  if fRaidId == "ALL" then fRaidId = nil end

  local map = {}
  local out = {}

  for i = 1, #source do
    local rowStr = source[i]
    if type(rowStr) == "string" then
      local ri, bi, bn, d
      if isPerf then
        local _, _, _, _, _, _, raidId, _, bossId, bossNameID, difficultyID = strsplit(",", rowStr)
        ri, bi, bn, d = raidId, bossId, bossNameID, difficultyID
      else
        local _, _, _, _, raidId, _, bossId, bossNameID, difficultyID = strsplit(",", rowStr)
        ri, bi, bn, d = raidId, bossId, bossNameID, difficultyID
      end
      
      local pass = true
      if pass and fRaidId and ri ~= fRaidId then pass = false end
      if pass and fDifficulty and d ~= fDifficulty then pass = false end

      if pass and bi and bi ~= "nil" and bn and d then
        local bkey = bi .. "|" .. d
        if not map[bkey] then
          map[bkey] = true
          table.insert(out, { key = bkey, bossId = bi, bossName = dict[tonumber(bn)] or bn, difficulty = dict[tonumber(d)] or d })
        end
      end
    else
      -- backward compatible table path
      local ri = WowLogsDataStore.GetRaidId(rowStr)
      local bi = WowLogsDataStore.GetBossId(rowStr)
      local bn = WowLogsDataStore.GetBossName(rowStr)
      local d = WowLogsDataStore.GetDifficulty(rowStr)

      local pass = true
      if pass and fRaidId and tostring(ri) ~= fRaidId then pass = false end
      if pass and fDifficultyText and fDifficultyText ~= "ALL" and d ~= fDifficultyText then pass = false end

      if pass and bi and bn and d then
        local bkey = tostring(bi) .. "|" .. tostring(d)
        if not map[bkey] then
          map[bkey] = true
          table.insert(out, { key = bkey, bossId = tostring(bi), bossName = bn, difficulty = d })
        end
      end
    end
  end

  return out
end

local runtimePlayerCache = nil

function WowLogsDataStore.GetPlayerRanking(name, realm)
  ensureDb()
  local lookupKey = WowLogsNormalizeKey(name, realm)
  
  -- Build/Refresh cache if missing or data updated
  local rk = getRankings()
  local lastUpdate = rk and rk.updatedAt or 0
  
  if not runtimePlayerCache or runtimePlayerCache._updatedAt ~= lastUpdate then
    runtimePlayerCache = { _updatedAt = lastUpdate }
    local dict = rk and rk.dict or {}
    
    local tempMap = {}

    local rows = rk and rk.rows or {}
    if rk.pointsV2 then
      for i = 1, #rows do
        local rowStr = rows[i]
        if type(rowStr) == "string" then
          -- V2: key,playerName,classID,specID,roleID,points,specPct,classPct,rolePct,categoryRank,isFollowed
          local _, n, c, s, ro, p, _, _, _, cr, _ = strsplit(",", rowStr)
          local pKey = WowLogsNormalizeKey(n, realm)
          local pts = tonumber(p) or 0
          local specStr = dict[tonumber(s)] or s
          local roleStr = dict[tonumber(ro)] or ro
          local classStr = dict[tonumber(c)] or c

          if not tempMap[pKey] then
            tempMap[pKey] = {
              playerName = n,
              playerClass = classStr,
              points = 0,
              overallRank = nil,
              specDiffMap = {},
            }
          end
          local pData = tempMap[pKey]
          if pts > pData.points then
            pData.points = pts
            pData.overallRank = cr
          end
          local sdKey = specStr .. "|" .. roleStr
          local existing = pData.specDiffMap[sdKey]
          if not existing or pts > existing.points then
            pData.specDiffMap[sdKey] = {
              difficulty = "V2",
              spec = specStr .. " · " .. roleStr,
              rank = cr,
              points = pts,
            }
          end
        end
      end
    else
    for i=1, #rows do
      local rowStr = rows[i]
      if type(rowStr) == "string" then
        -- key,playerName,classID,specID,raidId,raidNameID,bossId,bossNameID,difficultyID,points,percentile,categoryRank,isFollowed
        local rowKey, n, c, s, ri, rn, bi, bn, d, p, pc, cr, f = strsplit(",", rowStr)
        local pKey = WowLogsNormalizeKey(n, realm)
        local pts = tonumber(p) or 0
        local specStr = dict[tonumber(s)] or s
        local diffStr = dict[tonumber(d)] or d
        local classStr = dict[tonumber(c)] or c

        if not tempMap[pKey] then
          tempMap[pKey] = {
            playerName = n,
            playerClass = classStr,
            points = 0,
            overallRank = nil,
            specDiffMap = {}
          }
        end
        local pData = tempMap[pKey]

        -- Track overall best points + rank
        if pts > pData.points then
          pData.points = pts
          pData.overallRank = cr
        end

        -- Deduplicate by spec+difficulty: keep only highest-points row
        local sdKey = specStr .. "|" .. diffStr
        local existing = pData.specDiffMap[sdKey]
        if not existing or pts > existing.points then
          pData.specDiffMap[sdKey] = {
            difficulty = diffStr,
            spec = specStr,
            rank = cr,
            points = pts
          }
        end
      end
    end
    end

    -- Flatten specDiffMap into a rankings list for each player
    for pKey, pData in pairs(tempMap) do
      local rankings = {}
      for _, entry in pairs(pData.specDiffMap) do
        table.insert(rankings, entry)
      end
      runtimePlayerCache[pKey] = {
        playerName = pData.playerName,
        playerClass = pData.playerClass,
        points = pData.points,
        overallRank = pData.overallRank,
        rankings = rankings
      }
    end
  end

  return runtimePlayerCache[lookupKey]
end

function WowLogsDataStore.GetUpdatedAt()
  ensureDb()
  local rk = getRankings()
  return (rk and rk.updatedAt) or 0
end

function WowLogsDataStore.Now()
  return now()
end
