//+------------------------------------------------------------------+
//|                                                   FileMemory.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "..\Model.mqh"
#include "memmaplib.mqh"

#define ERROR_FILE_NOT_FOUND		2
//#define HANDLE32	int
/*
#import "MemMap32.dll"
   HANDLE32 MemOpen(char &path[],int size,int mode,int &err); // открываем/создаем файл в памяти, получаем хендл
   void MemClose(HANDLE32 hmem); // закрываем файл в памяти
   HANDLE32 MemGrows(HANDLE32 hmem, char &path[],int newsize,int &err); // увеличиваем размер файла в памяти
   int MemWrite(HANDLE32 hmem,uchar &v[], int pos, int sz, int &err); // запись int(4) вектора v в память с указанной позиции pos, размером sz
   int MemRead(HANDLE32 hmem, uchar &v[], int pos, int sz, int &err); // чтение вектора v с указанной позиции pos размером sz
   int MemWriteStr(HANDLE32 hmem, uchar &str[], int pos, int sz, int &err); // запись строки
   int MemReadStr(HANDLE32 hmem, uchar &str[], int pos, int &sz, int &err); // чтение строки вектора 
   int MemGetSize(HANDLE32 hmem, int &err);
   int MemSetSize(HANDLE32 hmem, uint size, int &err);
#import
*/

template <typename T>
void ToByte(const T &value, uchar &bytes[])
{
   struct SVector
   {
      T V;
   };
   SVector vector;
   vector.V = value;
   SByte byte = vector;
   
   int size = sizeof(T);
   ArrayResize(bytes, size); ArrayInitialize(bytes, 0);
   ArrayCopy(bytes, byte.V, 0, 0, size);
}

template <typename T>
void ByteTo(const uchar &bytes[], T &value)
{
   struct SVector
   {
      T V;
   };
   SByte byte;
   ArrayCopy(byte.V, bytes);
   SVector vector;
   vector = byte;
   value = vector.V;
}
/*
enum FlagOpenMode
{
   modeOpen = 0,
   modeCreate = 1
};
*/
class FileMemory
{
private:
   string m_fileName;
   char m_fileNameChar[];
   uint m_fileSize;
   bool m_opened;
   int m_error;
   uint m_offset;
   HANDLE32 m_hMem;
   CMemMapApi API;

public:
	FileMemory(string fileName)
	{
	   Name(fileName);
	   m_opened = false;
	   this.Seek(0);
	   LastError();
	   
      Init();
	};
   ~FileMemory()
	{
      Deinit();
	};

public: // Features
   bool     isInit()    { return (m_opened && isInstance()); }
   string   Name()  { return m_fileName; }
   int      LastError()
   {
      int error = m_error;
      m_error = 0;
      return error;
   }

protected:
   bool    isOpened()  { return m_opened; }
   bool    isInstance(){ return (m_hMem != NULL); }
   virtual void Init()
   {
	   CreateIfOpenNotFound();
   }
public:
   virtual void Deinit(bool close = true)
   {
      //if (close)
      //   this.Close();
   }
private: // Methods
   void Name(string fileName)  { m_fileName = fileName; StringToCharArray(m_fileName, m_fileNameChar); }
   void OpenOrCreate(OpenFlags mode)
   {
      if (!m_opened)
      {
         switch(mode)
         {
            case modeOpen:   m_hMem = API.Open(m_fileName, -1, mode, m_error); break;
            case modeCreate: m_hMem = API.Open(m_fileName, 100000, mode, m_error); break;
         }
         
         if(m_hMem > 0)
         {
            m_opened = true;
            Print("[", EnumToString(mode) ,"]: true: ", m_fileName, ". handle = " + string(m_hMem));
         }
         else
         {
            m_opened = false;
            Print("[", EnumToString(mode) ,"]: false \"", m_fileName, "\"");
         }
      }
   }
   void Create()
   {
      OpenOrCreate(modeCreate);
   }
   void Open()
   {
      OpenOrCreate(modeOpen);
   }
   void Close()
   {
      if (isOpened())
      {
         if(m_hMem != NULL)
         {
            API.Close(m_hMem);
            m_hMem = NULL;
            m_opened = false;
         }
      }
   }
   void CreateIfOpenNotFound()
   {
      this.Open(); if (isOpened()) return;
      
      int error = this.LastError();
      if (error == ERROR_FILE_NOT_FOUND)
      {
         Print("[CreateIfOpenNotFound]: File not found. Try create...");
         Create();
      }
      else Print("[CreateIfOpenNotFound]: file not opened");
   }

public:
   uint Size()
   {
      return API.GetSize(m_hMem, m_error);
   }
   void Size(uint size)
   {
      API.SetSize(m_hMem, size, m_error);
   }
   uint Tell()
   {
      if (!isInit()) return 0;
      return m_offset;
   }
   void Seek(uint offset, const ENUM_FILE_POSITION origin = SEEK_SET)
   {
      if (!isInit()) return;
      
      uint size = this.Size();
   	if (origin==SEEK_SET) m_offset = offset;
   	if (origin==SEEK_CUR) m_offset += offset;
   	if (origin==SEEK_END) m_offset = size - offset;
   	
   	m_offset = (m_offset < 0)        ? 0      : m_offset;
   	m_offset = (m_offset > size)     ? size   : m_offset;
   }
   bool IsEnding()
   {
      if (!isInit()) return false;
      
      return (m_offset >= this.Size());
   }
   bool Grow(uint addSize)
   {
      if (!isInit()) return false;
      
      uint size = this.Size();
      uint newSize = size + addSize;
      
      if (newSize <= 0 ||  this.Size() > newSize)
      {
         Print("[Grow]: attempt allocate incorrect new file size. Old = ", this.Size(), ", New = ", newSize);
         return false;
      }
      Print("[Grow]: Add ", addSize, " byte");
      m_hMem = API.Grows(m_hMem, m_fileName, newSize, m_error);
      if (m_hMem <= 0)
      {
         Print("[Grow]: attampt allocate new file size. error = ", m_error);
         m_opened = false;
         m_hMem = NULL;
         return false;
      }      
      return true;
   }
   
