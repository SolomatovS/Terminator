//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include <stdlib.mqh>
#include "Model.mqh"

class Trade
{
protected:
   static bool CheckAndCorrectPrice(int cmd, double ask, double bid, double minstoplevel, bool requestPriceCorrect, double& price, int& error)
   {
      double _minStopLevel = 0;
      if (cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP)
      {
            if (cmd == OP_BUYLIMIT)
            {
               _minStopLevel = ask - minstoplevel;
               if (price > _minStopLevel || NormalizeDouble(price, 5) == 0.00000)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
            }
            else if (cmd == OP_BUYSTOP)
            {
               _minStopLevel = ask + minstoplevel;
               if (price < _minStopLevel || NormalizeDouble(price, 5) == 0.00000)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
            }
            else
            {
               price = ask;
               _minStopLevel = 0;
            }
      }
      if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_SELLSTOP)
      {
            if (cmd == OP_SELLLIMIT)
            {
               _minStopLevel = bid + minstoplevel;
               if (price < _minStopLevel || NormalizeDouble(price, 5) == 0.00000)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
               
            }
            else if (cmd == OP_SELLSTOP || NormalizeDouble(price, 5) == 0.00000)
            {
               _minStopLevel = bid - minstoplevel;
               if (price > _minStopLevel)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
            }
            else
            {
               price = bid;
               _minStopLevel = 0;
            }
      }
      
