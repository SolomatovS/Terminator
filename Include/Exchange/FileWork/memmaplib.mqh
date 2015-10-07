//+------------------------------------------------------------------+
//|                                                           MemMap |
//|               Copyright © 2006-2013, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2013, FINEXWARE Technologies GmbH"
#property link      "www.FINEXWARE.com"

// объявления из WinApi

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


// сами классы для работы с Mapping
#define HEAD_MEM		4 // размер заголовка файла, для хранения его длины
enum OpenFlags { modeOpen=(int) 0x00000, modeCreate=(int)0x00001 }; // Flag values


//------------------------------------------------------------------	class CMemMapAPI
class CMemMapApi
{
public:
	CMemMapApi() { };
	~CMemMapApi() { };

public:
	virtual HANDLE64 Open(LPTSTR path, DWORD size, int mode, DWORD &err); // создание
	virtual void Close(HANDLE64 hmem); // закрытие
	virtual int Fill(HANDLE64 h, BYTE b, DWORD &err); // заполнить память указанным значением
	virtual HANDLE64 Grows(HANDLE64 hmem, LPTSTR path, DWORD size, DWORD &err); // увеличит размер
	virtual PBYTE64	ViewFile(HANDLE64 hmem, DWORD &err); // получаем буфер
	virtual void UnViewFile(PBYTE64 buf); // закрываем буфер
	virtual DWORD GetSize(HANDLE64 hmem, DWORD &err); // получаем размер
	virtual int SetSize(HANDLE64 hmem, DWORD size, DWORD &err); // устанавливаем размер
	virtual int Write(HANDLE64 hmem, const uchar &buf[], DWORD pos, int sz, DWORD &err); // запись данных в память с указаной позиции на указанное число байт
	virtual int Read(HANDLE64 hmem, uchar &buf[], DWORD pos, int sz, DWORD &err); // чтение данных из памяти с указаной позиции на указанное число байт
};

//------------------------------------------------------------------	Open
HANDLE64 CMemMapApi::Open(LPTSTR path, DWORD size, int mode, DWORD &err)
{
	err=0;
	if (path=="") return(NULL);
	HANDLE64 hmem=NULL;
	if (mode==modeCreate) hmem=CreateFileMappingWX(INVALID_HANDLE_VALUE64, NULL, PAGE_READWRITE, 0, size+HEAD_MEM, path); // создаем объект памяти
	if (mode==modeOpen)		hmem=OpenFileMappingW(FILE_MAP_ALL_ACCESS, 0, path); // открываем объект памяти
	if (hmem==NULL) { err=kernel32::GetLastError(); return(NULL); }// если ошибка создания
	if (mode==modeCreate) { DWORD r=SetSize(hmem, size, err); if (r!=0 || err!=0) { Close(hmem); return(NULL); } } // если режим создания, записываем размер
	return(hmem);
}
//------------------------------------------------------------------	Close
void CMemMapApi::Close(HANDLE64 hmem)
{
	if (hmem!=NULL) CloseHandleX(hmem); hmem=NULL; // закрываем хендл
}
//------------------------------------------------------------------	Fill
int CMemMapApi::Fill(HANDLE64 hmem, BYTE b, DWORD &err) // заполнить память указанным значением
{
	if (hmem==NULL) return(0);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // если не открыт
	DWORD size=GetSize(hmem, err); if (size<=0 || err!=0) return(-2); // получили размер
	memsetX(view, b, size);
	return(size);
}
//------------------------------------------------------------------	Grows
HANDLE64 CMemMapApi::Grows(HANDLE64 hmem, LPTSTR path, DWORD newsize, DWORD &err)
{
	if (hmem==NULL) { err=-1; return(0); } // если указатель неверный
	DWORD size=GetSize(hmem, err); if (newsize<=size || err!=0) return(hmem); // проверили размер
	HANDLE64 hnew=Open(path, newsize, modeCreate, err); if (hnew==NULL || err!=0) { CloseHandleX(hnew); return(0); } // если ошибка создания
	CloseHandleX(hmem); // закрываем предыдущий
	return(hnew); // вернули новый
}
struct _byte8 { uchar b[8]; };
struct _longStruct { long b; };

