//+------------------------------------------------------------------+
//|                                                       Config.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "json.mqh"
#include <Exchange\Model.mqh>
#include <Exchange\FileWork\FileMemory.mqh>


class Setting
{
public:
   Setting(string filePath)
   {
      m_handle = INVALID_HANDLE;
      m_filePath = filePath;
   }
  ~Setting() { }
private:
   bool        m_instance;
   string      m_filePath;
   int         m_handle;
   
public:
   bool Load(EXPERT& setting)
   {
      string content = FileRead(); if (content == NULL) return false;
      
      JSONParser* parser = new JSONParser();
      JSONValue* config = parser.parse(content);
      
      bool result;
      if (config == NULL)
      {
        Print(__FUNCTION__, ": error: " + (string)parser.getErrorCode() + parser.getErrorMessage());
        result = false;
      }
      else
      {
         result = Parse((JSONObject*)config, setting);
         Print(__FUNCTION__, ": json:");
      }
      
      if (CheckPointer(config) == POINTER_DYNAMIC) { delete config; config = NULL; }
      if (CheckPointer(parser) == POINTER_DYNAMIC) { delete parser; parser = NULL; }
      
      setting.m_configPath = TerminalPath() + "\\MQL4\\Files\\" + m_filePath;
      
      return result;
   }
private:
   bool Parse(JSONObject& object, EXPERT& setting)
   {
      //string keys[]; object.GetKeys(keys);
      //bool result;
      bool result = object.getInt("UpdateMilliSecondsExpert", setting.m_updateMilliSecondsExpert);
      if (!result)
      {
         Print(__FUNCTION__, ": not pase 'UpdateMilliSecondsExpert'. stop parsing."); return result;
      }
      
      MONITOR defaultMonitor; defaultMonitor.Init();
      JSONObject* defaults = object.getObject("Defaults");
      if(defaults != NULL)
      {
         JSONObject* defaultMonitorJson = defaults.getObject("Monitor");
         if (defaultMonitorJson != NULL)
         {
            if (ParseMonitor(defaultMonitorJson, defaultMonitor))
            {
               setting.m_monitor.Init(defaultMonitor);// setting.m_monitor.m_symbolTerminal = Symbol(); setting.m_monitor.m_symbolMemory = Symbol();
               JSONArray* arrayMonitors = object.getArray("Monitors");
               if (arrayMonitors != NULL)
               {
                  JSONObject* monitor = NULL;
                  int size = arrayMonitors.size();
                  for (int i = 0; i < size; i++)
                  {
                     monitor = arrayMonitors.getObject(i);
                     if (monitor != NULL)
                     {
                        MONITOR cash; cash.Init(defaultMonitor);
                        ParseMonitor(monitor, cash);
                        if (Symbol() == cash.m_symbolTerminal)
                        {
                           setting.m_monitor.Init(cash);
                        }
                     }
                  }
               }
               else
               {
                  Print(__FUNCTION__, ": not pase 'Defaults:Monitor'. stop parsing."); result = false;
               }
               if (CheckPointer(arrayMonitors) == POINTER_DYNAMIC)  delete arrayMonitors;
            }
         }
         else
         {
            Print(__FUNCTION__, ": not pase 'Defaults:Monitor'. stop parsing."); result = false;
         }
         if (CheckPointer(defaultMonitorJson) == POINTER_DYNAMIC)  delete defaultMonitorJson;
      }
      else
      {
         Print(__FUNCTION__, ": not pase 'Defaults'. stop parsing."); result = false;
      }
      if (CheckPointer(defaults) == POINTER_DYNAMIC)  delete defaults;
      
      return result;
   }
   
