#include "inspircd.h"
#include "users.h"
#include "channels.h"
#include "modules.h"

/* $ModDesc: Adds channel mode +U */

class ModeHideIdleChan : public ModeHandler
{
 public:
    ModeHideIdleChan(InspIRCd* Instance) : ModeHandler(Instance, 'U', 0, 0, false, MODETYPE_CHANNEL, false, false) {}
    
  ModeAction OnModeChange(userrec* user, userrec* dest, chanrec* channel, std::string&, bool adding)
    {
        if (channel->IsModeSet('U') != adding)
        {
            channel->SetMode('U', adding);
            return MODEACTION_ALLOW;
        }

        return MODEACTION_DENY;
    }
};

class ModuleHideIdleChan : public Module
{
    ModeHideIdleChan* mode;

 public:
    ModuleHideIdleChan(InspIRCd* Me)
         : Module(Me)
    {
        mode = new ModeHideIdleChan(ServerInstance);

        if (!ServerInstance->AddMode(mode, 'U'))
            throw ModuleException("Could not add new modes!");
    }

    virtual ~ModuleHideIdleChan()
    {
            ServerInstance->Modes->DelMode(mode);
            delete mode;
    }

    virtual void Implements(char* List)
    {
         List[I_OnWhoisLine] = 1;
    }

    virtual Version GetVersion()
    {
         return Version(1,0,0,1,VF_COMMON,API_VERSION);
    }

    int OnWhoisLine(userrec *user, userrec *dest, int &numeric, std::string &text)
    {
        if (numeric != 317 || user == dest || IS_OPER(user))
            return 0;

        for (UCListIter it = dest->chans.begin(); it != dest->chans.end(); it++)
        {
            if (it->first->IsModeSet('U'))
                return 1;
        }

        return 0;
    }
};

MODULE_INIT(ModuleHideIdleChan)