//------------------------------------------------------------------	GetSize
DWORD CMemMapApi::GetSize(HANDLE64 hmem, DWORD &err)
{
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // получаем просмотр
	int sz=sizeof(DWORD);
	_byte8 dest; // байтовый указатель на размер
	memcpyX(dest.b, view, sz);
	_longStruct _size=(_longStruct)dest;
	UnViewFile(view); // закрываем просмотр
	return((DWORD)_size.b); // возвращаем размер
}
//------------------------------------------------------------------	SetSize
int CMemMapApi::SetSize(HANDLE64 hmem, DWORD size, DWORD &err)
{
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // получаем просмотр
	int sz=sizeof(DWORD);
	_longStruct _size; _size.b=size;
	_byte8 src=(_byte8)_size; // байтовый указатель на размер
	memcpyX(view, src.b, sz);
	UnViewFile(view); // закрываем просмотр
	return(0); // возвращаем ОК
}

//------------------------------------------------------------------	ViewFile
PBYTE64	CMemMapApi::ViewFile(HANDLE64 hmem, DWORD &err) // получаем буфер
{
	err=0;
	if (hmem==NULL) { err=-1; return(NULL); }// если не открыт
	PBYTE64 view=(PBYTE64)MapViewOfFileX(hmem, FILE_MAP_ALL_ACCESS, 0, 0, 100000); // получили представление файла
	if (view==NULL) { err=kernel32::GetLastError(); return(NULL); } // если ошибка представления
	return(view); // возвращаем указатель на байтовый просмотр
}
//------------------------------------------------------------------	UnViewFile
void CMemMapApi::UnViewFile(PBYTE64 view) // закрываем буфер
{
	if (view!=NULL) UnmapViewOfFileX(view); view=NULL; // закрываем хендл
}

//------------------------------------------------------------------	Write
int CMemMapApi::Write(HANDLE64 hmem, const uchar &buf[], DWORD pos, int sz, DWORD &err) // запись в память указанное число байт
{
	if (hmem==NULL) return(-1);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // если не открыт
	DWORD size=GetSize(hmem, err); if (pos+sz>size) { UnViewFile(view); return(-2); }; // если размер меньше, то выходим
	uchar src[]; ArrayResize(src, size+HEAD_MEM); memcpyX(src, view, size+HEAD_MEM); // взяли байтбуфер
	for(int i=0; i<sz; i++)
	   src[pos+i+HEAD_MEM]=buf[i]; // записали в память
	memcpyX(view, src, size); // скопировали обратно
	UnViewFile(view); // закрыли просмотр
	return(0); // вернули ОК
}
//------------------------------------------------------------------	Read
int CMemMapApi::Read(HANDLE64 hmem, uchar &buf[], DWORD pos, int sz, DWORD &err) // чтение из памяти указанное число байт
{
	if (hmem==NULL) return(-1);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // если не открыт
	DWORD size=GetSize(hmem, err); // получили размер
	uchar src[]; ArrayResize(src, size+HEAD_MEM); memcpyX(src, view, size+HEAD_MEM); // взяли байтбуфер
	ArrayResize(buf, sz);
	int i=0;
	for(i=0; i<sz && pos+i<size; i++)
	   buf[i]=src[pos+i+HEAD_MEM]; // читаем байты
	
	UnViewFile(view); // закрыли просмотр 
	return(i); // число скопированных байт
}



