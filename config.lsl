/** Floats **/
#define AO_TIMER_RATE 0.1
        // In seconds
#define DELAY_THRESHOLD_MELEE 0.3
        // In seconds. Prevents melee spam.
#define PERCENT_LOW_AMMO_WARNING 0.15
        // Decimal percentage, i.e. 0.0 to 1.0.
        // Inspired by Warframe. Firing timbre changes to audibly alert user to low ammo state.
#define RANGE_MELEE 3.5
        // In meters, less than 10.0.
// #define SPREAD_THETA 1.0
        // In degrees of deviation
// #define SPREAD_MODIFIER 0.1
        // Decimal fraction of 100%
#define TEXTURE_COUNTER_FRAME_OFFSET 0.1
        // Offset distance between frames
        // Dependent on TEXTURE_AMMO_COUNTER_FONT
/** Floats **/

/** Integers **/
#define AUX_CMD_CHAN_OFFSET 69
#define LINK_NUM_AMMO_DISP 2
#define LINK_NUM_BOLT 0
#define LINK_NUM_EJECTOR 0
#define LINK_NUM_FLASH 0
#define LINK_NUM_MAGAZINE 0
#define LINK_NUM_MUZZLE 0
#define LINK_NUM_NODE 2
#define MATERIAL_FACE_NODE 0
        // Face of LINK_NUM_NODE to be used for rez node triggering.
#define MAX_MAG_CAPACITY 40
#define NUM_AVAILABLE_NODES 3
        // Number of rez nodes to be used.
        // Currently only capapble of handling 3 max.
#define NUM_FIRE_MODES 3
        // 1 == Auto; 2 == Auto, Semi; 3 == Auto, Semi, Burst
#define ROUNDS_PER_BURST 3
#define TRACER_EVERY_NTH_ROUND 5
        // I.e. a tracer will be fired every Nth round
#define TRACER_LAST_N_ROUNDS 5
        // I.e. the last N rounds will be tracers, to visually show mag is nearing empty.
#define USER_COMMAND_CHANNEL 10
/** Integers **/

/** Lists **/
// list ANIMATIONS_MELEE = [""];
list SOUNDS_MELEE_HIT = ["2bbd2fc4-6c3a-45ac-1760-5bf5353e1aec", 
        "24664de5-ed54-6d2a-7df7-8e0ec3ba0fb5", 
        "b959209a-50b7-ecde-12c3-15d69c5e9bc4"];
list SOUNDS_MELEE_MISS = ["eff009eb-ea42-b520-8b9a-0a3f5d75370d", 
        "2fdd9c89-2803-b303-50e3-7072e94746da", 
        "fef93985-2118-3db4-ec5d-ce2a67cbc967"];
/** Lists **/

/** Strings **/
#define ANIMATION_AIMING "Rifle ADS"
#define ANIMATION_IDLE "Rifle Relax"
#define ANIMATION_MELEE "Rifle Melee"
#define ANIMATION_RELOAD "Rifle Reload"
#define ANIMATION_WPN_DRAW "Rifle Draw"
#define ANIMATION_WPN_HOLSTER "Rifle Draw"
#define COMMAND_MELEE "cqc"
#define COMMAND_RELOAD "reload"
#define COMMAND_TOGGLE_WPN_MODE "mode"
#define COMMAND_TOGGLE_WPN_SAFETY "safety"
#define SOUND_LOW_AMMO_FIRING_LOOP ""
        // Inspired by Warframe. Firing timbre changes to audibly alert user to low ammo state.
        // Triggers at and below the value determined by PERCENT_LOW_AMMO_WARNING
#define SOUND_MODE_SWITCH_TOGGLE "b97d8b1b-486b-3666-d459-0ca82f0cc49f"
#define SOUND_NOMINAL_FIRING_LOOP ""
#define SOUND_RELOAD "8accadd0-9326-ef1f-1190-4ae383659e48"
#define NAME_OBJ_MAGAZINE "wht.empty mag"
#define NAME_OBJ_MELEE_DMG "wht.melee"
#define NAME_OBJ_NORM_BULLET "wht.bullet kill feed"
#define NAME_OBJ_TRCR_BULLET "wht.tracer kill feed"
#define NAME_SCRP_REZNODE "wht.node"
// #define SCRIPT_NAME_MELEE_MODULE "wht.melee module"
#define TEXTURE_AMMO_COUNTER_FONT "f36adc44-a692-0329-3360-7d6fc298fcce"
/** Strings **/

/** Vectors **/
#define DISP_COLOR_LOW_AMMO_STATE <0.996, 0.353, 0.000>
#define DISP_COLOR_NOMINAL_AMMO_STATE <1.0, 1.0, 1.0>
/** Vectors **/

 
 /*** GLOBAL SEMI-CONSTANT VARIABLES ***/
// Initialized once in state_entry / weaponInit()
 
integer ACCESSORY_COMMAND_CHANNEL; 

key OWNER_KEY;
