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
      bool isOpened = OrderIsOpened(symbol, m_magic);
      
      if (isOpened)  return;
      
      MQLRequestOpen request; request.Init(); FillRequest(request, his, alien);
      if (request.m_cmd == -1)
      {
         Print(__FUNCTION__, ": Ќе удалось определить направление, не торгую"); return;
      }
      
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
      request.m_cmd = SignalDetection(his, alien);
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
   
   bool OrderUnic(string symbol, int magic)
   {
      return (StringCompare(OrderSymbol(), symbol) != 0 && OrderMagicNumber() == magic);
   }
   bool OrderIsOpened(string symbol, int magic)
   {
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderUnic(symbol, magic))
            {
               return true;
            }
         }
      }
      return false;
   }
   
   // ¬озвращает направление позиции
   // OP_BUY - в случае тренда наверх
   // OP_SELL - в случае тренда вниз
   // -1 - в случае если тренд неопределен и торговать не нужно
   int SignalDetection(SData& his, SData& alien)
   {
      Print(__FUNCTION__, ": ќпредел€ем направление сигнала");
      if (his.TimeOutQuote >= alien.TimeOutQuote)
      {
         Print(__FUNCTION__, ": ", DoubleToString((his.TimeOutQuote - alien.TimeOutQuote) / 1000, 2), " сек. задержка относительно '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "'");
         if (alien.MQLTick.bid > his.MQLTick.ask)
         {
            Print(__FUNCTION__, ": –азница курсов: +", DoubleToString(alien.MQLTick.bid - his.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) > 0 &&
                (alien.MQLTick.bid - alien.MQLTickBefore.bid) > 0)
            {
               Print(__FUNCTION__, ": ¬ терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вверх на: ASK = +", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = +", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_BUY;
            }
         }
         if (alien.MQLTick.ask < his.MQLTick.bid)
         {
            Print(__FUNCTION__, ": разница курсов: +", DoubleToString(his.MQLTick.bid - alien.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) < 0 &&
                (alien.MQLTick.bid - alien.MQLTickBefore.bid) < 0)
            {
               Print(__FUNCTION__, ": ¬ терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вниз на: ASK = ", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = ", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_SELL;
            }
         }
      }
      Print(__FUNCTION__, ": “ренд не определен");
      return -1;
   }
};