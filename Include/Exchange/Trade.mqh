//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include <stdlib.mqh>

struct MQLRequestClose
{
   int      m_ticket;
   double   m_lots;
   double   m_price;
   int      m_slippage;
   int      m_opposite;
   color    m_arraow_color;
   int      m_error;
   
   void Init(int ticket, double lots, double price, int slippage, int opposite, color arraw_color = clrNONE, int error = 0)
   {
      m_ticket = ticket; m_lots = lots; m_price = price; m_slippage = slippage; m_opposite = opposite; m_arraow_color = arraw_color; m_error = error;
   }
   void Init(const MQLRequestClose& request)
   {
      Init(request.m_ticket, request.m_lots, request.m_price, request.m_slippage, request.m_opposite, request.m_arraow_color, request.m_error);
   }
};

struct MQLRequestOpen
{
   string   m_symbol;
   int      m_cmd;
   double   m_volume;
   double   m_price;
   int      m_slippage;
   double   m_stoploss;
   double   m_takeprofit;
   string   m_comment;
   int      m_magic;
   datetime m_expiration;
   color    m_arrow_color;
   int      m_error;
   
   void Init(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment=NULL, int magic=0, datetime expiration=0, color arrow_color = clrNONE, int error = 0)
   {
      m_symbol = symbol; m_cmd = cmd; m_volume = volume; m_price = price; m_stoploss = stoploss; m_takeprofit = takeprofit;
      m_comment = comment; m_magic = magic; m_expiration = expiration; m_arrow_color = arrow_color; m_error = error;
   }
   void Init(const MQLRequestOpen& request)
   {
      Init(request.m_symbol, request.m_cmd, request.m_volume, request.m_price, request.m_slippage, request.m_stoploss, request.m_takeprofit, request.m_comment, request.m_magic, request.m_expiration, request.m_arrow_color, request.m_error);
   }
   /*
   void Init(const MQLOrder& order)
   {
      Init(order.m_symbol, order.m_cmd, order.m_volume, order.m_price, order.m_slippage, order.m_stoploss, order.m_takeprofit, order.m_comment, order.m_magic, order.m_expiration, order.m_arrow_color, 0);
   }
   */
};

struct MQLOrder
{
   int      m_ticket;
   string   m_symbol;
   int      m_cmd;
   double   m_volume;
   double   m_price;
   int      m_slippage;
   double   m_stoploss;
   double   m_takeprofit;
   string   m_comment;
   int      m_magic;
   datetime m_expiration;
   color    m_arrow_color;
   
