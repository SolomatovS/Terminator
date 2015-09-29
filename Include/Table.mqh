//+------------------------------------------------------------------+
//|                                                       CTable.mqh |
//|                                                 Marcin Konieczny |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Marcin Konieczny"

#include <Arrays\List.mqh>
#include <Row.mqh>

const string nameBase="Table_Coord#"; // ������� ��� ���� �������� ���� label, ������������ � �������
//+------------------------------------------------------------------+
//| ����� CTable                                                     |
//+------------------------------------------------------------------+
class CTable
  {
private:
   int               xDistance;    // ���������� �� ������� ���� �������
   int               yDistance;    // ���������� �� ������� ������� �������
   int               cellHeight;   // ������ ������ �������
   int               cellWidth;    // ������ ������ �������
   string            font;         // ������������ ������
   int               fontSize;
   color             fontColor;

   CList            *rowList;      // ������ �������� 
   bool              tfMode;       // ���� ������ multi-timeframe

   ENUM_TIMEFRAMES   timeframes[]; // ������ ����������� ��� ������ multi-timeframe
   string            symbols[];    // ������ �������� ��� ��� ������ multi-currency

   //--- private-������
   //--- ��������� ���������� ������� �� ���������
   void              Init();
   //--- ���������� ��������� ����� ��������� ������ �������
   void              DrawLabel(int x,int y,string text,string font,color col);
   //--- ���������� ��������� � ���� ������
   string            PeriodToString(ENUM_TIMEFRAMES period);

public:
   //--- ����������� ��� ������ multi-timeframe
                     CTable(ENUM_TIMEFRAMES &tfs[]);
   //--- ����������� ��� ������ multi-currency
                     CTable(string &symb[]);
   //--- ����������
                    ~CTable();
   //--- ����������� �������
   void              Update();
   //--- ������ ��������� ���������� �������
   void              SetDistance(int xDist,int yDist);
   void              SetCellSize(int cellW,int cellH);
   void              SetFont(string fnt,int size,color clr);
   //--- ��������� ������ CRow � �������
   void              AddRow(CRow *row);
  };
//+------------------------------------------------------------------+
//| ����������� ��� ������ Multi-timeframe                           |
//+------------------------------------------------------------------+
CTable::CTable(ENUM_TIMEFRAMES &tfs[])
  {
//--- �������� ���������� � ���� ������
   ArrayResize(timeframes,ArraySize(tfs),0);
   ArrayCopy(timeframes,tfs);
   tfMode=true;

//--- ���������� ������� symbols ������� ��������
   ArrayResize(symbols,ArraySize(tfs),0);
   for(int i=0; i<ArraySize(tfs); i++)
      symbols[i]=Symbol();

//--- ��������� ���������� �� ���������
   Init();
  }
//+------------------------------------------------------------------+
//| ����������� ��� ������ Multi-currency                            |
//+------------------------------------------------------------------+
CTable::CTable(string &symb[])
  {
//--- �������� ������� � ���� ������
   ArrayResize(symbols,ArraySize(symb),0);

   ArrayCopy(symbols,symb);
   tfMode=false;
   
//--- ��������� ���������� �� ���������
   ArrayResize(timeframes,ArraySize(symb),0);
   ArrayInitialize(timeframes,Period());

//--- ��������� ���������� �� ���������
   Init();

//--- ��������� ����������� SpyAgents ��� ���� ������������� ��������
   for(int x=0; x<ArraySize(symbols); x++)
      if(symbols[x]!=Symbol()) // �� ����� ������������� �� ��� �������� �������
         if(iCustom(symbols[x],0,"SpyAgent",ChartID(),0)==INVALID_HANDLE)
           {
            Print("������ � ��������� ���������� SpyAgent �� ������ "+symbols[x]);
            return;
           }
  }
//+------------------------------------------------------------------+
//| ��������� �������� �� ��������� ���������� �������               |
//+------------------------------------------------------------------+
CTable::Init()
  {
//--- ������� ������ ��� �������� �������� ����� Row
   rowList=new CList;

//--- ��������� �������� �� ���������
   xDistance = 10;
   yDistance = 10;
   cellWidth = 60;
   cellHeight= 20;
   font="Arial";
   fontSize=10;
   fontColor=clrWhite;
  }
