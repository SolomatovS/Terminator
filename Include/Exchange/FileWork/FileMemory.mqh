//+------------------------------------------------------------------+
//|                                                   FileMemory.mqh |
//|                                 Copyright 2015, Solomatov Sergey |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Solomatov Sergey"
#property link      ""
#property strict

#include "..\Model.mqh"
//#include "memmaplib.mqh"

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

//типы данных
#define BYTE				uchar
#define DWORD				int
#define BOOL				int
#define LPTSTR			string
#define LPCTSTR			const string

#define PBYTE64			long
#define LPVOID64		long
#define LPCVOID64 	const long
#define SIZE_T64		long
#define HANDLE64		long
#define INVALID_HANDLE_VALUE64 ((HANDLE64)(long)-1) 
#define LPSECURITY_ATTRIBUTES64			long

#define PBYTE32			int
#define LPVOID32		int
#define LPCVOID32 	const int
#define SIZE_T32		int
#define HANDLE32		int
#define INVALID_HANDLE_VALUE32 ((HANDLE32)(int)-1) 
#define LPSECURITY_ATTRIBUTES32			int

// кончстанты
#define PAGE_READWRITE								0x04     
#define FILE_MAP_ALL_ACCESS 					SECTION_ALL_ACCESS
#define STANDARD_RIGHTS_REQUIRED			(0x000F0000)
#define SECTION_QUERY               	0x0001
#define SECTION_MAP_WRITE           	0x0002
#define SECTION_MAP_READ            	0x0004
#define SECTION_MAP_EXECUTE         	0x0008
#define SECTION_EXTEND_SIZE         	0x0010
#define SECTION_MAP_EXECUTE_EXPLICIT	0x0020 // not included in SECTION_ALL_ACCESS
#define SECTION_ALL_ACCESS						(STANDARD_RIGHTS_REQUIRED|SECTION_QUERY|SECTION_MAP_WRITE|SECTION_MAP_READ|SECTION_MAP_EXECUTE|SECTION_EXTEND_SIZE)
#define FILE_MAPPING_SIZE 103056

#import "kernel32.dll"
	HANDLE64 OpenFileMappingW(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCTSTR lpName);
	// 64
	HANDLE64 CreateFileMappingW(HANDLE64 hFile, LPSECURITY_ATTRIBUTES64 lpAttributes, DWORD flProtect, DWORD dwMaximumSizeHigh, DWORD dwMaximumSizeLow, LPCTSTR lpName);
	LPVOID64 MapViewOfFile(HANDLE64 hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, SIZE_T64 dwNumberOfBytesToMap);
	BOOL UnmapViewOfFile(LPCVOID64 lpBaseAddress);
	BOOL CloseHandle(HANDLE64 hObject);
	// 32
	HANDLE32 CreateFileMappingW(HANDLE32 hFile, LPSECURITY_ATTRIBUTES32 lpAttributes, DWORD flProtect, DWORD dwMaximumSizeHigh, DWORD dwMaximumSizeLow, LPCTSTR lpName);
	LPVOID32 MapViewOfFile(HANDLE32 hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, SIZE_T32 dwNumberOfBytesToMap);
	BOOL UnmapViewOfFile(LPCVOID32 lpBaseAddress);
	BOOL CloseHandle(HANDLE32 hObject);

	int GetLastError();
#import "msvcrt.dll"
	// 64
	long memset(uchar &Destination[], long c, int Length);
	long memset(long Destination, long c, int Length);
	long memcpy(uchar &Destination[], long Source, int Length);
	long memcpy(long Destination, uchar &Source[], int Length);
	long memcpy(uchar &Destination[], uchar &Source[], int Length);
	// 32
	int memset(uchar &Destination[], int c, int Length);
	int memset(int Destination, int c, int Length);
	int memcpy(uchar &Destination[], int Source, int Length);
	int memcpy(int Destination, uchar &Source[], int Length);
#import


