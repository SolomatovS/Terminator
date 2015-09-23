//+------------------------------------------------------------------+
//|                                                      Manager.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "Model.mqh"
#include "Notification.mqh"


class Manager
{
protected:
   bool  m_enabler;
   
public:
   Manager(bool enabler = true) { m_enabler = enabler; }
  ~Manager() {}

protected:
   virtual void VWork(SData& datas[], int index)   { }

public:
   void Work(SData& datas[], int index)
   {
      if (!m_enabler)   return;
      
      VWork(datas, index);
   }
   void Enable(bool enabler = true) { m_enabler = enabler; }
};



// seald class
class Filter
{
public:
   Filter() { Enable(true); }

protected:
   bool m_enabler;
   
protected:
   virtual bool VCheck(SData &his, SData &alien)
   {
      return true;
   }

public:
   // if filter disable, return true
   // if check successful, return true, otherwise fale
   bool Check(SData &his, SData &alien)
   {
      if (!m_enabler) return true;
      
      return VCheck(his, alien);
   }
   
   void Enable(bool enabler = true) { m_enabler = enabler; }
};

// Filter Deviation point size
class MinPointsDeviation : Filter
{
public:
   MinPointsDeviation(MIN_DEVIATION& settings) : Filter() { m_enabler = settings.m_enabler; m_buyDeviation = settings.m_buyDeviation; m_sellDeviation = settings.m_sellDeviation; }

private:
   double   m_buyDeviation;
   double   m_sellDeviation;

protected:
   virtual bool VCheck(SData &his, SData &alien)
   {
      double spreadCurrent = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      double spread = (spreadCurrent + spreadBefore) / 2;
      double calculatedAsk = (alien.MQLTick.ask + alien.MQLTick.bid) / 2 + spread / 2;
      double clculatedBid = calculatedAsk - spread;
      
      double pointDeviationBuy   = clculatedBid - his.MQLTick.ask;
      double pointDeviationSell  = his.MQLTick.bid - calculatedAsk;
      return (pointDeviationBuy > m_buyDeviation || pointDeviationSell > m_sellDeviation);
   }
};

class MinSpreadsDeviation : Filter
{
public:
   MinSpreadsDeviation(MIN_DEVIATION& settings) : Filter() { m_enabler = settings.m_enabler; m_buyDeviation = settings.m_buyDeviation; m_sellDeviation = settings.m_sellDeviation; }

private:
   double   m_buyDeviation;
   double   m_sellDeviation;

protected:
   virtual bool VCheck(SData &his, SData &alien)
   {
      double spreadCurrent = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      double spread = (spreadCurrent + spreadBefore) / 2;
      double calculatedAsk = (alien.MQLTick.ask + alien.MQLTick.bid) / 2 + spread / 2;
      double clculatedBid = calculatedAsk - spread;
      double koeffBuy = 0; double koeffSell = 0;
      if (NormalizeDouble(spread, 5) > 0)
      {
         koeffBuy  = (clculatedBid - his.MQLTick.ask) / spread;
         koeffSell = (his.MQLTick.bid - calculatedAsk) / spread;
      }
      return (koeffBuy > m_buyDeviation || koeffSell > m_sellDeviation);
   }
};

class FilterConfigurator
{
   FILTERS m_setting;
   
public:
   FilterConfigurator(FILTERS& setting)
   {
      m_setting.Init(setting);
   }
   
private:
   void Add(Filter* &filtes[], Filter* filter)
   {
      int index = ArrayResize(filtes, ArraySize(filtes) + 1) - 1;
      filtes[index] = filter;
   }
   
public:
   void FilterInit(Filter* &filters[])
   {
      if (m_setting.m_minPointDeviation.m_enabler)
      {
         Add(filters, new MinPointsDeviation(m_setting.m_minPointDeviation));
      }
      if (m_setting.m_minSpreadDeviation.m_enabler)
      {
         Add(filters, new MinSpreadsDeviation(m_setting.m_minSpreadDeviation));
      }
   }
};

class DeviationQuotes: Manager
{
protected:
   Filter*        m_filters[];
   TIMEOUT        m_timeOutSettings;
   
public:
   DeviationQuotes(FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings , bool enabler = true) : Manager(enabler)
   {
      filterConfigurator.FilterInit(m_filters);
      m_timeOutSettings.Init(timeOutSettings);
   }
  ~DeviationQuotes()
   {
      for (int i = 0; i < ArraySize(m_filters); i++)
      {
         if (CheckPointer(m_filters[i]) == POINTER_DYNAMIC)
         {
            delete m_filters[i]; m_filters[i] = NULL;
         }
      }
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         
         if(CheckStopQuotes(datas[index], datas[i]))
         {
            Action(datas[index], datas[i]);
         }
      }
   }
   virtual void Action(SData& his, SData& alien)
   {
      //OnNotification(Log(datas[index], datas[i]));
   }
   
   bool CheckStopQuotes(SData &his, SData &alien)
   {
      if (BaseCheck(his, alien))
      {
         if (Filtration(his, alien))
         {
            return true;
         }
      }
      return false;
   }

