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
   double   m_lots;
   int      m_magic;
   
   bool     m_requestVolumeCorrect;
   bool     m_requestPriceCorrect;
   bool     m_requestStoplossCorrect;
   bool     m_requestTakeprofitCorrect;
   int      m_tryOpenCount;
   
public:
   DHunter(FilterConfigurator* filterConfigurator, TIMEOUT& timeOutSettings, double lots, int magic, bool logger = true, bool enabler = true) :
      DeviationQuotes(filterConfigurator, timeOutSettings, logger, enabler)
   {
      m_requestVolumeCorrect = false;
      m_requestPriceCorrect = false;
      m_requestStoplossCorrect = true;
      m_requestTakeprofitCorrect = true;
      m_tryOpenCount = 10;
      m_lots = lots;
      m_magic = magic;
   }
protected:
   virtual void ActionStopQuotes(SData& his, SData& alien, int typeOrder)
   {
      int total = OrdersTotal();
      string symbol = Symbol();
      bool isOpened = OrderIsOpened(symbol, m_magic, typeOrder);
      
      if (isOpened) return;
      else ActionOpenOrder(his, alien, typeOrder); return;
      
      /*
      typeOrderReverse = typeOrder;
      if (typeOrder == OP_BUY)   typeOrderReverse = OP_SELL;
      if (typeOrder == OP_SELL)  typeOrderReverse = OP_BUY;
      
      isOpened = OrderIsOpened(symbol, m_magic, typeOrder);
      if (isOpened)
      {
         ActionOpenOrder(his, alien, typeOrderReverse);
         return;
      }
      */
   }
   void ActionOpenOrder(SData& his, SData& alien, int typeOrder)
   {
      MQLRequestOpen request; request.Init(); request.m_cmd = typeOrder;
      FillRequest(request, his, alien);
      if (request.m_cmd == -1)
      {
         Print(__FUNCTION__, ": �� ������� ���������� �����������, �� ������"); return;
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
      
   }
   void ActionCloseOrders(SData& his, SData& alien)
   {
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderCloseTime() > 0 || !OrderUnic(Symbol(), m_magic))   continue;
            
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
      //request.m_cmd = SignalDetection(his, alien);
      ArrayCopy(request.m_symbol, his.TSymbol);
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
   
   bool OrderUnic(string symbol, int magic, int typeOrder = -1)
   {
      return (StringCompare(OrderSymbol(), symbol) == 0 && OrderMagicNumber() == magic && (OrderType() == typeOrder || typeOrder == -1));
   }
   
   bool OrderIsOpened(string symbol, int magic, int typeOrder)
   {
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderUnic(symbol, magic, typeOrder))
            {
               return true;
            }
         }
      }
      return false;
   }
   
   // ���������� ����������� �������
   // OP_BUY - � ������ ������ ������
   // OP_SELL - � ������ ������ ����
   // -1 - � ������ ���� ����� ����������� � ��������� �� �����
   int SignalDetection(SData& his, SData& alien)
   {
      //Print(__FUNCTION__, ": ���������� ����������� �������");
      //if (his.TimeOutQuote >= alien.TimeOutQuote)
      //{
         Print(__FUNCTION__, ": ", DoubleToString((his.TimeOutQuote - alien.TimeOutQuote) / 1000, 2), " ���. �������� ������������ '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "'");
         if (alien.MQLTick.bid > his.MQLTick.ask)
         {
            Print(__FUNCTION__, ": ������� ������: +", DoubleToString(alien.MQLTick.bid - his.MQLTick.ask, 5), ", ������� ����� ����� ��������: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) > 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) > 0)
            //{
               Print(__FUNCTION__, ": � ��������� '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', ��������� ���������� ����� ��: ASK = +", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = +", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_BUY;
            //}
         }
         if (alien.MQLTick.ask < his.MQLTick.bid)
         {
            Print(__FUNCTION__, ": ������� ������: +", DoubleToString(his.MQLTick.bid - alien.MQLTick.ask, 5), ", ������� ����� ����� ��������: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) < 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) < 0)
            //{
               Print(__FUNCTION__, ": � ��������� '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', ��������� ���������� ���� ��: ASK = ", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = ", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_SELL;
            //}
         }
      //}
      Print(__FUNCTION__, ": ����� �� ���������");
      return -1;
   }
};