//+------------------------------------------------------------------+
//|                                        StopQuotesNotificator.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "DeviationQuotes.mqh"
#include "..\Notification.mqh"


class StopQuotesNotificator : DeviationQuotes
{
protected:
   Notification*  m_notifications[];
   
public:
   StopQuotesNotificator(NotificationConfigurator* notificationConfigurator, FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings, bool logger = true, bool enabler = true) :
      DeviationQuotes(filterConfigurator, timeOutSettings, logger, enabler)
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
   virtual void ActionStopQuotes(SData& his, SData& alien, int typeOrder) override
   {
      //Print(__FUNCTION__);
      OnNotification(StopLog(his, alien));
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

protected:
   string StopLog(SData &his, SData &alien)
   {
      double spreadCurrent = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      double spread = (spreadCurrent + spreadBefore) / 2;
      double calculatedBid, calculatedAsk;
      CalculateTick(his, alien, calculatedAsk, calculatedBid);
      
      double koeffBuy = 0; double koeffSell = 0;
      if (NormalizeDouble(spread, 5) > 0)
      {
         koeffBuy  = (calculatedBid - his.MQLTick.ask) / spread;
         koeffSell = (his.MQLTick.bid - calculatedAsk) / spread;
      }
      double kDiff = koeffBuy > koeffSell ? koeffBuy : koeffSell;
      int OP = koeffBuy > koeffSell ? OP_BUY : OP_SELL;
      //m_checker.Check(KBuy, KSell, kDiff, OP);
      double points;
      string textOP = NULL;
      if (OP == OP_BUY)
      {
         points = (calculatedBid - his.MQLTick.ask);
         textOP = "BUY";
      }
      else
      {
         points = (his.MQLTick.bid - calculatedAsk);
         textOP = "SELL";
      }
      
      return StringConcatenate(
         "STOP ", CharArrayToString(his.TSymbol), DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.\n",
         textOP, ": ", "+ ", DoubleToString(kDiff, 2), " sp. ( ", DoubleToString(points, 5), " p. )", "\n",
         CharArrayToString(alien.Terminal.Company)
      );
   }
};