   void Init(int ticket, string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment=NULL, int magic=0, datetime expiration=0, color arrow_color = clrNONE)
   {
      m_ticket = ticket; m_symbol = symbol; m_cmd = cmd; m_volume = volume; m_price = price; m_stoploss = stoploss; m_takeprofit = takeprofit;
      m_comment = comment; m_magic = magic; m_expiration = expiration; m_arrow_color = arrow_color;
   }
   void Init(const MQLOrder& order)
   {
      Init(order.m_ticket, order.m_symbol, order.m_cmd, order.m_volume, order.m_price, order.m_slippage, order.m_stoploss, order.m_takeprofit, order.m_comment, order.m_magic, order.m_expiration, order.m_arrow_color);
   }
   void Init(const MQLRequestOpen& request)
   {
      Init(0, request.m_symbol, request.m_cmd, request.m_volume, request.m_price, request.m_slippage, request.m_stoploss, request.m_takeprofit, request.m_comment, request.m_magic, request.m_expiration, request.m_arrow_color);
   }
};

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
               if (price > _minStopLevel)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
            }
            else if (cmd == OP_BUYSTOP)
            {
               _minStopLevel = ask + minstoplevel;
               if (price < _minStopLevel)
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
               if (price < _minStopLevel)
               {
                  if (requestPriceCorrect)   { price = _minStopLevel; }
                  else                       { error = ERR_INVALID_PRICE; return false; }
               }
               
            }
            else if (cmd == OP_SELLSTOP)
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
   
   static bool CheckAndCorrectRequest(MQLRequestOpen& request, bool requestPriceCorrect, bool stoplossCorrect, bool takeprofitCorrect)
   {
      double point = SymbolInfoDouble(request.m_symbol, SYMBOL_POINT);
      double minstoplevel = SymbolInfoInteger(request.m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
      double ask = MarketInfo(request.m_symbol, MODE_ASK);
      double bid = MarketInfo(request.m_symbol, MODE_BID);
      double spread = ask - bid;
      
      if (!CheckAndCorrectPrice(request.m_cmd, ask, bid, minstoplevel, requestPriceCorrect, request.m_price, request.m_error)) return false;
      
      double priceForCheckStopOrder = request.m_price;
      double priceForCheckTakeOrder = request.m_price;
      if (request.m_cmd == OP_BUY || request.m_cmd == OP_BUYLIMIT || request.m_cmd == OP_BUYSTOP)
      {
         priceForCheckStopOrder -= spread; priceForCheckTakeOrder += spread;
      }
      else
      {
         priceForCheckStopOrder += spread; priceForCheckTakeOrder -= spread;
      }
      
      if (!CheckAndCorrectStopLoss(request.m_cmd, priceForCheckStopOrder, minstoplevel, stoplossCorrect, request.m_stoploss, request.m_error))     return false;
      if (!CheckAndCorrectTakeProfit(request.m_cmd, priceForCheckTakeOrder, minstoplevel, stoplossCorrect, request.m_stoploss, request.m_error))   return false;
      
      return true;
   }
   
   static bool CheckAndCorrectRequest(MQLRequestClose& request, string orderSymbol, int orderCmd, double orderLots, bool requestPriceCorrect, bool requestVolumeCorrect)
   {
      double point = SymbolInfoDouble(orderSymbol, SYMBOL_POINT);
      double minstoplevel = SymbolInfoInteger(orderSymbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
      double ask = MarketInfo(orderSymbol, MODE_ASK);
      double bid = MarketInfo(orderSymbol, MODE_BID);
      
      if (!CheckAndCorrectPrice(orderCmd, ask, bid, minstoplevel, requestPriceCorrect, request.m_price, request.m_error)) return false;
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

public:
   static bool OpenOrder(const MQLRequestOpen& request, MQLOrder& responce, MQLRequestOpen& requestTry[], int countTryLimit = 5, bool requestPriceCorrect = true, bool stoplossCorrect = true, bool takeprofitCorrect = true)
   {
      ulong timeOpenPosition = GetMicrosecondCount(); Print(__FUNCTION__, ": Start");
      bool criticalError = false; int ticket = -1;
      bool result = false;
      
      do
      {
         int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
         requestTry[index].Init(request);
         
         if (!CheckAndCorrectRequest(requestTry[index], requestPriceCorrect, stoplossCorrect, takeprofitCorrect)) break;
         
         int digits = SymbolInfoInteger(requestTry[index].m_symbol, SYMBOL_DIGITS);
         
         ulong timeExecution = GetMicrosecondCount();
         
         ticket = OrderSend(requestTry[index].m_symbol,
                            requestTry[index].m_cmd,
                            NormalizeDouble(requestTry[index].m_volume, 2),
                            NormalizeDouble(requestTry[index].m_price, digits),
                            requestTry[index].m_slippage,
                            NormalizeDouble(requestTry[index].m_stoploss, digits),
                            NormalizeDouble(requestTry[index].m_takeprofit, digits),
                            requestTry[index].m_comment,
                            requestTry[index].m_magic,
                            requestTry[index].m_expiration,
                            requestTry[index].m_arrow_color);
         
         timeExecution = (GetMicrosecondCount() - timeExecution);
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
            responce.Init(requestTry[index]);
            responce.m_ticket = ticket;
            responce.m_price = OrderOpenPrice();
            
            double _slippage = 0;
            if (responce.m_cmd == OP_BUY || responce.m_cmd == OP_BUYLIMIT || responce.m_cmd == OP_BUYSTOP)
            {
               _slippage = requestTry[index].m_price - responce.m_price;
            }
            else  _slippage = responce.m_price - requestTry[index].m_price;
            
            Print(__FUNCTION__, ": OK; ticket #", responce.m_ticket, "; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds;", " Request price: ", DoubleToString(requestTry[index].m_price, digits), "; Execution Price: ", DoubleToString(responce.m_price, digits), "; Slippage: ", DoubleToString(_slippage, digits));
            result = true;
         }
      }
      while(!criticalError && ticket < 0 && countTryLimit > 0);
      
      timeOpenPosition = (GetMicrosecondCount() - timeOpenPosition);
      Print(__FUNCTION__, ": End; time: ", DoubleToString(timeOpenPosition / 1000, 3), " milliseconds");
      
      return result;
   }
   
   static bool CloseOrDeleteOrder(const MQLRequestClose& request, MQLRequestClose& requestTry[], int countTryLimit = 5, bool requestPriceCorrect = true, bool requestVolumeCorrect = true)
   {
      ulong timeOpenPosition = GetMicrosecondCount(); Print(__FUNCTION__, ": Start");
      ulong timeExecution = 0; string error_description = NULL;
      
      bool result = false;
      if (OrderSelect(request.m_ticket, SELECT_BY_TICKET))
      {
         int type = OrderType();
         if (type == OP_BUY || type == OP_SELL)
         {
            if (request.m_opposite > 0)
            {
               int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
               requestTry[index].Init(request);
               
               timeExecution = GetMicrosecondCount();
               result = OrderCloseBy(request.m_ticket, request.m_opposite, request.m_arraow_color);
               timeExecution = (GetMicrosecondCount() - timeExecution);
               
               if (result)
               {
                  Print(__FUNCTION__, ": Order #", request.m_ticket, " closed by #", request.m_opposite, "; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
               }
               else
               {
                  requestTry[index].m_error = GetLastError();
                  error_description = ErrorDescription(request.m_error);
                  Print(__FUNCTION__, ": Order #", request.m_ticket, " not closed by #", request.m_opposite, "; error code: ", request.m_error, " - '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
               }
               
            }
            else
            {
               bool criticalError = false;
               do
               {
                  int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
                  requestTry[index].Init(request);
                  
                  if (!CheckAndCorrectRequest(requestTry[index], OrderSymbol(), OrderType(), OrderLots(), true, true))   break;
                  
                  timeExecution = GetMicrosecondCount();
                  result = OrderClose(requestTry[index].m_ticket, requestTry[index].m_lots, requestTry[index].m_price, requestTry[index].m_slippage, requestTry[index].m_arraow_color);
                  timeExecution = (GetMicrosecondCount() - timeExecution);
                  
                  countTryLimit--;
                  if (result)
                  {
                     Print(__FUNCTION__, ": Order #", requestTry[index].m_ticket, " closed; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
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
                        case ERR_INVALID_STOPS:
                        case ERR_PRICE_CHANGED:
                        case ERR_OFF_QUOTES:
                        case ERR_REQUOTE: criticalError = false; break;
                        default: criticalError = true;
                     }
                     result = false;
                  }
               }
               while(!criticalError && !result && countTryLimit > 0);
            }
         }
         else
         {
            int index = ArrayResize(requestTry, ArraySize(requestTry) + 1) - 1;
            requestTry[index].Init(request);
            
            timeExecution = GetMicrosecondCount();
            result = OrderDelete(request.m_ticket, request.m_arraow_color);
            timeExecution = (GetMicrosecondCount() - timeExecution);
            
            if (result)
            {
               Print(__FUNCTION__, ": Order #", request.m_ticket, " deleted; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
               result = true;
            }
            else
            {
               requestTry[index].m_error = GetLastError();
               error_description = ErrorDescription(request.m_error);
               Print(__FUNCTION__, ": Order #", request.m_ticket, " not deleted; error code: ", request.m_error, " - '", error_description, "'; execution time: ", DoubleToString(timeExecution / 1000, 3), " milliseconds");
               result = false;
            }
         }
      }
      else
      {
         Print(__FUNCTION__, ": order #", request.m_ticket, " not found");
         result = false;
      }
      
      timeOpenPosition = (GetMicrosecondCount() - timeOpenPosition);
      Print(__FUNCTION__, ": End; time: ", DoubleToString(timeOpenPosition / 1000, 3), " milliseconds");
      return result;
   }
};