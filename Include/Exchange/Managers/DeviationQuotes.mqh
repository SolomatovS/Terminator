//+------------------------------------------------------------------+
//|                                              DeviationQuotes.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "Manager.mqh"

// seald class
class Filter
{
public:
   Filter() { Enable(true); }

protected:
   bool m_enabler;
   
protected:
   virtual bool VCheck(SData &his, SData &alien, int& typeOrder)
   {
      return true;
   }

public:
   // if filter disable, return true
   // if check successful, return true, otherwise fale
   bool Check(SData &his, SData &alien, int& typeOrder)
   {
      if (!m_enabler) return true;
      
      return VCheck(his, alien, typeOrder);
   }
   
   void Enable(bool enabler = true) { m_enabler = enabler; }
};

void CalculateTick(SData& his, SData& alien, double& calculatedAsk, double& clculatedBid)
{
   double spread = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
   //double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
   //double spread = (spreadCurrent + spreadBefore) / 2;
   calculatedAsk = (alien.MQLTick.ask + alien.MQLTick.bid) / 2 + spread / 2;
   clculatedBid = calculatedAsk - spread;
}

// Filter Deviation point size
class MinPointsDeviation : Filter
{
public:
   MinPointsDeviation(MIN_DEVIATION& settings) : Filter() { m_enabler = settings.m_enabler; m_buyDeviation = settings.m_buyDeviation; m_sellDeviation = settings.m_sellDeviation; }

private:
   double   m_buyDeviation;
   double   m_sellDeviation;

protected:
   virtual bool VCheck(SData &his, SData &alien, int& typeOrder)
   {
      double calculatedBid, calculatedAsk;
      CalculateTick(his, alien, calculatedAsk, calculatedBid);
      
      double pointDeviationBuy   = calculatedBid - his.MQLTick.ask;
      double pointDeviationSell  = his.MQLTick.bid - calculatedAsk;
      bool result = (pointDeviationBuy > m_buyDeviation || pointDeviationSell > m_sellDeviation);
      if (result)
      {
         int i = 0;
      }
      return result;
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
   virtual bool VCheck(SData &his, SData &alien, int& typeOrder)
   {
      double spread = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      //double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      //double spread = (spreadCurrent + spreadBefore) / 2;
      double calculatedBid, calculatedAsk;
      CalculateTick(his, alien, calculatedAsk, calculatedBid);
      
      double koeffBuy = 0; double koeffSell = 0;
      if (NormalizeDouble(spread, 5) > 0)
      {
         koeffBuy  = (calculatedBid - his.MQLTick.ask) / spread;
         koeffSell = (his.MQLTick.bid - calculatedAsk) / spread;
      }
      bool result = (koeffBuy > m_buyDeviation || koeffSell > m_sellDeviation);
      if (result)
      {
         int jlnsdf = 0;
      }
      return result;
   }
};

class MinGeneralSpreadsDeviation : Filter
{
public:
   MinGeneralSpreadsDeviation(MIN_GENERAL_FILTER& setting) : Filter() { m_enabler = setting.m_enabler; m_setting.Init(setting); }

private:
   MIN_GENERAL_FILTER m_setting;

protected:
   virtual bool VCheck(SData &his, SData &alien, int& typeOrder)
   {
      double spreadHis = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      double spreadHisBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      double spreadHisAvg = (spreadHis + spreadHisBefore) / 2;
      if (spreadHisAvg > spreadHis) spreadHis = spreadHisAvg;
      double spreadAlien = NormalizeDouble(alien.MQLTick.ask - alien.MQLTick.bid, 5);
      double spreadAlienBefore = NormalizeDouble(alien.MQLTickBefore.ask - alien.MQLTickBefore.bid, 5);
      double spreadAlienAvg = (spreadAlien + spreadAlienBefore) / 2;
      if (spreadAlienAvg > spreadAlien)  spreadAlien = spreadAlienAvg;
      double spread = spreadHis + spreadAlien;
      double pointBuy = (alien.MQLTick.bid - his.MQLTick.ask);
      double pointSell = (his.MQLTick.bid - alien.MQLTick.ask);
      double koeffBuy = 0; double koeffSell = 0;
      if (NormalizeDouble(spread, 5) > 0)
      {
         koeffBuy  = pointBuy / spread;
         koeffSell = pointSell / spread;
      }
      bool result = (koeffBuy > m_setting.m_minGeneralSpreads || koeffSell > m_setting.m_minGeneralSpreads);
      result = result && (pointBuy >= m_setting.m_minGeneralPoints || pointSell >= m_setting.m_minGeneralPoints);
      if (result)
      {
         typeOrder = (pointBuy >= m_setting.m_minGeneralPoints) ? OP_BUY : OP_SELL;
      }
      return result;
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
         Add(filters, (Filter*) new MinPointsDeviation(m_setting.m_minPointDeviation));
      }
      if (m_setting.m_minSpreadDeviation.m_enabler)
      {
         Add(filters, (Filter*) new MinSpreadsDeviation(m_setting.m_minSpreadDeviation));
      }
      if (m_setting.m_minGeneralFilter.m_enabler)
      {
         Add(filters, (Filter*) new MinGeneralSpreadsDeviation(m_setting.m_minGeneralFilter));
      }
   }
};


