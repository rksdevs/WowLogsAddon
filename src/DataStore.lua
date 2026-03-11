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

WowLogsDataStore = {}

-- Getter functions for compressed data
local function getDict(id)
  local dict = WowLogsAddonDB and WowLogsAddonDB.rankings and WowLogsAddonDB.rankings.dict
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

-- CSV Lazy String Parser
function WowLogsDataStore.Query(isPerf, filters)
  local db = WowLogsDataStore.GetDb()
  local out = {}
  local source = isPerf and (db.rankings and db.rankings.performanceRows) or (db.rankings and db.rankings.rows)
  if not source then return out end

  local dict = db.rankings and db.rankings.dict or {}
  
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
    else
      table.insert(out, rowStr)
    end
  end
  return out
end

function WowLogsDataStore.QueryBosses(isPerf, fRaidId, fDifficultyText)
  local db = WowLogsDataStore.GetDb()
  local source = isPerf and (db.rankings and db.rankings.performanceRows) or (db.rankings and db.rankings.rows)
  if not source then return {} end

  local dict = db.rankings and db.rankings.dict or {}
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
  local db = WowLogsDataStore.GetDb()
  local lastUpdate = db.rankings and db.rankings.updatedAt or 0
  
  if not runtimePlayerCache or runtimePlayerCache._updatedAt ~= lastUpdate then
    runtimePlayerCache = { _updatedAt = lastUpdate }
    local dict = db.rankings and db.rankings.dict or {}
    
    local function getP(playerName, pClassId)
       local k = WowLogsNormalizeKey(playerName, realm)
       if not runtimePlayerCache[k] then
         runtimePlayerCache[k] = {
           playerName = playerName,
           playerClass = dict[tonumber(pClassId)] or pClassId,
           points = 0,
           overallRank = nil,
           rankings = {}
         }
       end
       return runtimePlayerCache[k]
    end

    -- 1. Scan Points Rows (rows) for overall points and ranks
    local rows = db.rankings and db.rankings.rows or {}
    for i=1, #rows do
      local rowStr = rows[i]
      if type(rowStr) == "string" then
        -- key,playerName,classID,specID,raidId,raidNameID,bossId,bossNameID,difficultyID,points,percentile,categoryRank,isFollowed
        local k, n, c, s, ri, rn, bi, bn, d, p, pc, cr, f = strsplit(",", rowStr)
        local pObj = getP(n, c)
        local pts = tonumber(p) or 0
        
        -- Update total points and overall rank (taking the best rank/points found)
        if pts > pObj.points then
            pObj.points = pts
            pObj.overallRank = cr
        end

        -- Aggregated ranking (one per spec/difficulty)
        table.insert(pObj.rankings, {
          difficulty = dict[tonumber(d)] or d,
          spec = dict[tonumber(s)] or s,
          rank = cr,
          points = pts
        })
      end
    end

    -- Note: Performance rows are skipped for tooltips to keep it clean, 
    -- showing only the summarized Phase Points per Spec/Difficulty.
  end

  return runtimePlayerCache[lookupKey]
end

function WowLogsDataStore.GetUpdatedAt()
  ensureDb()
  return WowLogsAddonDB.rankings.updatedAt or 0
end

function WowLogsDataStore.Now()
  return now()
end
