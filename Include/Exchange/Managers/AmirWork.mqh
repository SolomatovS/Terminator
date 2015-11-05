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
bool bInit; // ���� � ������������� ����
int nAccuracy; // ��������� ���� ��� �������� �� 4-�� ������� ��������
int nDigits; // ����������� Digits ����� �������� double �����

int nMinutesStopTrade = 5; // ���������� �����, ���� ���� ���������. ���� ���������� ��������/���������� � �������� - �������� �� ����� ������������ ����. ���� �������
int nMinutesToClose = 20;  // ���������� �����, ����� ������� �������� ����� ������ ��������� �������� ������ (������ ����������� �������� �� ���������)
double dLots = 0.01;       // ����� �������� ��������
int nTakeProfit = 10;      // ������������� ������ �� �������� ������� �� ��������
int nCloseProfit = 10;     // ������������� ������ �� �������� ������� �� ��������
bool bOpenOrders = true;   // ���/���� ����������� �������� (����� ���������/���������)
bool bCloseOrders = true;  // ���/���� ����������� �������� ������� (����� ���������/���������)
int nMaxOrders = 999;      // ������������ ���������� ������� � ����� ����������� (���� ���� ���������/����� ���������� ����� �������)
bool bMadeLyingComment = true; // ���/���� �������� ������ �����������
string sTextLyingComment = "Intraday Trend Scalper"; // ������������� �� ��� "������������� ��������� ��������"

