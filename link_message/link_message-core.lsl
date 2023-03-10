/** 
 @ TODO: Intra-object communication messages to global constant variables for consistency
 @ replace if (llGetTime() > (0.1 / NUM_AVAILABLE_NODES)) with llMinEventDelay(0.1 / NUM_AVAILABLE_NODES)
 @ TODO: Reduce bullet rez offset / Add dynamic offset based on user velocity
 @ TODO: Muzzle exhaust effects
 @ TODO: Adjust spread calculations (Gaussian? CSGO style?)
 @ TODO: Variable "recoil" / spread-over-time on trigger hold.
        - Should be biased towards vertical spread to simulate recoil?
 @ TODO: Memory optimization for "production" version
 */


#define DEBUG
#include "debug.lsl"

#define TRACERS_ENABLED
#define WEAPON_MELEE_ENABLED 


/*** GLOBAL CONSTANT VARIABLES ***/

#include "config.lsl"

#define REQUESTED_PERM_BITMASK 20
        // (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION) 


/*** GLOBAL SEMI-CONSTANT VARIABLES ***/
// Initialized once in state_entry / weaponInit()
// See config file for existing declarations.
 
// list PART_PARAMS_EJECTOR;
// list PART_PARAMS_MUZZLE_EXHAUST;

// vector PRIM_POS_BOLT_FORWARD;  // Holds the original position of the bolt object within the linkset


/*** GLOBAL MUTABLE VARIABLES ***/
// Don't mess with these, they're just container variables.

integer activeNode = 0;
integer currentRoundsInMag = 0;
integer fireMode = 0;  // 0 == auto, 1 == single, 2 == burst
integer inActionState = FALSE;  // Handles melee, weapon draw, etc.
integer inReloadState = FALSE; 
integer meleeOverride = FALSE;
integer prevFrameMLState = 0;
integer weaponArmed = TRUE; 


/*** FUNCTION DEFINITIONS ***/

/* 
 * Only supports display of two digit places, i.e. 00 to 99.
 */
ammoCountDisp(integer num) 
{
    // Pass to HUD, accessories, etcetera.
    llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, "ammo:" + (string)num);
    
    integer tens = 0;
    integer ones = 0;
    
    if (!(num & 0x80000000)) {  // Marginally faster than (num >= 0)
        if (num >= 100) {
            ammoCountDisp(99);
            return;
        } else if((num < 100) && (num >= 10)) {
            tens = (integer)(num * 0.10);
            ones = num - (tens * 10);  // Marginally faster than (num % 10)
        } else if (num < 10) {
            tens = 0;
            ones = num;
        } else {
            errorMessage("Invalid ammo count.");
        }
    } else {
        errorMessage("Invalid ammo count.");
    }
    
    if (num <= (MAX_MAG_CAPACITY * LOW_AMMO_WARNING_PERCENT)) {
        llSetLinkColor(LINK_NUM_AMMO_DISP, DISP_COLOR_LOW_AMMO_STATE, ALL_SIDES);
    }
    
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_LINK_TARGET, LINK_NUM_AMMO_DISP, 
                PRIM_TEXTURE, 5, TEXTURE_AMMO_COUNTER_FONT, 
                        <0.1, 1.0, 0.0>, 
                        <-0.45 + (ones * TEXTURE_COUNTER_FRAME_OFFSET), 0.0, 0.0>, 
                        0.0,
                PRIM_TEXTURE, 6, TEXTURE_AMMO_COUNTER_FONT, 
                        <0.1, 1.0, 0.0>, 
                        <-0.45 + (tens * TEXTURE_COUNTER_FRAME_OFFSET), 0.0, 0.0>, 
                        0.0
    ]);
}  // ammoCountDisp

string avatarName(key id)
{
    return "secondlife:///app/agent/"+(string)id+"/about";
}  // avatarName

errorMessage(string msg)
{
    llOwnerSay("/!\ " + llGetScriptName() + ": ERROR: " + msg);
}  // errorMessage

