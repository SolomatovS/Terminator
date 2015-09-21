//+------------------------------------------------------------------+
//|                                                       Config.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "json.mqh"
#include "Model.mqh"
#include "FileMemory.mqh"


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
      
      MONITOR defaultMonitor; defaultMonitor.m_UTC = 0; defaultMonitor.m_updater = false; defaultMonitor.m_logger = false;
      JSONObject* defaults = object.getObject("Defaults");
      if(defaults != NULL)
      {
         JSONObject* defaultMonitorJson = defaults.getObject("Monitor");
         if (defaultMonitorJson != NULL)
         {
            if (ParseMonitor(defaultMonitorJson, defaultMonitor))
            {
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
                        if (!SymbolSelect(cash.m_symbolTerminal, false))
                        {
                           if (!SymbolSelect(cash.m_symbolTerminal, true))
                           {
                              continue;
                           }
                        }
                        
                        int index = ArrayResize(setting.m_monitors, ArraySize(setting.m_monitors) + 1) - 1;
                        setting.m_monitors[index].Init(cash);
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
            
            // Logger
            result = defaultMonitor.getBool("Logger", monitor.m_logger);
            if (!result)
            {
               Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Logger'. stop parsing.");
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
            
            // MANAGERS
            JSONObject* managers = defaultMonitor.getObject("Managers");
            if (managers != NULL)
            {
               JSONObject* dHunter = managers.getObject("DHunter");
               if (dHunter != NULL)
               {
                  // STOP QUOTES NOTIFICATOR ENABLER
                  result = dHunter.getBool("Enabler", monitor.m_managers.m_dHunter.m_enabler);
                  if (!result)
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter:Enabler'. stop parsing.");
                  }
               }
               else
               {
                  Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:DHunter'. stop parsing.");
               }
               if (CheckPointer(dHunter) == POINTER_DYNAMIC)  delete dHunter;
               
               JSONObject* stopQuotesNotificator = managers.getObject("StopQuotesNotificator");
               if (stopQuotesNotificator != NULL)
               {
                  // STOP QUOTES NOTIFICATOR ENABLER
                  result = stopQuotesNotificator.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_enabler);
                  if (!result)
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Enabler'. stop parsing.");
                  }
                  
                  // STOP QUOTES NOTIFICATOR FILTERS
                  JSONObject* filters = stopQuotesNotificator.getObject("Filters");
                  if(filters != NULL)
                  {
                     JSONObject* minPointsDeviation = filters.getObject("MinPointsDeviation");
                     if(minPointsDeviation != NULL)
                     {
                        result = minPointsDeviation.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minPointDeviation.m_enabler);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinPointsDeviation:Enabler'. stop parsing.");
                        }
                        
                        result = minPointsDeviation.getDouble("DeviationBuy", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minPointDeviation.m_buyDeviation);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinPointsDeviation:DeviationBuy'. stop parsing.");
                        }
                        
                        result = minPointsDeviation.getDouble("DeviationSell", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minPointDeviation.m_sellDeviation);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinPointsDeviation:DeviationSell'. stop parsing.");
                        }
                     }
                     else
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinPointsDeviation'. stop parsing.");
                     }
                     if (CheckPointer(minPointsDeviation) == POINTER_DYNAMIC)  delete minPointsDeviation;
                     
                     JSONObject* minSpreadsDeviation = filters.getObject("MinSpreadsDeviation");
                     if(minSpreadsDeviation != NULL)
                     {
                        result = minSpreadsDeviation.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minSpreadDeviation.m_enabler);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinSpreadsDeviation:Enabler'. stop parsing.");
                        }
                        
                        result = minSpreadsDeviation.getDouble("DeviationBuy", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minSpreadDeviation.m_buyDeviation);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinSpreadsDeviation:DeviationBuy'. stop parsing.");
                        }
                        
                        result = minSpreadsDeviation.getDouble("DeviationSell", monitor.m_managers.m_stopQuotesNotificator.m_filters.m_minSpreadDeviation.m_sellDeviation);
                        if (!result)
                        {
                           Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinSpreadsDeviation:DeviationSell'. stop parsing.");
                        }
                     }
                     else
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters:MinSpreadsDeviation'. stop parsing.");
                     }
                     if (CheckPointer(minSpreadsDeviation) == POINTER_DYNAMIC)  delete minSpreadsDeviation;
                  }
                  else
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:Filters'. stop parsing.");
                  }
                  if (CheckPointer(filters) == POINTER_DYNAMIC)  delete filters;
                  
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
                  
                  JSONObject* timeout = stopQuotesNotificator.getObject("TimeOut");
                  if(timeout != NULL)
                  {
                     result = timeout.getBool("Enabler", monitor.m_managers.m_stopQuotesNotificator.m_timeOut.m_enabler);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:TimeOut:Enabler'. stop parsing.");
                     }
                     
                     result = timeout.getDouble("TimeOutSeconds", monitor.m_managers.m_stopQuotesNotificator.m_timeOut.m_timeOutSeconds);
                     if (!result)
                     {
                        Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:TimeOut:TimeOutSeconds'. stop parsing.");
                     }
                  }
                  else
                  {
                     Print(__FUNCTION__, ": not parse 'Defaults:Monitor:Managers:StopQuotesNotificator:TimeOut'. stop parsing.");
                  }
                  if (CheckPointer(timeout) == POINTER_DYNAMIC)  delete timeout;
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