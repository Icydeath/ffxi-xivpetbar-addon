--[[
        Copyright © 2017, SirEdeonX
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of xivbar nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL SirEdeonX BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- Addon description
_addon.name = 'XIV Pet Bar'
_addon.author = 'Edeon(xivbar) + SnickySnacks(pettp) + Icy(xivpetbar)'
_addon.version = '1.0'
_addon.language = 'english'
_addon.commands = {'xivpetbar', 'petbar'}

-- BELOW CODE/METHODS WAS BARROWED FROM XIVBAR - THANK YOU Edeon ^.^

-- Libs
config = require('config')
texts  = require('texts')
images = require('images')
packets = require('packets')

-- User settings
local defaults = require('defaults')
local settings = config.load(defaults)
config.save(settings)

-- Load theme options according to settings
local theme = require('theme')
local theme_options = theme.apply(settings)

-- Addon Dependencies
local ui = require('ui')
local player = require('player')
local pet = require('pet')
local xivbar = require('variables')

-- initialize addon
function initialize()
    ui:load(theme_options)
	printpettp(pet.index, player.index)

    xivbar.initialized = true
end

-- update a bar
function update_bar(bar, text, width, current, pp, flag)
    local old_width = width
    local new_width = math.floor((pp / 100) * theme_options.bar_width)

    if new_width ~= nil and new_width >= 0 then
        if old_width == new_width then
            if new_width == 0 then
                bar:hide()
            end

            if flag == 1 then
                xivbar.hp_update = false
            elseif flag == 2 then
                xivbar.update_mp = false
            elseif flag == 3 then
                xivbar.update_tp = false
            end
        else
            local x = old_width

            if old_width < new_width then
                x = old_width + math.ceil((new_width - old_width) * 0.1)

                x = math.min(x, theme_options.bar_width)
            elseif old_width > new_width then
                x = old_width - math.ceil((old_width - new_width) * 0.1)

                x = math.max(x, 0)
            end

            if flag == 1 then
                xivbar.hp_bar_width = x
            elseif flag == 2 then
                xivbar.mp_bar_width = x
            elseif flag == 3 then
                xivbar.tp_bar_width = x
            end

            bar:size(x, theme_options.total_height)
            bar:show()
        end
    end

    if flag == 3 and current >= 1000 then
        text:color(theme_options.full_tp_color_red, theme_options.full_tp_color_green, theme_options.full_tp_color_blue)
        if theme_options.dim_tp_bar then bar:alpha(255) end
    else
        text:color(theme_options.font_color_red, theme_options.font_color_green, theme_options.font_color_blue)
        if theme_options.dim_tp_bar then bar:alpha(180) end
    end

	-- check to see if we are handling % for hp/mp
	
	if flag == 1 and pet.max_hp == 0 then
		text:text(tostring(pp)..'%')
	elseif flag == 2 and pet.max_mp == 0 then
		text:text(tostring(pp)..'%')
	else
		text:text(tostring(current))
	end
end

-- hide the addon
function hide()
    ui:hide()
    xivbar.ready = false
end

-- show the addon
function show()
    if xivbar.initialized == false then
        initialize()
    end

    ui:show()
    xivbar.ready = true
end

-- ON LOGOUT
windower.register_event('logout', function()
    hide()
end)

windower.register_event('prerender', function()
	if xivbar.ready == false then
        return
    end

    if xivbar.update_hp then
		if pet.max_hp > 0 then
			update_bar(ui.hp_bar, ui.hp_text, xivbar.hp_bar_width, pet.current_hp, pet.hpp, 1)
		else
			update_bar(ui.hp_bar, ui.hp_text, xivbar.hp_bar_width, pet.hpp, pet.hpp, 1)
		end
    end

    if xivbar.update_mp then
		if pet.max_mp > 0 then
			update_bar(ui.mp_bar, ui.mp_text, xivbar.mp_bar_width, pet.current_mp, pet.mpp, 2)
		else
			update_bar(ui.mp_bar, ui.mp_text, xivbar.mp_bar_width, 0, 0, 2)
		end
    end

    if xivbar.update_tp then
        update_bar(ui.tp_bar, ui.tp_text, xivbar.tp_bar_width, pet.current_tp, pet.tpp, 3)
    end
	
	if xivbar.update_petname then
        ui.petname_text:text(pet.name)
    end
end)


-- BELOW CODE/METHODS WAS BARROWED FROM PETTP - THANK YOU SnickySnacks ^.^
function make_visible()
    pet.active = true
    show()
    if xivbar.verbose == true then windower.add_to_chat(8, 'xivpetbar: Visible') end
end

function make_invisible()
    if pet.active then
        ui.petname_text:text('')
        hide()
        if xivbar.verbose == true then windower.add_to_chat(8, 'xivpetbar: Invisible') end
    end
    pet.active = false
    pet.index = nil
    pet.name = nil
    pet.current_hp = 0
    pet.max_hp = 0
    pet.current_mp = 0
    pet.max_mp = 0
    pet.hpp = 0
    pet.mpp = 0
    pet.current_tp = 0
end

function valid_pet(source,pet_idx_in, own_idx_in)
    local windower_player = windower.ffxi.get_player()
	player.index = windower_player.index
    if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet('..source..'): pet.active: '..tostring(pet.active)..', pet.index: '..(pet.index or 'nil')..', pet_idx_in: '..(pet_idx_in or 'nil')..', own_idx_in: '..(own_idx_in or 'nil')..', player.index '..player.index) end
    if windower_player.vitals.hp == 0 then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : false : Player is dead') end
        xivbar.timercountdown = 0
        return
    end

    if pet.active then 
        if pet.index then
            if not pet_idx_in or pet.index == pet_idx_in then
                if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : true : using pet.index') end
                return pet.index
            else
                if xivbar.superverbose == true then 
                    windower.add_to_chat(8, 'pet.index ~= pet_idx_in '..pet.index..' vs. '..pet_idx_in) 
                end
            end
        elseif own_idx_in and player.index == own_idx_in then
            if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : true : using pet_idx_in') end
            pet.index = pet_idx_in
            return pet.index
        end
    end
    
    local windower_pet = windower.ffxi.get_mob_by_target('pet')    
    if pet_idx_in and windower_pet and pet_idx_in ~= windower_pet.index then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : false : windower_pet.index ~= pet_idx_in '..windower_pet.index..' vs. '..pet_idx_in) end
        return
    elseif pet_idx_in and player.mob and player.mob.pet_index and pet_idx_in ~= player.mob.pet_index then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : false : player.mob.pet_index ~= pet_idx_in '..player.mob.pet_index..' vs. '..pet_idx_in) end
        return
    elseif windower_pet then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : true : Using windower_pet.index') end
        pet.index = windower_pet.index
        return pet.index
    elseif player.mob and player.mob.pet_index then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : true : Using player.mob.pet_index') end
        pet.index = player.mob.pet_index    
        return pet.index
    end
    if xivbar.superverbose == true then windower.add_to_chat(8, 'valid_pet() : false : No pet found') end
    return
end

function update_pet(source, pet_idx_in, own_idx_in)
    pet.index = valid_pet(source, pet_idx_in, own_idx_in)

    if pet.index == nil then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : false : pet.index == nil, pet_idx_in: '..(pet_idx_in or 'nil')..', own_idx_in: '..(own_idx_in or 'nil')) end
        return false
    end

    local pet_table = windower.ffxi.get_mob_by_index(pet.index)
    if pet_table == nil then
        if pet.active then -- presumably we have a pet, he just hasn't loaded, yet...
            if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : true : pet_table == nil, pet.index: '..(pet.index or 'nil')..', '..(own_idx_in or 'nil')) end
            return true
        end
        if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : false: pet_table == nil, pet.index: '..(pet.index or 'nil')..', '..(own_idx_in or 'nil')) end
        make_invisible()
        return false
    end

    pet.name = pet_table['name']
    if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : Updating pet.name: '..pet.name) end
    pet.hpp = pet_table['hpp']
    if not pet.active and pet.hpp == 0 then  -- we're likely picking up a dead or despawning pet
        if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : Picked up a likely dead pet') end
        make_invisible()
        return false
    end
    if xivbar.superverbose == true then windower.add_to_chat(8, 'update_pet() : true : Picked up a pet: '..pet.name..', hp%: '..pet.hpp..', pet.index: '..pet.index) end
    return true
end

function printpettp(pet_idx_in, own_idx_in)
	if xivbar.ready == false then
        return
    end
    if not pet.active then
        return
    end
    if pet.name == nil then
        if update_pet('printpettp',pet_idx_in,own_idx_in) == false then
            return
        end
    end
	
	-- update UI values.
	xivbar.update_petname = true
	xivbar.update_hp = true
	xivbar.update_mp = true
	xivbar.update_tp = true

end

windower.register_event('time change', function()
    if xivbar.timercountdown == 0 then
        return
    elseif pet.active then
        if xivbar.superverbose == true then windower.add_to_chat(8, 'SCAN: Pet appeared between scans!') end
        xivbar.timercountdown = 0
    else
        xivbar.timercountdown = xivbar.timercountdown - 1
        if update_pet('scan') == true then
            if xivbar.superverbose == true then windower.add_to_chat(8, 'SCAN: Found a pet!') end
            xivbar.timercountdown = 0
            make_visible()
            printpettp()
        elseif xivbar.timercountdown == 0 then
            if xivbar.superverbose == true then windower.add_to_chat(8, 'SCAN: No pet found in 5 ticks') end
        end
    end
end)

windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
    if not injected then
        if id == 0x44 then
            if original:unpack('C', 0x05) == 0x12 then    -- puppet update
                local new_current_hp, new_max_hp, new_current_mp, new_max_mp = original:unpack('HHHH', 0x069)

                if (not pet.active) or (pet.name == nil) or (pet.name == "") or (new_current_hp ~= pet.current_hp) or (new_max_hp ~= pet.max_hp) or (new_current_mp ~= pet.current_mp) or (new_max_mp ~= pet.max_mp) then
                    if xivbar.superverbose == true then                
                        windower.add_to_chat(8, '0x44'
                            ..', cur_hp: '..new_current_hp
                            ..', pet.max_hp: '..new_max_hp
                            ..', cur_mp: '..new_current_mp
                            ..', pet.max_mp: '..new_max_mp
                            ..', name: '.. original:unpack('z', 0x59)
                        )
                    end

                    if pet.active then
                        local new_petname = original:unpack('z', 0x59)
                        if pet.name == nil or pet.name == "" then
                            if xivbar.superverbose == true then windower.add_to_chat(8, 'Updating PuppetName: '..new_petname) end
                            pet.name = new_petname
                        end
                        if pet.name == new_petname then -- make sure we only update if we actually have a puppet out
                            pet.current_hp = new_current_hp
                            pet.max_hp     = new_max_hp
                            pet.current_mp = new_current_mp
                            pet.max_mp     = new_max_mp
                            if pet.max_hp ~= 0 then
                                pet.hpp=math.floor(100*pet.current_hp/pet.max_hp)
                            else
                                pet.hpp=0
                            end
                            if pet.max_mp ~= 0 then
                                pet.mpp=math.floor(100*pet.current_mp/pet.max_mp)
                            else
                                pet.mpp=0
                            end
                            printpettp()
                        else
                            if xivbar.superverbose == true then windower.add_to_chat(8, '0x44, pet is not a puppet') end
                        end
                    else
                        if xivbar.superverbose == true then windower.add_to_chat(8, '0x44, puppet not active') end
                    end
                end
            end
        elseif id == 0x67 or id == 0x068 then    -- general hp/tp/mp update
            local packet = packets.parse('incoming', original)
            local msg_type = packet['Message Type']
            local msg_len = packet['Message Length']
            pet.index = packet['Pet Index']
            player.index = packet['Owner Index']

            if (msg_type == 0x04) and id == 0x067 then
                pet.index, player.index = player.index, pet.index
            end

            if xivbar.superverbose == true and id == 0x067 and not ( 
                   (msg_type == 0x02) -- not pet related
                or (msg_type == 0x03 and (player.index == 0)) -- NPC pops
                or (msg_type == 0x03 and (player.index ~= windower.ffxi.get_player().index)) -- other people summoning
            ) then
                windower.add_to_chat(8, '0x67'
                       ..', msg_type: '..string.format('0x%02x', msg_type)
                       ..', msg_len: '..msg_len
                       ..', pet.index: '..pet.index
                       ..', pet_id: '..(original:byte(0x09)+original:byte(0x0A)*256)
                       ..', player.index: '..player.index
                       ..', hp%: '..original:byte(0x0F)
                       ..', mp%: '..original:byte(0x10)
                       ..', tp%: '..(original:byte(0x11)+original:byte(0x12)*256)
                       ..', name: '.. ((msg_len > 24) and original:unpack('z', 0x19) or "")
                    )
            end
            if (msg_type == 0x04) then
                if (pet.index == 0) then
                    if xivbar.verbose == true then windower.add_to_chat(8, 'xivpetbar: Pet died/despawned') end
                    make_invisible()
                else
                    local newpet = false
                    if not pet.active then
                        pet.active = true  -- force our pet to appear even if it's not attached to us yet
                        if update_pet('0x67-0x*4',pet.index,player.index) == true then
                            make_visible()
                            newpet = true
                        else
                            if xivbar.superverbose == true then windower.add_to_chat(8, 'Pet not found') end
                            make_invisible()
                        end
                    end
                    local new_hp_percent = packet['Current HP%']
                    local new_mp_percent = packet['Current MP%']
                    local new_tp_percent = packet['Pet TP']
                    if newpet or (new_hp_percent ~= pet.hpp) or (new_mp_percent ~= pet.mpp) or (new_tp_percent ~= pet.current_tp) or (pet.name == nil) or (pet.name == "") then
                        if (pet.max_hp ~= 0) and (new_hp_percent ~= pet.hpp) then
                            pet.current_hp = math.floor(new_hp_percent * pet.max_hp / 100)
                        end
                        if (pet.max_mp ~= 0) and (new_mp_percent ~= pet.mpp) then
                            pet.current_mp = math.floor(new_mp_percent * pet.max_mp / 100)
                        end
                        if ((pet.name == nil) or (pet.name == "")) then
                            pet.name = packet['Pet Name']
                            if xivbar.superverbose == true then windower.add_to_chat(8, 'Updated pet.name: '..pet.name) end
                        end
                        pet.hpp = new_hp_percent
                        pet.mpp = new_mp_percent
                        pet.current_tp = new_tp_percent
						pet:calculate_tpp()
                        printpettp(pet.index,player.index)
                    end
                end
            elseif not pet.active and (msg_type == 0x03) and (player.index == windower.ffxi.get_player().index) then
                if update_pet('0x67-0x03', pet.index, player.index) == true then
                    make_visible()
                    printpettp(pet.index, player.index)
                else    -- last resort
                    xivbar.timercountdown = 5
                    if xivbar.superverbose == true then windower.add_to_chat(8, 'Starting to scan for a pet...') end
                end
            end
        elseif id==0x0E and S{0x07,0x0F}:contains(original:byte(0x0B)) then    -- npc update
            if pet.index == original:unpack('H', 0x09) then
                if pet.hpp ~= original:byte(0x1F) then
                    if xivbar.superverbose == true then windower.add_to_chat(8, '0x0E - '..original:byte(0x0B)..': '..original:byte(0x1F)) end
                    pet.hpp = original:byte(0x1F)
                    if pet.max_hp ~= 0 then
                        pet.current_hp = math.floor(pet.hpp * pet.max_hp / 100)
                    end
                    printpettp(pet.index)
                end
            end
        elseif id==0x0E and not S{0x00,0x01,0x08,0x09,0x20}:contains(original:byte(0x0B)) and pet.index == (original:byte(0x09)+original:byte(0x0A)*256) then
            if xivbar.superverbose == true then windower.add_to_chat(8, '0x0E ~ '..original:byte(0x0B)..': '..original:byte(0x1F)) end
        end
    end
end)

windower.register_event('load', function()
    if xivbar.superverbose == true then
        windower.add_to_chat(8, 'Player index: '..windower.ffxi.get_player().index)
        if windower.ffxi.get_mob_by_target('pet') then
            windower.add_to_chat(8, 'Pet index: '..windower.ffxi.get_mob_by_target('pet').index)
        end
    end
    if windower.ffxi.get_player() then
        if update_pet('load') == true then
            make_visible()
            printpettp(pet.index)
        end
    end
end)

windower.register_event('zone change', function()
    pet.index = nil
    if update_pet('zone') == true then
        if xivbar.verbose == true then windower.add_to_chat(8, 'xivpetbar: Found pet after zoning...') end
        make_visible()
        printpettp()
    elseif pet.active then
        make_invisible()
        if xivbar.verbose == true then windower.add_to_chat(8, 'xivpetbar: Lost pet after zoning...') end
    end
end)

windower.register_event('job change', function()
    make_invisible()
end)

windower.register_event('addon command', function(...)
    local splitarr = {...}

    for i,v in pairs(splitarr) do
        if v:lower() == 'save' then
            config.save(settings, 'all')
        elseif v:lower() == 'verbose' then
            xivbar.verbose = not xivbar.verbose
            windower.add_to_chat(121,'xivpetbar: verbose Mode flipped! - '..tostring(xivbar.verbose))
        elseif v:lower() == 'superverbose' then
            xivbar.superverbose = not xivbar.superverbose
            windower.add_to_chat(121,'xivpetbar: superverbose Mode flipped! - '..tostring(xivbar.superverbose))
        elseif v:lower() == 'help' then
            print('   :::   '.._addon.name..' ('.._addon.version..')   :::')
            print('xivpetbar Utilities:')
            print(' verbose --- Some light logging, Default = false')
			print(' superverbose --- comprehensive logging, Default = false')
            print(' help    --- shows this menu')
        end
    end
end)