   template<typename T>
   bool Read(T &value)
   {
      if (!isInit()) return false;
      
      int size = sizeof(T);
      uchar value_char[]; ArrayResize(value_char, size); ArrayInitialize(value_char, 0);
      int result = API.Read(m_hMem, value_char, m_offset, size, m_error);
      this.Seek(result, SEEK_CUR);
      if(result < size || m_error != 0)
      {
         //Print("[Read T]: cannot read value, error code: ", m_error);
         return false;
      }
      else
      {
         ByteTo(value_char, value);
         return true;
      }
   }
   template<typename T>
   bool Read(T &array[], uint &count)
   {
      if (!isInit()) return false;
      
      ArrayResize(array, count);
      for (int i = 0; i < count; i++)
      {
         T value;
         bool result = this.Read(value);
         if (!result)
         {
            //Print("[Read T[]]: read array [", i, "]");
            ArrayResize(array, i);
            count = i;
            return true;
         }
         array[i] = value;
      }
      if (ArraySize(array) == 0) return false;
      return true;
   }
   bool ReadString(string &text, uint count = 1)
   {
      uchar text_char[]; ArrayResize(text_char, 0); ArrayInitialize(text_char, 0);
      bool result = this.Read(text_char, count);
      if (result)
      {
         text = CharArrayToString(text_char);
         return true;
      }
      return false;
   }
   
   template<typename T>
   bool Write(const T &value)
   {
      if (!isInit()) return false;
      
      uint size = sizeof(T);
      uint fileSize = this.Size();
      uint offset = this.Tell();
      if (size + offset > fileSize)
      {
         this.Grow(offset + size - fileSize);
      }
      
      uchar value_char[];
      ToByte(value, value_char);
      
      int result = API.Write(m_hMem, value_char, m_offset, size, m_error);
      if(result != 0 || m_error != 0)
      {
         if (result == -2) // try memory grow
         {
            Print("[Write T: cannot write becouse fileSize min]");
         }
         Print("[Write T]: cannot write value, error code: ", m_error);
         return false;
      }
      else
      {
         this.Seek(size, SEEK_CUR);
         return true;
      }
   }
   template<typename T>
   bool Write(T &array[])
   {
      if (!isInit()) return false;
      
      int size = ArraySize(array);
      for (int i = 0; i < size; i++)
      {
         T value = array[i];
         bool result = this.Write(value);
         if (!result)
         {
            Print("[Write T[]]: cannot write array");
            return false;
         }

      }
      return true;
   }
   bool WriteString(string &text)
   {
      uchar text_char[]; ArrayResize(text_char, 0); ArrayInitialize(text_char, 0);
      StringToCharArray(text, text_char);
      bool result = this.Write(text_char);
      if (result)
      {
         return true;
      }
      return false;
   }
};


// static class for work of file "head"
class HeadWork
{
public:
   HeadWork() {}
  ~HeadWork() {}
private:
   uint Offset(EHead type = UsersOffset)
   {
      return 0 + type;
   }
public:
   
