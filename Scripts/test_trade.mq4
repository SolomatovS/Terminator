//+------------------------------------------------------------------+
//|                                                   test_trade.mq4 |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property version   "1.00"
#property strict

#include <Exchange\Trade.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Asset* asset = new Asset();
   
   asset.CheckIncorrectPriceRequest();
   
   delete asset;
   
   Comment(IsTradeAllowed(Symbol(), TimeCurrent()));
}
//+------------------------------------------------------------------+

class Asset
{
   Trade trade;
   MQLRequestOpen request;
   MQLRequestOpen try[];
   MQLOrder       response;
   int try_count;
   bool requestVolumeCorrect;
   bool requestPriceCorrect;
   bool requestStopLossCorrect;
   bool requestTakeProfitCorrect;

public:
   bool CheckIncorrectPriceRequest()
   {
      request.m_symbol = Symbol();
      request.m_cmd = OP_BUY;
      request.m_volume = 0.00;
      try_count = 5;
      requestVolumeCorrect = true; requestPriceCorrect = true; requestStopLossCorrect = true; requestTakeProfitCorrect = true;
      
      SymbolInfoTick(request.m_symbol, request.m_tick);
      request.m_price = 0;
      
      bool result = trade.OpenOrder(request, response, try, try_count, requestVolumeCorrect, requestPriceCorrect, requestStopLossCorrect, requestTakeProfitCorrect);
      
      if (result)
      {
         Comment("ticket: ", response.m_ticket);
      }
      else
      {
         string text = NULL;
         for(int i = 0; i < ArraySize(try); i++)
         {
            text = "error: " + try[i].m_error + "\n";
         }
         Comment(text);
      }
      
      return result;
   }
};