class DeviationQuotes: Manager
{
protected:
   Filter*        m_filters[];
   TIMEOUT        m_timeOutSettings;
   bool           m_logger;
   
public:
   DeviationQuotes(FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings, bool logger = true , bool enabler = true) : Manager(enabler)
   {
      m_logger = logger;
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
      Log(datas, index);
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         
         int typeOrder = -1;
         if(CheckStopQuotes(datas[index], datas[i], typeOrder))
         {
            ActionStopQuotes(datas[index], datas[i], typeOrder);
         }
         else
         {
            ActionNoStopQuotes(datas[index], datas[i]);
         }
      }
   }
   virtual void ActionStopQuotes(SData& his, SData& alien, int typeOrder)
   {
      
   }
   virtual void ActionNoStopQuotes(SData& his, SData& alien)
   {
      
   }
   
   bool CheckStopQuotes(SData &his, SData &alien, int& typeOrder)
   {
      if (BaseCheck(his, alien, typeOrder))
      {
         if (Filtration(his, alien, typeOrder))
         {
            return true;
         }
      }
      return false;
   }

   bool BaseCheck(SData &his, SData &alien, int& typeOrder)
   {
      bool result = true;
      if (m_enabler)
      {
         result = result && !ExpertTimeOut(alien);
         result = result && TradeAllowed(his, alien);
         result = result && QuotesTimeOut(his);
         result = result && QuotesDeviation(his, alien, typeOrder);
      }
      return result;
   }
   
   // Check quotes deviation (BID > ASK || ASK < BID)
   virtual bool QuotesDeviation(SData &his, SData &alien, int& typeOrder)
   {
      if (!m_enabler) return false;
      
      typeOrder = (alien.MQLTick.bid > his.MQLTick.ask) ? OP_BUY : ((alien.MQLTick.ask < his.MQLTick.bid) ? OP_SELL : -1);
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
      return (TimeGMT() - alien.LastUpdateExpert) > m_timeOutSettings.m_timeOutExpertSeconds;
   }
   
   bool TradeAllowed(SData& his, SData& alien)
   {
      return (his.isTradeAllowed && alien.isTradeAllowed);
   }
   
   bool Filtration(SData &his, SData &alien, int& typeOrder)
   {
      int size = ArraySize(m_filters); int i = 0;
      bool result = true;
      while(i < size && result)
      {
         result = (result && m_filters[i].Check(his, alien, typeOrder));
         i++;
      }
      
      return result;
   }
   