      return true;
   }
   
   static bool CheckAndCorrectStopLoss(int cmd, double price, double minstoplevel, bool stoplossCorrect, double& stoplossPoint, int& error)
   {
      double _minStopLevel = 0;
      double stoploss = 0;
      if (cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP)
      {
         if (stoplossPoint > 0)
         {
            stoploss = price - stoplossPoint;
            _minStopLevel = price - minstoplevel;
            if (stoploss > _minStopLevel)
            {
               if (stoplossCorrect) { stoplossPoint = minstoplevel; }
               else                 { error = ERR_INVALID_STOPS; return false; }
            }
         }
         else stoplossPoint = 0;
      }
      if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_SELLSTOP)
      {
         if (stoplossPoint > 0)
         {
            stoploss = price + stoplossPoint;
            _minStopLevel = price + minstoplevel;
            if (stoploss < _minStopLevel)
            {
               if (stoplossCorrect) { stoplossPoint = minstoplevel; }
               else                 { error = ERR_INVALID_STOPS; return false; }
            }
         }
         else stoplossPoint = 0;
      }
      
      return true;
   }
   
   static bool CheckAndCorrectTakeProfit(int cmd, double price, double minstoplevel, bool takeprofitCorrect, double& takeprofitPoint, int& error)
   {
      double _minStopLevel = 0;
      double takeprofit = 0;
      if (cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP)
      {
         if (takeprofitPoint > 0)
         {
            _minStopLevel = price + minstoplevel;
            takeprofit = price + takeprofitPoint;
            
            if (takeprofit < _minStopLevel)
            {
               if (takeprofitCorrect)  { takeprofitPoint = minstoplevel; }
               else                    { error = ERR_INVALID_STOPS; return false; }
            }
         }
         else takeprofitPoint = 0;
      }
      if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_SELLSTOP)
      {
         // SET STOPLOSS
         if (takeprofitPoint > 0)
         {
            _minStopLevel = price - minstoplevel;
            takeprofit = price - takeprofitPoint;
            
            if (takeprofit > _minStopLevel)
            {
               if (takeprofitCorrect)  { takeprofitPoint = minstoplevel; }
               else                    { error = ERR_INVALID_STOPS; return false; }
            }
         }
         else takeprofitPoint = 0;
      }
      
      return true;
   }
   
   static bool CheckAndCorrectRequest(MQLRequestOpen& request, bool requestVolumeCorrect, bool requestPriceCorrect, bool stoplossCorrect, bool takeprofitCorrect)
   {
      double point = SymbolInfoDouble(CharArrayToString(request.m_symbol), SYMBOL_POINT);
      double minstoplevel = SymbolInfoInteger(CharArrayToString(request.m_symbol), SYMBOL_TRADE_STOPS_LEVEL) * point;
      double spread = request.m_tick.ask - request.m_tick.bid;
      if (request.m_cmd == OP_BUY)  request.m_price = request.m_tick.ask;
      if (request.m_cmd == OP_SELL) request.m_price = request.m_tick.bid;
      if (!CheckAndCorrectVolume(CharArrayToString(request.m_symbol), request.m_volume, requestVolumeCorrect))   return false;
      if (!CheckAndCorrectPrice(request.m_cmd, request.m_tick.ask, request.m_tick.bid, minstoplevel, requestPriceCorrect, request.m_price, request.m_error)) return false;
      
      double priceForCheckStopOrder = request.m_price;
      if (request.m_cmd == OP_BUY || request.m_cmd == OP_BUYLIMIT || request.m_cmd == OP_BUYSTOP)
      {
         priceForCheckStopOrder -= spread;
      }
      else
      {
         priceForCheckStopOrder += spread;
      }
      
      if (!CheckAndCorrectStopLoss(request.m_cmd, priceForCheckStopOrder, minstoplevel, stoplossCorrect, request.m_stoploss, request.m_error))     return false;
      if (!CheckAndCorrectTakeProfit(request.m_cmd, priceForCheckStopOrder, minstoplevel, stoplossCorrect, request.m_stoploss, request.m_error))   return false;
      
      return true;
   }
   
   static bool CheckAndCorrectRequest(MQLRequestClose& request, string orderSymbol, int orderCmd, double orderLots, bool requestPriceCorrect, bool requestVolumeCorrect)
   {
      double point = SymbolInfoDouble(orderSymbol, SYMBOL_POINT);
      double minstoplevel = SymbolInfoInteger(orderSymbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
      int cmd;
      switch(orderCmd)
      {
         case OP_BUY: cmd = OP_SELL; break;
         case OP_SELL: cmd = OP_BUY; break;
      }
      
      if (cmd == OP_BUY)
      {
         request.m_price = SymbolInfoDouble(orderSymbol, SYMBOL_ASK);
      }
      if (cmd == OP_SELL)
      {
         request.m_price = SymbolInfoDouble(orderSymbol, SYMBOL_BID);
      }
      
      if (!CheckAndCorrectPrice(cmd, request.m_tick.ask, request.m_tick.bid, minstoplevel, requestPriceCorrect, request.m_price, request.m_error)) return false;
      if (orderLots < request.m_lots || request.m_lots <= 0)
      {
         if (requestVolumeCorrect)
         {
            request.m_lots = orderLots;
         }
         else
         {
            Print(__FUNCTION__, ": Order #", request.m_ticket, " not closed; request volume = ", request.m_lots, "; order volume = ", OrderLots());
            return false;
         }
      }
      
      return true;
   }
   static bool CheckAndCorrectVolume(string symbol, double& volume, bool volumeCorrect = true)
   {
      bool result = false;
      double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      double stepVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      
      if (volume > 0 && volume >= minVolume && volume <= maxVolume)
      {
         result = true;
      }
      else
      {
         Print(__FUNCTION__, ": incorrect volume '", volume, "'");
         if (volumeCorrect)
         {
            if (volume < 0 || volume < minVolume) volume = minVolume;
            if (volume > maxVolume) volume = maxVolume;
            Print(__FUNCTION__, ": volume corrected '", volume, "'");
            result = true;
         }
         else result = false;
      }
      return result;
   }
   static bool SymbolExists(string symbol)
   {
      if (!SymbolSelect(symbol, false))
      {
         if (!SymbolSelect(symbol, true))
         {
            Print(__FUNCTION__, ": symbol '", "' not found");
            return false;
         }
      }
      return true;
   }
   static bool CmdExists(int cmd)
   {
      if (!(cmd >= OP_BUY && cmd <= OP_SELLSTOP))
      {
         Print(__FUNCTION__, ": cmd '", cmd, "' not valid");
         return false;
      }
      return true;
   }
   
public:
   static bool OpenOrder(const MQLRequestOpen& request, MQLOrder& responce, MQLRequestOpen& requestTry[], int countTryLimit = 5, bool requestVolumeCorrect = true, bool requestPriceCorrect = true, bool stoplossCorrect = true, bool takeprofitCorrect = true)
   {
      ulong timeOpenPosition = GetMicrosecondCount(); Print(__FUNCTION__, ": Start");
      bool criticalError = false; int ticket = -1;
      bool result = false;
      if (!(IsConnected() && IsExpertEnabled()))   return false;
      if (!SymbolExists(CharArrayToString(request.m_symbol))) return false;
      
      if (!CmdExists(request.m_cmd))   return false;
      
      do
      {  
         int i = 1000;
         while (!IsTradeAllowed() && i > 0)   { Sleep(10); i--; }
         int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
         requestTry[index].Init(request);
         SymbolInfoTick(CharArrayToString(requestTry[index].m_symbol), requestTry[index].m_tick);
         
         if (!CheckAndCorrectRequest(requestTry[index], requestVolumeCorrect, requestPriceCorrect, stoplossCorrect, takeprofitCorrect)) break;
         
         int digits = SymbolInfoInteger(CharArrayToString(requestTry[index].m_symbol), SYMBOL_DIGITS);
         double stoploss, takeprofit;
         if (requestTry[index].m_cmd == OP_BUY || requestTry[index].m_cmd == OP_BUY || requestTry[index].m_cmd == OP_BUY)
         {
            stoploss = NormalizeDouble(requestTry[index].m_stoploss, digits) > 0 ? requestTry[index].m_price - requestTry[index].m_stoploss : 0;
            takeprofit = NormalizeDouble(requestTry[index].m_takeprofit, digits) > 0 ? requestTry[index].m_price + requestTry[index].m_takeprofit : 0;
         }
         else
         {
            stoploss = NormalizeDouble(requestTry[index].m_stoploss, digits) > 0 ? requestTry[index].m_price + requestTry[index].m_stoploss : 0;
            takeprofit = NormalizeDouble(requestTry[index].m_takeprofit, digits) > 0 ? requestTry[index].m_price - requestTry[index].m_takeprofit : 0;
         }
         
         ulong timeExecution = GetMicrosecondCount();
         ticket = OrderSend(CharArrayToString(requestTry[index].m_symbol),
                            requestTry[index].m_cmd,
                            NormalizeDouble(requestTry[index].m_volume, 2),
                            NormalizeDouble(requestTry[index].m_price, digits),
                            requestTry[index].m_slippage,
                            NormalizeDouble(stoploss, digits),
                            NormalizeDouble(takeprofit, digits),
                            CharArrayToString(requestTry[index].m_comment),
                            requestTry[index].m_magic,
                            requestTry[index].m_expiration,
                            requestTry[index].m_arrow_color);
         timeExecution = (GetMicrosecondCount() - timeExecution);
         requestTry[index].m_executionMicrosecond = timeExecution;
         
         countTryLimit--;
         
         if (ticket < 0)
         {
            requestTry[index].m_error = GetLastError(); criticalError = false;
            string error_description = ErrorDescription(requestTry[index].m_error);
            Print(__FUNCTION__, ": error code ", requestTry[index].m_error, ": '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
            
            switch(requestTry[index].m_error)
            {
               case ERR_TRADE_TIMEOUT: 
               case ERR_INVALID_PRICE:
               Print(__FUNCTION__, ": Current ask: ", requestTry[index].m_tick.ask, ", Current bid: ", requestTry[index].m_tick.bid, ", request price:", requestTry[index].m_price);
                        break;
               case ERR_INVALID_STOPS:
               case ERR_PRICE_CHANGED:
               case ERR_OFF_QUOTES:
               case ERR_REQUOTE: criticalError = false; break;
               default: criticalError = true;
            }
         }
         else
         {
            OrderSelect(ticket, SELECT_BY_TICKET);
            requestTry[index].m_executionPrice = OrderOpenPrice();
            responce.Init(requestTry[index]);
            responce.m_ticket = ticket;
            responce.m_price = requestTry[index].m_executionPrice;
            
            double _slippage = 0;
            if (responce.m_cmd == OP_BUY || responce.m_cmd == OP_BUYLIMIT || responce.m_cmd == OP_BUYSTOP)
            {
               _slippage = requestTry[index].m_price - requestTry[index].m_executionPrice;
            }
            else  _slippage = requestTry[index].m_executionPrice - requestTry[index].m_price;
            
            Print(__FUNCTION__, ": OK; ticket #", responce.m_ticket, "; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds;", " Request price: ", DoubleToString(requestTry[index].m_price, digits), "; Execution Price: ", DoubleToString(requestTry[index].m_executionPrice, digits), "; Slippage: ", DoubleToString(_slippage, digits));
            result = true;
         }
      }
      while(!criticalError && ticket < 0 && countTryLimit > 0);
      
      timeOpenPosition = (GetMicrosecondCount() - timeOpenPosition);
      Print(__FUNCTION__, ": End; time: ", DoubleToString(timeOpenPosition / 1000, 3), " milliseconds");
      
      return result;
   }
   
   static bool CloseOrDeleteOrder(const MQLRequestClose& request, MQLRequestClose& requestTry[], int countTryLimit = 5, bool requestVolumeCorrect = true, bool requestPriceCorrect = true)
   {
      ulong timeOpenPosition = GetMicrosecondCount(); Print(__FUNCTION__, ": Start");
      ulong timeExecution = 0; string error_description = NULL;
      
      if (!(IsConnected() && IsExpertEnabled()))   return false;
      
      bool result = false; bool criticalError = false;
      do
      {
         int i = 1000;
         while (!IsTradeAllowed() && i > 0)   { Sleep(10); i--; }
         
         if (OrderSelect(request.m_ticket, SELECT_BY_TICKET))
         {
            int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
            
            requestTry[index].Init(request);
            SymbolInfoTick(OrderSymbol(), requestTry[index].m_tick);
            int digits = SymbolInfoInteger(OrderSymbol(), SYMBOL_DIGITS);
            
            int type = OrderType();
            if (type == OP_BUY || type == OP_SELL)
            {
               if (requestTry[index].m_opposite > 0)
               {
                  if (OrderSelect(requestTry[index].m_ticket, SELECT_BY_TICKET))
                  {
                     timeExecution = GetMicrosecondCount();
                     result = OrderCloseBy(
                        requestTry[index].m_ticket,
                        requestTry[index].m_opposite,
                        requestTry[index].m_arraow_color);
                     timeExecution = (GetMicrosecondCount() - timeExecution);
                     requestTry[index].m_executionMicrosecond = timeExecution;
                  }
                  
                  countTryLimit--;
                  
                  if (result)
                  {
                     if (OrderSelect(requestTry[index].m_ticket, SELECT_BY_TICKET))
                     {
                        requestTry[index].m_executionPrice = OrderClosePrice();
                     }
                     if (OrderSelect(requestTry[index].m_opposite, SELECT_BY_TICKET))
                     {
                        requestTry[index].m_price = OrderClosePrice();
                     }
                     Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " closed by #", requestTry[index].m_opposite, "; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
                  }
                  else
                  {
                     requestTry[index].m_error = GetLastError(); criticalError = false;
                     error_description = ErrorDescription(requestTry[index].m_error);
                     Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " not closed by #", requestTry[index].m_opposite, "; error code: ", requestTry[index].m_error, " - '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
                     switch(requestTry[index].m_error)
                     {
                        default: criticalError = true;
                     }
                  }
               }
               else
               {
                  if (!CheckAndCorrectRequest(requestTry[index], OrderSymbol(), OrderType(), OrderLots(), requestPriceCorrect, requestVolumeCorrect))   break;
                  
                  if (OrderSelect(requestTry[index].m_ticket, SELECT_BY_TICKET))
                  {
                     timeExecution = GetMicrosecondCount();
                     result = OrderClose(
                        requestTry[index].m_ticket,
                        NormalizeDouble(requestTry[index].m_lots, 2),
                        NormalizeDouble(requestTry[index].m_price, digits),
                        requestTry[index].m_slippage,
                        requestTry[index].m_arraow_color);
                     timeExecution = (GetMicrosecondCount() - timeExecution);
                     requestTry[index].m_executionMicrosecond = timeExecution;
                  }
                  countTryLimit--;
                  
                  if (result)
                  {
                     if (OrderSelect(request.m_ticket, SELECT_BY_TICKET))
                     {
                        requestTry[index].m_executionPrice = OrderClosePrice();
                        double _slippage = 0;
                        if (type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP)
                        {
                           _slippage = requestTry[index].m_price - requestTry[index].m_executionPrice;
                        }
                        else  _slippage = requestTry[index].m_executionPrice - requestTry[index].m_price;
                     
                        Print(__FUNCTION__, ": OK; Order #", requestTry[index].m_ticket, "; closed; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds;", " Request price: ", DoubleToString(requestTry[index].m_price, digits), "; Execution Price: ", DoubleToString(requestTry[index].m_executionPrice, digits), "; Slippage: ", DoubleToString(_slippage, digits));
                     }
                     else
                     {
                        Print(__FUNCTION__, ": OK; Order #", requestTry[index].m_ticket, "; closed; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds;", " Request price: ", DoubleToString(requestTry[index].m_price, digits));
                     }
                     result = true;
                  }
                  else
                  {
                     requestTry[index].m_error = GetLastError(); criticalError = false;
                     error_description = ErrorDescription(requestTry[index].m_error);
                     Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " not closed; error code: ", requestTry[index].m_error, " - '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
                     
                     switch(requestTry[index].m_error)
                     {
                        case ERR_TRADE_TIMEOUT: 
                        case ERR_INVALID_PRICE:
                           Print(__FUNCTION__, ": Current ask: ", requestTry[index].m_tick.ask, ", Current bid: ", requestTry[index].m_tick.bid, ", request price:", requestTry[index].m_price);
                        break;
                        case ERR_INVALID_STOPS:
                        case ERR_PRICE_CHANGED:
                        case ERR_OFF_QUOTES:
                        case ERR_INVALID_TRADE_PARAMETERS:
                           Print(__FUNCTION__, ": Ticket: ", requestTry[index].m_ticket, ", Lots: ", requestTry[index].m_lots, ", Price: ", requestTry[index].m_price, ", Slippage: ", requestTry[index].m_slippage, ", Arrow_color: ", requestTry[index].m_arraow_color);
                        break;
                        case ERR_REQUOTE: criticalError = false; break;
                        default: criticalError = true;
                     }
                     result = false;
                  }
               }
            }
            else
            {
               if (type == OP_BUYLIMIT || type == OP_BUYSTOP)
               {
                  requestTry[index].m_price = requestTry[index].m_tick.bid;
               }
               else
               {
                  requestTry[index].m_price = requestTry[index].m_tick.ask;
               }
               
               if (OrderSelect(requestTry[index].m_ticket, SELECT_BY_TICKET))
               {
                  timeExecution = GetMicrosecondCount();
                  result = OrderDelete(
                     requestTry[index].m_ticket,
                     requestTry[index].m_arraow_color);
                  timeExecution = (GetMicrosecondCount() - timeExecution);
                  requestTry[index].m_executionMicrosecond = timeExecution;
               }
               countTryLimit--;
               
               if (result)
               {
                  if (OrderSelect(requestTry[index].m_ticket, SELECT_BY_TICKET))
                  {
                     requestTry[index].m_executionPrice = OrderClosePrice();
                  }
                  Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " deleted; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
                  result = true;
               }
               else
               {
                  requestTry[index].m_error = GetLastError();
                  error_description = ErrorDescription(requestTry[index].m_error);
                  Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " not deleted; error code: ", requestTry[index].m_error, " - '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
                  result = false;
               }
            }
         }
         else
         {
            Print(__FUNCTION__, ": order #", request.m_ticket, " not found");
            result = false;
         }
      }
      while(!criticalError && !result && countTryLimit > 0);

      timeOpenPosition = (GetMicrosecondCount() - timeOpenPosition);
      Print(__FUNCTION__, ": End; time: ", DoubleToString(timeOpenPosition / 1000, 3), " milliseconds");
      return result;
   }
};