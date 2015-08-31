//+------------------------------------------------------------------+
//|                                                 test_monitor.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include  <Exchange.mqh>

Monitor* Visor;
Monitor* Visor2;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Visor = new Monitor(StringSubstr(Symbol(), 0, 6), Symbol());
   Print(Visor.HeadToString());
   Comment(Visor.DataToString());
   
   Visor2 = new Monitor(StringSubstr(Symbol(), 0, 6), Symbol());
   Print(Visor2.HeadToString());
   Comment(Visor.DataToString() + "\n\n" + Visor2.DataToString());
   
   delete Visor;
   delete Visor2;
}
//+------------------------------------------------------------------+
