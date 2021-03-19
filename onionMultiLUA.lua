local imageLib = require("gamesense/images") or client.log("[Optional] Images Library\nhttps://gamesense.pub/forums/viewtopic.php?id=22917");

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

local Webhooks = {};
Webhooks.__index = Webhooks;

local Controls = {}
Controls.__index = Controls;

local js = panorama.open();
local GameStateAPI = js.GameStateAPI;
local MatchStatsAPI = js.MatchStatsAPI;
local localPlayer = entity.get_local_player();
local playerResource = entity.get_player_resource();
local gameRules = entity.get_game_rules();
local scrW, scrH = client.screen_size();

local hitGroups = {"head", "chest", "stomach", "arms", "arms", "legs", "legs", "generic"};
local loggedShots = {};
local loggedChat = {};
local ingame = false;
local windows = {{"chatbox", 10, 10, 350, 20, false, 0, 0, true, 250, 500}, {"shotlogs", 10, 10, 350, 20, false, 0, 0, true, 250, 600}, {"spectator", 10, 10, 350, 20, false, 0, 0, false}};
local selectedIndex = 0;
local windowsControls = {}
local visible = true

function toggleControlVisiblity()
    visible = not visible;

    for i = 1, #windowsControls do
        for d = 1, #windowsControls[i] do
            if (type(windowsControls[i][d]) ~= "string") then
                ui.set_visible(windowsControls[i][d], visible)
            end
        end
    end
end

local toggleButton = ui.new_button("LUA", "B", "Edit Positions", toggleControlVisiblity);

for i = 1, #windows do
    if (not windows[i][9]) then
        table.insert(windowsControls, {windows[i][1], ui.new_label("LUA", "B", windows[i][1]), ui.new_slider("LUA", "B", windows[i][1] .. " x - ", 0, scrW, windows[i][2]), ui.new_slider("LUA", "B", windows[i][1] .. " y - ", 0, scrH, windows[i][3])});
    else
        table.insert(windowsControls, {windows[i][1], ui.new_label("LUA", "B", windows[i][1]), ui.new_slider("LUA", "B", windows[i][1] .. " x - ", 0, scrW, windows[i][2]), ui.new_slider("LUA", "B", windows[i][1] .. " y - ", 0, scrH, windows[i][3]), ui.new_slider("LUA", "B", windows[i][1] .. " w - ", windows[i][10], windows[i][11], windows[i][4])});
    end
end

toggleControlVisiblity()

client.set_event_callback("player_chat", function(e)
    if (e.entity ~= nil) then manageChats(Chat(e.name, e.text, entity.get_steam64(e.entity), entity.get_prop(playerResource, "m_iTeam", e.entity))); end
end)

function findWindow(windowName)
    for i = 1, #windowsControls do
        if (windowsControls[i][1] == windowName) then
            return windowsControls[i];
        end
    end

    return nil;
end

