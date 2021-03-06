//+------------------------------------------------------------------+
//|                                                 Notification.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "Model.mqh"
/*
class ProviderSMS
{
public:
   virtual string GetStringRequest(string Message)
   {
      return Message;
   }
};

class SMSC : ProviderSMS
{
private:
   string m_URL;
   string m_login;
   string m_password;
   string m_phones;
   string m_cost;
public:
   SMSC(string login, string password, string phones, string cost = "")
   {
      this.m_URL = "http://smsc.ru/sys/send.php";
      this.m_login = login;
      this.m_password = password;
      this.m_phones = phones;
      this.m_cost = cost;
   }
   virtual string GetStringRequest(string message)
   {
      string messageGet = StringConcatenate(
         m_URL, "?",
         "login=", m_login, "&",
         "psw=", m_password, "&",
         "phones=", m_phones, "&",
         "mes=", message, "&");
      if(m_cost != "") messageGet = StringConcatenate(messageGet, "cost=", m_cost);
      return messageGet;
   }
   string GetURL()
   {
      return m_URL;
   }
};

class SMS : public Notification
{
public:
   SMS(ProviderSMS *Provider)
   {
      this.m_Provider = Provider;
   }
   ~SMS()
   {
      if (CheckPointer(m_Provider) == POINTER_DYNAMIC)
      {
         delete m_Provider; m_Provider = NULL;
      }
   }
   
private:
   ProviderSMS *m_Provider;
protected:
   virtual bool VSignal(string Message)
   {
      return Send(Message);
   }
   bool Send(string Message)
   {
      if (CheckPointer(m_Provider) == POINTER_INVALID) return false;
      
      string messageGet = m_Provider.GetStringRequest(Message);
      // отправляем GET запрос на сервер
      string cookie = NULL, headers;
      char post[], result[];
      int timeout=5000; //--- timeout менее 1000 (1 сек.) недостаточен при низкой скорости Интернета

      int res = WebRequest("GET", messageGet, cookie, NULL, timeout, post, 0, result, headers);
      if(res == -1)
      {
         Print("Ошибка в WebRequest. Код ошибки = ",GetLastError());
         //--- возможно URL отсутствует в списке, выводим сообщение о необходимости его добавления
         MessageBox("Необходимо добавить адрес '"+messageGet+"' в список разрешенных URL во вкладке 'Советники'","Ошибка",MB_ICONINFORMATION);
         
         return false;
      }
      else
      {
         return true;
      }
   }
};
*/

class Notification
{
   NOTIFICATION   m_notification;
   uint           m_count;             // текущее количество отправленных сигналов
   datetime       m_lastNotification;  // последнее время отправки сигнала
   string         m_message;           // 

public:
   Notification(NOTIFICATION& settings)
   {
      m_notification.Init(settings);
      m_count = 0; m_lastNotification = 0;
   }
protected:
   // Reset counter
   void Reset() { m_count = 0; }
   
   // Set time (local time) last notification
   void SetLastTimeNotification() { m_lastNotification = TimeLocal(); }
   
   // override VSignal method of children class
   virtual bool VSend(string Message)
   {
      return false;
   }
   
   // Check reset counter
   void CheckResetCount()
   {
      datetime time = TimeLocal();
      datetime last = m_lastNotification;
      datetime compare = last + int(m_notification.m_resetCountMin * 60);
      if (time >= compare)
      {
         Reset();
      }
   }
      
   // is notification ?
public:
   void Enable(bool enable)   { m_notification.m_enabler = enable; }
   bool Enable()              { return m_notification.m_enabler; }
   
   bool isNotification()
   {
      if (!Enable())  return false;
      CheckResetCount(); // проверяем нужно ли сбросить счетчик, если да, то сбрасываем
      
      return m_count < m_notification.m_countLimit;
   }
   // Set Message
   void SetMessage(string Message)
   {
      this.m_message = Message;
   }
   
   // Send notification
   bool Send()
   {
      if (isNotification()) // Проверяем можно ли запускать сигнал
      {
         if (VSend(m_message)) // запускаем сигнал
         {
            SetLastTimeNotification(); // устанавливаем последнее время, запуска сигнала
            m_count++; // увеличиваем количество сигналов
            return true;
         }
      }
      return false;
   }
};

class SystemAlert : Notification
{
public:
   SystemAlert(ALERT_NOTIFICATION& settings) : Notification(settings) { }
  ~SystemAlert() { }

protected:
   virtual bool VSend(string Message)
   {
      Alert(Message);
      return true;
   }
};

class PushNotification : Notification
{
public:
   PushNotification(PUSH_NOTIFICATION& settings) : Notification(settings) { }
  ~PushNotification() {}

protected:
   virtual bool VSend(string Message)
   {
      return SendNotification(Message);
   }
};

class EmailNotification : Notification
{
private:
   string m_header;

public:
   EmailNotification(EMAIL_NOTIFICATION& settings) : Notification(settings) { m_header = settings.m_header;}
  ~EmailNotification() {}

protected:
   virtual bool VSend(string Message)
   {
      return SendMail(m_header, Message);
   }
};


class NotificationConfigurator
{
   NOTIFICATIONS  m_setting;
public:
   NotificationConfigurator(NOTIFICATIONS& setting)
   {
      m_setting.Init(setting);
   }
private:
   void Add(Notification*  &notifications[], Notification* notification)
   {
      int index = ArrayResize(notifications, ArraySize(notifications) + 1) - 1;
      notifications[index] = notification;
   }

public:
   void NotificationInit(Notification* &notifications[])
   {
      // ALERT
      if (m_setting.m_alert.m_enabler)
      {
         Add(notifications, (Notification*) new SystemAlert(m_setting.m_alert));
      }
      // EMAIL
      if (m_setting.m_email.m_enabler)
      {
         Add(notifications, (Notification*) new EmailNotification(m_setting.m_email));
      }
      // PUSH
      if (m_setting.m_push.m_enabler)
      {
         Add(notifications, (Notification*) new PushNotification(m_setting.m_push));
      }
   }
};
