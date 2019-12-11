//+------------------------------------------------------------------+
//|                                                 test_monitor.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "H:\Projects\FortFS\MT\MQL\Terminator\Include\Exchange\Config\Config.mqh"
#include "H:\Projects\FortFS\MT\MQL\Terminator\Include\Exchange\Model.mqh"
#include "H:\Projects\FortFS\MT\MQL\Terminator\Include\Exchange\Expert.mqh"


input string         FileConfig = "setting.json"; // Config file expert
EXPERT               Config;
Expert*              MainExpert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   OnTick();
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   InitExpert(Config);
   while(!IsStopped())
  {
      ulong count = GetMicrosecondCount();
      
      RefreshRates();
      MainExpert.Working();   // MAIN WORKING EXPERTS
      
      count = GetMicrosecondCount() - count;
      
      if (count * 0.001 < Config.m_updateMilliSecondsExpert)
      {
         Sleep(Config.m_updateMilliSecondsExpert - count * 0.001);    // SLEEP EXPERTS
      }
   }
   DeinitExpert();
}
//+------------------------------------------------------------------+

void InitConfig(EXPERT& config)
{
   Setting* setting = new Setting(FileConfig);
   setting.Load(config);
   if (CheckPointer(setting) == POINTER_DYNAMIC) delete setting;
}

void InitExpert(EXPERT& expertConfig)
{
   // deinit expert if not NULL
   DeinitExpert();
   // Config init
   InitConfig(expertConfig);
   // Expert configurator init
   ExpertConfigurator*  mainConfigurator = new ExpertConfigurator(expertConfig);
   // Create expert
   MainExpert = new Expert(mainConfigurator);
   // delete expert configurator
   if (CheckPointer(mainConfigurator) == POINTER_DYNAMIC) delete mainConfigurator;
}

void DeinitExpert()
{
   if (CheckPointer(MainExpert) == POINTER_DYNAMIC) delete MainExpert;
}