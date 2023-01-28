// https://github.com/bird-get/lsl-snippets/blob/master/debug.lsl
#ifdef DEBUG
debugMemory()
{
    integer usedMemory = llGetUsedMemory();
    integer totalMemory = llGetMemoryLimit();
    float percentage = (float)usedMemory / (float)totalMemory * 100;
    llOwnerSay("(" + llGetScriptName() + ") Memory usage: " 
    + (string)usedMemory + "/" 
    + (string)totalMemory + " bytes. (" + (string)percentage + "%)");
}

debugMessage(string message)
{
    llOwnerSay("Debug @ " + (string)__LINE__ + ": " + (string)message);
}
#else
#define debugMemory()
#define debugMessage(void)
#endif