class Amir : Manager
{
public:
   Amir(AMIR& amir) : Manager(amir.m_enabler)
   {
      
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      if(!bInit) // ������� ������� ����
      {  // ���������� ���� ��� ������ � 5-�� ������� ������������ �� 4-�� ������� ��������
         if(Point == 0.00001 || Point == 0.001) 
         {
            nAccuracy = 1;
            nDigits = 4; 
         }
         else 
         {
            nAccuracy = 10;
            nDigits = 5;
         }
         bInit = true; // ���������� ������� ����
      }
      // ArraySize(datas) - �������� ������ ���������� �������� ���������, �� ������� �������� �������� 
      // index - ��� ���� ��������, ��� �� �� ����� ���������
      string sTextToComment = OrdersTotal()+ " �����(��). ��������� �������� �������������: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
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
      if(alien.TimeOutQuote * 0.000001 < nMinutesStopTrade*60 && his.TimeOutQuote * 0.000001 < nMinutesStopTrade*60) // ���������� ������ "������ ���". ���� ���� �� ����������� ��� � � ������� ������� ����� 3 ����� - �� ������� �� �����������
      {  // ������ ������� �������� ���� � �����
         int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
         int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
         
         // �������� ���� � �������� �������, �������� "SELL[0]-BUY[1]"
         if(his.TimeOutQuote > 0 && nDelayDown >= nCloseProfit && TimeLocal() >= tbTimeAlertDown[nNumberBroker]) 
         {
            if(ThereAreOrdersToClose(0, his.MQLTick.bid, Symbol()))
            {
               Print("=============================================================");
               Print("������� ���������� ���: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
               Print("���������� ���� = ", IntegerToString(nDelayUp));
               Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ���� ", IntegerToString(nDelayDown),
                     " �������, �������� CLOSE BUY[", DoubleToString(his.MQLTick.bid,5),"]-CLOSE SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
               Print("===  �������� ������� CLOSE BUY � ����������� CLOSE SELL ====");
            }
            else
            {
               if(nDelayDown >= nTakeProfit)
               {
                  Print("=============================================================");
                  if(bOpenOrders && GetOpenOrders(1, Symbol()) <= nMaxOrders) OpenMarketOrder(1, his.MQLTick.bid); // ���� � �������� ������� ��������, a � ������� ���������� ���� - ��������� �����
                  tbTimeAlertDown[nNumberBroker] = TimeLocal() + 60; // ���������� �����, ����� ����������� �� ���� 1 ���� � 1 ������
                  Print("������� ���������� ���: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
                  Print("����� ����� ���� ��������� �������� = ", TimeToString(tbTimeAlertDown[nNumberBroker],TIME_DATE|TIME_SECONDS));
                  Print("���������� ���� = ", IntegerToString(nDelayDown));
                  Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ���� ", IntegerToString(nDelayDown),
                        " �������, �������� SELL[", DoubleToString(his.MQLTick.bid,5),"]-BUY[", DoubleToString(alien.MQLTick.ask,5),"]");
                  Print("===  �������� ������� SELL � ������������ BUY ===============");
               }
            }
         }
         
         // �������� ����� � �������� �������, �������� "BUY[0]-SELL[1]"
         if(his.TimeOutQuote > 0 && nDelayUp >= nCloseProfit && TimeLocal() >= tbTimeAlertUp[nNumberBroker]) 
         {
            if(ThereAreOrdersToClose(1, his.MQLTick.ask, Symbol()))
            {
               Print("=============================================================");
               Print("������� ���������� ���: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
               Print("���������� ���� = ", IntegerToString(nDelayUp));
               Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ���� ", IntegerToString(nDelayDown),
                     " �������, �������� CLOSE SELL[", DoubleToString(his.MQLTick.ask,5),"]-CLOSE BUY[", DoubleToString(alien.MQLTick.bid,5),"]");
               Print("===  �������� ������� CLOSE SELL � ����������� CLOSE BUY ====");
            }
            else
            {
               if(nDelayUp >= nTakeProfit)
               {
                  Print("=============================================================");
                  if(bOpenOrders && GetOpenOrders(0, Symbol()) <= nMaxOrders) OpenMarketOrder(0, his.MQLTick.ask); // ���� � �������� ������� ��������, a � ������� ���������� ���� - ��������� �����
                  tbTimeAlertUp[nNumberBroker] = TimeLocal() + 60; // ���������� �����, ����� ����������� �� ���� 1 ���� � 1 ������
                  Print("������� ���������� ���: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
                  Print("����� ����� ���� ��������� �������� = ", TimeToString(tbTimeAlertUp[nNumberBroker],TIME_DATE|TIME_SECONDS));
                  Print("���������� ���� = ", IntegerToString(nDelayUp));
                  Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", �������� ����� ", IntegerToString(nDelayUp),
                        " �������, �������� BUY[", DoubleToString(his.MQLTick.ask,5),"]-SELL[", DoubleToString(alien.MQLTick.bid,5),"]");
                  Print("===  �������� ������� BUY � ������������ SELL ===============");
               }
            }
         }      
      }
   }
   string GetText(SData& his, SData& alien)
   {
      string sTextToComment;
      int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
      int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
      sTextToComment = StringConcatenate(DoubleToStr(alien.MQLTick.bid,nDigits), "/", DoubleToStr(alien.MQLTick.ask,nDigits), ". ���� " , IntegerToString(nDelayDown) , ", ����� " , IntegerToString(nDelayUp) , ". " , CharArrayToString(alien.Terminal.Company) , ". " , DoubleToString(alien.TimeOutQuote * 0.000001, 1) , " sec." , "\n");
      return(sTextToComment);
   }
//+------------------------------------------------------------------+
//| ������� ���������� �������� �������                              |
//+------------------------------------------------------------------+
int GetOpenOrders(int nTypeOrder, string sSymbolFind)
{
   int i, nMarketOrders;
    
   for(i=0; i<OrdersTotal(); i++)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType() == nTypeOrder && OrderSymbol() == sSymbolFind) nMarketOrders++;
   }
   