// определение 32/64 платформы
//------------------------------------------------------------------	CreateFileMappingWX
HANDLE64 CreateFileMappingWX(HANDLE64 hFile, LPSECURITY_ATTRIBUTES64 lpAttributes, DWORD flProtect, DWORD dwMaximumSizeHigh, DWORD dwMaximumSizeLow, LPCTSTR lpName)
{
	if (_IsX64) return(CreateFileMappingW(hFile, lpAttributes, flProtect, dwMaximumSizeHigh, dwMaximumSizeLow, lpName));
	else return(CreateFileMappingW((HANDLE32)hFile, (LPSECURITY_ATTRIBUTES32)lpAttributes, flProtect, dwMaximumSizeHigh, dwMaximumSizeLow, lpName));
}
//------------------------------------------------------------------	MapViewOfFileX
LPVOID64 MapViewOfFileX(HANDLE64 hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, SIZE_T64 dwNumberOfBytesToMap)
{
	if (_IsX64) return(MapViewOfFile(hFileMappingObject, dwDesiredAccess, dwFileOffsetHigh, dwFileOffsetLow, dwNumberOfBytesToMap));
	else return(MapViewOfFile((HANDLE32)hFileMappingObject, dwDesiredAccess, dwFileOffsetHigh, dwFileOffsetLow, (SIZE_T32)dwNumberOfBytesToMap));
}
//------------------------------------------------------------------	UnmapViewOfFileX
BOOL UnmapViewOfFileX(LPCVOID64 lpBaseAddress)
{
	if (_IsX64) return(UnmapViewOfFile(lpBaseAddress));
	else return(UnmapViewOfFile((int)lpBaseAddress));
}
//------------------------------------------------------------------	CloseHandleX
BOOL CloseHandleX(HANDLE64 hObject)
{
	if (_IsX64) return(CloseHandle(hObject));
	else return(CloseHandle((HANDLE32)hObject));
}
//------------------------------------------------------------------	memsetX
long memsetX(uchar &Destination[], long c, int Length) { if (_IsX64) return(memset(Destination, c, Length)); else return(memset(Destination, (int)c, Length)); }
//------------------------------------------------------------------	memsetX
long memsetX(long Destination, long c, int Length) { if (_IsX64) return(memset(Destination, c, Length)); return(memset((int)Destination, (int)c, Length)); }
//------------------------------------------------------------------	memcpyX
long memcpyX(uchar &Destination[], long Source, int Length) { if (_IsX64) return(memcpy(Destination, Source, Length)); return(memcpy(Destination, (int)Source, Length)); }
//------------------------------------------------------------------	memcpyX
long memcpyX(long Destination, uchar &Source[], int Length) { if (_IsX64) return(memcpy(Destination, Source, Length)); return(memcpy((int)Destination, Source, Length)); }


#define HEAD_MEM		4 // размер заголовка файла, для хранения его длины
enum OpenFlags
{
   modeOpen    =(int)   0x00000,
   modeCreate  =(int)   0x00001
}; // Flag values


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
   string   m_fileName;
   //char     m_fileNameChar[];
   uint     m_fileSize;
   //uint     m_filledSize;
   int      m_error;
   uint     m_offset;
   uint     m_headSize;
   HANDLE64 m_hMem;

public:
	FileMemory(string fileName)
	{
	   m_headSize = 4;
	   m_fileSize = 4096; // bytes
	   m_fileName = fileName;
	   this.Seek(0);
	   LastError();
	   
      Init();
	};
   ~FileMemory()
	{
      Deinit();
	};

public: // Features
   bool     isInit()    { return isOpened(); }
   string   Name()      { return m_fileName; }
   int      LastError()
   {
      int error = m_error;
      m_error = 0;
      return error;
   }