notifyAttachments(string msg)
{
    llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, msg);
}  // notifyAttachments

toggleFireMode() 
{
    // fireMode = !fireMode;  // Works for dual-mode operation. Otherwise use modulo for more modes.
    if (++fireMode >= NUM_FIRE_MODES) { 
        fireMode = 0;
    }
    llPlaySound("b97d8b1b-486b-3666-d459-0ca82f0cc49f", 1.0);  // Flick mode switch
    
    if (fireMode == 0) {  // Auto
        llOwnerSay("Auto");
    } else if (fireMode == 1) {  // Single
        llOwnerSay("Single");
    } else if (fireMode == 2) {  // Burst
        llOwnerSay("Burst");
    }
    // Pass to HUD, accessories, etcetera.
    notifyAttachments("mode:" + (string)fireMode);
}  // toggleFireMode

weaponDischarge()
{
    if (llGetTime() > (0.1 / NUM_AVAILABLE_NODES)) { 
        // Muzzle flash opaque, bolt jounce pos
        /* llSetLinkPrimitiveParamsFast(LINK_SET, [
                PRIM_LINK_TARGET, LINK_NUM_FLASH, PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 1.0,
                PRIM_LINK_TARGET, LINK_NUM_BOLT, PRIM_POS_LOCAL, PRIM_POS_BOLT_FORWARD + <, , ,>
        ]); */
        // llLinkParticleSystem(LINK_NUM_MUZZLE, PART_PARAMS_MUZZLE_EXHAUST);
        // llLinkParticleSystem(LINK_NUM_EJECTOR, PART_PARAMS_EJECTOR);
                                        
        if (++activeNode >= NUM_AVAILABLE_NODES) {
            activeNode = 0;
        } 
        
#ifdef TRACERS_ENABLED
        // Last 5 rounds will be a tracer, and every Nth round, 
        // excluding the first N rounds (so that the first round isn't a tracer).
        if ((currentRoundsInMag <= 5) || (!(currentRoundsInMag % TRACER_EVERY_NTH_ROUND) 
                && (currentRoundsInMag <= (MAX_MAG_CAPACITY - TRACER_EVERY_NTH_ROUND)))) { 
            llMessageLinked(LINK_SET, activeNode, NAME_OBJ_TRCR_BULLET, "");
        } else {
            llMessageLinked(LINK_SET, activeNode, NAME_OBJ_NORM_BULLET, "");
        }
#else
        llMessageLinked(LINK_SET, activeNode, NAME_OBJ_NORM_BULLET, "");
#endif
        
        ammoCountDisp(--currentRoundsInMag);
        
        // llLinkParticleSystem(LINK_SET, []);  // Clear existing particle emitters.
        // Muzzle flash alpha, bolt rebound pos
        /* llSetLinkPrimitiveParamsFast(LINK_SET, [
                PRIM_LINK_TARGET, LINK_NUM_FLASH, PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0.0,
                PRIM_LINK_TARGET, LINK_NUM_BOLT, PRIM_POS_LOCAL, PRIM_POS_BOLT_FORWARD
        ]); */
        llResetTime();
    }
}  // weaponDischarge

weaponDraw()
{
    inActionState = TRUE;
    llRequestPermissions(OWNER_KEY, REQUESTED_PERM_BITMASK);
    llStartAnimation(ANIMATION_WPN_DRAW);
    llSleep(0.022222);  // 1.0 / 45.0
    llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, "rifle_draw");
    llSleep(0.022222);  // 1.0 / 45.0
    llSetAlpha(1.0, ALL_SIDES);
    // weaponReload();
    weaponArmed = TRUE;
    inActionState = FALSE;  // ! REMOVE IF USING weaponReload ABOVE !
}  // weaponDraw

