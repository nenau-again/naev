--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Minerva Pirates 3">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>4</priority>
  <chance>100</chance>
  <location>Bar</location>
  <planet>Minerva Station</planet>
  <done>Minerva Pirates 2</done>
 </avail>
 <notes>
  <campaign>Minerva</campaign>
  <provides name="Spa Propaganda" />
  <provides name="Chicken Rendezvous">Kidnapped Winner</provides>
 </notes>
</mission>
--]]

--[[
-- Find the Dvaered spy
--]]
local minerva = require "minerva"
local portrait = require 'portrait'
local vn = require 'vn'
require 'numstring'

logidstr = minerva.log.pirate.idstr

misn_title = _("Finding the Dvaered Spy")
misn_reward = _("Cold hard credits")
misn_desc = _("Someone wants you to find a Dvaered spy that appears to be located at Minerva Station.")
reward_amount = 200000 -- 200k

harper_portrait = portrait.get() -- TODO replace?

mainsys = "Limbo"
-- Mission states:
--  nil: mission not accepted yet
--    0: try to find out how to plant listening device
--    1. hear about chicken spa event
--    2. enter chicken spa event
--    3. capture chicken spa event winner
--    4. do chicken spa event
--    5. planted listening device
--    6. kidnap spy and take to torture ship
--    7. defend torture ship
misn_state = nil


function create ()
   if not misn.claim( system.get(mainsys) ) then
      misn.finish( false )
   end
   misn.setNPC( minerva.pirate.name, minerva.pirate.portrait )
   misn.setDesc( minerva.pirate.description )
   misn.setReward( misn_reward )
   misn.setTitle( misn_title )
end


function accept ()
   approach_pir()

   -- If not accepted, misn_state will still be nil
   if misn_state==nil then
      misn.finish(false)
      return
   end

   misn.accept()
   misn.setDesc( misn_desc )
   osd = misn.osdCreate( _("Minerva Moles"),
         {_("Plant a listening device in a VIP room.") } )

   shiplog.appendLog( logidstr, _("You accepted another job from the shady individual to uncover moles at Minerva Station.") )

   hook.enter("enter")
   hook.load("generate_npc")
   hook.land("generate_npc")
   generate_npc()
end


function generate_npc ()
   if planet.cur() == planet.get("Minerva Station") then
      npc_pir = misn.npcAdd( "approach_pir", minerva.pirate.name, minerva.pirate.portrait, minerva.pirate.description )
   end
end


