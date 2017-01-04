#include "inspircd.h"
#include "users.h"
#include "channels.h"
#include "modules.h"

/* $ModDesc: Adds user mode +U which hides the idle time */

/** Handles user mode +U
 */
class ModeHideIdle : public ModeHandler
{
 public:
        ModeHideIdle(InspIRCd* Instance) : ModeHandler(Instance, 'U', 0, 0, false, MODETYPE_USER, false, false) {}
    
        ModeAction OnModeChange(userrec* source, userrec* dest, chanrec* channel, std::string &parameter, bool adding, bool)
        {
                if (adding)
                {
                        if (!dest->IsModeSet('U'))
                        {
                                dest->SetMode('U',true);
                                return MODEACTION_ALLOW;
                        }
                }
                else
                {
                        if (dest->IsModeSet('U'))
                        {
                                dest->SetMode('U',false);
                                return MODEACTION_ALLOW;
                        }
                }
                
                return MODEACTION_DENY;
        }
};

class ModuleHideIdle : public Module
{
        ModeHideIdle* mode;

 public:
        ModuleHideIdle(InspIRCd* Me)
                : Module::Module(Me)
        {
                mode = new ModeHideIdle(ServerInstance);
                if (!ServerInstance->Modes->AddMode(mode))
                        throw ModuleException("Could not add new modes!");
        }

        virtual ~ModuleHideIdle()
        {
                ServerInstance->Modes->DelMode(mode);
                delete mode;
        }

        virtual Version GetVersion()
        {
                return Version(1,0,0,1,VF_COMMON,API_VERSION);
        }

        int OnWhoisLine(userrec* user, userrec* dest, int &numeric, std::string &text)
        {
                /* Dont display idle time if they have +U set
                 */
                return ((user != dest) && !IS_OPER(user) && (numeric == 317) && dest->IsModeSet('U'));
        }
};


MODULE_INIT(ModuleHideIdle)
