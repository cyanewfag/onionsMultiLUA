local imageLib = require("gamesense/images") or client.log("[Optional] Images Library\nhttps://gamesense.pub/forums/viewtopic.php?id=22917");

local js = panorama.open();
local GameStateAPI = js.GameStateAPI;
local localPlayer = entity.get_local_player();
local playerResource = entity.get_player_resource();
local gameRules = entity.get_game_rules();
local scrW, scrH = client.screen_size();

local hitGroups = {"head", "chest", "stomach", "arms", "arms", "legs", "legs", "generic"};
local loggedShots = {};
local loggedChat = {};

client.set_event_callback("player_chat", function(e)
    if (e.entity ~= nil) then manageChats(Chat(e.name, e.text, entity.get_steam64(e.entity), entity.get_prop(playerResource, "m_iTeam", e.entity))); end
end)

function manageChats(chat)
    if (#loggedChat > 10) then
        table.remove(loggedChat, 1);      
    end

    table.insert(loggedChat, chat)
end

function manageShots(shot)
    if (#loggedShots > 5) then
        table.remove(loggedShots, 1);      
    end

    table.insert(loggedShots, shot)
end

client.set_event_callback('aim_hit', function(e)
    local hitbox = hitGroups[e.hitgroup];
    if (e.hitgroup > #hitGroups - 1) then hitbox = hitGroups[#hitGroups]; end
    local target = entity.get_player_name(e.target);
    local steamID; if (not GameStateAPI.IsFakePlayer(e.target)) then steamID = GameStateAPI.GetPlayerXuidStringFromEntIndex(e.target); end

    manageShots(Shot(target, steamID, hitbox, e.damage, math.floor(e.hit_chance), true));
end)

client.set_event_callback('aim_miss', function(e)
    local hitbox = hitGroups[e.hitgroup];
    if (e.hitgroup > #hitGroups - 1) then hitbox = hitGroups[#hitGroups]; end
    local target = entity.get_player_name(e.target);
    local steamID; if (not GameStateAPI.IsFakePlayer(e.target)) then steamID = GameStateAPI.GetPlayerXuidStringFromEntIndex(e.target); end

    manageShots(Shot(target, steamID, hitbox, nil, math.floor(e.hit_chance), false, e.reason));
end)

-- Library
local Rects = {};
Rects.__index = Rects;

local Colors = {};
Colors.__index = Colors;

local Shots = {};
Shots.__index = Shots;

local Vector = {};
Vector.__index = Vector;

local Vector2D = {};
Vector2D.__index = Vector2D;

local Chats = {};
Chats.__index = Chats;

function Chat(name, text, steamid, teamid)
    if (name == nil or type(name) ~= "string") then name = ""; end
    if (text == nil or type(text) ~= "string") then text = ""; end
    if (steamid ~= nil and type(steamid) ~= "number") then steamid = nil; end
    if (teamid == nil or type(teamid) ~= "number") then teamid = 0; end

    name = name or "";
    text = text or "";
    steamid = steamid or nil;
    teamid = teamid or 0;

    return setmetatable({ name = name, text = text, steamid = steamid, teamid = teamid }, Chats);
end

function Chats:isEnemy()
    if (localPlayer == nil or playerResource == nil) then return nil; end

    if (self.teamid == entity.get_prop(playerResource, "m_iTeam", localPlayer)) then
        return false;
    else
        return true;
    end
end

function Chats:string()
    return self.name .. ": " .. self.text;
end

function Chats:print()
    print(self:string());
end

function Rect(x, y, w, h)
    if (x == nil or type(x) ~= "number") then x = 0; end
    if (y == nil or type(y) ~= "number") then y = 0; end
    if (w == nil or type(w) ~= "number") then w = 0; end
    if (h == nil or type(h) ~= "number") then h = 0; end

    x = x or 0;
    y = y or 0;
    w = w or 0;
    h = h or 0;

    return setmetatable({ x = x, y = y, w = w, h = h }, Rects);
end

function Rects:pointInside(vec)
    if (vec.x >= self.x and vec.x <= self.x + self.w and vec.y >= self.y and vec.y <= self.y + self.h) then
        return true;
    else
        return false;
    end
end

function Shot(target, steamid, hitbox, damage, hitchance, hit, reason)
    if (steamid ~= nil and type(steamid) ~= "number") then steamid = nil; end
    if (hitbox ~= nil and type(hitbox) ~= "string") then hitbox = ""; end
    if (damage == nil or type(damage) ~= "number") then damage = 0; end
    if (hitchance == nil or type(hitchance) ~= "number") then hitchance = 0; end
    if (hit == nil or type(hit) ~= "boolean") then hit = false; end
    if (reason == nil or type(reason) ~= "string") then reason = ""; end

    target = target or nil;
    steamid = steamid or nil;
    hitbox = hitbox or "";
    damage = damage or 0;
    hitchance = hitchance or 0;
    hit = hit or false;
    reason = reason or "";

    return setmetatable({ target = target, steamid = steamid, hitbox = hitbox, damage = damage, hitchance = hitchance, hit = hit, reason = reason }, Shots);
end

function Shots:string()
    if (self.hit) then
        return "Hit in the " .. self.hitbox .. " for " .. self.damage .. "hp with a " .. self.hitchance .. "% hc.";
    else
        return "Shot at the " .. self.hitbox .. " with a " .. self.hitchance .. "% hc, missed due to " .. self.reason .. ".";
    end
end

function Shots:print()
    print(self:string());
end

function Color(r, g, b, a)
    if (r == nil or type(r) ~= "number") then r = 0; end
    if (g == nil or type(g) ~= "number") then g = 0; end
    if (b == nil or type(b) ~= "number") then b = 0; end
    if (a == nil or type(a) ~= "number") then a = 255; end

    r = r or 0;
    g = g or 0;
    b = b or 0;
    a = a or 255;

    return setmetatable({ r = r, g = g, b = b, a = a }, Colors);
end

function Colors:get()
    return self.r, self.g, self.b, self.a;
end

function Colors:string()
    return self.r .. ", " .. self.g .. ", " .. self.b .. ", " .. self.a;
end

function Vector3(x, y, z)
    if (x == nil or type(x) ~= "number") then x = 0; end
    if (y == nil or type(y) ~= "number") then y = 0; end
    if (z == nil or type(z) ~= "number") then z = 0; end

    x = x or 0;
    y = y or 0;
    z = z or 0;

    return setmetatable({ x = x, y = y, z = z }, Vector);
end

function Vector:length()
    return math.sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z));
end

function Vector:distTo(vec)
    return (vec - self):length();
end

function Vector:length2D()
    return math.sqrt((self.x * self.x) + (self.y * self.y));
end

function Vector2(x, y)
    if (x == nil or type(x) ~= "number") then x = 0; end
    if (y == nil or type(y) ~= "number") then y = 0; end

    x = x or 0;
    y = y or 0;

    return setmetatable({ x = x, y = y }, Vector2D);
end

function Vector2D:length()
    return math.sqrt((self.x * self.x) + (self.y * self.y));
end

function Vector2D:distTo(vec)
    return (vec - self):length();
end
