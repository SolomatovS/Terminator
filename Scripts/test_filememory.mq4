//+------------------------------------------------------------------+
//|                                              test_filememory.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Exchange.mqh>

FileMemory* File;
string Name = "lohovozka";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   File = new FileMemory(Name);
   
   MqlTick value_string;
   SymbolInfoTick(Symbol(), value_string);
   MqlTick value_string_read;
   uchar value[];
   //StringToCharArray(value_string, value);
   do
   {
      if (File.Write(value_string))
      {
         Print("write: ", value_string.ask, ", ", value_string.bid);
      }
      else break;
   }
   while(!File.IsEnding());
   File.Grow(10);
   File.Seek(0);
   do
   {
      if (File.Read(value_string_read))
      {
         Print("read = ", value_string_read.ask, value_string_read.bid);      
      }
   }
   while(!File.IsEnding());
   delete File;
}
//+------------------------------------------------------------------+
