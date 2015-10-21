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
      // ArraySize(datas) - �������� ������ ���������� �������� ���������, �� ������� �������� �������� 
      // index - ��� ���� ��������, ��� �� �� ����� ���������
      double dPendingProfit[30]; // ������� ������ � �������� ���������� ��������
      string sTextToComment = "��������� �������� �������������: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
      for(int i = 0; i < ArraySize(datas); i++) // ���������� ���������, ���������� � ������ � ���������� ����
      {
         if (i == index) continue;  
         
         TradeStopQuotes(datas[index], datas[i]);
         sTextToComment += GetText(datas[index], datas[i]);
      }
      Comment(sTextToComment);
   }
   
   void TradeStopQuotes(SData& his, SData& alien)
   {
      // ��� ������, ������� ���������� �����������:
      // 1) �������� �� �������� ��������� (����� ���� ��������)
      // 2) ���������� ����� � ����� �� 3-�� ���������� � �������� (��������� ������� ������ �������� ���� � ������� ��������)
      // 3) ���������� �������� ���������� ��� ����������� �������� ��������� ("������ ������ ���" � �� �������)
      
      
      
      // ������ ���, ����� ������ ����� ������!
      /*if((his.MQLTick.bid - alien.MQLTick.ask)/Point >= 35) // �������� ����, �������� "BUY[0]-SELL[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", �������� ���� ", DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0),
            " �������, �������� BUY[", DoubleToString(his.MQLTick.bid,5),"]-SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
      if((alien.MQLTick.bid - his.MQLTick.ask)/Point >= 35) // �������� �����, �������� "SELL[0]-BUY[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", �������� ����� ", DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0),
            " �������, �������� Sell[", DoubleToString(alien.MQLTick.bid,5),"]-BUY[", DoubleToString(his.MQLTick.ask,5),"]");
      //Comment("��������� �������� �������������: ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS));*/
   }
   string GetText(SData& his, SData& alien)
   {
      return("���� " + DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0) + ", ����� " + DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0) + ". " + CharArrayToString(alien.Terminal.Company) + "\n");
   }
   
};