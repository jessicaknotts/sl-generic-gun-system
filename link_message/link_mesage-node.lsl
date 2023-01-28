/*** GLOBAL CONSTANT VARIABLES ***/

// #define SPREAD_THETA 1.0
        // In degrees, one standard deviation from point of aim
// #define SPREAD_MODIFIER 0.1
        // Decimal fraction of 100%
#define REQUESTED_PERM_BITMASK 1024
        /* (PERMISSION_TRACK_CAMERA) */
#define REZ_NODE_NAME_PREFIX "wht.node"


/*** GLOBAL SEMI-CONSTANT VARIABLES ***/
// Set once in state_entry

key OWNER_KEY; 
integer NODE_NUM; 
// vector HALF_SPREAD; 

/* 
 * http://wiki.secondlife.com/wiki/Random_Gaussian_Number_Generator
 */
vector randGaussPair(vector center, float stdev)
{
    // returns a random point on the x/y plain with a specified standard deviation from center.
    float r2;
    vector p;
    do {  // Generate a point in a unit circle that is not zero.
        p = <0, llFrand(2.) - 1, llFrand(2.) - 1>;
        r2 = p * p;  //dot product
    } while (r2 > 1.0 || r2 == 0);
 
    // Box-Muller transformation
    return center + (p * (stdev * llSqrt( -2 * llLog(r2) / r2)));
}  // randGaussPair


default
{
    state_entry() {
        string scriptName = llGetScriptName();
        list temp = llParseString2List(scriptName, [" "], [""]);
        if (llToLower(llList2String(temp, 0)) == REZ_NODE_NAME_PREFIX) {
            NODE_NUM = (integer)llGetSubString(llList2String(temp, 1), 0, 0);  // Single digit only
            // Also this should ignore some junk in second string part, 'cause it'd take too much effort  
            // and script resources to check if the given input is numeric.
        } else {
            llOwnerSay("Error! Script \"" + scriptName + "\" has an invalid name!");
            llOwnerSay("Name must be of form \"" + REZ_NODE_NAME_PREFIX 
                    + " X\" where X is an integer value (0-9), and indexed beginning at 0.");
            llOwnerSay("Example script name: \"" + REZ_NODE_NAME_PREFIX + " 0\", \"" 
                    + REZ_NODE_NAME_PREFIX + " 1\", etcetera.");
            return;
        }
        
        OWNER_KEY = llGetOwner();
        // HALF_SPREAD = <0., SPREAD_THETA, SPREAD_THETA> * 0.5;
        if (llGetAttached()) {
            llRequestPermissions(OWNER_KEY, REQUESTED_PERM_BITMASK);
        }
        // llOwnerSay("Used memory: " + (string)llGetUsedMemory());
    }  // state_entry

    run_time_permissions(integer perms) {
        if (!(perms & REQUESTED_PERM_BITMASK)) {
            llInstantMessage(OWNER_KEY, llGetScriptName() + ": You must accept permissions!");
            llResetScript();
        }
    }  // run_time_permissions

    link_message(integer src, integer num, string bulletName, key bulletType) {
        if (num == -1) {
            llResetScript();
        } else if ((llGetTime() > 0.1) && (num == NODE_NUM)) {
            llResetTime();
            
            // ! REZ PARAMS USED BELOW ARE FOR TESTING ONLY !
            // dmg_exp_a 0.007000 0. 100 0000.0000 00
            
            /* float spread = 0.00100;
            float vel = 208.2;
            float z_off = 0.0;
                        
            rotation rot = llGetRot();
            rotation rot2 = llRotBetween(randGaussPair(<0.0, 0.0, 1.0>, 0.3), <1,0,0> * rot);
            vector avVel = (llGetVel() / rot) * .75;
            float offset = 2.8 + (avVel.x * .225);
            //          Minimum offset                  Variable offset                   Maximum offset
            offset = (offset <= 2.1) * 2.1 + (offset < 4.8 && offset > 2.1) * offset + (offset >= 4.8) * 4.8;
            vector avPos = llGetPos();
            vector camPos = llGetCameraPos();
            avPos = <   (camPos.x + (avPos.x * 2)) * .33333, 
                        (camPos.y + (avPos.y * 2)) * .33333, 
                        (camPos.z - z_off)
                    >;
                    
            llRezObject(bulletName, 
                    avPos + (<0.0, 0.0, z_off> * rot) + (<0.0, 0.0, offset> * rot2), 
                    <0.0, 0.0, vel> * rot2, 
                    rot2, 
                    0
            ); */
            
            rotation camRot = llGetCameraRot();
            // float vel = llVecMag(llGetVel()) * 0.44;
            vector avVel = (llGetVel() / camRot) * .75;
            float offset = 1.2 + (avVel.x * .225);
            //          Minimum offset                  Variable offset                 Maximum offset
            offset = (offset <= 1.2) * 1.2 + (offset < 4.8 && offset > 1.2) * offset + (offset >= 4.8) * 4.8;
            
            llRezObject(bulletName, /* Name */
                    llGetCameraPos() + <offset, 0., 0.> * camRot, /* Offset */
                    <202.8, 0., 0.> * camRot, /* Velocity */
                    <1., 0., 0., 0.> * camRot, /* Rotation */
                    0 /* Start Param */
            );
        }
    }  // link_message
}  // default