protected:
   bool    isOpened()  { return (m_hMem != NULL); }
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
   bool Close()
   {
      if (!isOpened())  return true;
      
      if (!CloseHandleX(m_hMem))
      {
         m_error = kernel32::GetLastError(); return false;
      }
      else
      {
         m_hMem = NULL; return true;
      }
   }
   void UnmapView(PBYTE64& view) // закрываем буфер
   {
   	if (view != NULL) UnmapViewOfFileX(view);
   	view = NULL; // закрываем хендл
   }
   PBYTE64 MapView() // получаем буфер
   {
   	if (!isOpened())  return NULL;
   	
   	PBYTE64 view = (PBYTE64)MapViewOfFileX(m_hMem, FILE_MAP_ALL_ACCESS, 0, 0, m_fileSize); // получили представление файла
   	m_error = kernel32::GetLastError();
   	if (view == NULL && m_error > 0)
   	{
   	   Print(__FUNCTION__, ": MapViewOfFile вернул NULL. Нет представления файла '", m_fileName, "' в памяти. код ошибки: ", m_error);
   	   return(NULL); // если ошибка представления
   	}
   	return(view); // возвращаем указатель на байтовый просмотр
   }
   int Read(uchar &value_char[], int offset, int size)
   {
      if (!isOpened())  return -1;
      
      if ((offset + size) > m_fileSize) return -1;
      
      PBYTE64 view = MapView();
      m_error = 0;
   	if (view == NULL)
   	{
   	   //if (view != NULL) UnmapView(view);
   	   return -1; // получаем представление файла
   	}
      
      int sizeInt = sizeof(int);
      uchar bytes[]; ArrayResize(bytes, sizeInt);
      memcpyX(bytes, view, sizeInt);
      int filledSize = 0;
      ByteTo(bytes, filledSize);
      
      if ((offset + size) > filledSize + m_headSize)
      {
         UnmapView(view); // закрыли просмотр 
         return -1;
      }
      
   	ArrayResize(value_char, size);
   	
   	memcpyX(value_char, view + offset, size); // взяли байтбуфер
   	
   	UnmapView(view); // закрыли просмотр 
   	m_error = 0;
   	
   	return(ArraySize(value_char)); // число скопированных байт
   }
   int Write(uchar &value_char[], int offset, int size)
   {
      if (!isOpened())  return -1;
      
      if (ArraySize(value_char) <= 0)  return -1;
      
      if ((offset + size) > m_fileSize) return -1;
      
      PBYTE64 view = MapView();
   	if (view == NULL)
   	{
   	   //if (view != NULL) UnmapView(view);
   	   return -1; // получаем представление файла
   	}
   	/*
   	int sizeInt = sizeof(int);
      uchar bytes[]; ArrayResize(bytes, sizeInt);
      memcpyX(bytes, view, sizeInt);
      int filledSize = 0;
      ByteTo(bytes, filledSize);
      
      if ((offset + size) > filledSize)
      {
         UnmapView(view); // закрыли просмотр 
         return -1;
      }
      */
   	memcpyX(view + offset, value_char, size); // взяли байтбуфер
   	
   	UnmapView(view); // закрыли просмотр 
   	m_error = 0;
   	
   	return(ArraySize(value_char)); // число скопированных байт
   }
public:
   bool FilledSize(DWORD size)
   {
      if (!isOpened())  return false;
      
   	uchar bytes[]; ToByte(size, bytes);
   	int result = Write(bytes, 0, sizeof(size));
   	
   	if (result <= 0)
   	{
   	   Print(__FUNCTION__, ": Не удалось записать размер заполненных данных в файле");
   	   return false;
   	}
   	return true;
   }
   int FilledSize()
   {
      if (!isOpened())  return -1;
      
   	uchar bytes[];
   	
   	int result = Read(bytes, 0, sizeof(int));
   	if (result <= 0)
   	{
   	   Print(__FUNCTION__, ": Не удалось прочитать данные из файла '", m_fileName, "'");   return -1;
   	}
   	
   	int size; ByteTo(bytes, size);
   	
   	return size;
   }