private:
   bool BaseCheck(SData &his, SData &alien)
   {
      bool result = true;
      if (m_enabler)
      {
         result = result && !ExpertTimeOut(alien);
         result = result && TradeAllowed(his, alien);
         result = result && QuotesDeviation(his, alien); if (!result)   return false;
         result = result && QuotesTimeOut(his);
      }
      return result;
   }
   
   // Check quotes deviation (BID > ASK || ASK < BID)
   bool QuotesDeviation(SData &his, SData &alien)
   {
      if (!m_enabler) return false;
      return (alien.MQLTick.bid > his.MQLTick.ask) || (alien.MQLTick.ask < his.MQLTick.bid);
   }
   
   // Check timeout quotes
   bool QuotesTimeOut(SData& his)
   {
      if (!m_timeOutSettings.m_enabler)   return true;
      return his.TimeOutQuote * 0.000001 >= m_timeOutSettings.m_timeOutSeconds;
   }
   
   bool ExpertTimeOut(SData& alien)
   {
      if (!m_timeOutSettings.m_enabler)   return false;
      return (TimeLocal() - alien.LastUpdateExpert) > m_timeOutSettings.m_timeOutExpertSeconds;
   }
   
   bool TradeAllowed(SData& his, SData& alien)
   {
      return (his.isTradeAllowed && alien.isTradeAllowed);
   }
   
   bool Filtration(SData &his, SData &alien)
   {
      int size = ArraySize(m_filters); int i = 0;
      bool result = true;
      while(i < size && result)
      {
         result = (result && m_filters[i].Check(his, alien));
         i++;
      }
      return result;
   }

