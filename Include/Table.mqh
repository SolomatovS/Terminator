//+------------------------------------------------------------------+
//|                                                       CTable.mqh |
//|                                                 Marcin Konieczny |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Marcin Konieczny"

#include <Arrays\List.mqh>
#include <Row.mqh>

const string nameBase="Table_Coord#"; // префикс для всех объектов типа label, используемых в таблице
//+------------------------------------------------------------------+
//| Класс CTable                                                     |
//+------------------------------------------------------------------+
class CTable
  {
private:
   int               xDistance;    // расстояние от правого угла графика
   int               yDistance;    // расстояние от верхней границы графика
   int               cellHeight;   // высота ячейки таблицы
   int               cellWidth;    // ширина ячейки таблицы
   string            font;         // наименование шрифта
   int               fontSize;
   color             fontColor;

   CList            *rowList;      // список объектов 
   bool              tfMode;       // флаг режима multi-timeframe

   ENUM_TIMEFRAMES   timeframes[]; // массив таймфреймов для режима multi-timeframe
   string            symbols[];    // массив валютных пар для режима multi-currency

   //--- private-методы
   //--- установка параметров таблицы по умолчанию
   void              Init();
   //--- отображает текстовую метку указанной ячейки таблицы
   void              DrawLabel(int x,int y,string text,string font,color col);
   //--- возвращает таймфрейм в виде строки
   string            PeriodToString(ENUM_TIMEFRAMES period);

public:
   //--- конструктор для режима multi-timeframe
                     CTable(ENUM_TIMEFRAMES &tfs[]);
   //--- конструктор для режима multi-currency
                     CTable(string &symb[]);
   //--- деструктор
                    ~CTable();
   //--- перерисовка таблицы
   void              Update();
   //--- методы установки параметров таблицы
   void              SetDistance(int xDist,int yDist);
   void              SetCellSize(int cellW,int cellH);
   void              SetFont(string fnt,int size,color clr);
   //--- добавляет объект CRow в таблицу
   void              AddRow(CRow *row);
  };
//+------------------------------------------------------------------+
//| Конструктор для режима Multi-timeframe                           |
//+------------------------------------------------------------------+
CTable::CTable(ENUM_TIMEFRAMES &tfs[])
  {
//--- копируем таймфреймы в свой массив
   ArrayResize(timeframes,ArraySize(tfs),0);
   ArrayCopy(timeframes,tfs);
   tfMode=true;

//--- заполнение массива symbols текущим символом
   ArrayResize(symbols,ArraySize(tfs),0);
   for(int i=0; i<ArraySize(tfs); i++)
      symbols[i]=Symbol();

//--- установка параметров по умолчанию
   Init();
  }
//+------------------------------------------------------------------+
//| Конструктор для режима Multi-currency                            |
//+------------------------------------------------------------------+
CTable::CTable(string &symb[])
  {
//--- копируем символы в свой массив
   ArrayResize(symbols,ArraySize(symb),0);

   ArrayCopy(symbols,symb);
   tfMode=false;
   
//--- установка параметров по умолчанию
   ArrayResize(timeframes,ArraySize(symb),0);
   ArrayInitialize(timeframes,Period());

//--- установка параметров по умолчанию
   Init();

//--- установка индикаторов SpyAgents для всех запращиваемых символов
   for(int x=0; x<ArraySize(symbols); x++)
      if(symbols[x]!=Symbol()) // не нужно устанавливать их для текущего графика
         if(iCustom(symbols[x],0,"SpyAgent",ChartID(),0)==INVALID_HANDLE)
           {
            Print("Ошибка в установке индикатора SpyAgent на символ "+symbols[x]);
            return;
           }
  }
//+------------------------------------------------------------------+
//| Установка значений по умолчанию параметров таблицы               |
//+------------------------------------------------------------------+
CTable::Init()
  {
//--- создаем список для хранения объектов строк Row
   rowList=new CList;

//--- установка значений по умолчанию
   xDistance = 10;
   yDistance = 10;
   cellWidth = 60;
   cellHeight= 20;
   font="Arial";
   fontSize=10;
   fontColor=clrWhite;
  }