   return(nMarketOrders);
}
//+------------------------------------------------------------------+
//| �������� ����������� ��� ������                                  |
//+------------------------------------------------------------------+
string CreateCommentForOrder()
{
   if(bMadeLyingComment) return(sTextLyingComment);
   else return("");
}
//+------------------------------------------------------------------+
//| �������� ������� �� ��������� �������                            |
//+------------------------------------------------------------------+
bool ThereAreOrdersToClose(int nTypeClose, double dPriceClose, string sSymbolFind)
{
   bool bReturn = false; // ���������� � ������ ������ ������ �������
   // ����������� �� ���� �������� �������
   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType() == nTypeClose && OrderSymbol() == sSymbolFind) // ���� ��� ������ � ������ ������ ��� ��������...
      {  // ... ��������� ��������� ������ � ������ ��� ������ N ����� � ������� ��������
         if(bCloseOrders && (TimeCurrent()-OrderOpenTime())/60 >= nMinutesToClose) 
         {  // � ������ ������ �������� ���� ������ ������� ����� "�����", ����� ��������� ������
            if(OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(dPriceClose,Digits), 0, Green)) bReturn = true;
            else
            {
               Print("������ �������� ������ ", OrderTicket(), ", ������: " + ErrorInformation(GetLastError()));
               break;
            }
         }
         else Print("��� �������� ������ ", nMinutesToClose, " ����� �� ������!");
      }
   }
   // � ������ ���� ����� ��������� ������� �� �������� � ���� ���� ���� ����� ������� ������ - ������� ������ "�����"
   return(bReturn);
}
//+------------------------------------------------------------------+
//| ������� �������� ������                                          |
//+------------------------------------------------------------------+
void OpenMarketOrder(int nType, double dPriceOrder)
{
  int nError = 0;
  double dPriceOpen;
  color cColorOpen;
  int i = 0;
  
  while(i < 1)
  {
     switch(nType)
     {
        case 0:
           dPriceOpen = NormalizeDouble(dPriceOrder, Digits);
           cColorOpen = Blue;
           break;
        case 1:
           dPriceOpen = NormalizeDouble(dPriceOrder, Digits);
           cColorOpen = Red;
           break;
        default: Print("�� ������ ��� ��������� ������!");
     }

     int nTicket = OrderSend(Symbol(), nType, dLots, dPriceOpen, 0, 0, 0, CreateCommentForOrder(), 0, 0, cColorOpen);
     if(nTicket != -1) break; //���� �������� ��������� �������, ������� ����������� ������ � ������� �� �����
     else
     {
        nError = GetLastError();
        if(nError != 0) Print("������ �������� ������: " + ErrorInformation(nError));
        i++;
        Sleep(1000); //� ������ ������ ������ ����� ����� ����� ��������
     }
  }
}
//+------------------------------------------------------------------+
//| ����������� ������ ��� �������� / ������������ ������            |
//+------------------------------------------------------------------+
string ErrorInformation(int nError)
{/* ������� ���������� ������ ���� ������ �������� �������� */
   switch(nError)
   {
      case(0):   return("��� ������!");
      case(1):   return("��� ������, �� ��������� ����������!");
      case(2):   return("����� ������!");
      case(3):   return("������������ ���������!");
      case(4):   return("�������� ������ �����!");
      case(5):   return("������ ������ ����������� ���������!");
      case(6):   return("��� ����� � �������� ��������!");
      case(7):   return("������������ ����!");
      case(8):   return("������� ������ �������!");
      case(9):   return("������������ �������� ���������� ���������������� �������!");
      case(64):  return("���� ������������!");
      case(65):  return("������������ ����� �����!");
      case(128): return("����� ���� �������� ���������� ������!");
      case(129): return("������������ ����!");
      case(130): return("������������ �����!");
      case(131): return("������������ �����!");
      case(132): return("����� ������!");
      case(133): return("�������� ���������!");
      case(134): return("������������ ����� ��� ���������� ��������!");
      case(135): return("���� ����������!");
      case(136): return("��� ���!");
      case(137): return("������ �����!");
      case(138): return("����� ����!");
      case(139): return("����� ������������ � ��� ��������������!");
      case(140): return("��������� ������ �������!");
      case(141): return("������� ����� ��������!");
      case(145): return("����������� ���������, �.�. ����� ������� ������ � �����!");
      case(146): return("���������� �������� ������!");
      case(147): return("������������� ���� ��������� ��������� ��������!");
      case(148): return("���������� �������� � ���������� ������� �������� �������, �������������� ��������!");
      case(149): return("������� ������� ��������������� ������� � ��� ������������ � ������, ���� ������������ ���������!");
      case(150): return("������� ������� ������� �� ����������� � ������������ � �������� FIFO!");
      // ���� ��������� ���������   
      case(4000): return("��� ������");
      case(4001): return("������������ ��������� �������");
      case(4002): return("������ ������� - ��� ���������");
      case(4003): return("��� ������ ��� ����� �������");
      case(4004): return("������������ ����� ����� ������������ ������");
      case(4005): return("�� ����� ��� ������ ��� �������� ����������");
      case(4006): return("��� ������ ��� ���������� ���������");
      case(4007): return("��� ������ ��� ��������� ������");
      case(4008): return("�������������������� ������");
      case(4009): return("�������������������� ������ � �������");
      case(4010): return("��� ������ ��� ���������� �������");
      case(4011): return("������� ������� ������");
      case(4012): return("������� �� ������� �� ����");
      case(4013): return("������� �� ����");
      case(4014): return("����������� �������");
      case(4015): return("������������ �������");
      case(4016): return("�������������������� ������");
      case(4017): return("������ DLL �� ���������");
      case(4018): return("���������� ��������� ����������");
      case(4019): return("���������� ������� �������");
      case(4020): return("������ ������� ������������ ������� �� ���������");
      case(4021): return("������������ ������ ��� ������, ������������ �� �������");
      case(4022): return("������� ������");
      case(4050): return("������������ ���������� ���������� �������");
      case(4051): return("������������ �������� ��������� �������");
      case(4052): return("���������� ������ ��������� �������");
      case(4053): return("������ �������");
      case(4054): return("������������ ������������� �������-���������");
      case(4055): return("������ ����������������� ����������");
      case(4056): return("������� ������������");
      case(4057): return("������ ��������� ����������� ����������");
      case(4058): return("���������� ���������� �� ����������");
      case(4059): return("������� �� ��������� � �������� ������");
      case(4060): return("������� �� ������������");
      case(4061): return("������ �������� �����");
      case(4062): return("��������� �������� ���� string");
      case(4063): return("��������� �������� ���� integer");
      case(4064): return("��������� �������� ���� double");
      case(4065): return("� �������� ��������� ��������� ������");
      case(4066): return("����������� ������������ ������ � ��������� ����������");
      case(4067): return("������ ��� ���������� �������� ��������");
      case(4099): return("����� �����");
      case(4100): return("������ ��� ������ � ������");
      case(4101): return("������������ ��� �����");
      case(4102): return("������� ����� �������� ������");
      case(4103): return("���������� ������� ����");
      case(4104): return("������������� ����� ������� � �����");
      case(4105): return("�� ���� ����� �� ������");
      case(4106): return("����������� ������");
      case(4107): return("������������ �������� ���� ��� �������� �������");
      case(4108): return("�������� ����� ������");
      case(4109): return("�������� �� ���������");
      case(4110): return("������� ������� �� ���������");
      case(4111): return("�������� ������� �� ���������");
      case(4200): return("������ ��� ����������");
      case(4201): return("��������� ����������� �������� �������");
      case(4202): return("������ �� ����������");
      case(4203): return("����������� ��� �������");
      case(4204): return("��� ����� �������");
      case(4205): return("������ ��������� �������");
      case(4206): return("�� ������� ��������� �������");
      case(4207): return("������ ��� ������ � ��������");

      default:   return("�� ��������� ������!");
   }
}
//+------------------------------------------------------------------+
};