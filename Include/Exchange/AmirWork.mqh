//+------------------------------------------------------------------+
//|                                                     AmirWork.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include "Manager.mqh"

class Amir : Manager
{
public:
   Amir(AMIR& amir) : Manager(amir.m_enabler)
   {
      
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      for(int i = 0; i < ArraySize(datas); i++)
      {
         if (i == index) continue;
         
         TradeStopQuotes(datas[index], datas[i]);
         /*
         if(CheckStopQuotes(datas[index], datas[i]))
         {
            Action(datas[index], datas[i]);
         }
         */
      }
   }
   
   void TradeStopQuotes(SData& his, SData& alien)
   {
      Comment(DoubleToString(his.MQLTick.bid - alien.MQLTick.bid, 5));
   }
};