//+------------------------------------------------------------------+
//| ����������                                                       |
//+------------------------------------------------------------------+
CTable::~CTable()
  {
   int total=ObjectsTotal();

//--- �������� ���� ��������� ����� (label) � ������� (���� �������� � ��������� nameBase)
   for(int i=total-1; i>=0; i--)
      if(StringFind(ObjectName(0,i),nameBase)!=-1)
         ObjectDelete(0,ObjectName(0,i));

//--- �������� ������ ����� � ������������ ������
   delete(rowList);
  }
//+------------------------------------------------------------------+
//| ��������� ����� ������ row � ����� �������                       |
//+------------------------------------------------------------------+
CTable::AddRow(CRow *row)
  {
   rowList.Add(row);
   row.Init(symbols,timeframes);
  }
//+------------------------------------------------------------------+
//| ����� ����������� �������                                        |
//+------------------------------------------------------------------+
CTable::Update()
  {
   CRow *row;
   string symbol;
   ENUM_TIMEFRAMES tf;

   int rows=rowList.Total(); // ����� �����
   int columns;              // ����� ��������

   if(tfMode)
      columns=ArraySize(timeframes);
   else
      columns=ArraySize(symbols);

//--- ����������� ������� �������(����� �����)
   for(int y=0; y<rows; y++)
     {
      row=(CRow*)rowList.GetNodeAtIndex(y);
      //--- ����������: ����������� ������������ ������� ������� GetName()
      DrawLabel(columns,y+1,row.GetName(),font,fontColor);
     }

//--- ����������� ������ ������ (����������������������� ��� �������� ���)
   for(int x=0; x<columns; x++)
     {
      if(tfMode)
         DrawLabel(columns-x-1,0,PeriodToString(timeframes[x]),font,fontColor);
      else
         DrawLabel(columns-x-1,0,symbols[x],font,fontColor);
     }

//--- ����������� ���������� ����� �������
   for(y=0; y<rows; y++)
      for(x=0; x<columns; x++)
        {
         row=(CRow*)rowList.GetNodeAtIndex(y);

         if(tfMode)
           {
            //--- � ������ multi-timeframe ���������� ������� ������ � ��������� �����������
            tf=timeframes[x];
            symbol=_Symbol;
           }
         else
           {
            //--- � ������ multi-currency ���������� ������� ��������� � ��������� ��������
            tf=Period();
            symbol=symbols[x];
           }

         //--- ����������: ������������� ����� �������, 
         //--- ���� � ������� ��������, ����������� ��� ��������� ���������� � �������
         DrawLabel(columns-x-1,y+1,row.GetValue(symbol,tf),row.GetFont(symbol,tf),row.GetColor(symbol,tf));
        }

//--- �������������� ����������� �������
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| ���������� ��������� ����� (label) �������� ������ �������       |
//+------------------------------------------------------------------+
CTable::DrawLabel(int x,int y,string text,string font,color col)
  {
//--- �������� ����������� ������������ ������
   string name=nameBase+IntegerToString(x)+":"+IntegerToString(y);

//--- �������� ������� ���� OBJ_LABEL
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

//--- ��������� ������� �������
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xDistance+x*cellWidth);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,yDistance+y*cellHeight);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);

//--- ��������� ������ �������
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }
//+------------------------------------------------------------------+
//| ������������� ������� ������                                     |
//+------------------------------------------------------------------+
CTable::SetCellSize(int cellW,int cellH)
  {
   cellWidth=cellW;
   cellHeight=cellH;
  }
//+------------------------------------------------------------------+
//| ������������� �����                                              |
//+------------------------------------------------------------------+
CTable::SetFont(string fnt,int size,color clr)
  {
   font=fnt;
   fontSize=size;
   fontColor=clr;
  }
//+------------------------------------------------------------------+
//| ������������� ������� �� �������                                 |
//+------------------------------------------------------------------+
CTable::SetDistance(int xDist,int yDist)
  {
   xDistance = xDist;
   yDistance = yDist;
  }
//+------------------------------------------------------------------+
//| ����������� ENUM_TIMEFRAMES � ������                             |
//+------------------------------------------------------------------+
string CTable::PeriodToString(ENUM_TIMEFRAMES period)
  {
   return(StringSubstr(EnumToString(period),7));
  }
//+------------------------------------------------------------------+

