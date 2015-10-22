//+------------------------------------------------------------------+
//|                                                     AmirWork.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include "Manager.mqh"
// ���������� ����������
datetime tbTimeAlertUp[30], tbTimeAlertDown[30];
int nPriceDown1, nPriceDown2, nPriceUp1, nPriceUp2;

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
      string sTextToComment = "��������� �������� �������������: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
      for(int i = 0; i < ArraySize(datas); i++) // ���������� ���������, ���������� � ������ � ���������� ����
      {
         if (i == index) continue;  
         
         TradeStopQuotes(datas[index], datas[i], i);
         sTextToComment += GetText(datas[index], datas[i]);
      }
      Comment(sTextToComment);
   }
   
   void TradeStopQuotes(SData& his, SData& alien, int nNumberBroker)
   {
      if(alien.TimeOutQuote * 0.000001 < 180 && his.TimeOutQuote * 0.000001 < 180) // ���������� ������ "������ ���". ���� ���� �� ����������� ��� � � ������� ������� ����� 3 ����� - �� ������� �� �����������
      {
         int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point; // ������ ������� �������� ����
         int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point; // ������ ������� �������� �����
         if(nDelayDown >= 20 && TimeLocal() >= tbTimeAlertDown[nNumberBroker]) // �������� ����, �������� "SELL[0]-BUY[1]"
         {
            if(nPriceDown1 == 0) nPriceDown1 = nDelayDown; // �������� ������ ��� ��������
            if(nPriceDown2 == 0 && nPriceDown1 != 0 && nPriceDown1 != nDelayDown) nPriceDown2 = nDelayDown; // �������� ������ ��� ��������
            if(nPriceDown1 != 0 && nPriceDown2 != 0 && nPriceDown2 != nDelayDown) // ����������� �� ������ ��� ��������
            {
               Print("������� ���������� ���: alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec. his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.");
               Print("����� ����� ���� ��������� �������� = ", TimeToString(tbTimeAlertDown[nNumberBroker],TIME_DATE|TIME_SECONDS));
               Print("���������� ������� ���� = ", IntegerToString(nPriceDown1));
               Print("���������� �������  ���� = ", IntegerToString(nPriceDown2));
               Print("���������� �������� ���� = ", IntegerToString(nDelayDown));
               // ��������� �������� �������� ��������� ���� � ��� ����
               tbTimeAlertDown[nNumberBroker] = TimeLocal() + 60; // ���������� �����, ����� ����������� �� ���� 1 ��� � 1 ������
               nPriceDown1 = 0;
               nPriceDown2 = 0;
               Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ���� ", IntegerToString(nDelayDown),
                     " �������, �������� SELL[", DoubleToString(his.MQLTick.bid,5),"]-BUY[", DoubleToString(alien.MQLTick.ask,5),"]");
            }
         }
         
         if(nDelayUp >= 20 && TimeLocal() >= tbTimeAlertUp[nNumberBroker]) // �������� �����, �������� "BUY[0]-SELL[1]"
         {
            if(nPriceUp1 == 0) nPriceUp1 = nDelayUp; // �������� ������ ��� ��������
            if(nPriceUp2 == 0 && nPriceUp1 != 0 && nPriceUp1 != nDelayUp) nPriceUp2 = nDelayUp; // �������� ������ ��� ��������
            if(nPriceUp1 != 0 && nPriceUp2 != 0 && nPriceUp2 != nDelayUp) // ����������� �� ������ ��� ��������
            {
               Print("������� ���������� ���: alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec. his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.");
               Print("����� ����� ���� ��������� �������� = ", TimeToString(tbTimeAlertUp[nNumberBroker],TIME_DATE|TIME_SECONDS));
               Print("���������� ������� ���� = ", IntegerToString(nPriceUp1));
               Print("���������� �������  ���� = ", IntegerToString(nPriceUp2));
               Print("���������� �������� ���� = ", IntegerToString(nDelayUp));
               // ��������� �������� �������� ��������� �����
               tbTimeAlertUp[nNumberBroker] = TimeLocal() + 60; // ���������� �����, ����� ����������� �� ���� 1 ��� � 1 ������
               nPriceUp1 = 0;
               nPriceUp2 = 0;
               Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ����� ", IntegerToString(nDelayUp),
                     " �������, �������� BUY[", DoubleToString(his.MQLTick.ask,5),"]-SELL[", DoubleToString(alien.MQLTick.bid,5),"]");
            }
         }      
      }
   }
   string GetText(SData& his, SData& alien)
   {
      int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point;
      int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point;
      return("���� " + IntegerToString(nDelayDown) + ", ����� " + IntegerToString(nDelayUp) + ". " + CharArrayToString(alien.Terminal.Company) + ". " + DoubleToString(alien.TimeOutQuote * 0.000001, 1) + " sec." + "\n");
   }
   
};


      // ������ ���, ����� ������ ����� ������!
      /*if((his.MQLTick.bid - alien.MQLTick.ask)/Point >= 35) // �������� ����, �������� "BUY[0]-SELL[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", �������� ���� ", DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0),
            " �������, �������� BUY[", DoubleToString(his.MQLTick.bid,5),"]-SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
      if((alien.MQLTick.bid - his.MQLTick.ask)/Point >= 35) // �������� �����, �������� "SELL[0]-BUY[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", �������� ����� ", DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0),
            " �������, �������� Sell[", DoubleToString(alien.MQLTick.bid,5),"]-BUY[", DoubleToString(his.MQLTick.ask,5),"]");
      //Comment("��������� �������� �������������: ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS));*/
