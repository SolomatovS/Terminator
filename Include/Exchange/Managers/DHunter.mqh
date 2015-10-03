//+------------------------------------------------------------------+
//|                                                      DHunter.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "DeviationQuotes.mqh"
#include "..\Trade.mqh"

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
   DHunter(FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings, bool logger = true , bool enabler = true) :
      DeviationQuotes(filterConfigurator, timeOutSettings, logger, enabler)
   {
      m_requestVolumeCorrect = false;
      m_requestPriceCorrect = false;
      m_requestStoplossCorrect = true;
      m_requestTakeprofitCorrect = true;
      m_tryOpenCount = 5;
      m_magic = 111;
   }
protected:
   virtual void ActionStopQuotes(SData& his, SData& alien)
   {
      int total = OrdersTotal();
      string symbol = Symbol();
      bool isOpened = false;
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderSymbol() == symbol)
            {
               isOpened = true; break;
            }
         }
      }
      if (isOpened)  return;
      
      //if (his.TimeOutQuote > alien.TimeOutQuote)   return;
      
      MQLRequestOpen request; request.Init(); FillRequest(request, his, alien);
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
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderCloseTime() > 0 || StringCompare(OrderSymbol(), Symbol()) != 0)   continue;
            
            MQLRequestClose request; request.Init();
            FillRequest(request, OrderTicket(), his);
            MQLRequestClose try[];
            
            bool result = m_trader.CloseOrDeleteOrder(
                                       request,
                                       try,
                                       m_tryOpenCount,
                                       m_requestVolumeCorrect,
                                       m_requestPriceCorrect);
            
            if (result)
            {
               if (OrderSelect(OrderTicket(), SELECT_BY_TICKET))
               {
                  Print(__FUNCTION__, ": Closed order #", OrderTicket(), "; cmd ", OrderType(), "; price ", DoubleToString(OrderClosePrice(), 5), ";");
               }
            }
            else
            {
               
            }
         }
      }
   }

private:
   void FillRequest(MQLRequestOpen& request, SData& his, SData& alien)
   {
      request.m_cmd = FillRequestCMD(his, alien);
      request.m_symbol = CharArrayToString(his.TSymbol);
      FillRequestVolume(request.m_volume);
      FillRequestPrice(request.m_tick, request.m_cmd, request.m_price);
      request.m_magic = m_magic;
      request.m_slippage = 0;
   }
   
   void FillRequest(MQLRequestClose& request, int ticket, SData& his)
   {
      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         request.m_ticket = ticket;
         request.m_lots = OrderLots();
         FillRequestPrice(request.m_tick, OrderType(), request.m_price);
         request.m_slippage = 0;
      }
      
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