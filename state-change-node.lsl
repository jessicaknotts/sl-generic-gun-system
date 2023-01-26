

/*** GLOBAL CONSTANT VARIABLES ***/

#include "wht.autopew config"

//integer REQUESTED_PERM_BITMASK = 1024;
        /* (PERMISSION_TRACK_CAMERA) */

#define REQUESTED_PERM_BITMASK 1024
        // (PERMISSION_TRACK_CAMERA) 


/*** GLOBAL SEMI-CONSTANT VARIABLES ***/
// Initialized once in state_entry
// See config file for existing declarations.

integer NODE_NUM; 
// vector HALF_SPREAD; 

/* 
 * Returns a randomized point on the X/Y plane, with a specified
 * stdev from center.
 */
vector randGaussPair(vector center, float stdev)
{
    float r2;
    vector p;
    do {  //Generate a point in a unit circle that is not zero.
        p = <0.0, llFrand(2.0) - 1.0, llFrand(2.0) - 1.0>;
        r2 = p * p;  //dot product
    } while (r2 > 1.0 || r2 == 0);
 
    //Box-Muller transformation
    return center + (p * (stdev * llSqrt( -2.0 * llLog(r2) / r2)));
}


default
{
    state_entry() {
        string scriptName = llGetScriptName();
        list temp = llParseString2List(scriptName, [" "], [""]);
        if (llToLower(llList2String(temp, 0)) == NAME_SCRP_REZNODE) {
            NODE_NUM = (integer)llGetSubString(llList2String(temp, 1), 0, 0);  // Single digit only
            // Also this should ignore some junk in second string part, 'cause it'd take too much effort  
            // and script resources to check if the given input is numeric.
        } else {
            llOwnerSay("Error! Script \"" + scriptName + "\" has an invalid name!");
            llOwnerSay("Name must be of form \"" + NAME_SCRP_REZNODE 
                    + " X\" where X is an integer value (0-9), and indexed beginning at 0.");
            llOwnerSay("Example script name: \"" + NAME_SCRP_REZNODE + " 0\", \"" 
                    + NAME_SCRP_REZNODE + " 1\", etcetera.");
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
            llRequestPermissions(OWNER_KEY, REQUESTED_PERM_BITMASK);
        }
    }  // run_time_permissions

    changed(integer chng) {
        if (chng & CHANGED_COLOR) {
            list params = llGetLinkPrimitiveParams(LINK_NUM_NODE, [
                    PRIM_COLOR, MATERIAL_FACE_NODE, 
                    PRIM_DESC
            ]);
            vector trigger = (vector)llList2String(params, 0);
            
            if ((llGetTime() > 0.1) && (trigger.x >= 0.9)) {
                llResetTime();
                string bulletName = llList2String(params, 2);
                
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
        }
    }  // changed
}  // default
