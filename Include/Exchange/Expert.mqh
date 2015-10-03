//+------------------------------------------------------------------+
//|                                                       Expert.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "Monitor.mqh"

class ExpertConfigurator : Configurator
{
   EXPERT m_expert;
public:
   ExpertConfigurator(EXPERT& expert)
   {
      m_expert.Init(expert);
   }
   
   void MonitorsInit(Monitor* &monitor)
   {
      if(SymbolSelect(m_expert.m_monitor.m_symbolTerminal, true))
      {
         MonitorConfigurator* monitorConfigurator = new MonitorConfigurator(m_expert.m_monitor);
         if (CheckPointer(monitor) == POINTER_DYNAMIC) { delete monitor; monitor = NULL; }
         monitor = new Monitor(monitorConfigurator);
         if (CheckPointer(monitorConfigurator) == POINTER_DYNAMIC) delete monitorConfigurator;
      }
      else
      {
         Print(__FUNCTION__, ": Symbol '", m_expert.m_monitor.m_symbolTerminal, "' not found in terminal (market watch). Please check and restart Expert");
      }
   }
   void ConfigNameInit(string& name)
   {
      name = m_expert.m_configPath;
   }
};

class Expert
{
   Monitor* m_monitor;
   string m_configPath;
   
public:
   Expert(ExpertConfigurator* expertConfigurator)
   {
      expertConfigurator.MonitorsInit(m_monitor);
      expertConfigurator.ConfigNameInit(m_configPath);
   }
  ~Expert()
   {
      if (CheckPointer(m_monitor) == POINTER_DYNAMIC)
      {
         delete m_monitor; m_monitor = NULL;
      }
   }
   
   void Working()
   {
      if (m_monitor != NULL)  m_monitor.Working();
      else
      {
         Comment("Config: '", m_configPath, "'\n", "Not found settings in symbol: '", Symbol(), "'", "\n", "Please check and update config...\n", "Please restart Expert after update config");
      }
   }
};
