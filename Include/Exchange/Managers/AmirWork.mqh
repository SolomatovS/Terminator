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
bool bInit; // вход в псевдофункцию инит
int nAccuracy; // добавляет ноль для расчетов на 4-ех значных брокерах
int nDigits; // собственный Digits чтобы обрезать double числа

int nMinutesStopTrade = 5; // количество минут, пока цена актуальна. Если выключится интернет/соединение с сервером - советник не будет воспринимать цены. Демо функция
int nMinutesToClose = 20;  // количество минут, после которых советник может начать закрывать открытые ордера (служит маскировкой торговли на задержках)
double dLots = 0.01;       // объем торговых операций
int nTakeProfit = 10;      // потенциальный профит от открытия позиций на задержке
int nCloseProfit = 10;     // потенциальный профит от закрытия позиций на задержке
bool bOpenOrders = true;   // вкл/выкл возможность торговли (перед новостями/выходными)
bool bCloseOrders = true;  // вкл/выкл возможность закрытия ордеров (перед новостями/выходными)
int nMaxOrders = 999;      // максимальное количество ордеров в одном направлении (если депо небольшое/хотим ограничить сетку ордеров)
bool bMadeLyingComment = true; // вкл/выкл создания псевдо комментария
string sTextLyingComment = "Intraday Trend Scalper"; // позиционируем ТС как "Внутридневной Трендовый Скальпер"