   void Init(FileMemory &file)
   {
      SHead head;
      if (Read(file, head)) // read current data
      {
         Print("[", __FUNCTION__, "]: read head. Users read file = ", head.Users);
         Print("[", __FUNCTION__, "]: add current user");
      }
      else
      {
         Print("[", __FUNCTION__, "] not read head file. try create...");
         head.Users = 0;
      }
      head.Users++;
      
      Write(file, head); // set head file
   }
   
   void Deinit(FileMemory &file)
   {
      SHead head;
      Read(file, head); // read current data
      if (head.Users > 0)  head.Users--;
      Write(file, head); // set head file
   }
   
   uint Size()
   {
      return sizeof(SHead);
   }
   
   bool Write(FileMemory &file, const SHead &head)
   {
      file.Seek(Offset());
      return file.Write(head);
   }
   
   bool Read(FileMemory &file, SHead &head)
   {
      file.Seek(Offset(), SEEK_SET);
      return file.Read(head);
   }
   // Count Users
   uint Count(FileMemory &file, const EHead type = UsersOffset)
   {
      file.Seek(Offset(type), SEEK_SET);
      
      SHead head;
      switch(type)
      {
         case UsersOffset:     file.Read(head.Users);       return head.Users;      break;
         //case TerminalsOffset: m_file.Read(m_head.Terminals);   return m_head.Terminals;  break;
         default: return 0;
      }
   }
};

class DataWork
{
private:
   uint m_maxDataArray;
public:
   DataWork() { m_maxDataArray = 100; }
  ~DataWork() {}
public:
   bool Init(FileMemory &file)
   {
      SData data[];
      uint index = 0;
      if (!Read(file, data))
      {
         Print("[", __FUNCTION__, "] not read data file. try create...");
         index = ArrayResize(data, ArraySize(data) + 1) - 1;
         return Write(file, data[index]);
      }
      return true;
   }
   bool Deinit(FileMemory &file, const SData &data)
   {
      // delete data
      uint index = 0;
      if (Index(file, data.Terminal, index))
      {
         SData datas[];
         if (!Read(file, datas))
         {
            return false;
         }
         else
         {
            int size = ArraySize(datas);
            
            SData datasNew[]; ArrayResize(datasNew, size - 1);
            int k = 0;
            for(int i = 0; i < size; i++)
            {
               if (i != index)
               {
                  datasNew[k] = datas[i];
                  k++;
               }
            }
            // deallocate memory
            file.Size(sizeof(SHead));
            file.Seek(sizeof(SHead));
            if (!file.Write(datasNew))
            {
               Print("[", __FUNCTION__, "]: cannot write new data in file");
               return false;
            }
         }
      }
      Print("[", __FUNCTION__, "]: ok delete data");
      return true;
   }
public:
   bool Read(FileMemory &file, SData &data[])
   {
      file.Seek(Offset(DataTerminalOffset), SEEK_SET);
      
      uint count = m_maxDataArray;      
      return file.Read(data, count);
   }
   bool Read(FileMemory &file, SData &data, uint index = 0)
   {
      file.Seek(Offset(DataTerminalOffset, index), SEEK_SET);
      return file.Read(data);
   }
   bool Write(FileMemory &file, const SData &data)
   {
      uint index = 0;
      if (!Index(file, data.Terminal, index)) return false;
      
      file.Seek(Offset(DataTerminalOffset, index), SEEK_SET);
      return file.Write(data);
   }
   bool Index(FileMemory &file, const STerminal &tdata, uint &index)
   {
      SData data[];
      if (!Read(file, data))  return false;
      
      uint size = ArraySize(data);
      for(int i = 0; i < size; i++)
      {
         if (tdata.Login == data[i].Terminal.Login)
         {
            index = i;
            return true;
         }
      }
      return false;
   }
   bool AddOrUpdate(FileMemory &file, const SData &data)
   {
      uint index = 0;
      if (!Index(file, data.Terminal, index))
      {
         SData datas[];
         if (!Read(file, datas))
         {
            Print("[", __FUNCTION__, "]: no data in file. try create...");
         }
         else Print("[", __FUNCTION__, "]: data exists in file. try add...");
         
         index = ArrayResize(datas, ArraySize(datas) + 1) - 1;
      }
      
      file.Seek(Offset(DataTerminalOffset, index), SEEK_SET);
      
      // add data
      if (!file.Write(data))
      {
         Print("[", __FUNCTION__, "]: can not write data. last error:", file.LastError());
         return false;
      }
      else return true;
   }
   
   bool Size(FileMemory &file, uint &size)
   {
      SData data[];
      if (Read(file, data))
      {
         size = ArraySize(data);
         return true;
      }
      return false;
   }
private:
   uint Offset(EData type = DataTerminalOffset, uint index = 0)
   {
      return sizeof(SHead) + sizeof(SData) * index + type;
   }
};