protected:
   string StopLog(SData &his, SData &alien)
   {
      
      double pointBuy  = alien.MQLTick.bid - his.MQLTick.ask;
      double pointSell = his.MQLTick.bid - alien.MQLTick.ask;
      double KBuy  = (alien.MQLTick.bid - his.MQLTick.ask) / (his.MQLTick.ask - his.MQLTick.bid);// m_checker.KBuy (alien.MQLTick.bid, his.MQLTick.ask, his.MQLTick.bid);
      double KSell = (his.MQLTick.ask - alien.MQLTick.bid) / (his.MQLTick.ask - his.MQLTick.bid);//m_checker.KSell(alien.MQLTick.ask, his.MQLTick.ask, his.MQLTick.bid);
      double kDiff = KBuy > KSell ? KBuy : KSell;
      int OP = KBuy > KSell ? OP_BUY : OP_SELL;
      //m_checker.Check(KBuy, KSell, kDiff, OP);
      double points;
      string textOP = NULL;
      if (OP == OP_BUY)
      {
         points = pointBuy;
         textOP = "BUY";
      }
      else
      {
         points = pointSell;
         textOP = "SELL";
      }
      
      return StringConcatenate(
         "STOP ", CharArrayToString(his.TSymbol), "\n",
         textOP, ": ", "+ ", DoubleToString(kDiff, 2), " sp. ( ", DoubleToString(points, 5), " p. )", "\n",
         CharArrayToString(alien.Terminal.Company)
      );
      
      return NULL;
   }
   
   
   string Log(SData &his, SData &alien)
   {
      string company = CharArrayToString(alien.Terminal.Company);
      int login = alien.Terminal.Login;
      
      double pointBuy  = alien.MQLTick.bid - his.MQLTick.ask;
      double pointSell = his.MQLTick.bid - alien.MQLTick.ask;
      double spreadAverage = ((his.MQLTick.ask - his.MQLTick.bid) + (his.MQLTickBefore.ask - his.MQLTickBefore.bid)) / 2;
      double spreadAverageAlien = ((alien.MQLTick.ask - alien.MQLTick.bid) + (alien.MQLTickBefore.ask - alien.MQLTickBefore.bid)) / 2;
      string text = StringConcatenate(
         company, " : ", login, "\n",
         "-------------------------------------------------------------------", "\n",
         "                           alien                this   ", "\n",
         "  spread              ", DoubleToString(alien.MQLTick.ask - alien.MQLTick.bid, 5), "    |    ", DoubleToString(his.MQLTick.ask - his.MQLTick.bid, 5), "\n",
         "  ask                  ", DoubleToString(alien.MQLTick.ask, 5), "    |    ", DoubleToString(his.MQLTick.ask, 5), "\n",
         "  bid                   ", DoubleToString(alien.MQLTick.bid, 5), "    |    ", DoubleToString(his.MQLTick.bid, 5), "\n"
         "-------------------------------------------------------------------", "\n",
         "  spread before     ", DoubleToString(alien.MQLTickBefore.ask - alien.MQLTickBefore.bid, 5), "    |    ", DoubleToString(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5), "\n",
         "  ask before         ", DoubleToString(alien.MQLTickBefore.ask, 5), "    |    ", DoubleToString(his.MQLTickBefore.ask, 5), "\n",
         "  bid before          ", DoubleToString(alien.MQLTickBefore.bid, 5), "    |    ", DoubleToString(his.MQLTickBefore.bid, 5), "\n"
         "-------------------------------------------------------------------", "\n");
       return text + StringConcatenate(
         "  TimeOut           ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.     |    ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.\n",
         "  LastUpdate        ", TimeToString(alien.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "    |    ", TimeToString(his.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "\n",
         "  Spread avg        ", DoubleToString(spreadAverageAlien, 5), "    |     ", DoubleToString(spreadAverage, 5), "    \n",
         "  TradeAllowed      ", alien.isTradeAllowed, "        |      ", his.isTradeAllowed, "          \n",
         "-------------------------------------------------------------------", "\n",
         "  Buy:                " , DoubleToString(NormalizeDouble(spreadAverage, 5) > 0 ? pointBuy / spreadAverage : 0,  2), " sp.    |   ", DoubleToString(pointBuy,  5), " pt.", "\n",
         "  Sell:                 ", DoubleToString(NormalizeDouble(spreadAverage, 5) > 0 ? pointSell / spreadAverage : 0, 2), " sp.    |   ", DoubleToString(pointSell, 5), " pt.", "\n",
         //"     Stop quotes: ", string(status), "\n",
         "-------------------------------------------------------------------", "\n\n"
      );
   }
};

class StopQuotesNotificator : DeviationQuotes
{
protected:
   Notification*  m_notifications[];
   
public:
   StopQuotesNotificator(NotificationConfigurator* notificationConfigurator, FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings , bool enabler = true) :
      DeviationQuotes(filterConfigurator, timeOutSettings, enabler)
   {
      notificationConfigurator.NotificationInit(m_notifications);
   }
  ~StopQuotesNotificator()
   {
      for (int i = 0; i < ArraySize(m_notifications); i++)
      {
         if (CheckPointer(m_notifications[i]) == POINTER_DYNAMIC)
         {
            delete m_notifications[i]; m_notifications[i] = NULL;
         }
      }
   }
protected:
   virtual void Action(SData& his, SData& alien)
   {
      OnNotification(Log(his, alien));
   }
   
   void OnNotification(string text)
   {
      for(int i = 0; i < ArraySize(m_notifications); i++)
      {
         if (m_notifications[i].isNotification())
         {
            m_notifications[i].SetMessage(text);
            m_notifications[i].Send();
         }
      }
   }
};


#include "Trade.mqh"


class DHunter : DeviationQuotes
{
   Trade    m_trader;
   int      m_magic;
   
   bool     m_requestVolumeCorrect;
   bool     m_requestPriceCorrect;
   bool     m_requestStoplossCorrect;
   bool     m_requestTakeprofitCorrect;
   int      m_tryOpenCount;
   
public:
   DHunter(FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings , bool enabler = true) :
      DeviationQuotes(filterConfigurator, timeOutSettings, enabler)
   {
      m_requestVolumeCorrect = false;
      m_requestPriceCorrect = false;
      m_requestStoplossCorrect = true;
      m_requestTakeprofitCorrect = true;
      m_tryOpenCount = 5;
      m_magic = 111;
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         
         if(CheckStopQuotes(datas[index], datas[i]))
         {
            ActionStopQuotes(datas[index], datas[i]);
         }
         else
         {
            ActionNoStopQuotes(datas[index], datas[i]);
         }
      }
   }
   virtual void ActionStopQuotes(SData& his, SData& alien)
   {
      MQLRequestOpen request; request.Init();
      FillRequest(request, his, alien);
      MQLRequestOpen try[];
      MQLOrder order; order.Init();
      
      bool result = m_trader.OpenOrder(request,
                                       order,
                                       try,
                                       m_tryOpenCount,
                                       m_requestVolumeCorrect,
                                       m_requestPriceCorrect,
                                       m_requestStoplossCorrect,
                                       m_requestTakeprofitCorrect);
      
      if (result)
      {
         Print(__FUNCTION__, ": Opened order #", order.m_ticket, "; cmd ", request.m_cmd, "; price ", DoubleToString(order.m_price, 5), ";");
      }
      else
      {
         
      }
   }
   virtual void ActionNoStopQuotes(SData& his, SData& alien)
   {
      
   }

private:
   void FillRequest(MQLRequestOpen& request, SData& his, SData& alien)
   {
      request.m_cmd = FillRequestCMD(his, alien);
      request.m_symbol = CharArrayToString(his.TSymbol);
      FillRequestVolume(request.m_volume);
      SymbolInfoTick(request.m_symbol, request.m_tick);
      FillRequestPrice(request.m_tick, request.m_cmd, request.m_price);
      request.m_magic = m_magic;
      request.m_slippage = 0;
   }
   
   int FillRequestCMD(SData& his, SData& alien)
   {
      if (alien.MQLTick.bid > his.MQLTick.ask)
      {
         return OP_BUY;
      }
      if (alien.MQLTick.ask < his.MQLTick.bid)
      {
         return OP_SELL;
      }
      return -1;
   }
   void FillRequestPrice(const MqlTick& tick, int cmd, double& price)
   {
      if (cmd == OP_BUY)  price = tick.ask;
      if (cmd == OP_SELL) price = tick.bid;
   }
   void FillRequestVolume(double& volume)
   {
      volume = 0.01;
   }
};