class Amir : Manager
{
public:
   Amir(AMIR& amir) : Manager(amir.m_enabler)
   {
      
   }
protected:
   virtual void VWork(SData& datas[], int index)
   {
      if(!bInit) // подобие функции инит
      {  // добавление нуля для работы с 5-ти значным котированием на 4-ех значных брокерах
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
         bInit = true; // выключение функции инит
      }
      // ArraySize(datas) - означает массив количества торговых териналов, на которых работает советник 
      // index - это свой терминал, его он не будет проверять
      string sTextToComment = OrdersTotal()+ " ордер(ов). Последняя успешная синхронизация: " + TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS) + "\n";
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
      if(alien.TimeOutQuote * 0.000001 < nMinutesStopTrade*60 && his.TimeOutQuote * 0.000001 < nMinutesStopTrade*60) // устранение ошибки "пустых цен". Если цена не обновлялась тут и у другого брокера более 3 минут - не считать их актуальными
      {  // расчет пунктов задержки вниз и вверх
         int nDelayDown = (his.MQLTick.bid - alien.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
         int nDelayUp = (alien.MQLTick.bid - his.MQLTick.ask - (alien.MQLTick.ask - alien.MQLTick.bid))/Point*nAccuracy;
         
         // зареджка вниз у текущего брокера, ситуация "SELL[0]-BUY[1]"
         if(his.TimeOutQuote > 0 && nDelayDown >= nCloseProfit && TimeLocal() >= tbTimeAlertDown[nNumberBroker]) 
         {
            if(ThereAreOrdersToClose(0, his.MQLTick.bid, Symbol()))
            {
               Print("=============================================================");
               Print("Секунды актуальных цен: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
               Print("Расстояние тика = ", IntegerToString(nDelayUp));
               Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вниз ", IntegerToString(nDelayDown),
                     " пунктов, ситуация CLOSE BUY[", DoubleToString(his.MQLTick.bid,5),"]-CLOSE SELL[", DoubleToString(alien.MQLTick.ask,5),"]");
               Print("===  Закрытие позиции CLOSE BUY и хеджирующей CLOSE SELL ====");
            }
            else
            {
               if(nDelayDown >= nTakeProfit)
               {
                  Print("=============================================================");
                  if(bOpenOrders && GetOpenOrders(1, Symbol()) <= nMaxOrders) OpenMarketOrder(1, his.MQLTick.bid); // если у текущего брокера задержка, a у второго актуальные цены - открываем ордер
                  tbTimeAlertDown[nNumberBroker] = TimeLocal() + 60; // записываем время, чтобы срабатывать не чаще 1 раза в 1 минуту
                  Print("Секунды актуальных цен: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
                  Print("Время когда была последняя задержка = ", TimeToString(tbTimeAlertDown[nNumberBroker],TIME_DATE|TIME_SECONDS));
                  Print("Расстояние тика = ", IntegerToString(nDelayDown));
                  Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вниз ", IntegerToString(nDelayDown),
                        " пунктов, ситуация SELL[", DoubleToString(his.MQLTick.bid,5),"]-BUY[", DoubleToString(alien.MQLTick.ask,5),"]");
                  Print("===  Открытие позиции SELL и хеджирование BUY ===============");
               }
            }
         }
         
         // зареджка вверх у текущего брокера, ситуация "BUY[0]-SELL[1]"
         if(his.TimeOutQuote > 0 && nDelayUp >= nCloseProfit && TimeLocal() >= tbTimeAlertUp[nNumberBroker]) 
         {
            if(ThereAreOrdersToClose(1, his.MQLTick.ask, Symbol()))
            {
               Print("=============================================================");
               Print("Секунды актуальных цен: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
               Print("Расстояние тика = ", IntegerToString(nDelayUp));
               Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вниз ", IntegerToString(nDelayDown),
                     " пунктов, ситуация CLOSE SELL[", DoubleToString(his.MQLTick.ask,5),"]-CLOSE BUY[", DoubleToString(alien.MQLTick.bid,5),"]");
               Print("===  Закрытие позиции CLOSE SELL и хеджирующей CLOSE BUY ====");
            }
            else
            {
               if(nDelayUp >= nTakeProfit)
               {
                  Print("=============================================================");
                  if(bOpenOrders && GetOpenOrders(0, Symbol()) <= nMaxOrders) OpenMarketOrder(0, his.MQLTick.ask); // если у текущего брокера задержка, a у второго актуальные цены - открываем ордер
                  tbTimeAlertUp[nNumberBroker] = TimeLocal() + 60; // записываем время, чтобы срабатывать не чаще 1 раза в 1 минуту
                  Print("Секунды актуальных цен: , his.TimeOutQuote = ", DoubleToString(his.TimeOutQuote * 0.000001, 1), " sec. alien.TimeOutQuote = ", DoubleToString(alien.TimeOutQuote * 0.000001, 1), " sec.");
                  Print("Время когда была последняя задержка = ", TimeToString(tbTimeAlertUp[nNumberBroker],TIME_DATE|TIME_SECONDS));
                  Print("Расстояние тика = ", IntegerToString(nDelayUp));
                  Print(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), " - ", CharArrayToString(alien.Terminal.Company), ", зареджка вверх ", IntegerToString(nDelayUp),
                        " пунктов, ситуация BUY[", DoubleToString(his.MQLTick.ask,5),"]-SELL[", DoubleToString(alien.MQLTick.bid,5),"]");
                  Print("===  Открытие позиции BUY и хеджирование SELL ===============");
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
      sTextToComment = StringConcatenate(DoubleToStr(alien.MQLTick.bid,nDigits), "/", DoubleToStr(alien.MQLTick.ask,nDigits), ". Вниз " , IntegerToString(nDelayDown) , ", вверх " , IntegerToString(nDelayUp) , ". " , CharArrayToString(alien.Terminal.Company) , ". " , DoubleToString(alien.TimeOutQuote * 0.000001, 1) , " sec." , "\n");
      return(sTextToComment);
   }
//+------------------------------------------------------------------+
//| Подсчет количества открытых ордеров                              |
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
//| Создание комментария для ордера                                  |
//+------------------------------------------------------------------+
string CreateCommentForOrder()
{
   if(bMadeLyingComment) return(sTextLyingComment);
   else return("");
}
//+------------------------------------------------------------------+
//| Закрытие ордеров по обратному сигналу                            |
//+------------------------------------------------------------------+
bool ThereAreOrdersToClose(int nTypeClose, double dPriceClose, string sSymbolFind)
{
   bool bReturn = false; // переменная с итогом работы данной функции
   // пробегаемся по всем открытым ордерам
   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderType() == nTypeClose && OrderSymbol() == sSymbolFind) // если тип ордера и символ нужный для закрытия...
      {  // ... разрешено закрывать ордера и прошло уже больше N минут с момента открытия
         if(bCloseOrders && (TimeCurrent()-OrderOpenTime())/60 >= nMinutesToClose) 
         {  // в случае успеха закрытия итог работы функции будет "успех", иначе принтанем ошибку
            if(OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(dPriceClose,Digits), 0, Green)) bReturn = true;
            else
            {
               Print("Ошибка закрытия ордера ", OrderTicket(), ", ошибка: " + ErrorInformation(GetLastError()));
               break;
            }
         }
         else Print("При закрытии ордера ", nMinutesToClose, " минут не прошло!");
      }
   }
   // в случае если будет несколько ордеров на закрытие и если хоть один будет успешно закрыт - функция вернет "успех"
   return(bReturn);
}
//+------------------------------------------------------------------+
//| Функция открытия ордера                                          |
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
        default: Print("Не верный тип рыночного ордера!");
     }

     int nTicket = OrderSend(Symbol(), nType, dLots, dPriceOpen, 0, 0, 0, CreateCommentForOrder(), 0, 0, cColorOpen);
     if(nTicket != -1) break; //если открытие произошло успешно, наносим графический объект и выходим из цикла
     else
     {
        nError = GetLastError();
        if(nError != 0) Print("Ошибка открытия ордера: " + ErrorInformation(nError));
        i++;
        Sleep(1000); //в случае ошибки делаем паузу перед новой попыткой
     }
  }
}
//+------------------------------------------------------------------+
//| Расшифровка ошибок при открытии / модицифкации ордера            |
//+------------------------------------------------------------------+
string ErrorInformation(int nError)
{/* функция охватывает только коды ошибок торговых операций */
   switch(nError)
   {
      case(0):   return("Нет ошибки!");
      case(1):   return("Нет ошибки, но результат неизвестен!");
      case(2):   return("Общая ошибка!");
      case(3):   return("Неправильные параметры!");
      case(4):   return("Торговый сервер занят!");
      case(5):   return("Старая версия клиентского терминала!");
      case(6):   return("Нет связи с торговым сервером!");
      case(7):   return("Недостаточно прав!");
      case(8):   return("Слишком частые запросы!");
      case(9):   return("Недопустимая операция нарушающая функционирование сервера!");
      case(64):  return("Счет заблокирован!");
      case(65):  return("Неправильный номер счета!");
      case(128): return("Истек срок ожидания совершения сделки!");
      case(129): return("Неправильная цена!");
      case(130): return("Неправильные стопы!");
      case(131): return("Неправильный объём!");
      case(132): return("Рынок закрыт!");
      case(133): return("Торговля запрещена!");
      case(134): return("Недостаточно денег для совершения операции!");
      case(135): return("Цена изменилась!");
      case(136): return("Нет цен!");
      case(137): return("Брокер занят!");
      case(138): return("Новые цены!");
      case(139): return("Ордер заблокирован и уже обрабатывается!");
      case(140): return("Разрешена только покупка!");
      case(141): return("Слишком много запросов!");
      case(145): return("Модификация запрещена, т.к. ордер слишком близок к рынку!");
      case(146): return("Подсистема торговли занята!");
      case(147): return("Использование даты истечения запрещено брокером!");
      case(148): return("Количество открытых и отложенных ордеров достигло предела, установленного брокером!");
      case(149): return("Попытка открыть противоположную позицию к уже существующей в случае, если хеджирование запрещено!");
      case(150): return("Попытка закрыть позицию по инструменту в противоречии с правилом FIFO!");
      // коды обработки программы   
      case(4000): return("Нет ошибки");
      case(4001): return("Неправильный указатель функции");
      case(4002): return("Индекс массива - вне диапазона");
      case(4003): return("Нет памяти для стека функций");
      case(4004): return("Переполнение стека после рекурсивного вызова");
      case(4005): return("На стеке нет памяти для передачи параметров");
      case(4006): return("Нет памяти для строкового параметра");
      case(4007): return("Нет памяти для временной строки");
      case(4008): return("Неинициализированная строка");
      case(4009): return("Неинициализированная строка в массиве");
      case(4010): return("Нет памяти для строкового массива");
      case(4011): return("Слишком длинная строка");
      case(4012): return("Остаток от деления на ноль");
      case(4013): return("Деление на ноль");
      case(4014): return("Неизвестная команда");
      case(4015): return("Неправильный переход");
      case(4016): return("Неинициализированный массив");
      case(4017): return("Вызовы DLL не разрешены");
      case(4018): return("Невозможно загрузить библиотеку");
      case(4019): return("Невозможно вызвать функцию");
      case(4020): return("Вызовы внешних библиотечных функций не разрешены");
      case(4021): return("Недостаточно памяти для строки, возвращаемой из функции");
      case(4022): return("Система занята");
      case(4050): return("Неправильное количество параметров функции");
      case(4051): return("Недопустимое значение параметра функции");
      case(4052): return("Внутренняя ошибка строковой функции");
      case(4053): return("Ошибка массива");
      case(4054): return("Неправильное использование массива-таймсерии");
      case(4055): return("Ошибка пользовательского индикатора");
      case(4056): return("Массивы несовместимы");
      case(4057): return("Ошибка обработки глобальныех переменных");
      case(4058): return("Глобальная переменная не обнаружена");
      case(4059): return("Функция не разрешена в тестовом режиме");
      case(4060): return("Функция не подтверждена");
      case(4061): return("Ошибка отправки почты");
      case(4062): return("Ожидается параметр типа string");
      case(4063): return("Ожидается параметр типа integer");
      case(4064): return("Ожидается параметр типа double");
      case(4065): return("В качестве параметра ожидается массив");
      case(4066): return("Запрошенные исторические данные в состоянии обновления");
      case(4067): return("Ошибка при выполнении торговой операции");
      case(4099): return("Конец файла");
      case(4100): return("Ошибка при работе с файлом");
      case(4101): return("Неправильное имя файла");
      case(4102): return("Слишком много открытых файлов");
      case(4103): return("Невозможно открыть файл");
      case(4104): return("Несовместимый режим доступа к файлу");
      case(4105): return("Ни один ордер не выбран");
      case(4106): return("Неизвестный символ");
      case(4107): return("Неправильный параметр цены для торговой функции");
      case(4108): return("Неверный номер тикета");
      case(4109): return("Торговля не разрешена");
      case(4110): return("Длинные позиции не разрешены");
      case(4111): return("Короткие позиции не разрешены");
      case(4200): return("Объект уже существует");
      case(4201): return("Запрошено неизвестное свойство объекта");
      case(4202): return("Объект не существует");
      case(4203): return("Неизвестный тип объекта");
      case(4204): return("Нет имени объекта");
      case(4205): return("Ошибка координат объекта");
      case(4206): return("Не найдено указанное подокно");
      case(4207): return("Ошибка при работе с объектом");

      default:   return("Не известная ошибка!");
   }
}
//+------------------------------------------------------------------+
};