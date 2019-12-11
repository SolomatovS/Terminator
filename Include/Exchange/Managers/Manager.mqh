//+------------------------------------------------------------------+
//|                                                      Manager.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "..\Model.mqh"
#include "..\Notification.mqh"


class Manager
{
protected:
   bool  m_enabler;
   
public:
   Manager(bool enabler = true) { m_enabler = enabler; }
  ~Manager() {}

protected:
   virtual void VWork(SData& datas[], int index)   { }

public:
   void Work(SData& datas[], int index)
   {
      if (!m_enabler)   return;
      
      VWork(datas, index);
   }
   void Enable(bool enabler = true) { m_enabler = enabler; }
};