//------------------------------------------------------------------	class CMemMapApi
class CMemMapFile: public CMemMapApi
{
public:
	HANDLE64 m_hmem; // дескриптор
	LPTSTR m_path; // имя к файлу
	DWORD m_size; // длина файла
	DWORD m_pos; // текущая позиция указателя
	int m_mode; // режим открытия
	//PBYTE m_buf; // указатель на буфер данных
	DWORD err;
	
public:
	CMemMapFile();
	~CMemMapFile();

public:
	virtual HANDLE64 Open(LPTSTR path, DWORD size, int mode); // создание
	virtual void Close(); // закрытие и сброс хендлов
	virtual int Fill(BYTE b); // заполнить память указанным значением
	virtual int Seek(DWORD pos, int orig); // установка указателя на блок памяти
	virtual int Grows(DWORD size); // увеличит размер
	virtual int IsEOF() { if (m_pos>=m_size) return(1); return(0); }; // положение
	virtual DWORD Tell() { return(m_pos); }; // положение

	virtual int Write(const uchar &buf[], int sz); // запись в память указанное число байт
	virtual int Read(uchar &buf[], int sz); // чтение из памяти указанное число байт
};

//------------------------------------------------------------------	CMemMapFile
CMemMapFile::CMemMapFile()
{
	m_path=""; m_hmem=NULL; m_size=0; m_pos=0; m_mode=-1;
}
//------------------------------------------------------------------	~CMemMapFile
CMemMapFile::~CMemMapFile()
{
	Close();
}

//------------------------------------------------------------------	Create
HANDLE64 CMemMapFile::Open(LPTSTR path, DWORD size, int mode=modeOpen)
{
	m_size=size; m_path=path; m_mode=mode; m_pos=0; // начальное положение
	if (m_path=="") return(-1);
	m_hmem=Open(m_path, size, mode, err);
	if (m_hmem==NULL) return(err); // если ошибка создания
	return(0);
}
//------------------------------------------------------------------	Close
void CMemMapFile::Close()
{
	if (m_hmem!=NULL) CloseHandleX(m_hmem); m_path=""; m_hmem=NULL; m_size=0; m_pos=0; m_mode=-1; // закрываем хендл
}
//------------------------------------------------------------------	Fill
int CMemMapFile::Fill(BYTE b) // заполнить память указанным значением
{
	if (m_hmem==NULL) return(-1); // если не открыт
	return(Fill(m_hmem, b, err));
}
//------------------------------------------------------------------	Grows
int CMemMapFile::Grows(DWORD size)
{
	if (m_hmem==NULL || m_path=="" || size<=0) return(-1);
	if (size<=m_size) return(0);
	HANDLE64 hnew=Grows(m_hmem, m_path, size, err);
	if (hnew==NULL) return(err); // если ошибка создания
	m_hmem=hnew; m_size=size;
	return(0);
}
//------------------------------------------------------------------	Seek
int CMemMapFile::Seek(DWORD pos, int seek=SEEK_SET) // установка указателя на блок памяти
{
	if (seek==SEEK_SET) m_pos=pos;
	if (seek==SEEK_CUR) m_pos+=pos;
	if (seek==SEEK_END) m_pos=m_size-pos;
	// выровняли
	m_pos=(m_pos<0)?0:m_pos;
	m_pos=(m_pos>m_size)?m_size:m_pos;
	return(0);
}
//------------------------------------------------------------------	Write
int CMemMapFile::Write(const uchar &buf[], int sz) // запись в память указанное число байт
{
	if (m_hmem==NULL) return(-1); // если не открыт
	if (m_pos+sz>m_size) if (Grows(m_pos+sz)!=0) return(-2);
	int w=CMemMapApi::Write(m_hmem, buf, m_pos, sz, err);
	if (w==0) m_pos+=sz; // подвинули указатель
	return(w); // венули результат
}
//------------------------------------------------------------------	Read
int CMemMapFile::Read(uchar &buf[], int sz) // чтение из памяти указанное число байт
{
	if (m_hmem==NULL) return(-1); // если не открыт
	int r=CMemMapApi::Read(m_hmem, buf, m_pos, sz, err);
	if (r>0) m_pos+=r; // подвинули указатель
	return(r); // вернули результат
}