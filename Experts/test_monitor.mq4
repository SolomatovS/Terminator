//+------------------------------------------------------------------+
//|                                                 test_monitor.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include  <Exchange.mqh>

enum NotificationType
{
   NAlert = 0,
   NEmail = 1,
   NPUSH = 2,
   NSMS = 3
};
enum FilterType
{
   FMinSpreads = 0,
   FMinPoints = 1
};

input string   textAlert = "----Notification settings";
input bool     Signal = true;
input NotificationType notificationType = NPUSH;
input int      CountLimit = 1;
input double   ResetCountMin = 1;
input string   textCheck = "----Check stop quotes settings";
input bool     TimeOut = true;
input double   TimeOutQuoteSeconds = 30;
input bool     MinSpreadsDeviations = true;
input int      MinSpreads = 3;
input string   textSystem = "----System settings";
input int      UpdateMilliSecondsExpert = 100;

Customer *Client;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
   //EventSetTimer(1);
   Init();
   Client.AddMonitor(StringSubstr(Symbol(), 0, 6), Symbol());
   OnTick();
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();
   Deinit();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   while(!IsStopped())
   {
      RefreshRates();
      Work();
      Sleep(UpdateMilliSecondsExpert);
      /*
      MqlDateTime time; TimeCurrent(time);
      string symbol = Symbol();
      datetime date_from[3], date_to[3];
      bool result = true; int i = 0; string Log;
      for (int i = 0; i < 3; i++)
      {
         result = SymbolInfoSessionQuote(symbol, time.day_of_week, i, date_from[i], date_to[i]);
         Log += "i = " + i + "\n";
         Log += "date from: " + TimeToString(date_from[i], TIME_SECONDS) + " sec. \n";
         Log += "date to: " + TimeToString(date_to[i], TIME_SECONDS) + " sec. \n";
      }
      datetime date_start = SymbolInfoInteger(symbol, SYMBOL_START_TIME);
      datetime date_end = SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME);
      double market = MarketInfo(symbol, MODE_TRADEALLOWED);
      Log += "date start: " + TimeToString(date_start) + " \n";
      Log += "date end: " + TimeToString(date_end) + " \n";
      Log += market;
      Comment(Log);
      */
   }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   Work();
}
//+------------------------------------------------------------------+

void Init()
{
   StopQuotesChecker* checkDiff = new StopQuotesChecker(TimeOutQuoteSeconds);
   CheckerInit(checkDiff);
   
   Client = new Customer(checkDiff);
   AddNotification(Client, notificationType);
}
void Deinit()
{
   if (CheckPointer(Client) == POINTER_DYNAMIC)
   {
      delete Client;  Client = NULL;
   }
   /*if (CheckPointer(checkDiff) == POINTER_DYNAMIC)
   {
      delete checkDiff;  checkDiff = NULL;
   }
   for (int i = 0; i < ArraySize(filters); i++)
   {
      if (CheckPointer(filters[i]) == POINTER_DYNAMIC)
      {
         delete filters[i];  filters[i] = NULL;
      }
   }
   if (CheckPointer(systemAlert) == POINTER_DYNAMIC)
   {
      delete systemAlert;  systemAlert = NULL;
   }
   */
}

void Work()
{
   string Log;
   Client.UpdateMonitors(Log);
   Comment(Log);
}

void AddMonitor()
{
   
}

void CheckerInit(StopQuotesChecker& checker)
{
   checker.EnableTimeOut(TimeOut);
   if (MinSpreadsDeviations) AddFilter(checker, FMinSpreads);
}

void AddNotification(Customer& client, NotificationType type)
{
   switch(type)
   {
      case NAlert: client.AddNotification(new SystemAlert(true, CountLimit, ResetCountMin)); break;
      case NEmail: client.AddNotification(new EmailNotification(true, CountLimit, ResetCountMin)); break;
      //case NSMS: client.AddNotification(new SMS()); break;
      case NPUSH: client.AddNotification(new PushNotification(true, CountLimit, ResetCountMin)); break;
      default: client.AddNotification(new SystemAlert(true, CountLimit, ResetCountMin));
   }
}

void AddFilter(Checker& checker, FilterType type)
{
   switch(type)
   {
      case FMinSpreads: checker.AddFilter(new MinSpreadsDeviation(MinSpreads, MinSpreads)); break;
      //case FMinPoints:  checker.AddFilter(new MinPointsDeviation(MinSpreads, MinSpreads);
      default:          checker.AddFilter(new MinSpreadsDeviation(MinSpreads, MinSpreads));
   }
}