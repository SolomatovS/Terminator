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
         
         bool master = false; bool sync;
         
         switch (m_dHunterSetting.m_type)
         {
            case m_delayer:
               if (!datas[index].Master && datas[i].Master) SignalProcessing(datas[index], datas[i]);
            break;
            case m_deviator:
               sync = isSync(datas[index], datas[i]);
               if (!sync)  master = isMaster(datas[index], datas[i]);
               else
               {
                  bool openedOrder = OrderIsOpened(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic);
                  if (openedOrder)
                  {
                     master = true;
                  }
                  else
                  {
                     master = datas[index].Master;
                  }
               }
               
               if (master/*datas[index].Master*/)
               {
                  SignalProcessing(datas[index], datas[i]);
               }
               else
               {
                  Synchronization(datas[index], datas[i]);
               }
            break;
         }
      }
   }
   
   bool ExpertTimeOut(SData& alien)
   {
      return (TimeGMT() - alien.LastUpdateExpert) > m_dHunterSetting.m_expertTimeOut;
   }
   
   bool TradeAllowed(SData& his, SData& alien)
   {
      return (his.isTradeAllowed && alien.isTradeAllowed);
   }
   
   bool SignalAllowed(ulong timeOutQuote, double minTimeBarrierInMilliSeconds, double maxTimeBarrierInMilliSeconds)
   {
      return NormalizeDouble(timeOutQuote / 1000, 2) >= NormalizeDouble(minTimeBarrierInMilliSeconds, 2)  &&
             (NormalizeDouble(timeOutQuote / 1000, 2) <= NormalizeDouble(maxTimeBarrierInMilliSeconds, 2) || NormalizeDouble(maxTimeBarrierInMilliSeconds, 2) != 0);
   }
   
   bool isMaster(SData& his, SData& alien)
   {
      return his.LastTimeTransaction > alien.LastTimeTransaction;
   }
   
   void CalculateTick(SData& his, SData& alien, double& calculatedAsk, double& clculatedBid)
   {
      double spread = NormalizeDouble(his.MQLTick.ask - his.MQLTick.bid, 5);
      //double spreadBefore = NormalizeDouble(his.MQLTickBefore.ask - his.MQLTickBefore.bid, 5);
      //double spread = (spreadCurrent + spreadBefore) / 2;
      calculatedAsk = (alien.MQLTick.ask + alien.MQLTick.bid) / 2 + spread / 2;
      clculatedBid = calculatedAsk - spread;
   }
   
   void SignalDelay(SData& his, SData& alien)
   {
      if (!m_dHunterSetting.m_enabler) return;
      
      if (ExpertTimeOut(alien) || !TradeAllowed(his, alien))  return;
      
      double calculatedBid, calculatedAsk;
      CalculateTick(his, alien, calculatedAsk, calculatedBid);
      
      double deviationBuy   = calculatedBid - his.MQLTick.ask;
      double deviationSell  = his.MQLTick.bid - calculatedAsk;
      
      bool openBuy = (deviationBuy - m_dHunterSetting.m_signalOpen.m_minPoints) > 0;
      bool openSell= (deviationSell- m_dHunterSetting.m_signalOpen.m_minPoints) > 0;
      
      int typeOrder = openBuy ? OP_BUY : openSell ? OP_SELL : -1;
      
      if (openBuy || openSell)
      {
         Print(__FUNCTION__, ": Сигнал: Открыть позицию. Расхождение Buy: ", DoubleToString(deviationBuy, 5), ", Расхождение Sell: ", DoubleToString(deviationSell, 5));
         Print(__FUNCTION__, ": BID = ", his.MQLTick.bid, ", calculate BID alien = ", calculatedBid);
         Print(__FUNCTION__, ": ASK = ", his.MQLTick.ask, ", calculate ASK alien = ", calculatedAsk);
         ActionSignalOpenOrder(his, alien, typeOrder);
      }
      else
      {
         bool openedOrderBuy = OrderIsOpened(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic, OP_BUY);
         bool openedOrderSell= OrderIsOpened(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic, OP_SELL);
         if (openedOrderBuy || openedOrderSell)
         {
            Print(__FUNCTION__, ": Сигнал: Закрыть позицию. Расхождение Buy: ", DoubleToString(deviationBuy, 5), ", Расхождение Sell: ", DoubleToString(deviationSell, 5));
            Print(__FUNCTION__, ": BID = ", his.MQLTick.bid, ", calculate BID alien = ", calculatedBid);
            Print(__FUNCTION__, ": ASK = ", his.MQLTick.ask, ", calculate ASK alien = ", calculatedAsk);
            ActionSignalCloseOrders(his, alien, openedOrderBuy ? OP_BUY : openedOrderSell ? OP_SELL : -1);
         }
      }
   }
   
   void DeviationCalculate(DHUNTER& setting, SData& his, SData& alien, double& deviationBuy, double& deviationSell)
   {
      double calculatedBid = alien.MQLTick.bid, calculatedAsk = alien.MQLTick.ask;
      switch (setting.m_type)
      {
         case m_delayer: CalculateTick(his, alien, calculatedAsk, calculatedBid);   break;
         case m_deviator: calculatedBid = alien.MQLTick.bid; calculatedAsk = alien.MQLTick.ask; break;
      }
      
      deviationBuy   = calculatedBid - his.MQLTick.ask;
      deviationSell  = his.MQLTick.bid - calculatedAsk;
   }
   
   // Check quotes deviation (BID > ASK || ASK < BID)
   void SignalProcessing(SData& his, SData& alien)
   {
      if (!m_dHunterSetting.m_enabler) return;
      
      if (ExpertTimeOut(alien) || !TradeAllowed(his, alien))  return;
      
      double deviationBuy = 0;
      double deviationSell = 0;
      DeviationCalculate(m_dHunterSetting, his, alien, deviationBuy, deviationSell);
      
      double spreadHisCurrent = his.MQLTick.ask - his.MQLTick.bid;
      double spreadHisBefore = his.MQLTickBefore.ask - his.MQLTickBefore.bid;
      double spreadHisAvg = (spreadHisCurrent + spreadHisBefore) / 2;
      double spreadHis = spreadHisAvg > spreadHisCurrent ? spreadHisAvg : spreadHisCurrent;
      
      double spreadAlienCurrent = alien.MQLTick.ask - alien.MQLTick.bid;
      double spreadAlienBefore = alien.MQLTickBefore.ask - alien.MQLTickBefore.bid;
      double spreadAlienAvg = (spreadAlienCurrent + spreadAlienBefore) / 2;
      double spreadAlien = spreadAlienAvg > spreadAlienCurrent ? spreadAlienAvg : spreadAlienCurrent;
      
      double spread = spreadHis + spreadAlien;
      switch (m_dHunterSetting.m_type)
      {
         case m_delayer: spread = spreadHis; break;
         case m_deviator: spread = spreadHis + spreadAlien; break;
      }
      if (spread < m_dHunterSetting.m_minRestrictionPoint) spread = m_dHunterSetting.m_minRestrictionPoint;
      
      double spreadBuy = deviationBuy / spread;
      double spreadSell = deviationSell / spread;
      
      int typeOrder = -1;
      
      ulong time = GetMicrosecondCount();
      
      if (SignalClose(deviationBuy, deviationSell, spreadBuy, spreadSell, typeOrder) && SignalAllowed(his.TimeOutQuote, m_dHunterSetting.m_signalClose.m_minTimeBarrierInMilliSeconds, m_dHunterSetting.m_signalClose.m_maxTimeBarrierInMilliSeconds) && OrderIsOpened(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic))
      {
         Print(__FUNCTION__, ": Сигнал: Закрыть позицию. Расхождение Buy: ", DoubleToString(deviationBuy, 5), ", Расхождение Sell: ", DoubleToString(deviationSell, 5), ", Спред: ", DoubleToString(spread, 5));
         Print(__FUNCTION__, ": BID = ", his.MQLTick.bid, ", BID alien = ", alien.MQLTick.bid);
         Print(__FUNCTION__, ": ASK = ", his.MQLTick.ask, ", ASK alien = ", alien.MQLTick.ask);
         ActionSignalCloseOrders(his, alien, typeOrder);
      }
      
      ulong timeExecution = GetMicrosecondCount() - time; if ((timeExecution / 1000) > 300)   return;
      
      if (SignalOpen(deviationBuy, deviationSell, spreadBuy, spreadSell, typeOrder) && SignalAllowed(his.TimeOutQuote, m_dHunterSetting.m_signalOpen.m_minTimeBarrierInMilliSeconds, m_dHunterSetting.m_signalOpen.m_maxTimeBarrierInMilliSeconds))
      {
         Print(__FUNCTION__, ": Сигнал: Открыть позицию. Расхождение Buy: ", DoubleToString(deviationBuy, 5), ", Расхождение Sell: ", DoubleToString(deviationSell, 5), ", Спред: ", DoubleToString(spread, 5));
         Print(__FUNCTION__, ": BID = ", his.MQLTick.bid, ", BID alien = ", alien.MQLTick.bid);
         Print(__FUNCTION__, ": ASK = ", his.MQLTick.ask, ", ASK alien = ", alien.MQLTick.ask);
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
   
   bool isSync(SData& his, SData& alien)
   {
      for(int i = 0; i < ArraySize(alien.Orders); i++)
      {
         if (alien.Orders[i].m_ticket <= 0)  continue;
         if (alien.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         //if (CharArrayToString(alien.Orders[i].m_symbol) != Symbol()) continue;
         
         bool isSync = false;
         for (int j = 0; j < ArraySize(his.Orders); j++)
         {
            if (his.Orders[j].m_ticket <= 0)  continue;
            if (his.Orders[j].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
            //if (CharArrayToString(his.Orders[j].m_symbol) != Symbol()) continue;
            
            isSync = his.Orders[j].m_cmd == Reverse(alien.Orders[i].m_cmd); if (isSync)   break;
         }
         if (!isSync)   return false;
      }
      
      for(int i = 0; i < ArraySize(his.Orders); i++)
      {
         if (his.Orders[i].m_ticket <= 0)  continue;
         if (his.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         //if (CharArrayToString(his.Orders[i].m_symbol) != Symbol()) continue;
         
         bool isSync = false;
         for (int j = 0; j < ArraySize(alien.Orders); j++)
         {
            if (alien.Orders[j].m_ticket <= 0)  continue;
            if (alien.Orders[j].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
            //if (CharArrayToString(alien.Orders[j].m_symbol) != Symbol()) continue;
            
            isSync = alien.Orders[j].m_cmd == Reverse(his.Orders[i].m_cmd); if (isSync)   break;
         }
         if (!isSync)   return false;
      }
      
      return true;
   }
   
   void Synchronization(SData& his, SData& alien)
   {
      if (ExpertTimeOut(alien) || !TradeAllowed(his, alien))  return;
      
      // Сначала открываем те ордера, которых нет в терминале slave
      for(int i = 0; i < ArraySize(alien.Orders); i++)
      {
         if (alien.Orders[i].m_ticket <= 0)  continue;
         if (alien.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         //if (CharArrayToString(alien.Orders[i].m_symbol) != Symbol()) continue;
         
         SynchronizationOpenOrder(his, alien.Orders[i]);
      }
      
      // Потом закрываем те ордера, которых нет в терминале master
      int total = OrdersTotal();
      for(int i = 0; i < total; i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (!OrderUnic(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic))   continue;
            
            SynchronizationCloseOrder(OrderTicket(), his, alien);
         }
      }
   }
   void SynchronizationOpenOrder(SData& his, MQLOrder& orderForSynchronization)
   {
      bool orderOpened = false;
      for (int i = 0; i < OrdersTotal(); i++)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (!OrderUnic(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic, Reverse(orderForSynchronization.m_cmd)))   continue;
            orderOpened = true; break;
         }
      }
      if (!orderOpened)
      {
         Print(__FUNCTION__, ": Обнаружен не синхронизированный ордер, открываем его.");
         MQLRequestOpen request; request.Init(orderForSynchronization);
         StringToCharArray(Symbol(), request.m_symbol);
         request.m_cmd = Reverse(orderForSynchronization.m_cmd);
         FillRequestPrice(his.MQLTick, request.m_cmd, request.m_price);
         //request.m_price = 0;
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
            Print(__FUNCTION__, ": Не удалось открыть ордер. Попробуем еще раз в следующую итерацию");
         }
      }
   }
   void SynchronizationCloseOrder(int ticket, SData& his, SData& alien)
   {
      if (!OrderSelect(ticket, SELECT_BY_TICKET))   return;
      
      bool orderOpened = false;
      int total = ArraySize(alien.Orders);
      for (int i = 0; i < total; i++)
      {
         if (alien.Orders[i].m_ticket <= 0)  continue;
         if (alien.Orders[i].m_magic != m_dHunterSetting.m_tradeSetting.m_magic)   continue;
         if (alien.Orders[i].m_cmd != Reverse(OrderType())) continue;
         //if (CharArrayToString(alien.Orders[i].m_symbol) != OrderSymbol()) continue;
         
         orderOpened = true; break;
      }
      
      if (!orderOpened)
      {
         MQLRequestClose request; request.Init();
         FillRequest(request, OrderTicket(), alien);
         FillRequestPrice(his.MQLTick, Reverse(OrderType()), request.m_price);
         
         //request.m_price = 0;
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
            Print(__FUNCTION__, ": Не удалось закрыть ордер #", ticket, ". Попробуем еще раз в следующую итерацию");
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
   bool CheckRequestLongExecution(SData& his, int typeOrder)
   {
      MqlTick tick; SymbolInfoTick(CharArrayToString(his.TSymbol), tick);
      if (typeOrder == OP_BUY)
      {
         if (tick.ask > his.MQLTick.ask)
         {
            Print(__FUNCTION__, ": Цена изменилась в худшую сторону. не открываем ордер. было: ", DoubleToString(his.MQLTick.ask, 5), ", стало: ", DoubleToString(tick.ask, 5));
            return false;
         }
      }
      if (typeOrder == OP_SELL)
      {
         if (tick.bid < his.MQLTick.bid)
         {
            Print(__FUNCTION__, ": Цена изменилась в худшую сторону. не открываем ордер. было: ", DoubleToString(his.MQLTick.bid, 5), ", стало: ", DoubleToString(tick.bid, 5));
            return false;
         }
      }
      return true;
   }
   void ActionOpenOrder(SData& his, SData& alien, int typeOrder)
   {
      MQLRequestOpen request; request.Init();
      if (!CheckRequestLongExecution(his, typeOrder))  return;
      
      request.m_cmd = typeOrder; 
      FillRequest(request, his, alien);
      if (request.m_cmd == -1)
      {
         Print(__FUNCTION__, ": Не удалось определить направление, не торгую"); return;
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
            if (OrderCloseTime() > 0 || !OrderUnic(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic, typeOrder))   continue;
            
            MQLRequestClose request; request.Init();
            
            if (!CheckRequestLongExecution(his, typeOrder))  return;
            
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
      FillRequestPrice(his.MQLTick, request.m_cmd, request.m_price);
      request.m_magic = m_dHunterSetting.m_tradeSetting.m_magic;
      request.m_slippage = 0;
   }
   
   void FillRequest(MQLRequestClose& request, int ticket, SData& his)
   {
      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         request.m_ticket = ticket;
         request.m_lots = OrderLots();
         FillRequestPrice(his.MQLTick, OrderType(), request.m_price);
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
   
   bool OrderIsOpened(string symbol, int magic, int typeOrder = -1)
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
   
   // Возвращает направление позиции
   // OP_BUY - в случае тренда наверх
   // OP_SELL - в случае тренда вниз
   // -1 - в случае если тренд неопределен и торговать не нужно
   int SignalDetection(SData& his, SData& alien)
   {
      //Print(__FUNCTION__, ": Определяем направление сигнала");
      //if (his.TimeOutQuote >= alien.TimeOutQuote)
      //{
         Print(__FUNCTION__, ": ", DoubleToString((his.TimeOutQuote - alien.TimeOutQuote) / 1000, 2), " сек. задержка относительно '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "'");
         if (alien.MQLTick.bid > his.MQLTick.ask)
         {
            Print(__FUNCTION__, ": Разница курсов: +", DoubleToString(alien.MQLTick.bid - his.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) > 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) > 0)
            //{
               Print(__FUNCTION__, ": В терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вверх на: ASK = +", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = +", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_BUY;
            //}
         }
         if (alien.MQLTick.ask < his.MQLTick.bid)
         {
            Print(__FUNCTION__, ": разница курсов: +", DoubleToString(his.MQLTick.bid - alien.MQLTick.ask, 5), ", текущий спред обоих брокеров: ", DoubleToString((alien.MQLTick.ask - alien.MQLTick.bid) + (his.MQLTick.ask - his.MQLTick.bid), 5));
            //if ((alien.MQLTick.ask - alien.MQLTickBefore.ask) < 0 &&
            //    (alien.MQLTick.bid - alien.MQLTickBefore.bid) < 0)
            //{
               Print(__FUNCTION__, ": В терминале '", CharArrayToString(alien.Terminal.Company), ": ", alien.Terminal.Login, "', котировка изменились вниз на: ASK = ", DoubleToString((alien.MQLTick.ask - alien.MQLTickBefore.ask), 5), ", BID = ", DoubleToString((alien.MQLTick.bid - alien.MQLTickBefore.bid), 5));
               return OP_SELL;
            //}
         }
      //}
      Print(__FUNCTION__, ": Тренд не определен");
      return -1;
   }
   
   void Log(SData& datas[], int index)
   {
      if (!m_dHunterSetting.m_logger) return;
      
      string m_log = NULL;
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         if ((datas[index].Master == datas[i].Master) && m_dHunterSetting.m_type == m_delayer) continue;
         
         m_log += Log(datas[index], datas[i]);
      }
      Comment(m_log);
   }
   string Log(SData &his, SData &alien)
   {
      string company = CharArrayToString(alien.Terminal.Company);
      int login = alien.Terminal.Login;
      int digits = 5;
      
      double pointBuy  = alien.MQLTick.bid - his.MQLTick.ask;
      double pointSell = his.MQLTick.bid - alien.MQLTick.ask;
      double spreadHis = (his.MQLTick.ask - his.MQLTick.bid);
      double spreadAlien = (alien.MQLTick.ask - alien.MQLTick.bid);
      double spreadGeneral = spreadHis + spreadAlien;
      double spreadAverage = ((his.MQLTick.ask - his.MQLTick.bid) + (his.MQLTickBefore.ask - his.MQLTickBefore.bid)) / 2;
      double spreadAverageAlien = ((alien.MQLTick.ask - alien.MQLTick.bid) + (alien.MQLTickBefore.ask - alien.MQLTickBefore.bid)) / 2;
      
      string orders = his.OrdersToString();
      string ordersHistory = his.OrdersHistoryToString();
      
      double sum = OrdersSum(his, alien);
      double sumHistory = OrdersHistorySum(his, alien);
      
      bool hisMaster = false, alienMaster = false;
         
      bool sync = isSync(his, alien);
      if (!sync){ hisMaster = isMaster(his, alien); alienMaster = hisMaster ? false : true; }
      else
      {
         bool openedOrder = OrderIsOpened(Symbol(), m_dHunterSetting.m_tradeSetting.m_magic);
         if (openedOrder)
         {
            hisMaster = true; alienMaster = true;
         }
         else
         {
            hisMaster = his.Master; alienMaster = alien.Master;
         }
         
      }
      
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
         text += StringConcatenate(
         "  TimeOut           ", DoubleToString(alien.TimeOutQuote * 0.000001, 2), " sec.     |    ", DoubleToString(his.TimeOutQuote * 0.000001, 2), " sec.\n",
         "  LastUpdate        ", TimeToString(alien.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "    |    ", TimeToString(his.LastUpdateExpert, TIME_MINUTES|TIME_SECONDS), "\n",
         "  Spread avg        ", DoubleToString(spreadAverageAlien, digits), "    |     ", DoubleToString(spreadAverage, digits), "    \n",
         "  TradeAllowed      ", alien.isTradeAllowed, "        |      ", his.isTradeAllowed, "          \n",
         "  Master                ", alien.Master, "       |      ", his.Master, "          \n",
         "  LastTransaction   ", TimeToString(alien.LastTimeTransaction, TIME_MINUTES|TIME_SECONDS), "   |   ", TimeToString(his.LastTimeTransaction, TIME_MINUTES|TIME_SECONDS), "          \n",
         "  CalcutateMaster   ", alienMaster, "        |    ", hisMaster, "        \n",
         "-------------------------------------------------------------------", "\n",
         "  Buy:                " , DoubleToString(NormalizeDouble(spreadGeneral, digits) > 0 ? pointBuy / spreadGeneral : 0,  2), " sp.    |   ", DoubleToString(pointBuy,  digits), " pt.", "\n",
         "  Sell:                 ", DoubleToString(NormalizeDouble(spreadGeneral, digits) > 0 ? pointSell / spreadGeneral : 0, 2), " sp.    |   ", DoubleToString(pointSell, digits), " pt.", "\n",
         "\n");
         return text + StringConcatenate("- Open Orders ---- ", DoubleToString(sum, 2), " ----------------------------------", "\n", orders, "\n", "-------------------------------------------------------------------", "\n",
         "- History Orders -- ", DoubleToString(sumHistory, 2), " ------------------------------", "\n", ordersHistory, "\n", "-------------------------------------------------------------------", "\n"
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
         
         sum += (orders[i].m_profit + orders[i].m_swap + orders[i].m_commission);
         
         /*switch(orders[i].m_cmd)
         {
            case OP_BUY: sum += orders[i].m_closePrice - orders[i].m_price; break;
            case OP_SELL:sum += orders[i].m_price - orders[i].m_closePrice; break;
         }
         */
      }
      
      return sum;
   }
   
   double OrdersHistorySum(SData &his, SData &alien, int magic = -1)
   {
      double sum = 0;
      MQLOrder orders[]; ArrayCopy(orders, his.OrdersHistory); ArrayCopy(orders, alien.OrdersHistory, ArraySize(his.OrdersHistory));
      for(int i = 0; i < ArraySize(orders); i++)
      {
         if (orders[i].m_ticket <= 0)  continue;
         if (orders[i].m_magic == magic && magic != -1) continue;
         
         sum += (orders[i].m_profit + orders[i].m_swap + orders[i].m_commission);
         /*switch(orders[i].m_cmd)
         {
            case OP_BUY: sum += orders[i].m_closePrice - orders[i].m_price; break;
            case OP_SELL:sum += orders[i].m_price - orders[i].m_closePrice; break;
         }
         */
      }
      
      return sum;
   }
};