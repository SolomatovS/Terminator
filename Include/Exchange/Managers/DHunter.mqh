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


class DHunter : Manager
{
   Trade    m_trader;
   DHUNTER  m_dHunterSetting;
   
public:
   DHunter(DHUNTER& dHunterSetting) :
      Manager(dHunterSetting.m_enabler)
   {
      m_dHunterSetting.Init(dHunterSetting);
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      Log(datas, index);
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         
         if (datas[index].Master)
         {
            SignalProcessing(datas[index], datas[i]);
         }
         else
         {
            Synchronization(datas[index], datas[i]);
         }
      }
   }
   

   bool ExpertTimeOut(SData& alien)
   {
      return (TimeGMT() - alien.LastUpdateExpert) > 3;
   }
   
   bool TradeAllowed(SData& his, SData& alien)
   {
      return (his.isTradeAllowed && alien.isTradeAllowed);
   }
      
   // Check quotes deviation (BID > ASK || ASK < BID)
   void SignalProcessing(SData& his, SData& alien)
   {
      if (!m_dHunterSetting.m_enabler) return;
      
      if (ExpertTimeOut(alien) || !TradeAllowed(his, alien))  return;
      
      double deviationBuy = alien.MQLTick.bid - his.MQLTick.ask;
      double deviationSell = his.MQLTick.bid - alien.MQLTick.ask;
      
      double spreadHisCurrent = his.MQLTick.ask - his.MQLTick.bid;
      double spreadHisBefore = his.MQLTickBefore.ask - his.MQLTickBefore.bid;
      double spreadHisAvg = (spreadHisCurrent + spreadHisBefore) / 2;
      double spreadHis = spreadHisAvg > spreadHisCurrent ? spreadHisAvg : spreadHisCurrent;
      
      double spreadAlienCurrent = alien.MQLTick.ask - alien.MQLTick.bid;
      double spreadAlienBefore = alien.MQLTickBefore.ask - alien.MQLTickBefore.bid;
      double spreadAlienAvg = (spreadAlienCurrent + spreadAlienBefore) / 2;
      double spreadAlien = spreadAlienAvg > spreadAlienCurrent ? spreadAlienAvg : spreadAlienCurrent;
      
      double spread = spreadHis + spreadAlien;
      
      double spreadBuy = deviationBuy / spread;
      double spreadSell = deviationSell / spread;
      
      int typeOrder = -1;
      
      if (SignalClose(deviationBuy, deviationSell, spreadBuy, spreadSell, typeOrder))
      {
         ActionSignalCloseOrders(his, alien, typeOrder);
      }
      
      if (SignalOpen(deviationBuy, deviationSell, spreadBuy, spreadSell, typeOrder))
      {
         ActionSignalOpenOrder(his, alien, typeOrder);
      }
   }
   bool SignalOpen(double deviationBuy, double deviationSell, double spreadBuy, double spreadSell, int& typeOrder)
   {
      bool openBuy = (spreadBuy > m_dHunterSetting.m_signalOpen.m_minSpreads) && (deviationBuy - m_dHunterSetting.m_signalOpen.m_minPoints)  > 0;
      bool openSell =(spreadSell > m_dHunterSetting.m_signalOpen.m_minSpreads)&& (deviationSell - m_dHunterSetting.m_signalOpen.m_minPoints) > 0;
      
      typeOrder = openBuy ? OP_BUY : openSell ? OP_SELL : -1;
      
      return (openBuy || openSell);
   }
   bool SignalClose(double deviationBuy, double deviationSell, double spreadBuy, double spreadSell, int& typeOrder)
   {
      bool closeSell = (spreadBuy > m_dHunterSetting.m_signalClose.m_minSpreads) && (deviationBuy - m_dHunterSetting.m_signalClose.m_minPoints)  > 0;
      bool closeBuy =(spreadSell > m_dHunterSetting.m_signalClose.m_minSpreads)&& (deviationSell - m_dHunterSetting.m_signalClose.m_minPoints) > 0;
   
      typeOrder = closeBuy ? OP_BUY : closeSell ? OP_SELL : -1;
      
      return (closeBuy || closeSell);
   }
   void Synchronization(SData& his, SData& alien)
   {
      if (ExpertTimeOut(alien) || !TradeAllowed(his, alien))  return;
      
      // —начала открываем те ордера, которых нет в терминале slave
      for(int i = 0; i < ArraySize(alien.Orders); i++)
      {
         if (alien.Orders[i].m_ticket <= 0)  continue;
         if (alien.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         if (CharArrayToString(alien.Orders[i].m_symbol) != Symbol()) continue;
         
         SynchronizationOpenOrder(alien.Orders[i]);
      }
      
      // ѕотом закрываем те ордера, которых нет в терминале master
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderMagicNumber() != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
            if (OrderSymbol() != Symbol())   continue;
            
            SynchronizationCloseOrder(OrderTicket(), alien);
         }
      }
   }
   void SynchronizationOpenOrder(MQLOrder& orderForSynchronization)
   {
      bool orderOpened = false;
      for (int i = 0; i < OrdersTotal(); i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderMagicNumber() != orderForSynchronization.m_magic)  continue;
            if (OrderType() != Reverse(orderForSynchronization.m_cmd))  continue;
            if (OrderSymbol() != Symbol())   continue;
            
            orderOpened = true; break;
         }
      }
      if (!orderOpened)
      {
         Print(__FUNCTION__, ": ќбнаружен не синхронизированный ордер, открываем его.");
         MQLRequestOpen request; request.Init(orderForSynchronization);
         request.m_cmd = Reverse(orderForSynchronization.m_cmd);
         request.m_price = 0;
         request.m_stoploss = orderForSynchronization.m_takeprofit; request.m_takeprofit = orderForSynchronization.m_stoploss;
         
         MQLRequestOpen try[];
         MQLOrder order; order.Init();
         
         bool result = m_trader.OpenOrder(request,
                                          order,
                                          try,
                                          m_dHunterSetting.m_tradeSetting.m_tryOpenCount,
                                          m_dHunterSetting.m_tradeSetting.m_requestVolumeCorrect,
                                          m_dHunterSetting.m_tradeSetting.m_requestPriceCorrect,
                                          m_dHunterSetting.m_tradeSetting.m_requestStoplossCorrect,
                                          m_dHunterSetting.m_tradeSetting.m_requestTakeprofitCorrect);
         
         if (result)
         {
            Print(__FUNCTION__, ": Opened order #", order.m_ticket, "; cmd ", request.m_cmd, "; price ", DoubleToString(order.m_price, 5), ";");
         }
         else
         {
            Print(__FUNCTION__, ": Ќе удалось открыть ордер. ѕопробуем еще раз в следующую итерацию");
         }
      }
   }
   void SynchronizationCloseOrder(int ticket, SData& alien)
   {
      if (!OrderSelect(ticket, SELECT_BY_TICKET))   return;
      
      bool orderOpened = false;
      int total = ArraySize(alien.Orders);
      for (int i = 0; i < total; i++)
      {
         if (alien.Orders[i].m_ticket <= 0)  continue;
         if (alien.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         if (alien.Orders[i].m_cmd != Reverse(OrderType())) continue;
         if (CharArrayToString(alien.Orders[i].m_symbol) != OrderSymbol()) continue;
         
         orderOpened = true; break;
      }
      
      if (!orderOpened)
      {
         MQLRequestClose request; request.Init();
         FillRequest(request, OrderTicket(), alien);
         request.m_price = 0;
         MQLRequestClose try[];
         bool result = m_trader.CloseOrDeleteOrder(
                                       request,
                                       try,
                                       m_dHunterSetting.m_tradeSetting.m_tryOpenCount,
                                       m_dHunterSetting.m_tradeSetting.m_requestVolumeCorrect,
                                       m_dHunterSetting.m_tradeSetting.m_requestPriceCorrect);
         
         if (result)
         {
            if (OrderSelect(OrderTicket(), SELECT_BY_TICKET))
            {
               Print(__FUNCTION__, ": Closed order #", OrderTicket(), "; cmd ", OrderType(), "; price ", DoubleToString(OrderClosePrice(), 5), ";");
            }
         }
         else
         {
            Print(__FUNCTION__, ": Ќе удалось закрыть ордер #", ticket, ". ѕопробуем еще раз в следующую итерацию");
         }
      }
   }
   virtual void ActionSignalOpenOrder(SData& his, SData& alien, int typeOrder)
   {
      int total = OrdersTotal();
      string symbol = Symbol();
      bool isOpened = OrderIsOpened(symbol, m_dHunterSetting.m_tradeSetting.m_magic, typeOrder);
      
      if (isOpened)
      {
         // нихера не делаем, если ордер этого типа уже открыт
      }
      else ActionOpenOrder(his, alien, typeOrder); return;
   }
   void ActionOpenOrder(SData& his, SData& alien, int typeOrder)
   {
      MQLRequestOpen request; request.Init();
      request.m_cmd = typeOrder;
      FillRequest(request, his, alien);
      if (request.m_cmd == -1)
      {
         Print(__FUNCTION__, ": Ќе удалось определить направление, не торгую"); return;
      }
      
      MQLRequestOpen try[];
      MQLOrder order; order.Init();
      
      bool result = m_trader.OpenOrder(request,
                                       order,
                                       try,
                                       m_dHunterSetting.m_tradeSetting.m_tryOpenCount,
                                       m_dHunterSetting.m_tradeSetting.m_requestVolumeCorrect,
                                       m_dHunterSetting.m_tradeSetting.m_requestPriceCorrect,
                                       m_dHunterSetting.m_tradeSetting.m_requestStoplossCorrect,
                                       m_dHunterSetting.m_tradeSetting.m_requestTakeprofitCorrect);
      
      if (result)
      {
         Print(__FUNCTION__, ": Opened order #", order.m_ticket, "; cmd ", request.m_cmd, "; price ", DoubleToString(order.m_price, 5), ";");
      }
      else
      {
         
      }
   }
   
   void ActionSignalCloseOrders(SData& his, SData& alien, int typeOrder)
   {
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderCloseTime() > 0 || !OrderUnic(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic))   continue;
            if (OrderType() != typeOrder) continue;
            
            MQLRequestClose request; request.Init();
            FillRequest(request, OrderTicket(), his);
            MQLRequestClose try[];
            
            bool result = m_trader.CloseOrDeleteOrder(
                                       request,
                                       try,
                                       m_dHunterSetting.m_tradeSetting.m_tryOpenCount,
                                       m_dHunterSetting.m_tradeSetting.m_requestVolumeCorrect,
                                       m_dHunterSetting.m_tradeSetting.m_requestPriceCorrect);
            
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
   int Reverse(int type)
   {
      switch (type)
      {
         case OP_BUY: return OP_SELL; break;
         case OP_SELL: return OP_BUY; break;
         case OP_BUYLIMIT: return OP_SELLSTOP; break;
         case OP_BUYSTOP: return OP_SELLLIMIT; break;
         case OP_SELLLIMIT: return OP_BUYSTOP; break;
         case OP_SELLSTOP: return OP_SELLLIMIT; break;
      }
      return -1;
   }
   void FillRequest(MQLRequestOpen& request, SData& his, SData& alien)
   {
      //request.m_cmd = SignalDetection(his, alien);
      ArrayCopy(request.m_symbol, his.TSymbol);
      FillRequestVolume(request.m_volume);
      FillRequestPrice(request.m_tick, request.m_cmd, request.m_price);
      request.m_magic = m_dHunterSetting.m_tradeSetting.m_magic;
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
      volume = m_dHunterSetting.m_tradeSetting.m_lots;
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
   
   // ¬озвращает направление позиции
   // OP_BUY - в случае тренда наверх
   // OP_SELL - в случае тренда вниз
   // -1 - в случае если тренд неопределен и торговать не нужно
   int SignalDetection(SData& his, SData& alien)
   {
      //Print(__FUNCTION__, ": ќпредел€ем направление сигнала");
      //if (his.TimeOutQuote >= alien.TimeOutQuote)
      //{
         Print(__FUNCTION__, ": ", DoubleToString((his.TimeOutQuote - alien.TimeOutQuote) / 1000, 2), " сек. задержка относительно '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "'");
         if (alien.MQLTick.bid > his.MQLTick.ask)
         {
            Print(__FUNCTION__, ": –азница курсов: +", DoubleToString(alien.MQLTick.bid - his.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) > 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) > 0)
            //{
               Print(__FUNCTION__, ": ¬ терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вверх на: ASK = +", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = +", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_BUY;
            //}
         }
         if (alien.MQLTick.ask < his.MQLTick.bid)
         {
            Print(__FUNCTION__, ": разница курсов: +", DoubleToString(his.MQLTick.bid - alien.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) < 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) < 0)
            //{
               Print(__FUNCTION__, ": ¬ терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вниз на: ASK = ", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = ", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_SELL;
            //}
         }
      //}
      Print(__FUNCTION__, ": “ренд не определен");
      return -1;
   }
   
   void Log(SData& datas[], int index)
   {
      if (!m_dHunterSetting.m_logger) return;
      
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
         "  Master                ", alien.Master, "       |      ", his.Master, "          \n",
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