weaponHolster()
{
    llSetTimerEvent(0.0);
    inActionState = TRUE;
    llStopAnimation(ANIMATION_AIMING);
    llStopAnimation(ANIMATION_IDLE);
    llStartAnimation(ANIMATION_WPN_HOLSTER);
    llSleep(0.022222);  // 1.0 / 45.0
    llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, "rifle holster");
    llSleep(0.022222);  // 1.0 / 45.0
    llSetAlpha(0.0, ALL_SIDES);
    llReleaseControls();
    weaponArmed = FALSE;
    inActionState = FALSE;
}  // weaponHolster

weaponInit() 
{
    OWNER_KEY = llGetOwner();
    ACCESSORY_COMMAND_CHANNEL = 0xFFFFFFFF - (integer)("0x" + llGetSubString((string)OWNER_KEY, -6, -1)) + (AUX_CMD_CHAN_OFFSET);
    // llMessageLinked(LINK_THIS, -2, NAME_OBJ_MELEE_DMG, "");
    // PRIM_POS_BOLT_FORWARD = llList2Vector(llGetLinkPrimitiveParams(LINK_NUM_BOLT, [PRIM_POS_LOCAL]), 0);
    currentRoundsInMag = MAX_MAG_CAPACITY;
    llSetLinkColor(LINK_NUM_AMMO_DISP, DISP_COLOR_NOMINAL_AMMO_STATE, ALL_SIDES);
    ammoCountDisp(currentRoundsInMag);
    /* PART_PARAMS_EJECTOR = [ 
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_TARGET_KEY, llGetKey(),
        PSYS_PART_START_SCALE, <0.031250, 0.031250, 0.0>,
        PSYS_SRC_TEXTURE, "afb73e3b-fd7d-d9eb-1b6f-42cd5aadbde8",
        PSYS_PART_MAX_AGE, 0.25,
        PSYS_SRC_BURST_RATE, (0.1 / NUM_AVAILABLE_NODES),
        PSYS_SRC_BURST_PART_COUNT, 1,
        PSYS_SRC_ACCEL, <40.0, -10.0, 8.0>,
        PSYS_SRC_BURST_SPEED_MAX, 0.5,
        PSYS_PART_FLAGS, PSYS_PART_WIND_MASK
    ]); */
    /* PART_PARAMS_MUZZLE_EXHAUST = [
        
    ]); */
    llLinkParticleSystem(LINK_SET, []);  // Clear pre-existing particle emitters.
    // llListen(USER_COMMAND_CHANNEL, "", OWNER_KEY, "");
    // Below allows other attachments to communicate with this device
    llListen(USER_COMMAND_CHANNEL, "", NULL_KEY, ""); 
    llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, "primary_attached");
    // llMinEventDelay(3.0 / 45.0);
}  // weaponInit

#ifdef WEAPON_MELEE_ENABLED 
weaponMelee() 
{
    inActionState = TRUE;
    llSensor("", "", AGENT, RANGE_MELEE, PI / 3);
    // llResetOtherScript(SCRIPT_NAME_MELEE_MODULE);
    // llMessageLinked(LINK_THIS, 0xDEAD, "", "");
    llStartAnimation(ANIMATION_MELEE);  // Might be nice to also have randomized melee animations
    inActionState = FALSE;
}  // weaponMelee
#endif

weaponReload()
{
    llSetTimerEvent(0.0);
    inReloadState = TRUE;
    llStopAnimation(ANIMATION_AIMING);
    llStopAnimation(ANIMATION_IDLE);
    llPlaySound("8accadd0-9326-ef1f-1190-4ae383659e48", 1.0);
    llStartAnimation(ANIMATION_RELOAD);
    llSetTimerEvent(4.7);
    // Continues in timer event
}  // weaponReload

weaponReset() 
{
    // llLinkParticleSystem(LINK_SET, []);  // Clear existing particle emitters.
    // Muzzle flash alpha, bolt rebound pos
    /* llSetLinkPrimitiveParamsFast(LINK_SET, [
            PRIM_LINK_TARGET, LINK_NUM_FLASH, PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0.0,
            PRIM_LINK_TARGET, LINK_NUM_BOLT, PRIM_POS_LOCAL, PRIM_POS_BOLT_FORWARD
    ]); */
    llMessageLinked(LINK_SET, -1, "", "");
    llResetScript();
}  // weaponReset


