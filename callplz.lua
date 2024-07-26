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
local chain = {}
local chainCount = 1
local announce = nil

message_ids = S{110,185,187,317,802}

categories = S{
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}

WINDOW_WAIT = 3
WINDOW_SIZE = 6

function reload_settings()
    loaded = require('profiles')
    profiles = loaded[windower.ffxi.get_player().name]
end
reload_settings()

windower.register_event('prerender', function()
    if eventTime and reaction then
        if os.clock() > eventTime then--Wait window open
            if os.clock() - eventTime < WINDOW_SIZE then
                if windower.ffxi.get_player()['vitals']['tp'] > 999 then -- within 7 seconds window
                    windower.send_command('input /ws "'..windower.to_shift_jis(reaction)..'" <t>')
                    if announce then
                        windower.send_command('input /p '..announce)
                        announce = nil
                    end
                end
            else--Timeout
                eventTime = nil
                reaction = nil
                log('Failed...')
            end
        end
    elseif eventTime == nil and reaction == nil and #chain>0 and os.clock() - tossTime > 2 then
        if windower.ffxi.get_player()['vitals']['tp'] > 999 then -- within 7 seconds window
            windower.send_command('input /ws "'..windower.to_shift_jis(chain[chainCount])..'" <t>')
        end
        tossTime = os.clock()
    end
end)

windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    if id == 0x29 then	-- Mob died
        local p = packets.parse('incoming',data)
        local target_id = p['Target'] --data:unpack('I',0x09)
        local player_id = p['Actor'] 
        local message_id = p['Message'] --data:unpack('H',0x19)%32768

        -- 6 == actor defeats target
        if player_id == windower.ffxi.get_player().id and message_id == 6 then
            -- log('killed a '..windower.ffxi.get_mob_by_id(target_id).name..' '..target_id)
            -- killedMob = windower.ffxi.get_mob_by_id(target_id).name
            eventTime = nil
            reaction = nil
            log('Reset...')
        end
        
        -- 20 == target falls to the ground
        -- if message_id == 20 then
            -- log('killed b '..windower.ffxi.get_mob_by_id(target_id).name    ..' '..target_id)
        -- end
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

    if message_ids:contains(message_id) then
        player = windower.ffxi.get_mob_by_id(actor).name
        ability = res[resource][action_id].name
        -- log(player..' used ' ..ability)
        if eventTime and reaction and os.clock() - eventTime > WINDOW_WAIT and actor == windower.ffxi.get_player().id and ability == reaction then
            reaction = nil
            eventTime = nil
            log('Confirmed.')
        end
        for _,p in pairs(profiles) do
            if p['enabled'] then
                for k, a in pairs(p['actions']) do
                    if a['player'] == player and a['ability'] == ability then
                        log('Going to use '..a['action'])
                        eventTime = os.clock() + WINDOW_WAIT
                        reaction = a['action']
                        if a['announce'] then
                            announce = a['announce']
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
                    log('Profile '..name..' enabled!!')
                else
                    log('Profile '..name..' disabled.')
                end
            else
                log('Profile not found')
            end
        else
            log('error')
        end
    elseif S{'t','toss'}:contains(cmd) then
        local arg = T{...}
        if #arg == 1 then
            name = arg[1]:lower()
            if profiles[name] and profiles[name]['chain'] then
                profiles[name].enabled = true
                log('Profile '..name..' enabled!!')
                chain = profiles[name]['chain']
            else
                log('Profile not found')
            end
        else
            toss = nil
            log('Toss disabled')
        end
    elseif S{'s','stop'}:contains(cmd) then
        for k,v in pairs(profiles) do
            v.enabled = false
        end
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
