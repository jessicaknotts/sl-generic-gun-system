/*** REMEMBER TO COMPILE WITH LSO, NOT MONO ***/

list COLLISION_SOUNDS = ["6f732102-890e-8e54-432e-d31f74d32b12", 
        "42c9ec75-888d-0e21-8c6e-62f209b347cd", 
        "5c3376c1-5763-1942-4d48-a9402b3e1726"];


key targetUuid;


string avatarName(key id)
{
    return "secondlife:///app/agent/"+(string)id+"/about";
}  // avatarName


default
{
    state_entry() {
        llCollisionFilter(llGetObjectName(), "", 0);
        llSetStatus(14, 0);
    }  // state_entry
    
    on_rez(integer param) {
        llCollisionSound(llList2String(COLLISION_SOUNDS, 
                llRound(llFrand(llGetListLength(COLLISION_SOUNDS) - 1))), 0.8);
    }  // on_rez
    
    collision_start(integer num) {
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_LINK_TARGET, 1, PRIM_SIZE, <0.1, 0.1, 0.1>,
                PRIM_LINK_TARGET, 2, PRIM_SIZE, <0.01, 0.01, 0.01>,
                PRIM_LINK_TARGET, 2, PRIM_GLOW, ALL_SIDES, 0.0,
                PRIM_LINK_TARGET, 2, PRIM_COLOR, ALL_SIDES, <0.0, 0.0, 0.0>, 0.0
        ]);
        
        do {
            if (llDetectedType(num) & AGENT) {
                targetUuid = llDetectedKey(num);
                
                llOwnerSay("Killed " + avatarName(targetUuid));
                // State change forces collision queue to clear (and stop being processed).
                // Otherwise we could just trigger a timer event.
                state kill;
            }
        } while (num--);
        
        llDie();
    }  // collision_start
    
    land_collision_start(vector pos) {
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetTimerEvent(0.0444);
    }  // land_collision_start
    
    timer() {
        llDie();
    }
}  // state default

state kill
{
    state_entry() {
        llSetDamage(120.0);
        // Re-calling agent pos to compensate for avatar movement
        llSetRegionPos(llList2Vector(llGetObjectDetails(targetUuid, [OBJECT_POS]), 0));
        llSetStatus(STATUS_PHANTOM, FALSE);
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSetTimerEvent(0.0444);
    }  // state_entry
    
    timer() {
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetStatus(STATUS_PHYSICS, FALSE);
        vector agentPos = llList2Vector(llGetObjectDetails(targetUuid, [OBJECT_POS]), 0);
        // This should prevent the bullets from killing them after they teleport to spawn
        if (llVecDist(llGetPos(), agentPos) < 20.0) {
            llSetRegionPos(agentPos);
            llSetStatus(STATUS_PHANTOM, FALSE);
            llSetStatus(STATUS_PHYSICS, TRUE);
        } else {
            llDie();
        }
        
        if (llGetTime() > 0.5) {
            llDie();
        }
    }  // timer
}  // state kill