default
{
    state_entry() {
        /*
        // Sanity check for valid configuration parameter
        if (!((NUM_FIRE_MODES >= 1) && (NUM_FIRE_MODES <= 3))) {
            debugMessage("ERROR: Invalid NUM_FIRE_MODES! Must be '1', '2', or '3'!");
            debugMessage("NUM_FIRE_MODES = " + (string)NUM_FIRE_MODES);
        } */
        
        ammoCountDisp(0);
        if (llGetAttached()) {
            weaponInit();
            weaponDraw();
        }
        
        debugMemory();
    }  // state_entry
    
    attach(key id) {
        if (id) {
            weaponReset();
        } else {
            // llReleaseControls();
            llRegionSayTo(OWNER_KEY, ACCESSORY_COMMAND_CHANNEL, "primary_detached");
            llOwnerSay("See you, Space Cowboy...");
        }
    }  // attach
    
    run_time_permissions(integer perms) {
        if (!(perms & REQUESTED_PERM_BITMASK)) {
            errorMessage("You must accept permissions!");
            weaponReset();
        } else {
            if (weaponArmed) {
                llTakeControls(CONTROL_ML_LBUTTON, TRUE, TRUE);
                llSetTimerEvent(AO_TIMER_RATE);
            }
        }
    }  // run_time_permissions
    
    changed(integer change) {
        if (weaponArmed && (change & 768)) {  // (CHANGED_TELEPORT | CHANGED_REGION)
            llMessageLinked(LINK_SET, -1, "", "");
            llRequestPermissions(OWNER_KEY, REQUESTED_PERM_BITMASK);
            weaponReload();
        }  else if (change & CHANGED_OWNER) {
            weaponReset();
        }
    }  // changed
    
    control(key id, integer level, integer edge) {
        // Prevents shooting during melee, sling/draw, and reload states.
        if (inReloadState || inActionState) {  
            return;
        }
        
        // integer buttonUntouched = ~(level | edge);
        integer buttonDepress = level & edge;
        // integer buttonHold = level & ~edge;
        // integer buttonRelease = ~level & edge;
        
        if (currentRoundsInMag > 0) {
            // We can remove a check for (~)edge via Boolean algebra
            if ((fireMode == 0) && (CONTROL_ML_LBUTTON & level)) {  // Auto
                weaponDischarge();
            } else if ((fireMode == 1) && (CONTROL_ML_LBUTTON & buttonDepress)) {  // Single
                weaponDischarge();
            } else if ((fireMode == 2) && (CONTROL_ML_LBUTTON & buttonDepress)) {  // Burst
                integer burst = 0;
                do {
                    weaponDischarge();
                    ++burst;
                    llSleep(0.1 / NUM_AVAILABLE_NODES);
                } while (currentRoundsInMag && (burst < ROUNDS_PER_BURST));
            } 
        } else {
            llPlaySound("76e4e99c-8d69-5968-10dd-07100ed05a97", 1.0);  // Dry fire
            llSleep(0.1);
            // llOwnerSay("Out of ammo.");
            weaponReload();  // Auto-reload
        }
    }  // control
    
    listen(integer chan, string name, key id, string msg) {
        if ((id == OWNER_KEY) || (llList2Key(llGetObjectDetails(id, [OBJECT_OWNER]), 0) == OWNER_KEY)) {
            msg = llToLower(msg);
            
            if (msg == "ping") {
                llRegionSayTo(id, ACCESSORY_COMMAND_CHANNEL, "primary_attached");
            } else if (msg == "cqc_attached") {
                meleeOverride = TRUE;
            } else if (msg == "cqc_detached") {
                meleeOverride = FALSE;
            } else if (!inActionState && !inReloadState) {
                // Ordered roughly by likeliness of greatest usage, to minimize number of checks.
                if (weaponArmed) { 
                    if ((msg == llToLower(COMMAND_RELOAD)) && (currentRoundsInMag < MAX_MAG_CAPACITY)) {
                        weaponReload();
                    } 
#ifdef WEAPON_MELEE_ENABLED 
                    else if ((llGetTime() > DELAY_THRESHOLD_MELEE) 
                            && (!meleeOverride) 
                            && (msg == llToLower(COMMAND_MELEE))) {
                        llResetTime();
                        weaponMelee();
                    } 
#endif 
                    else if (msg == llToLower(COMMAND_TOGGLE_WPN_MODE)) {
                        toggleFireMode();
                    } else if (msg == llToLower(COMMAND_TOGGLE_WPN_SAFETY)) {
                        weaponHolster();
                    }
                } else {
                    if (msg == llToLower(COMMAND_TOGGLE_WPN_SAFETY)) {
                        weaponDraw();
                    }
                }
            }
        }
    }  // listen
    
    sensor(integer numDetected) {
        llPlaySound(llList2String(SOUNDS_MELEE_HIT, 
                llRound(llFrand(llGetListLength(SOUNDS_MELEE_HIT) - 1))), 1.0);
        
        // This handles multiple avatars within a single scan.
        // Might be overpowered/unfair from meta perspective?
        do {
            --numDetected;  // List index starts at 0, so we subtract to bring us to the last item
            
            llRezObject(NAME_OBJ_MELEE_DMG, llDetectedPos(numDetected), 
                    llDetectedVel(numDetected), ZERO_ROTATION, 0);
            llOwnerSay("Melee struck " + avatarName(llDetectedKey(numDetected)));
        } while (numDetected);
    }  // sensor
    
    no_sensor() {
        llPlaySound(llList2String(SOUNDS_MELEE_MISS, 
                llRound(llFrand(llGetListLength(SOUNDS_MELEE_MISS) - 1))), 1.0);
    }  // no_sensor
    
    timer() {
        if (inReloadState) { 
            // Magazine drop
            /* llSetLinkPrimitiveParamsFast(LINK_SET, [
                        PRIM_LINK_TARGET, LINK_NUM_MAGAZINE, PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0.0
            ]);
            vector cameraRot = llGetCameraRot();
            llRezObject(NAME_OBJ_MAGAZINE, /|* Name *|/
                            <0.5, 0.0, 0.0> * cameraRot, /|* Offset *|/
                            <, , > * cameraRot, /|* Velocity *|/
                            <, , , > * cameraRot, /|* Rotation *|/
                            0 /|* Start Param *|/
            );
            llSleep();
            // Magazine insert
            llSetLinkPrimitiveParamsFast(LINK_SET, [
                        PRIM_LINK_TARGET, LINK_NUM_MAGAZINE, PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 1.0
            ]); */
            currentRoundsInMag = MAX_MAG_CAPACITY;
            llSetLinkColor(LINK_NUM_AMMO_DISP, DISP_COLOR_NOMINAL_AMMO_STATE, ALL_SIDES);
            ammoCountDisp(currentRoundsInMag);
            inReloadState = FALSE;
            llSetTimerEvent(AO_TIMER_RATE);
            llOwnerSay("Ready.");
        } else {
            integer currentFrameMLState = (llGetAgentInfo(OWNER_KEY) & AGENT_MOUSELOOK);
            
            //if (currentFrameMLState != prevFrameMLState) {
                if (currentFrameMLState) {
                    llStopAnimation(ANIMATION_IDLE);
                    llStartAnimation(ANIMATION_AIMING);
                } else {
                    llStopAnimation(ANIMATION_AIMING);
                    llStartAnimation(ANIMATION_IDLE);
                }
            //} prevFrameMLState = currentFrameMLState;
        }
    }  // timer
}  // default
