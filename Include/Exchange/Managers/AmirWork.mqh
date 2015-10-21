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
      // ArraySize(datas) - означает массив количества торговых териналов, на которых работает советник 
      // index - это свой терминал, его он не будет проверять
      double dPendingProfit[30]; // создали массив с размером количества брокеров
      string sTextToComment = "Последняя успешная синхронизация: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
      for(int i = 0; i < ArraySize(datas); i++) // перебираем терминалы, записанные в массив и сравниваем цены
      {
         if (i == index) continue;  
         
         TradeStopQuotes(datas[index], datas[i]);
         sTextToComment += GetText(datas[index], datas[i]);
      }
      Comment(sTextToComment);
   }
   
   void TradeStopQuotes(SData& his, SData& alien)
   {
      // Три пункта, которые необходимо реализовать:
      // 1) открытие на задержке котировки (ранее было закрытие)
      // 2) фильтрация входа в рынок по 3-ем котировкам в задержке (исключать моменты резких прорыров цены в область задержки)
      // 3) фильтрация сигналов возникащих при перезапуске торговой платформы ("ошибка пустых цен" я ее называю)
      
      
      
      // старый код, будем кодить новую логику!
      /*if((his.MQLTick.bid - alien.MQLTick.ask)/Point >= 35) // зареджка вниз, ситуация "BUY[0]-SELL[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", зареджка вниз ", DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0),
            " пунктов, ситуация BUY[", DoubleToString(his.MQLTick.bid,5),"]-SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
      if((alien.MQLTick.bid - his.MQLTick.ask)/Point >= 35) // зареджка вверх, ситуация "SELL[0]-BUY[1]"
      Alert(CharArrayToString(alien.Terminal.Company), " - ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS), ", зареджка вверх ", DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0),
            " пунктов, ситуация Sell[", DoubleToString(alien.MQLTick.bid,5),"]-BUY[", DoubleToString(his.MQLTick.ask,5),"]");
      //Comment("Последняя успешная синхронизация: ", TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS));*/
   }
   string GetText(SData& his, SData& alien)
   {
      return("Вниз " + DoubleToString((his.MQLTick.bid - alien.MQLTick.ask)/Point, 0) + ", вверх " + DoubleToString((alien.MQLTick.bid - his.MQLTick.ask)/Point, 0) + ". " + CharArrayToString(alien.Terminal.Company) + "\n");
   }
   
};