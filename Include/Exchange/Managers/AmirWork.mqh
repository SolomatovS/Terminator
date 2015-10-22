//+------------------------------------------------------------------+
//|                                                     AmirWork.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include "Manager.mqh"
// глобальные переменные
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
      // ArraySize(datas) - означает массив количества торговых териналов, на которых работает советник 
      // index - это свой терминал, его он не будет проверять
      string sTextToComment = "Последняя успешная синхронизация: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
      for(int i = 0; i < ArraySize(datas); i++) // перебираем терминалы, записанные в массив и сравниваем цены
      {
         if (i == index) continue;  
         
         TradeStopQuotes(datas[index], datas[i], i);
         sTextToComment += GetText(datas[index], datas[i]);
      }
      Comment(sTextToComment);
   }
   
   void TradeStopQuotes(SData& his, SData& alien, int nNumberBroker)
   {
      if(alien.TimeOutQuote * 0.000001 < 180 && his.TimeOutQuote * 0.000001 < 180) // устранение ошибки "пустых цен". Если цена не обновлялась тут и у другого брокера более 3 минут - не считать их актуальными
      {
         int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point; // расчет пунктов задержки вниз
         int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point; // расчет пунктов задержки вверх
         if(nDelayDown >= 20 && TimeLocal() >= tbTimeAlertDown[nNumberBroker]) // зареджка вниз, ситуация "SELL[0]-BUY[1]"
         {
            if(nPriceDown1 == 0) nPriceDown1 = nDelayDown; // записали первый тик задержки
            if(nPriceDown2 == 0 && nPriceDown1 != 0 && nPriceDown1 != nDelayDown) nPriceDown2 = nDelayDown; // записали второй тик задержки
            if(nPriceDown1 != 0 && nPriceDown2 != 0 && nPriceDown2 != nDelayDown) // открываемся на третий тик задержки
            {
               Print("Секунды актуальных цен: alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec. his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.");
               Print("Время когда была последняя задержка = ", TimeToString(tbTimeAlertDown[nNumberBroker],TIME_DATE|TIME_SECONDS));
               Print("Расстояние первого тика = ", IntegerToString(nPriceDown1));
               Print("Расстояние второго  тика = ", IntegerToString(nPriceDown2));
               Print("Расстояние третьего тика = ", IntegerToString(nDelayDown));
               // полностью успешная задержка котировок вниз в три тика
               tbTimeAlertDown[nNumberBroker] = TimeLocal() + 60; // записываем время, чтобы срабатывать не чаще 1 раз в 1 минуту
               nPriceDown1 = 0;
               nPriceDown2 = 0;
               Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вниз ", IntegerToString(nDelayDown),
                     " пунктов, ситуация SELL[", DoubleToString(his.MQLTick.bid,5),"]-BUY[", DoubleToString(alien.MQLTick.ask,5),"]");
            }
         }
         
         if(nDelayUp >= 20 && TimeLocal() >= tbTimeAlertUp[nNumberBroker]) // зареджка вверх, ситуация "BUY[0]-SELL[1]"
         {
            if(nPriceUp1 == 0) nPriceUp1 = nDelayUp; // записали первый тик задержки
            if(nPriceUp2 == 0 && nPriceUp1 != 0 && nPriceUp1 != nDelayUp) nPriceUp2 = nDelayUp; // записали второй тик задержки
            if(nPriceUp1 != 0 && nPriceUp2 != 0 && nPriceUp2 != nDelayUp) // открываемся на третий тик задержки
            {
               Print("Секунды актуальных цен: alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec. his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec.");
               Print("Время когда была последняя задержка = ", TimeToString(tbTimeAlertUp[nNumberBroker],TIME_DATE|TIME_SECONDS));
               Print("Расстояние первого тика = ", IntegerToString(nPriceUp1));
               Print("Расстояние второго  тика = ", IntegerToString(nPriceUp2));
               Print("Расстояние третьего тика = ", IntegerToString(nDelayUp));
               // полностью успешная задержка котировок вверх
               tbTimeAlertUp[nNumberBroker] = TimeLocal() + 60; // записываем время, чтобы срабатывать не чаще 1 раз в 1 минуту
               nPriceUp1 = 0;
               nPriceUp2 = 0;
               Alert(TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вверх ", IntegerToString(nDelayUp),
                     " пунктов, ситуация BUY[", DoubleToString(his.MQLTick.ask,5),"]-SELL[", DoubleToString(alien.MQLTick.bid,5),"]");
            }
         }      
      }
   }
   string GetText(SData& his, SData& alien)
   {
      int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point;
      int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point;
      return("Вниз " + IntegerToString(nDelayDown) + ", вверх " + IntegerToString(nDelayUp) + ". " + CharArrayToString(alien.Terminal.Company) + ". " + DoubleToString(alien.TimeOutQuote * 0.000001, 1) + " sec." + "\n");
   }
   
};


      // старый код, будем кодить новую логику!
      /*if((his.MQLTick.bid - alien.MQLTick.ask)/Point >= 35) // зареджка вниз, ситуация "BUY[0]-SELL[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", зареджка вниз ", DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0),
            " пунктов, ситуация BUY[", DoubleToString(his.MQLTick.bid,5),"]-SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
      if((alien.MQLTick.bid - his.MQLTick.ask)/Point >= 35) // зареджка вверх, ситуация "SELL[0]-BUY[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", зареджка вверх ", DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0),
            " пунктов, ситуация Sell[", DoubleToString(alien.MQLTick.bid,5),"]-BUY[", DoubleToString(his.MQLTick.ask,5),"]");
      //Comment("Последняя успешная синхронизация: ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS));*/
