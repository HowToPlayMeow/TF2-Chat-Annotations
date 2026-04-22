#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#tryinclude <basecomm>
#tryinclude <sourcecomms>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "6.6.1"
#define PLUGIN_PREFIX "\x03Chat Annotations\x01"

public Plugin myinfo = 
{
    name = "TF2Chat Annotations",
    author = "HowToPlayMeow",
    description = "Meow Meow",
    version = PLUGIN_VERSION,
    url = "https://github.com/HowToPlayMeow/TF2-Chat-Annotations"
};

ConVar cvAnnEnable;
ConVar cvAnnRange;
ConVar cvAnnShowRange;
ConVar cvAnnShowMsg;
ConVar cvAnnShowCmd;
ConVar cvAnnInterval;
ConVar cvAnnLife;
ConVar cvAnnSound;
ConVar cvAnnLimit;
ConVar cvAnnMaxLen;
ConVar cvAnnCMDAnn;
ConVar cvAnnCMDSound;
ConVar cvAnnCMDRange;
ConVar cvAnnRemove;
ConVar cvAnnBlock;

Handle  g_hAnnChatCookie;                               // Cookie CMD Chat
Handle  g_hAnnSoundCookie;                              // Cookie CMD Sound
Handle  g_hAnnRangeCookie;                              // Cookie CMD Range
Handle  g_hTimerAnn = null;                             // Annotation Update Timer
char    g_cLastMsg[MAXPLAYERS+1][256];                  // Last Chat Message
int     g_iAnnID[MAXPLAYERS+1];                         // Player Annotation ID
int     g_iAnnIDMeow = 1;                               // Annotation ID
int     g_ibasecomm;                                    // There is a basecomm
int     g_isourcecomms;                                 // There is a sourcecomms
bool    g_bAnnIsTeam[MAXPLAYERS+1];                     // Team Chat
bool    g_bViewerSee[MAXPLAYERS+1][MAXPLAYERS+1];       // Viewer Visibility Cache
bool    g_bPlayerMoved[MAXPLAYERS+1];                   // Player Moved
bool    g_bAnnEnabled[MAXPLAYERS+1];                    // Annotation Enabled
bool    g_bAnnSound[MAXPLAYERS+1];                      // Sound Enabled
bool    g_bAnnRange[MAXPLAYERS+1];                      // Range Enabled
float   g_fAnnN[MAXPLAYERS+1];                          // Annotation lifetime (END)
float   g_fLastPos[MAXPLAYERS+1][3];                    // Last Position
float   g_fLastAng[MAXPLAYERS+1][3];                    // Last View Angles
float   g_fCachePos[MAXPLAYERS+1][3];                   // Cached Position

