--[[
Copyright © 2024, Cliff
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of CallPlz nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL CLIFF BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
_addon.author = 'Cliff'
_addon.command = 'cpz'
_addon.name = 'CallPlz'
_addon.version = '1.0.0'

require('luau')
require('pack')
require('actions')
local packets = require("packets")

local eventTime = nil
local lastwsCheck = os.clock()
local tossTime = os.clock()
local reaction = nil
local toss = nil
local chain = {}
local chainCount = 1
local announce = nil
local finished = false

message_ids = S{110,185,187,317,802}

categories = S{
    'weaponskill_begin',
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}

WINDOW_WAIT = 3
WINDOW_SIZE = 7

function reload_settings()
    package.loaded['profiles'] = nil
    loaded = require('profiles')
    profiles = loaded[windower.ffxi.get_player().name]
end
reload_settings()

function checkDeBuffs()
    local player = windower.ffxi.get_player()
    local buffs = S(player.buffs):map(string.lower .. table.get-{'english'} .. table.get+{res.buffs})
    if buffs.sleep or buffs.petrification or buffs.stun or buffs.charm or buffs.amnesia or buffs.terror or buffs.lullaby or buffs.impairment then
        return false
    end
    return true
end

function launchws(ws)
    local mob = windower.ffxi.get_mob_by_target()
    local player = windower.ffxi.get_player()
    if (player ~= nil) and (player.status == 1) and (mob ~= nil) then
        if player.vitals.tp > 999 and checkDeBuffs() then
            windower.send_command('input /ws "'..ws..'" <t>')
            if announce then
                windower.send_command('input /p '..announce)
                announce = nil
            end
        end
    end
end

windower.register_event('prerender', function()
    local player = windower.ffxi.get_player()
    if (player == nil) or (player and player.status ~= 1) then
        return
    end
    if eventTime and reaction then
        if os.clock() > eventTime then--Wait window open
            if os.clock() - eventTime < WINDOW_SIZE then -- within 7 seconds window
                launchws(windower.to_shift_jis(reaction))
            else--Timeout
                eventTime = nil
                reaction = nil
                if toss then
                    reaction = toss
                    eventTime = os.clock()
                else
                    reaction = nil
                end
                -- log('Failed...')
            end
        end
    elseif eventTime == nil and reaction == nil and #chain>0 then
        if os.clock() - tossTime > 2 then--Toss check every 2 seconds
            launchws(windower.to_shift_jis(chain[chainCount]))
            tossTime = os.clock()
        end
    end
end)

function isInParty(pid)
    if pid == windower.ffxi.get_player().id then
        return true
    end
    local pt = windower.ffxi.get_party()
    for i = 0, 5 do
        local member = pt['p'..i]
        if member ~= nil and member.mob and member.mob.id == pid then
            return true
        end
    end
    return false
end

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    if id == 0x29 then	-- Mob died
        local p = packets.parse('incoming',data)
        local target_id = p['Target'] --data:unpack('I',0x09)
        local player_id = p['Actor'] 
        local message_id = p['Message'] --data:unpack('H',0x19)%32768

        -- 6 == actor defeats target, 20 == target falls to the ground
        if (message_id == 6 or message_id == 20) and isInParty(player_id) then
            -- log('killed a '..windower.ffxi.get_mob_by_id(target_id).name..' '..target_id..' by '..player_id)
            -- killedMob = windower.ffxi.get_mob_by_id(target_id).name
            if toss then
                reaction = toss
                eventTime = os.clock()
            else
                reaction = nil
                eventTime = nil
            end
            chainCount = 1
            -- log('Reset...')
        end
    end
end)

function action_handler(act)
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()

    if not categories:contains(category) or act.param == 0 then
        return
    end

    local actor = actionpacket:get_id()
    local target = actionpacket:get_targets()()
    local action = target:get_actions()()
    local message_id = action:get_message_id()
    local add_effect = action:get_add_effect()
    local param, resource, action_id, interruption, conclusion = action:get_spell()

    if S{'weaponskill_begin'}:contains(category) then
        player = windower.ffxi.get_mob_by_id(actor).name
        if res[resource][action_id] then
            ability = res[resource][action_id].name
            -- log(player..' using ' ..ability)
            if eventTime and reaction and actor == windower.ffxi.get_player().id and ability == reaction then
                reaction = nil
                eventTime = nil
            end
        end
    elseif eventTime==nil and reaction==nil and message_ids:contains(message_id) then
        player = windower.ffxi.get_mob_by_id(actor).name
        ability = res[resource][action_id].name
        -- log(player..' used ' ..ability)
        for _,p in pairs(profiles) do
            if p['enabled'] then
                if p['chain'] and actor == windower.ffxi.get_player().id then
                    if #chain > 0 then
                        if chainCount + 1 > #chain then
                            chainCount = 1
                            log('Confirmed, chain over.')
                        else
                            chainCount = chainCount + 1
                            log('Confirmed, go to next chain #'..chainCount)
                        end
                    else
                        log('Confirmed.')
                    end
                elseif p['actions'] then
                    for k, a in pairs(p['actions']) do
                        if a['player'] == player and a['ability'] == ability then
                            if finished then
                                finished = false
                                if toss then
                                    reaction = toss
                                    eventTime = os.clock()
                                    log('Chain finished, back to toss')
                                else
                                    reaction = nil
                                    eventTime = nil
                                    log('Chain finished.')
                                end
                                return
                            end
                            log('Going to use '..a['action'])
                            eventTime = os.clock() + WINDOW_WAIT
                            reaction = a['action']
                            if a['announce'] then
                                announce = a['announce']
                            end
                            if a['finish'] then
                                finished = true
                            else
                                finished = false
                            end
                        end
                    end
                end
            end
        end
    end
end

ActionPacket.open_listener(action_handler)


windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower()
	if S{'r','reload','load','l'}:contains(cmd) then
        reload_settings()
        log('Profile reloaded.')
    elseif S{'p','profile'}:contains(cmd) then
        local arg = T{...}
        if #arg == 1 then
            name = arg[1]:lower()
            if profiles[name] then
                profiles[name].enabled = not profiles[name].enabled
                if profiles[name].enabled then
                    if profiles[name].toss then
                        toss = profiles[name].toss
                        reaction = toss
                        eventTime = os.clock()
                        log('Profile '..name..' enabled, new toss: '..toss)
                    else
                        toss = nil
                        log('Profile '..name..' enabled!!')
                    end                    
                else
                    toss = nil
                    log('Profile '..name..' disabled.')
                end
            else
                log('Profile not found')
            end
        else
            log('error')
        end
    elseif S{'c','chain'}:contains(cmd) then
        local arg = T{...}
        if #arg == 1 then
            name = arg[1]:lower()
            if profiles[name] and profiles[name]['chain'] then
                profiles[name].enabled = true
                log('Chain '..name..' enabled!!')
                chain = profiles[name]['chain']
            else
                log('Profile not found')
            end
        else
            toss = nil
            log('Chain disabled')
        end
    elseif S{'s','stop'}:contains(cmd) then
        for k,v in pairs(profiles) do
            v.enabled = false
        end
        chain = {}
        log('All disabled.')
    else
        for k,v in pairs(profiles) do
            if v.enabled then
                log(k..' enabled')
            end
        end
    end
end)


windower.register_event('load', function()
end)

windower.register_event('unload', function()
end)