private:
   bool Create(string fileName, int filledSize)
   {
      if (isOpened())
      {
         Print(__FUNCTION__, ": файл '", m_fileName, "' уже открыт. Что бы создать его заного, неоьбходимо сначала закрыть существующий");
         return true;
      }
      
      m_hMem = CreateFileMappingWX(INVALID_HANDLE_VALUE64, NULL, PAGE_READWRITE, 0, m_fileSize, fileName);
      m_error = kernel32::GetLastError();
      if (m_hMem == NULL || m_error != 0)
      {
         this.Close(); return false;
      }
      
      bool resultSetFilledSize = FilledSize(filledSize);
      m_error = kernel32::GetLastError();
      if (!resultSetFilledSize || m_error != 0)
      {
         if (m_error == 2) return true;
         
         this.Close(); return false;
      }
      
      return true;
   }
   bool Open()
   {
      if (isOpened())
      {
         Print(__FUNCTION__, ": файл '", m_fileName, "' уже открыт. Что бы открыть его заного, неоьбходимо сначала закрыть существующий");
         return true;
      }
      
      m_hMem = OpenFileMappingW(FILE_MAP_ALL_ACCESS, 0, m_fileName); // открываем объект памяти
      m_error = kernel32::GetLastError();
      if (m_hMem == NULL || m_error != 0)
      {
         if (m_error == 2)
         {
            Print(__FUNCTION__, ": файл '", m_fileName, "' уже открыт. Что бы открыть его заного, неоьбходимо сначала закрыть существующий");
            return true;
         }
         
         this.Close(); return false;
      }
      
      return true;
   }
   void CreateIfOpenNotFound()
   {
      this.Open(); if (isOpened()) return;
      
      int error = this.LastError();
      if (error == ERROR_FILE_NOT_FOUND)
      {
         Print(__FUNCTION__, ": File not found. Try create...");
         if (Create(m_fileName, 1))
         {
            Print(__FUNCTION__, ": OK, file created");
         }
         else
         {
            Print(__FUNCTION__, ": Falue, file not created");
         }
      }
      else Print(__FUNCTION__, ": file not opened");
   }

public:
   uint Size()
   {
      return m_fileSize;
   }
   
   uint Tell()
   {
      if (!isOpened()) return 0;
      
      return m_offset;
   }
   void Seek(uint offset, const ENUM_FILE_POSITION origin = SEEK_SET)
   {
      if (!isOpened()) return;
      
      int size = this.FilledSize();
   	if (origin==SEEK_SET) m_offset = offset;
   	if (origin==SEEK_CUR) m_offset += offset;
   	if (origin==SEEK_END) m_offset = size - offset;
   	
   	m_offset = (m_offset < 0)        ? 0      : m_offset;
   	m_offset = (m_offset > size)     ? size   : m_offset;
   }
   bool IsEnding()
   {
      if (!isOpened()) return true;
      
      return (m_offset >= this.FilledSize());
   }
   bool Grow(uint addSize)
   {
      if (!isOpened()) return false;
      
      uint size = this.FilledSize();
      uint newSize = size + addSize;
      
      if (newSize <= 0 || size > newSize)
      {
         Print("[Grow]: attempt allocate incorrect new file size. Old = ", size, ", New = ", newSize);
         return false;
      }
      if (newSize > this.Size())
      {
         Print(__FUNCTION__, "Невозможно увеличить размер буффера, т.к. он превышысет размер файла.");
         return false;
      }
      
      Print("[Grow]: Add ", addSize, " byte");
      
      return FilledSize(newSize);
      
      //return true;
   }
   
   template<typename T>
   bool Read(T &value)
   {
      if (!isInit()) return false;
      
      int size = sizeof(T);
      uchar value_char[]; ArrayResize(value_char, size); ArrayInitialize(value_char, 0);
      
      int result = Read(value_char, m_offset + m_headSize, size);
      
      if(result < size || m_error != 0)
      {
         //Print("[Read T]: cannot read value, error code: ", m_error);
         return false;
      }
      else
      {
         this.Seek(result, SEEK_CUR);
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
            //if (i == 0) return false;
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
      int fileSize = this.FilledSize();
      int offset = this.Tell();
      if (size + offset > fileSize)
      {
         if (!this.Grow(offset + size - fileSize))
         {
            Print(__FUNCTION__, ": не удалось увеличить размер памяти. Запись данных невозможна");
            return false;
         }
      }
      
      uchar value_char[];
      ToByte(value, value_char);
      
      m_error = 0;
      int result = Write(value_char, offset + m_headSize, size);
      if(result <= 0 || m_error != 0)
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
            file.FilledSize(sizeof(SHead));
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