public void OnPluginStart() 
{
    CreateConVar("sm_cvann_version", PLUGIN_VERSION, "Version of TF2Chat Annotations", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cvAnnEnable    = CreateConVar("sm_cvann_enable", "1", "TF2Chat Annotations. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnRange     = CreateConVar("sm_cvann_range", "25", "Distance to See Annotations.", FCVAR_NONE, true, 0.0);
    cvAnnShowRange = CreateConVar("sm_cvann_show_range", "1", "Show Distance to speaker in Annotations. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnShowMsg   = CreateConVar("sm_cvann_show_msg", "1", "Allow Players to See their own Chat Annotation. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnShowCmd   = CreateConVar("sm_cvann_show_cmd", "1", "Command Visibility. (0 = Hide ! and /, 1 = Hide /, 2 = Hide !, 3 = Show ! and /)", FCVAR_NONE, true, 0.0, true, 3.0);
    cvAnnInterval  = CreateConVar("sm_cvann_interval", "0.5", "Update interval for checking Annotation Visibility.", FCVAR_NONE, true, 0.5);
    cvAnnLife      = CreateConVar("sm_cvann_lifetime", "10.0", "How long Message stays visible (Seconds).", FCVAR_NONE, true, 0.0);
    cvAnnSound     = CreateConVar("sm_cvann_sound", "ui/hint.wav", "Sound File to play when Annotation Appears. (Empty = No sound)");
    cvAnnLimit     = CreateConVar("sm_cvann_limit", "5", "Maximum Number of Annotations shown at same time. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
    cvAnnMaxLen    = CreateConVar("sm_cvann_maxlen", "64", "Maximum Length of Chat Message shown in Annotations.", FCVAR_NONE, true, 0.0, true, 128.0);
    cvAnnCMDAnn    = CreateConVar("sm_cvann_cmd_chat", "1", "Default Chat Command. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnCMDSound  = CreateConVar("sm_cvann_cmd_sound", "0", "Default Sound Command. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnCMDRange  = CreateConVar("sm_cvann_cmd_range", "0", "Default Range Command. (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAnnRemove    = CreateConVar("sm_cvann_entity_remove", "1900", "Remove All Annotations if Entity count reaches this.", FCVAR_NONE, true, 0.0, true, 2048.0);
    cvAnnBlock     = CreateConVar("sm_cvann_entity_block", "2000", "Block New Annotations if Entity count reaches this.", FCVAR_NONE, true, 0.0, true, 2048.0);

    g_hAnnChatCookie  = RegClientCookie("cvann_chat", "Chat", CookieAccess_Public);
    g_hAnnSoundCookie = RegClientCookie("cvann_sound", "Sound", CookieAccess_Public);
    g_hAnnRangeCookie = RegClientCookie("cvann_range", "Range", CookieAccess_Public);

    RegConsoleCmd("sm_annotations", Command_Settings);
    RegConsoleCmd("sm_annotation", Command_Settings);
    RegConsoleCmd("sm_annotate", Command_Settings);
    RegConsoleCmd("sm_ann", Command_Settings);

    HookEvent("player_spawn", ReAnnID);
    HookEvent("player_death", ReAnnID);

    AutoExecConfig(true, "TF2Chat-Annotations");
    StartAnnotation();
}

public void OnMapStart()
{
    StartAnnotation();
}

public void OnPluginEnd()
{
    StopAnnotation();
}

public void OnMapEnd()
{
    StopAnnotation();
}

public void OnClientPutInServer(int client)
{
    OnClientCookiesCached(client);
    HideAnnotation(client);
}

public void OnClientDisconnect(int client)
{
    OnClientCookiesCached(client);
    HideAnnotation(client);
}

// Hide Annotations Spy (cloak/disguise)
public void TF2_OnConditionAdded(int client, TFCond condition)
{
    switch (condition)
    {
        case TFCond_Cloaked, TFCond_Disguised, TFCond_Disguising, TFCond_DisguisedAsDispenser:
        {
            if (client > 0 && IsClientInGame(client))
                HideAnnotation(client);
        }
    }
}

void StartAnnotation()
{
    g_ibasecomm = LibraryExists("basecomm");
    g_isourcecomms = LibraryExists("sourcecomms");

    static char sound[PLATFORM_MAX_PATH];
    cvAnnSound.GetString(sound, sizeof(sound));
    if (sound[0] != '\0')
        PrecacheSound(sound, true);

    float interval = cvAnnInterval.FloatValue;
    if (g_hTimerAnn == null)
        g_hTimerAnn = CreateTimer(interval, UpdateAnnotation, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopAnnotation()
{
    RemoveAnnotationAll();

    g_ibasecomm = false;
    g_isourcecomms = false;

    if (g_hTimerAnn != null)
    {
        delete g_hTimerAnn;
        g_hTimerAnn = null;
    }
}

// Reset Annotation and ID when Player Spawns or Dies
public void ReAnnID(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client))
        HideAnnotation(client);
}

// Prevent Entity Overflow by Remove or Block Annotations
bool RealServerCrash()
{
    int RealCrash = GetEntityCount();
    int remove = cvAnnRemove.IntValue;
    int block = cvAnnBlock.IntValue;
    
    if (remove > 0 && remove <= 2048 && RealCrash >= remove)
        RemoveAnnotationAll();

    if (block > 0 && block <= 2048 && RealCrash >= block)
        return false;

    return true;
}

// Check Players
bool YouIsCat(int client)
{
    if (client <= 0 || !IsClientInGame(client))
        return false;

    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)
    || TF2_IsPlayerInCondition(client, TFCond_Disguised) 
    || TF2_IsPlayerInCondition(client, TFCond_Disguising)
    || TF2_IsPlayerInCondition(client, TFCond_DisguisedAsDispenser))
        return false;

    return true;
}

// Got gagged
bool CatToxic(int client)
{
    #if defined _basecomm_included
    if (g_ibasecomm)
    {
        if (BaseComm_IsClientGagged(client))
            return false;
    }
    #endif

    #if defined _sourcecomms_included
    if (g_isourcecomms)
    {
        int NOPE = view_as<int>(SourceComms_GetClientGagType(client));
        if (NOPE == 1 || NOPE == 3)
            return false;
    }
    #endif

    return true;
}

// Check Chat
public void OnClientSayCommand_Post(int client, const char[] command, const char[] argc)
{
    bool enable = cvAnnEnable.BoolValue;
    float range = cvAnnRange.FloatValue;
    float life = cvAnnLife.FloatValue;
    int cmd = cvAnnShowCmd.IntValue;
    int maxlen = cvAnnMaxLen.IntValue;

    if (!enable || !RealServerCrash())
        return;

    if (range <= 0.0 || life <= 0.0 || maxlen <= 0)
        return;

    if (!YouIsCat(client) || !CatToxic(client) || !IsPlayerAlive(client))
        return;

    char msg[256];
    strcopy(msg, sizeof(msg), argc);
    StripQuotes(msg);
    TrimString(msg);

    ReplaceString(msg, sizeof(msg), "%", "﹪");
    ReplaceString(msg, sizeof(msg), "&", "﹠");

    if (msg[0] == '\0')
        return;

    if (cmd < 3)
    {
        if (cmd == 0 && (msg[0] == '!' || msg[0] == '/'))
            return;

        if (cmd == 1 && msg[0] == '/')
            return;

        if (cmd == 2 && msg[0] == '!')
            return;
    }

    if (strlen(msg) > maxlen)
        msg[maxlen] = '\0';

    bool isTeam = StrEqual(command, "say_team");

    MeowMeow(client, isTeam, msg, life);
}

// Store Annotation data for a talking client
void MeowMeow(int client, bool isTeam, const char[] msg, float life)
{
    HideAnnotation(client);

    g_bAnnIsTeam[client] = isTeam;
    g_iAnnIDMeow = (g_iAnnIDMeow % 0x7FFFFFFF) + 1;
    g_iAnnID[client] = g_iAnnIDMeow;

    strcopy(g_cLastMsg[client], sizeof(g_cLastMsg[client]), msg);
    g_fAnnN[client] = GetGameTime() + life;
}

// Main timer loop that Updates, Shows or Hides Annotations
public Action UpdateAnnotation(Handle timer)
{
    bool enable = cvAnnEnable.BoolValue;
    float range = cvAnnRange.FloatValue * 40.0;
    float rangeSqr = range * range;
    float now = GetGameTime();
    int activeTalkers[MAXPLAYERS+1];
    int activeCount = 0;

    if (!enable)
        return Plugin_Continue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        g_bPlayerMoved[i] = CatSleep(i);
        GetClientEyePosition(i, g_fCachePos[i]);

        if (g_iAnnID[i] != 0)
        {
            if (!YouIsCat(i) || g_fAnnN[i] <= now)
            {
                HideAnnotation(i);
            }
            else
            {
                activeTalkers[activeCount++] = i;
            }
        }
    }

    if (activeCount == 0)
        return Plugin_Continue;

    for (int t = 0; t < activeCount; t++)
    {
        int talker = activeTalkers[t];
        bool talkerMoved = g_bPlayerMoved[talker];

        for (int viewer = 1; viewer <= MaxClients; viewer++)
        {
            if (!IsClientInGame(viewer) || IsFakeClient(viewer))
                continue;

            YouSeeAnnotation(viewer, talker, talkerMoved, g_bPlayerMoved[viewer], rangeSqr, now);
        }
    }

    return Plugin_Continue;
}

// Check for Movement
bool CatSleep(int client)
{
    if (!IsClientInGame(client))
        return false;

    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientEyeAngles(client, ang);

    if (GetVectorDistance(pos, g_fLastPos[client], true) > 4.0 || GetVectorDistance(ang, g_fLastAng[client], true) > 1.0)
    {
        for (int i = 0; i < 3; i++) 
        { 
            g_fLastPos[client][i] = pos[i];
            g_fLastAng[client][i] = ang[i];
        }

        return true;
    }

    return false;
}

// Determine whether viewer can see talker Annotation
void YouSeeAnnotation(int viewer, int talker, bool talkerMoved, bool viewerMoved, float rangeSqr, float now)
{
    if (!IsClientInGame(viewer) || IsFakeClient(viewer))
        return;

    if (!g_bAnnEnabled[viewer])
        return;

    bool seemsg = cvAnnShowMsg.BoolValue;
    if (viewer == talker && !seemsg)
        return;

    if (g_bAnnIsTeam[talker] && GetClientTeam(talker) != GetClientTeam(viewer))
        return;

    if (!talkerMoved && !viewerMoved && g_bViewerSee[viewer][talker])
        return;

    if (GetVectorDistance(g_fCachePos[talker], g_fCachePos[viewer], true) > rangeSqr)
    {
        if (g_bViewerSee[viewer][talker])
        { 
            HideAnnotationReal(talker, viewer);
            g_bViewerSee[viewer][talker] = false;
        }
        return;
    }

    float ang[3], dir[3], vec[3];
    GetClientEyeAngles(viewer, ang);
    GetAngleVectors(ang, dir, NULL_VECTOR, NULL_VECTOR); 
    MakeVectorFromPoints(g_fCachePos[viewer], g_fCachePos[talker], vec);
    NormalizeVector(vec, vec);

    if (GetVectorDotProduct(dir, vec) < 0.0)
    {
        if (g_bViewerSee[viewer][talker])
        {
            HideAnnotationReal(talker, viewer);
            g_bViewerSee[viewer][talker] = false;
        }

        return;
    }

    TR_TraceRayFilter(g_fCachePos[viewer], g_fCachePos[talker], MASK_VISIBLE, RayType_EndPoint, CatSee, viewer);

    if (!TR_DidHit())
    {
        if (!g_bViewerSee[viewer][talker] && !MaxAnnotation(viewer))
        {
            ShowAnnotation(talker, viewer, g_fAnnN[talker] - now);
            g_bViewerSee[viewer][talker] = true;
        }
    }
    else if (g_bViewerSee[viewer][talker])
    {
        HideAnnotationReal(talker, viewer);
        g_bViewerSee[viewer][talker] = false;
    }
}

// Not Block Players
public bool CatSee(int entity, int mask, any data)
{
    if (entity == data)
        return false;

    if (entity > 0 && entity <= MaxClients)
        return false;

    return true;
}

// Limit Number of visible Annotations per viewer
bool MaxAnnotation(int viewer) 
{
    if (!g_bAnnEnabled[viewer])
        return true;

    int count = 0;
    int oldestTalker = -1;
    int limit = cvAnnLimit.IntValue;
    float life = cvAnnLife.FloatValue;
    float time = GetGameTime() + life;

    if (limit <= 0)
        return false;
    
    for (int t = 1; t <= MaxClients; t++)
    {
        if (g_bViewerSee[viewer][t])
        {
            if (t == viewer)
                continue;

            count++;

            if (g_fAnnN[t] < time)
            {
                time = g_fAnnN[t];
                oldestTalker = t;
            }
        }
    }

    if (count < limit)
        return false;

    if (oldestTalker != -1)
    {
        HideAnnotationReal(oldestTalker, viewer);
        g_bViewerSee[viewer][oldestTalker] = false;
        return false;
    }

    return true;
}

// Show Annotation
void ShowAnnotation(int client, int viewer, float life)
{
    if (!IsClientInGame(client) || !IsClientInGame(viewer))
        return;

    bool See = cvAnnShowRange.BoolValue;
    static char sound[PLATFORM_MAX_PATH]; 
    cvAnnSound.GetString(sound, sizeof(sound));

    Event ev = CreateEvent("show_annotation");
    if (!ev)
        return;

    ev.SetInt("follow_entindex", client);
    ev.SetInt("id", g_iAnnID[client]);
    ev.SetString("text", g_cLastMsg[client]);
    ev.SetFloat("lifetime", life);

    if (g_bAnnSound[viewer] && sound[0] != '\0')
        ev.SetString("play_sound", sound);

    if (g_bAnnRange[viewer] && viewer != client)
        ev.SetBool("show_distance", See);
    
    ev.FireToClient(viewer);
}

// Check and Remove
void HideAnnotation(int client)
{
    if (g_iAnnID[client] != 0)
        HideAnnotationReal(client, 0);

    g_iAnnID[client] = 0;
    g_fAnnN[client] = 0.0;
    g_bAnnIsTeam[client] = false;

    for (int i = 1; i <= MaxClients; i++)
        g_bViewerSee[i][client] = false;
}

// Real Remove
void HideAnnotationReal(int client, int viewer)
{
    Event ev = CreateEvent("hide_annotation");
    if (!ev)
        return;

    ev.SetInt("follow_entindex", client);
    ev.SetInt("id", g_iAnnID[client]);

    if (viewer > 0 && IsClientInGame(viewer))
    {
        ev.FireToClient(viewer);
    }
    else
    {
        ev.Fire();
    }
}

// Remove ALL
void RemoveAnnotationAll()
{
    for (int i = 1; i <= MaxClients; i++)
        HideAnnotation(i);
}

// Load Cookies Client 
public void OnClientCookiesCached(int client)
{
    bool cmdann   = cvAnnCMDAnn.BoolValue;
    bool cmdsound = cvAnnCMDSound.BoolValue;
    bool cmdrange = cvAnnCMDRange.BoolValue;

    char vAnn[8];
    GetClientCookie(client, g_hAnnChatCookie, vAnn, sizeof(vAnn));
    if (vAnn[0] == '\0')
    {
        g_bAnnEnabled[client] = cmdann;
    }
    else
    {
        g_bAnnEnabled[client] = (StringToInt(vAnn) == 1);
    }

    char vSound[8];
    GetClientCookie(client, g_hAnnSoundCookie, vSound, sizeof(vSound));
    if (vSound[0] == '\0')
    {
        g_bAnnSound[client] = cmdsound;
    }
    else
    {
        g_bAnnSound[client] = (StringToInt(vSound) == 1);
    }  

    char vRange[8];
    GetClientCookie(client, g_hAnnRangeCookie, vRange, sizeof(vRange));
    if (vRange[0] == '\0')
    {
        g_bAnnRange[client] = cmdrange;
    }
    else
    {
        g_bAnnRange[client] = (StringToInt(vRange) == 1);
    }
}

// Open Annotation settings menu
public Action Command_Settings(int client, int args)
{
    Menu_Settings(client);
    return Plugin_Handled;
}

// Open Annotation settings menu
void Menu_Settings(int client)
{
    if (client <= 0 || !IsClientInGame(client))
        return;

    bool See = cvAnnShowRange.BoolValue;
    static char sound[PLATFORM_MAX_PATH];
    cvAnnSound.GetString(sound, sizeof(sound));
    
    Menu menu = CreateMenu(MenuHandler_Settings);
    menu.SetTitle("[Chat Annotations Settings]");

    char buffer[64];
    Format(buffer, sizeof(buffer), "Chat: [%s]", g_bAnnEnabled[client] ? "Enable" : "Disable");
    menu.AddItem("cvann_chat", buffer);

    if (g_bAnnEnabled[client] && sound[0] != '\0')
    {
        Format(buffer, sizeof(buffer), "Sound: [%s]", g_bAnnSound[client] ? "Enable" : "Disable");
        menu.AddItem("cvann_sound", buffer);
    }

    if (g_bAnnEnabled[client] && See)
    {
        Format(buffer, sizeof(buffer), "Range: [%s]", g_bAnnRange[client] ? "Enable" : "Disable");
        menu.AddItem("cvann_range", buffer);
    }
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

// Save Settings
public int MenuHandler_Settings(Menu menu, MenuAction action, int client, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            bool See = cvAnnShowRange.BoolValue;
            char value[8];
            static char sound[PLATFORM_MAX_PATH];
            cvAnnSound.GetString(sound, sizeof(sound));
            
            switch (param2)
            {
                case 0:
                {
                    g_bAnnEnabled[client] = !g_bAnnEnabled[client];

                    IntToString(g_bAnnEnabled[client] ? 1 : 0, value, sizeof(value));
                    SetClientCookie(client, g_hAnnChatCookie, value);
                    
                    if (g_bAnnEnabled[client])
                    {
                        PrintToChat(client, "\x01[%s]\x01 Enable: \x05Chat", PLUGIN_PREFIX);
                    }
                    else
                    {
                        PrintToChat(client, "\x01[%s]\x01 Disable: \x05Chat", PLUGIN_PREFIX);

                        for (int t = 1; t <= MaxClients; t++)
                        {
                            if (g_bViewerSee[client][t])
                            {
                                HideAnnotationReal(t, client);
                                g_bViewerSee[client][t] = false;
                            }
                        }
                    }
                }
                case 1:
                {
                    g_bAnnSound[client] = !g_bAnnSound[client];

                    IntToString(g_bAnnSound[client] ? 1 : 0, value, sizeof(value));
                    SetClientCookie(client, g_hAnnSoundCookie, value);

                    if (g_bAnnEnabled[client] && g_bAnnSound[client] && sound[0] != '\0')
                    {
                        PrintToChat(client, "\x01[%s]\x01 Enable: \x05Sound", PLUGIN_PREFIX);
                    }
                    else
                    {
                        PrintToChat(client, "\x01[%s]\x01 Disable: \x05Sound", PLUGIN_PREFIX);
                    }
                }
                case 2:
                {
                    g_bAnnRange[client] = !g_bAnnRange[client];

                    IntToString(g_bAnnRange[client] ? 1 : 0, value, sizeof(value));
                    SetClientCookie(client, g_hAnnRangeCookie, value);
                    
                    if (g_bAnnEnabled[client] && g_bAnnRange[client] && See)
                    {
                        PrintToChat(client, "\x01[%s]\x01 Enable: \x05Range", PLUGIN_PREFIX);
                    }
                    else
                    {
                        PrintToChat(client, "\x01[%s]\x01 Disable: \x05Range", PLUGIN_PREFIX);
                    }
                }
            }

            Menu_Settings(client);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return Plugin_Continue;
}
