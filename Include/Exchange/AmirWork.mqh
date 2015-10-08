//+------------------------------------------------------------------+
//|                                                     AmirWork.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include "Manager.mqh"

datetime tbTimeAlertUp[30], tbTimeAlertDown[30];

class Amir : Manager
{
public:
   Amir(AMIR& amir) : Manager(amir.m_enabler)
   {
      
   }
protected:
   //==========================================#
   virtual void VWork(SData& datas[], int index)
   {
      // ArraySize(datas) - �������� ������ ���������� �������� ���������, �� ������� �������� �������� 
      // index - ��� ���� ��������, ��� �� �� ����� ���������
      string sTextToComment = "��������� �������� �������������: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
      for(int i = 0; i < ArraySize(datas); i++) // ���������� ���������, ���������� � ������ � ���������� ����
      {
         if (i == index) continue;  
         
         TradeStopQuotes(datas[index], datas[i]);
         sTextToComment += GetText(datas[index], datas[i]);
      }
      Comment(sTextToComment);
   }
   
   //==========================================#
   void TradeStopQuotes(SData& his, SData& alien)
   {
      int i, c, nTotalOrders = OrdersTotal();
      if((his.MQLTick.bid - alien.MQLTick.ask)/Point >= 39) // �������� ����, �������� "BUY[0]-SELL[1]"
      {
         Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ���� ", DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0),
               " �������, �������� BUY[", DoubleToString(his.MQLTick.bid,5),"]-SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
         for(i=nTotalOrders-1; i>=0; i--)
         {
            c=0;
            if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
            {
               while(c < 5)
               {
                  RefreshRates();
                  bool bResult = false;
                  switch(OrderType())
                  {
                     case OP_BUY:  bResult = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 1, Blue); break;
                     //case OP_SELL: bResult = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 1, Red); break;
                     default:      bResult = true;
                  }
                  if(!bResult)
                  {
                     c++;
                     Print("������ �������� ������ ", OrderTicket());
                     Sleep(100);
                  }else break;
               }
            }
         }
      }
      
      if((alien.MQLTick.bid - his.MQLTick.ask)/Point >= 39) // �������� �����, �������� "SELL[0]-BUY[1]"
      {
         Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ����� ", DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0),
               " �������, �������� Sell[", DoubleToString(alien.MQLTick.bid,5),"]-BUY[", DoubleToString(his.MQLTick.ask,5),"]");
         for(i=nTotalOrders-1; i>=0; i--)
         {
            c=0;
            if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
            {
               while(c < 5)
               {
                  RefreshRates();
                  bool bResult = false;
                  switch(OrderType())
                  {
                     //case OP_BUY:  bResult = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 1, Blue); break;
                     case OP_SELL: bResult = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 1, Red); break;
                     default:      bResult = true;
                  }
                  if(!bResult)
                  {
                     c++;
                     Print("������ �������� ������ ", OrderTicket());
                     Sleep(100);
                  }else break;
               }
            }
         }
      }
   }
   //==========================================#
   string GetText(SData& his, SData& alien)
   {
      return("���� " + DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0) + ", ����� " + DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0) + ". " + CharArrayToString(alien.Terminal.Company) + "\n");
   }
};