//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
CTable::~CTable()
  {
   int total=ObjectsTotal();

//--- удаление всех текстовых меток (label) с графика (всех объектов с префиксом nameBase)
   for(int i=total-1; i>=0; i--)
      if(StringFind(ObjectName(0,i),nameBase)!=-1)
         ObjectDelete(0,ObjectName(0,i));

//--- удаление списка строк и освобождение памяти
   delete(rowList);
  }
//+------------------------------------------------------------------+
//| Добавляет новый объект row в конец таблицы                       |
//+------------------------------------------------------------------+
CTable::AddRow(CRow *row)
  {
   rowList.Add(row);
   row.Init(symbols,timeframes);
  }
//+------------------------------------------------------------------+
//| Метод перерисовки таблицы                                        |
//+------------------------------------------------------------------+
CTable::Update()
  {
   CRow *row;
   string symbol;
   ENUM_TIMEFRAMES tf;

   int rows=rowList.Total(); // число строк
   int columns;              // число столбцов

   if(tfMode)
      columns=ArraySize(timeframes);
   else
      columns=ArraySize(symbols);

//--- отображение первого стоблца(имена строк)
   for(int y=0; y<rows; y++)
     {
      row=(CRow*)rowList.GetNodeAtIndex(y);
      //--- примечание: запращиваем наименование объекта методом GetName()
      DrawLabel(columns,y+1,row.GetName(),font,fontColor);
     }

//--- отображение первой строки (наименованиятаймфреймов или валютных пар)
   for(int x=0; x<columns; x++)
     {
      if(tfMode)
         DrawLabel(columns-x-1,0,PeriodToString(timeframes[x]),font,fontColor);
      else
         DrawLabel(columns-x-1,0,symbols[x],font,fontColor);
     }

//--- отображение внутренних ячеек таблицы
   for(y=0; y<rows; y++)
      for(x=0; x<columns; x++)
        {
         row=(CRow*)rowList.GetNodeAtIndex(y);

         if(tfMode)
           {
            //--- в режиме multi-timeframe используем текущий символ и несколько таймфреймов
            tf=timeframes[x];
            symbol=_Symbol;
           }
         else
           {
            //--- в режиме multi-currency используем текущий таймфрейм и несколько символов
            tf=Period();
            symbol=symbols[x];
           }

         //--- примечание: запрашиваются шрифт объекта, 
         //--- цвет и текущее значение, вычисленное для заданного таймфрейма и символа
         DrawLabel(columns-x-1,y+1,row.GetValue(symbol,tf),row.GetFont(symbol,tf),row.GetColor(symbol,tf));
        }

//--- принудительная перерисовка графика
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Отображает текстовую метку (label) заданной ячейки таблицы       |
//+------------------------------------------------------------------+
CTable::DrawLabel(int x,int y,string text,string font,color col)
  {
//--- создание уникального наименования ячейки
   string name=nameBase+IntegerToString(x)+":"+IntegerToString(y);

//--- создание объекта типа OBJ_LABEL
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

//--- установка свойств объекта
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xDistance+x*cellWidth);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,yDistance+y*cellHeight);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);

//--- установка текста объекта
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }
//+------------------------------------------------------------------+
//| Устанавливает размеры ячейки                                     |
//+------------------------------------------------------------------+
CTable::SetCellSize(int cellW,int cellH)
  {
   cellWidth=cellW;
   cellHeight=cellH;
  }
//+------------------------------------------------------------------+
//| Устанавливает шрифт                                              |
//+------------------------------------------------------------------+
CTable::SetFont(string fnt,int size,color clr)
  {
   font=fnt;
   fontSize=size;
   fontColor=clr;
  }
//+------------------------------------------------------------------+
//| Устанавливает позицию на графике                                 |
//+------------------------------------------------------------------+
CTable::SetDistance(int xDist,int yDist)
  {
   xDistance = xDist;
   yDistance = yDist;
  }
//+------------------------------------------------------------------+
//| Преобразует ENUM_TIMEFRAMES в строку                             |
//+------------------------------------------------------------------+
string CTable::PeriodToString(ENUM_TIMEFRAMES period)
  {
   return(StringSubstr(EnumToString(period),7));
  }
//+------------------------------------------------------------------+