   bool ParseDeviationManager(JSONObject& object, DEVIATION_QUOTES& setting)
   {
      // ENABLER
      bool result = object.getBool("Enabler", setting.m_enabler);
      if (!result)
      {
      	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Enabler'. stop parsing.");
      }
      
      // Logger
      result = object.getBool("Logger", setting.m_logger);
      if (!result)
      {
      	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Logger'. stop parsing.");
      }
      
   	// STOP QUOTES NOTIFICATOR FILTERS
   	JSONObject* filters = object.getObject("Filters");
   	if (filters != NULL)
   	{
      	JSONObject* minPointsDeviation = filters.getObject("MinPointsDeviation");
      	if (minPointsDeviation != NULL)
      	{
      		result = minPointsDeviation.getBool("Enabler", setting.m_filters.m_minPointDeviation.m_enabler);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinPointsDeviation:Enabler'. stop parsing.");
      		}
      
      		result = minPointsDeviation.getDouble("DeviationBuy", setting.m_filters.m_minPointDeviation.m_buyDeviation);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinPointsDeviation:DeviationBuy'. stop parsing.");
      		}
      
      		result = minPointsDeviation.getDouble("DeviationSell", setting.m_filters.m_minPointDeviation.m_sellDeviation);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinPointsDeviation:DeviationSell'. stop parsing.");
      		}
      	}
      	else
      	{
      		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinPointsDeviation'. stop parsing.");
      	}
      	if (CheckPointer(minPointsDeviation) == POINTER_DYNAMIC)  delete minPointsDeviation;
      
      	JSONObject* minSpreadsDeviation = filters.getObject("MinSpreadsDeviation");
      	if (minSpreadsDeviation != NULL)
      	{
      		result = minSpreadsDeviation.getBool("Enabler", setting.m_filters.m_minSpreadDeviation.m_enabler);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinSpreadsDeviation:Enabler'. stop parsing.");
      		}
      
      		result = minSpreadsDeviation.getDouble("DeviationBuy", setting.m_filters.m_minSpreadDeviation.m_buyDeviation);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinSpreadsDeviation:DeviationBuy'. stop parsing.");
      		}
      
      		result = minSpreadsDeviation.getDouble("DeviationSell", setting.m_filters.m_minSpreadDeviation.m_sellDeviation);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinSpreadsDeviation:DeviationSell'. stop parsing.");
      		}
      	}
      	else
      	{
      		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinSpreadsDeviation'. stop parsing.");
      	}
      	if (CheckPointer(minSpreadsDeviation) == POINTER_DYNAMIC)  delete minSpreadsDeviation;
      	
      	JSONObject* minGeneralSpreadsDeviation = filters.getObject("MinGeneralSpreadsDeviation");
      	if (minGeneralSpreadsDeviation != NULL)
      	{
      		result = minGeneralSpreadsDeviation.getBool("Enabler", setting.m_filters.m_minGeneralFilter.m_enabler);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinGeneralSpreadsDeviation:Enabler'. stop parsing.");
      		}
      
      		result = minGeneralSpreadsDeviation.getDouble("MinGeneralSpreads", setting.m_filters.m_minGeneralFilter.m_minGeneralSpreads);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinSpreadsDeviation:MinGeneralSpreads'. stop parsing.");
      		}
      
      		result = minGeneralSpreadsDeviation.getDouble("MinGeneralPoints", setting.m_filters.m_minGeneralFilter.m_minGeneralPoints);
      		if (!result)
      		{
      			Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinGeneralSpreadsDeviation:MinGeneralPoints'. stop parsing.");
      		}
      	}
      	else
      	{
      		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters:MinGeneralSpreadsDeviation'. stop parsing.");
      	}
      	if (CheckPointer(minGeneralSpreadsDeviation) == POINTER_DYNAMIC)  delete minGeneralSpreadsDeviation;
      }
      else
      {
   	   Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Filters'. stop parsing.");
      }
      if (CheckPointer(filters) == POINTER_DYNAMIC)  delete filters;
   
   	JSONObject* timeout = object.getObject("TimeOut");
   	if (timeout != NULL)
   	{
      	result = timeout.getBool("Enabler", setting.m_timeOut.m_enabler);
      	if (!result)
      	{
      		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:TimeOut:Enabler'. stop parsing.");
      	}
      
      	result = timeout.getDouble("TimeOutSeconds", setting.m_timeOut.m_timeOutSeconds);
      	if (!result)
      	{
      		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:TimeOut:TimeOutSeconds'. stop parsing.");
      	}
   	}
   	else
   	{
   		Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:TimeOut'. stop parsing.");
   	}
   	
   	if (CheckPointer(timeout) == POINTER_DYNAMIC)  delete timeout;
   	return result;
   }
   
   bool ParseDHunter(JSONObject& managers, DHUNTER& setting)
   {
               JSONObject* dHunter = managers.getObject("DHunter");
               if (dHunter != NULL)
               {
                  // ENABLER
                  bool result = dHunter.getBool("Enabler", setting.m_enabler);
                  if (!result)
                  {
                  	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Enabler'. stop parsing.");
                  }
                  
                  // Logger
                  result = dHunter.getBool("Logger", setting.m_logger);
                  if (!result)
                  {
                  	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:Logger'. stop parsing.");
                  }
                  
                  // MinRestrictionPoint
                  result = dHunter.getDouble("MinRestrictionPoint", setting.m_minRestrictionPoint);
                  if (!result)
                  {
                  	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:MinRestrictionPoint'. stop parsing.");
                  }
                  
                  // ExpertTimeOut
                  result = dHunter.getInt("ExpertTimeOut", setting.m_expertTimeOut);
                  if (!result)
                  {
                  	Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DeviationQuotes:ExpertTimeOut'. stop parsing.");
                  }
                  
                  JSONObject* tradeSetting = dHunter.getObject("TradeSetting");
                  if (tradeSetting != NULL)
                  {
                     result = tradeSetting.getDouble("Lots", setting.m_tradeSetting.m_lots);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Lots'. stop parsing.");
                     }
                     
                     result = tradeSetting.getInt("Magic", setting.m_tradeSetting.m_magic);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Magic'. stop parsing.");
                     }
                     
                     result = tradeSetting.getInt("TryOpenCount", setting.m_tradeSetting.m_tryOpenCount);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:TradeSetting:m_tryOpenCount'. stop parsing.");
                     }
                     
                     result = tradeSetting.getBool("RequestVolumeCorrect", setting.m_tradeSetting.m_requestVolumeCorrect);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:TradeSetting:RequestVolumeCorrect'. stop parsing.");
                     }
                     
                     result = tradeSetting.getBool("RequestPriceCorrect", setting.m_tradeSetting.m_requestPriceCorrect);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:TradeSetting:RequestPriceCorrect'. stop parsing.");
                     }
                     
                     result = tradeSetting.getBool("RequestStoplossCorrect", setting.m_tradeSetting.m_requestStoplossCorrect);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:TradeSetting:RequestStoplossCorrect'. stop parsing.");
                     }
                     
                     result = tradeSetting.getBool("RequestTakeprofitCorrect", setting.m_tradeSetting.m_requestTakeprofitCorrect);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:TradeSetting:RequestTakeprofitCorrect'. stop parsing.");
                     }
                  }
                  if (CheckPointer(tradeSetting) == POINTER_DYNAMIC)  delete tradeSetting;
                  
                  string type = "";
                  result = dHunter.getString("Type", type);
                  if (!result)
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Type'. stop parsing.");
                  }
                  else
                  {
                     if (StringCompare(type, "Master", false) == 0) setting.m_type = m_master;
                     if (StringCompare(type, "Slave", false) == 0) setting.m_type = m_slave;
                  }
                  
                  JSONObject* signal = dHunter.getObject("Signal");
                  if (signal != NULL)
                  {
                     JSONObject* open = signal.getObject("Open");
                     if (open != NULL)
                     {
                        result = open.getDouble("MinSpreads", setting.m_signalOpen.m_minSpreads);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Open:MinSpreads'. stop parsing.");
                        }
                        result = open.getDouble("MinPoints", setting.m_signalOpen.m_minPoints);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Open:MinPoints'. stop parsing.");
                        }
                        result = open.getDouble("MinTimeBarrierInMilliSeconds", setting.m_signalOpen.m_minTimeBarrierInMilliSeconds);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Open:MinTimeBarrierInMilliSeconds'. stop parsing.");
                        }
                        result = open.getDouble("MaxTimeBarrierInMilliSeconds", setting.m_signalOpen.m_maxTimeBarrierInMilliSeconds);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Open:MaxTimeBarrierInMilliSeconds'. stop parsing.");
                        }
                     }
                     if (CheckPointer(open) == POINTER_DYNAMIC)   delete open;
                     
                     JSONObject* close = signal.getObject("Close");
                     if (close != NULL)
                     {
                        result = close.getDouble("MinSpreads", setting.m_signalClose.m_minSpreads);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Close:MinSpreads'. stop parsing.");
                        }
                        result = close.getDouble("MinPoints", setting.m_signalClose.m_minPoints);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Close:MinPoints'. stop parsing.");
                        }
                        result = close.getDouble("MinTimeBarrierInMilliSeconds", setting.m_signalClose.m_minTimeBarrierInMilliSeconds);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Close:MinTimeBarrierInMilliSeconds'. stop parsing.");
                        }
                        result = close.getDouble("MaxTimeBarrierInMilliSeconds", setting.m_signalClose.m_minTimeBarrierInMilliSeconds);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Signal:Close:MaxTimeBarrierInMilliSeconds'. stop parsing.");
                        }
                     }
                     if (CheckPointer(close) == POINTER_DYNAMIC)   delete close;
                  }
                  if (CheckPointer(signal) == POINTER_DYNAMIC)   delete signal;
               }
               if (CheckPointer(dHunter) == POINTER_DYNAMIC)   delete dHunter;
               return true;
   }
   
   bool ParseMonitor(JSONObject& defaultMonitor, MONITOR& monitor)
   {
            // PREFIX
            bool result = defaultMonitor.getString("Prefix", monitor.m_prefix);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Prefix'. stop parsing.");
            }
            
            // UTC
            result = defaultMonitor.getInt("UTC", monitor.m_UTC);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:UTC'. stop parsing.");
            }
            
            // Updater
            result = defaultMonitor.getBool("Updater", monitor.m_updater);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Updater'. stop parsing.");
            }
            
            // SymbolMemory
            result = defaultMonitor.getString("SymbolMemory", monitor.m_symbolMemory);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:SymbolMemory'. stop parsing.");
            }
            
            // SymbolTerminal
            result = defaultMonitor.getString("SymbolTerminal", monitor.m_symbolTerminal);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:SymbolTerminal'. stop parsing.");
            }
            
            // Master
            result = defaultMonitor.getBool("Master", monitor.m_master);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Master'. stop parsing.");
            }
            
            // MANAGERS
            JSONObject* managers = defaultMonitor.getObject("Managers");
            if (managers != NULL)
            {
               ParseDHunter(managers, monitor.m_managers.m_dHunter);
               
               JSONObject* amir = managers.getObject("Amir");
               if (amir != NULL)
               {
                  // Amir ENABLER
                  result = amir.getBool("Enabler", monitor.m_managers.m_amir.m_enabler);
                  if (!result)
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:Amir:Enabler'. stop parsing.");
                  }
               }
               else
               {
                  Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:Amir'. stop parsing.");
               }
               if (CheckPointer(amir) == POINTER_DYNAMIC)  delete amir;
               
               JSONObject* stopQuotesNotificator = managers.getObject("StopQuotesNotificator");
               if (stopQuotesNotificator != NULL)
               {
                  ParseDeviationManager(stopQuotesNotificator, monitor.m_managers.m_stopQuotesNotificator);

                  // STOP QUOTES NOTIFICATOR FILTERS
                  JSONObject* notifications = stopQuotesNotificator.getObject("Notifications");
                  if(notifications != NULL)
                  {
                     JSONObject* alert = notifications.getObject("Alert");
                     if (alert != NULL)
                     {
                        result = alert.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_alert.m_enabler);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Alert:Enabler'. stop parsing.");
                        }
                        
                        result = alert.getInt("CountLimit", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_alert.m_countLimit);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Alert:CountLimit'. stop parsing.");
                        }
                        
                        result = alert.getDouble("ResetCountMinute", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_alert.m_resetCountMin);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Alert:ResetCountMinute'. stop parsing.");
                        }
                     }
                     else
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notification:Alert'. stop parsing.");
                     }
                     if (CheckPointer(alert) == POINTER_DYNAMIC)  delete alert;
                     
                     JSONObject* email = notifications.getObject("Email");
                     if (email != NULL)
                     {
                        result = email.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_email.m_enabler);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Email:Enabler'. stop parsing.");
                        }
                        
                        result = email.getInt("CountLimit", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_email.m_countLimit);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Email:CountLimit'. stop parsing.");
                        }
                        
                        result = email.getDouble("ResetCountMinute", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_email.m_resetCountMin);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Email:ResetCountMinute'. stop parsing.");
                        }
                        
                        result = email.getString("Header", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_email.m_header);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Email:Header'. stop parsing.");
                        }
                     }
                     else
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notification:Email'. stop parsing.");
                     }
                     if (CheckPointer(email) == POINTER_DYNAMIC)  delete email;
                     
                     JSONObject* push = notifications.getObject("Push");
                     if (alert != NULL)
                     {
                        result = push.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_push.m_enabler);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Push:Enabler'. stop parsing.");
                        }
                        
                        result = push.getInt("CountLimit", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_push.m_countLimit);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Push:CountLimit'. stop parsing.");
                        }
                        
                        result = push.getDouble("ResetCountMinute", monitor.m_managers.m_stopQuotesNotificator.m_notifications.m_push.m_resetCountMin);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notifications:Push:ResetCountMinute'. stop parsing.");
                        }
                     }
                     else
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notification:Push'. stop parsing.");
                     }
                     if (CheckPointer(push) == POINTER_DYNAMIC)  delete push;
                  }
                  else
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Notification'. stop parsing.");
                  }
                  if (CheckPointer(notifications) == POINTER_DYNAMIC)  delete notifications;
               }
               else
               {
                  Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator'. stop parsing.");
               }
               if (CheckPointer(stopQuotesNotificator) == POINTER_DYNAMIC)  delete stopQuotesNotificator;
            }
            else
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers'. stop parsing.");
            }
            if (CheckPointer(managers) == POINTER_DYNAMIC)  delete managers;
      return result;
   }
   
   bool ObjectToByte(JSONValue* parent, string key, char& bytes[])
   {
      ENUM_JSON_TYPE type = parent.getType();
      switch(type)
      {
         case JSON_NULL:   return false; break;
         case JSON_OBJECT: break;
         case JSON_ARRAY:  break;
         case JSON_NUMBER: ArrayResize(bytes, 8);
         case JSON_STRING: break;
         case JSON_BOOL:   break;
      }
      return false;
   }
   
private:
   void Close()
   {
      FileClose(m_handle);
   }
   bool Open(int flags = FILE_READ|FILE_SHARE_READ|FILE_TXT)
   {
      if (m_handle != INVALID_HANDLE)
      {
         this.Close();
      }
      
      m_handle = FileOpen(m_filePath, flags);
      if(m_handle == INVALID_HANDLE)
      {
         Print(__FUNCTION__, ": File '", m_filePath, "' not open. error = ", GetLastError()); return false;
      }
      return true;
   }
   string FileRead()
   {
      if (m_handle != INVALID_HANDLE)
      {
         this.Close();
      }
      if (!this.Open()) return NULL;
      
      FileSeek(m_handle, 0, SEEK_SET);
      string content;
      Print(__FUNCTION__, ": read file '", m_filePath, "'...");
      while(!FileIsEnding(m_handle))
      {
         content += FileReadString(m_handle);
      }
      Print(__FUNCTION__, ": read file '", m_filePath, "' is compited");
      
      this.Close();
      return content;
   }
};


class Configurator
{
protected:
   template <typename T>
   void Add(T* &managers[], T* manager)
   {
      int index = ArrayResize(managers, ArraySize(managers) + 1) - 1;
      managers[index] = manager;
   }
};