function approach_pir ()
   if misn_state==0 and player.evtDone("Spa Propaganda") then
      misn_state = 1
   end

   vn.clear()
   vn.scene()
   local pir = vn.newCharacter( minerva.pirate.name, {image=minerva.pirate.image} )
   vn.transition()

   if misn_state==nil then
      -- Not accepted
      vn.na(_("You approach the sketch individual who seems to be calling your attention yet once again."))
      pir(_("Hello again, we have another job for you. Our previous actions has led us to believe that there are several Dvaered and Za'lek spies deeply infiltrated into the station infrastructure. Would you be up to the challenge of helping us get rid of them?"))
      vn.menu( {
         {_("Accept the job"), "accept"},
         {_("Kindly decline"), "decline"},
      } )

      vn.label("decline")
      vn.na(_("You decline their offer and take your leave."))
      vn.done()

      vn.label("accept")
      vn.func( function () misn_state=0 end )
      pir(_([["Glad to have you onboard again. From the few intercepted Dvaered and Za'lek communications we were able to decode, it seems like we might have some moles at Minerva Station. They are probably really deep so it won't be an easy task to drive them out."]]))
      pir(_([["That's where this comes in to place."
They take out a metallic object from their pocket and show it to you. You don't know what to make of it.
"Ain't she a beauty?"]]))
      pir(_([["This is some high tech shit that we got from some geeks. It is a latest gen signal capturing device. It should be able to bypass most of the jamming, however, we're going to need you to plant it in a VIP room or some place where we might catch the mole."]]))
      pir(_([["The main issue we have now is that VIP rooms and such are not of easy access, so we're going to have to keep our eyes open and see if we can spot an opportunity."]]))
      pir(_([[They hand you the signal capturing device and explain briefly how it works.
"Take the device and see if you can find an opportunity to place it. I'll be at the spaceport bar if you figure out anything."]]))
   else
      -- Accepted.
      vn.na(_("You approach the shady character you have become familiarized with."))
   end

   vn.label("menu_msg")
   pir(_([["Is there anything you would like to know?"]]))
   vn.menu( function ()
      local opts = {
         {_("Ask about the job"), "job"},
         {_("Ask about Minerva Station"), "station"},
         {_("Leave"), "leave"},
      }
      if player.evtDone("Spa Propaganda") then
         if var.peek("minerva_spa_ticket")==nil then
            table.insert( opts, 1, {_("Ask them about the Spa"), "spa" } ) 
         else
            table.insert( opts, 1, {_("Show them the Spa Ticket"), "spaticket" } ) 
         end
      end

      return opts
   end )

   vn.label("job")
   pir(_([["From intercepted Dvaered and Za'lek communication it seems like "]]))
   vn.jump("menu_msg")

   vn.label("station")
   pir(_([["Isn't this place great? They managed to set up an incredibly successful business model here. The way the Empire basically turns an eye to everything that goes on here is just incurable. Makes you want to root for their success you no?"]]))
   pir(_([["The issue is that even though the set-up is great, all the Dvaered and Za'lek bickering is just messing it all up. It would be a real shame if things went tits up and either the Dvaered or Za'lek were able to take over this wonderful place."]]))
   pir(_([["So me and my investors thought to ourselves, what could we do to ensure the success of such a wonderful place? This led to that and here we are."]]))
   vn.jump("menu_msg")

   vn.label("spa")
   pir(_([["Ah, so you heard the news too? The spa sounds like a perfect place to set up the signal capturing device. Nobody will suspect a thing! You should buy a ticket and see if we can get lucky. If  not, we may have to take other measures to ensure success."
They wink at you.]]))
   vn.jump("menu_msg")

   vn.label("spaticket")
   pir(_("Our chances of getting into the Spa can't be that bad can they?"))
   local t = minerva.vn_terminal()
   vn.appear( t )
   t(_([[Suddenly, the terminals around you blast a fanfare and begin to talk on the loudspeakers.
"WE ARE HAPPY TO ANNOUNCE THE WINNER OF THE FABULOUS SPA WITH CYBORG CHICKEN EVENT!"
The terminal pauses for emphasis.]]))
   t(_([["THE WINNER IS HARPER BOWDOIN! PLEASE COME TO YOUR NEAREST TERMINAL TO COLLECT YOUR PRIZE."]]))
   vn.disappear( t )
   pir(_([["Shit! I thought we had that rigged. Damn it. Give me one second."
They start frantically typing into their portable holo-deck. It makes weird beeps and noises.]]))
   pir(_([["OK, so we aren't so bad off. It seems like the winner was doing some space tourism around the system. Not like there is anything to see here."]]))
   pir(_([["So change of plans, I need you to go pay this guy a visit, see if you can 'encourage' them to give the ticket to you. Everyone has a price at Minerva Station."]]))
   vn.func( function ()
      osd = misn.osdCreate( _("Minerva Moles"),
         {_("Get Harper Bowdoin's ticket in Limbo.")},
         {_("Plant a listening device in a VIP room.") } )
      misn_state = 3
   end )
   vn.jump("menu_msg")

   pir("victory msg")
   vn.na(string.format(_("You have received #g%s."), creditstring(reward_amount)))
   vn.func( function ()
      player.pay( reward_amount )
      shiplog.appendLog( logidstr, "win log" )

   end )
   vn.sfxVictory()
   vn.done()

   vn.label("leave")
   if misn_state==0 then
      vn.na(_("You take your leave and ponder where you should start looking. The casino seems to be your best bet."))
   else
      vn.na(_("You take your leave."))
   end
   vn.run()

   misn.finish(true)
end


function enter ()
   if misn_state==3 and not harper_nospawn and system.cur()==system.get("Limbo") then
      -- Spawn Harper Bowdoin and stuff
      local pos = foo
      harper = pilot.add("Gawain", "Independent", pos, "Harper", "civilian" )
      local mem = harper:memory()
      mem.loiter = math.huge -- Should make them loiter forever
      harper:setHilight(true)
      harper:setNoLand(true)
      harper:setNoJump(true)
      hook.pilot( harper, "attacked", "harper_attacked" )
      hook.pilot( harper, "death", "harper_death" )
      hook.pilot( harper, "board", "harper_board" )
      hook.pilot( harper, "hail", "harper_hail" )
   end
end


function harper_death ()
   harper_killed = true
   harper_nospawn = true
end


function harper_board ()
   harper_gotticket = true
   harper_nospawn = true

   vn.clear()
   vn.scene()
   vn.transition()
   vn.na(_("Foo."))
   vn.run()
end


function harper_attacked ()
end


function harper_hail ()
   vn.clear()
   vn.scene()
   local h = vn.newCharacter( _("Harper"),
         { image=portrait.hologram( harper_portrait ) } )
   vn.transition("electric")
   vn.na(_("You hail Harper's vessel and you see him appear into view."))
   h(_([["What do you want? Can't you see I'm celebrating my luck?"]]))
   vn.menu( {
      {_("Foo."), "foo" },
   } )

   vn.func( function ()
      harper_gotticket = true
      harper_nospawn = true
   end )
   vn.done("electric")
   vn.run()
end