function manageChats(chat)
    if (#loggedChat > 10) then
        table.remove(loggedChat, 1);      
    end

    table.insert(loggedChat, chat)
    chat:print()
end

function manageShots(shot)
    if (#loggedShots > 5) then
        table.remove(loggedShots, 1);      
    end

    table.insert(loggedShots, shot)
    Webhooks.send("apikey", shot:string())
    shot:print()
end

function getGamemode()
    local gameMode = cvar.game_mode:get_int()
    local gameType = cvar.game_type:get_int()

    local table = {{{0, 1}, "Competitive"}, {{0, 2}, "Wingman"}, {{0, 3}, "Custom Match"}, {{4, 0}, "Guardian"}, {{4, 1}, "Co-Op Strike"}, {{6, 0}, "Danger Zone"}, {{0, 0}, "Casual"}, {{1, 0}, "Arms Race"}, {{1, 1}, "Demolition"}, {{1, 2}, "Deathmatch"}}  

    for i = 1, #table do
        if (gameMode == table[i][1][1] and gameType == table[i][1][2]) then return table[i][2]; end
    end
    
    return "Unknown";
end

function drawChatbox()
    local controlTable = findWindow("chatbox");
    local control = Control("chatbox", ui.get(controlTable[3]), ui.get(controlTable[4]), ui.get(controlTable[5]), 20)
    control:drawWindow("Chatbox")

    for i = 1, #loggedChat do
        control:drawSlide(loggedChat[i].name, loggedChat[i].text);
    end
end

function drawShotlogs()
    local controlTable = findWindow("shotlogs");
    local control = Control("shotlogs", ui.get(controlTable[3]), ui.get(controlTable[4]), ui.get(controlTable[5]), 20)
    control:drawWindow("Shotlogs")

    for i = 1, #loggedShots do
        control:drawSlide(loggedShots[i].target, loggedShots[i]:string());
    end
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

client.set_event_callback('paint', function()
    local localPlayer = entity.get_local_player();
    local playerResource = entity.get_player_resource();
    local gameRules = entity.get_game_rules();

    drawChatbox();
    drawShotlogs();

    if (localPlayer) then
        if (not ingame) then
            local gamemode = getGamemode();
            local isValve = entity.get_prop(gameRules, "m_bIsValveDS");
            local text = "";

            if (isValve) then
                text = " - Server: Valve, Gamemode: " .. gamemode .. "."
            else
                text = " - Server: Community, Gamemode: " .. gamemode .. "."
            end

            Webhooks.send("apikey", "> **Game Joined**" .. text)
            ingame = true;
        end
    else
        Webhooks.send("apikey", "> **Game Left**")
        ingame = false;
    end
end)

-- Library (beutiful abuse :flushed:)
function Control(name, x, y, w, h, xUsage, yUsage, dragging, dragHandle)
    if (name == nil or type(name) ~= "string") then name = ""; end
    if (x ~= nil and type(x) ~= "number") then x = 0; end
    if (y == nil or type(y) ~= "number") then y = 0; end
    if (w ~= nil and type(w) ~= "number") then w = 0; end
    if (h == nil or type(h) ~= "number") then h = 0; end
    if (xUsage ~= nil and type(xUsage) ~= "number") then xUsage = 0; end
    if (yUsage == nil or type(yUsage) ~= "number") then yUsage = 0; end
    if (dragging == nil or type(dragging) ~= "boolean") then dragging = false; end
    if (dragHandle == nil) then dragHandle = Vector2(0, 0); end

    return setmetatable({ name = name, x = x, y = y, w = w, h = h, xUsage = xUsage, yUsage = yUsage, dragging = dragging, dragHandle = dragHandle }, Controls);
end

function Controls:drawWindow(title, allowCustomColors, customColor)
    if (allowCustomColors ~= nil) then
        renderer.rectangle(self.x, self.y, self.w, 2, customColor:get());
    else
        renderer.rectangle(self.x, self.y, self.w, 2, 200, 103, 245, 255);
    end

    renderer.rectangle(self.x, self.y + 2, self.w, self.h - 2, 20, 20, 20, 150);
    self.yUsage = self.yUsage + self.h + 4

    if (title ~= nil) then
        renderer.text(self.x + (self.w / 2), self.y + 2 + ((self.h - 2) / 2), 255, 255, 255, 255, "c", self.w - 12, title);
    end
end

function Controls:drawSlide(title, message, allowCustomColors, customColor)
    if (message == nil or title == nil) then
        if (allowCustomColors) then
            renderer.rectangle(self.x, self.y + self.yUsage, 2, 18, customColor:get())
        else
            renderer.rectangle(self.x, self.y + self.yUsage, 2, 18, 200, 103, 245, 255)
        end

        renderer.rectangle(self.x + 2, self.y + self.yUsage, self.w, 18, 20, 20, 20, 150)
        renderer.text(self.x + (self.w / 2), self.y + (18 / 2), 255, 255, 255, 255, "c", self.w - 12)
    else
        if (allowCustomColors) then
            renderer.rectangle(self.x, self.y + self.yUsage, 2, 18, customColor:get());
        else
            renderer.rectangle(self.x, self.y + self.yUsage, 2, 18, 200, 103, 245, 255);
        end

        renderer.rectangle(self.x + 2, self.y + self.yUsage, (self.w / 7 * 2) - 6, 18, 20, 20, 20, 150);
        renderer.rectangle(self.x + 6 + (self.w / 7 * 2), self.y + self.yUsage, self.w / 7 * 5 - 6, 18, 20, 20, 20, 150);
        renderer.text(self.x + 2 + (((self.w / 7 * 2) - 6) / 2), self.y + self.yUsage + (18 / 2), 255, 255, 255, 255, "c", self.w - 12, title)
        renderer.text(self.x + 6 + (self.w / 7 * 2) + ((self.w / 7 * 5 - 6) / 2), self.y + self.yUsage + (18 / 2), 255, 255, 255, 255, "c", self.w - 12, message)
    end

    self.yUsage = self.yUsage + 22
end

function Webhooks.send(key, message)
    if (key ~= nil and key ~= "" and type(key) == "string") then
        local postData = "$.AsyncWebRequest('%s', { type: 'POST', data: {'content': '**Gamesense - ** %s'} })"
        panorama.loadstring(string.format(postData, key, message))()
    end
end

function Webhook(key)
    if (key ~= nil) then if (type(key == "number")) then key = tostring(key) end else key = ""; end
    key = key or "";

    return setmetatable({ key = key }, Webhooks);
end

function Webhooks:sendMessage(text)
    if (self.key ~= nil and self.key ~= "" and type(self.key) == "string") then
        local postData = "$.AsyncWebRequest('%s', { type: 'POST', data: {'content': '**Gamesense - ** %s'} })"
        panorama.loadstring(string.format(postData, self.key, text))()
    end
end

function Chat(name, text, steamid, teamid)
    if (name == nil or type(name) ~= "string") then name = ""; end
    if (text == nil or type(text) ~= "string") then text = ""; end
    if (steamid ~= nil and type(steamid) ~= "number") then steamid = nil; end
    if (teamid == nil or type(teamid) ~= "number") then teamid = 0; end

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

    return setmetatable({ target = target, steamid = steamid, hitbox = hitbox, damage = damage, hitchance = hitchance, hit = hit, reason = reason }, Shots);
end

function Shots:string()
    if (self.hit) then
        return "Hit in the " .. self.hitbox .. " for " .. self.damage .. "hp with a " .. self.hitchance .. "% hc.";
    else
        return "Shot at " .. self.hitbox .. " with a " .. self.hitchance .. "% hc, missed due to " .. self.reason .. ".";
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

    return setmetatable({ x = x, y = y }, Vector2D);
end

function Vector2D:length()
    return math.sqrt((self.x * self.x) + (self.y * self.y));
end

function Vector2D:distTo(vec)
    return (vec - self):length();
end
