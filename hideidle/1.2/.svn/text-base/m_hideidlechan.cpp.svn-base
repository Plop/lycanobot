#include "inspircd.h"
#include "users.h"
#include "channels.h"
#include "modules.h"

/* $ModDesc: Adds channel mode +U */

class ModeHideIdleChan : public ModeHandler
{
 public:
    ModeHideIdleChan(InspIRCd* Instance) : ModeHandler(Instance, 'U', 0, 0, false, MODETYPE_CHANNEL, false, false) {}
    
  ModeAction OnModeChange(User* user, User* dest, Channel* channel, std::string&, bool adding, bool)
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

        if (!ServerInstance->Modes->AddMode(mode))
            throw ModuleException("Could not add new modes!");
	Implementation eventlist[] = { I_OnWhoisLine };
	ServerInstance->Modules->Attach(eventlist, this, 1);
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

    int OnWhoisLine(User *user, User *dest, int &numeric, std::string &text)
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