protected:
   void Log(SData& datas[], int index)
   {
      if (!m_logger) return;
      
      string m_log = NULL;
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         m_log += Log(datas[index], datas[i]);
      }
      Comment(m_log);
   }
   string Log(SData &his, SData &alien)
   {
      string company = CharArrayToString(alien.Terminal.Company);
      int login = alien.Terminal.Login;
      int digits = SymbolInfoInteger(CharArrayToString(his.TSymbol), SYMBOL_DIGITS);
      
      double pointBuy  = alien.MQLTick.bid - his.MQLTick.ask;
      double pointSell = his.MQLTick.bid - alien.MQLTick.ask;
      double spreadHis = (his.MQLTick.ask - his.MQLTick.bid);
      double spreadAlien = (alien.MQLTick.ask - alien.MQLTick.bid);
      double spreadGeneral = spreadHis + spreadAlien;
      double spreadAverage = ((his.MQLTick.ask - his.MQLTick.bid) + (his.MQLTickBefore.ask - his.MQLTickBefore.bid)) / 2;
      double spreadAverageAlien = ((alien.MQLTick.ask - alien.MQLTick.bid) + (alien.MQLTickBefore.ask - alien.MQLTickBefore.bid)) / 2;
      
      string orders = his.OrdersToString();
      
      double sum = OrdersSum(his, alien);
      
      string text = StringConcatenate(
         company, " : ", login, "\n",
         "-------------------------------------------------------------------", "\n",
         "                           alien                this   ", "\n",
         "  spread              ", DoubleToString(alien.MQLTick.ask - alien.MQLTick.bid, digits), "    |    ", DoubleToString(his.MQLTick.ask - his.MQLTick.bid, digits), "\n",
         "  ask                  ", DoubleToString(alien.MQLTick.ask, digits), "    |    ", DoubleToString(his.MQLTick.ask, digits), "\n",
         "  bid                   ", DoubleToString(alien.MQLTick.bid, digits), "    |    ", DoubleToString(his.MQLTick.bid, digits), "\n"
         "-------------------------------------------------------------------", "\n",
         "  spread before     ", DoubleToString(alien.MQLTickBefore.ask - alien.MQLTickBefore.bid, digits), "    |    ", DoubleToString(his.MQLTickBefore.ask - his.MQLTickBefore.bid, digits), "\n",
         "  ask before         ", DoubleToString(alien.MQLTickBefore.ask, digits), "    |    ", DoubleToString(his.MQLTickBefore.ask, digits), "\n",
         "  bid before          ", DoubleToString(alien.MQLTickBefore.bid, digits), "    |    ", DoubleToString(his.MQLTickBefore.bid, digits), "\n"
         "-------------------------------------------------------------------", "\n");
       return text + StringConcatenate(
         "  TimeOut           ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.     |    ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.\n",
         "  LastUpdate        ", TimeToString(alien.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "    |    ", TimeToString(his.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "\n",
         "  Spread avg        ", DoubleToString(spreadAverageAlien, digits), "    |     ", DoubleToString(spreadAverage, digits), "    \n",
         "  TradeAllowed      ", alien.isTradeAllowed, "        |      ", his.isTradeAllowed, "          \n",
         "-------------------------------------------------------------------", "\n",
         "  Buy:                " , DoubleToString(NormalizeDouble(spreadGeneral, digits) > 0 ? pointBuy / spreadGeneral : 0,  2), " sp.    |   ", DoubleToString(pointBuy,  digits), " pt.", "\n",
         "  Sell:                 ", DoubleToString(NormalizeDouble(spreadGeneral, digits) > 0 ? pointSell / spreadGeneral : 0, 2), " sp.    |   ", DoubleToString(pointSell, digits), " pt.", "\n",
         //"     Stop quotes: ", string(status), "\n",
         "-------------------------------------------------------------------", "\n", orders, "\n", "-------------------------------------------------------------------", "\n",
         "  Orders sum        ", DoubleToString(sum, digits), " pt.\n", "-------------------------------------------------------------------", "\n"
      );
   }
   
   double OrdersSum(SData &his, SData &alien, int magic = -1)
   {
      double sum = 0;
      MQLOrder orders[]; ArrayCopy(orders, his.Orders); ArrayCopy(orders, alien.Orders, ArraySize(his.Orders));
      for(int i = 0; i < ArraySize(orders); i++)
      {
         if (orders[i].m_ticket <= 0)  continue;
         if (orders[i].m_magic == magic && magic != -1) continue;
         
         switch(orders[i].m_cmd)
         {
            case OP_BUY: sum += orders[i].m_closePrice - orders[i].m_price; break;
            case OP_SELL:sum += orders[i].m_price - orders[i].m_closePrice; break;
         }
      }
      
      return sum;
   }
};