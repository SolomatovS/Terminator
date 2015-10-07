//+------------------------------------------------------------------+
//|                                                           MemMap |
//|               Copyright � 2006-2013, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2006-2013, FINEXWARE Technologies GmbH"
#property link      "www.FINEXWARE.com"

// ���������� �� WinApi

//���� ������
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

// ����������
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

// ����������� 32/64 ���������
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


// ���� ������ ��� ������ � Mapping
#define HEAD_MEM		4 // ������ ��������� �����, ��� �������� ��� �����
enum OpenFlags { modeOpen=(int) 0x00000, modeCreate=(int)0x00001 }; // Flag values


//------------------------------------------------------------------	class CMemMapAPI
class CMemMapApi
{
public:
	CMemMapApi() { };
	~CMemMapApi() { };

public:
	virtual HANDLE64 Open(LPTSTR path, DWORD size, int mode, DWORD &err); // ��������
	virtual void Close(HANDLE64 hmem); // ��������
	virtual int Fill(HANDLE64 h, BYTE b, DWORD &err); // ��������� ������ ��������� ���������
	virtual HANDLE64 Grows(HANDLE64 hmem, LPTSTR path, DWORD size, DWORD &err); // �������� ������
	virtual PBYTE64	ViewFile(HANDLE64 hmem, DWORD &err); // �������� �����
	virtual void UnViewFile(PBYTE64 buf); // ��������� �����
	virtual DWORD GetSize(HANDLE64 hmem, DWORD &err); // �������� ������
	virtual int SetSize(HANDLE64 hmem, DWORD size, DWORD &err); // ������������� ������
	virtual int Write(HANDLE64 hmem, const uchar &buf[], DWORD pos, int sz, DWORD &err); // ������ ������ � ������ � �������� ������� �� ��������� ����� ����
	virtual int Read(HANDLE64 hmem, uchar &buf[], DWORD pos, int sz, DWORD &err); // ������ ������ �� ������ � �������� ������� �� ��������� ����� ����
};

//------------------------------------------------------------------	Open
HANDLE64 CMemMapApi::Open(LPTSTR path, DWORD size, int mode, DWORD &err)
{
	err=0;
	if (path=="") return(NULL);
	HANDLE64 hmem=NULL;
	if (mode==modeCreate) hmem=CreateFileMappingWX(INVALID_HANDLE_VALUE64, NULL, PAGE_READWRITE, 0, size+HEAD_MEM, path); // ������� ������ ������
	if (mode==modeOpen)		hmem=OpenFileMappingW(FILE_MAP_ALL_ACCESS, 0, path); // ��������� ������ ������
	if (hmem==NULL) { err=kernel32::GetLastError(); return(NULL); }// ���� ������ ��������
	if (mode==modeCreate) { DWORD r=SetSize(hmem, size, err); if (r!=0 || err!=0) { Close(hmem); return(NULL); } } // ���� ����� ��������, ���������� ������
	return(hmem);
}
//------------------------------------------------------------------	Close
void CMemMapApi::Close(HANDLE64 hmem)
{
	if (hmem!=NULL) CloseHandleX(hmem); hmem=NULL; // ��������� �����
}
//------------------------------------------------------------------	Fill
int CMemMapApi::Fill(HANDLE64 hmem, BYTE b, DWORD &err) // ��������� ������ ��������� ���������
{
	if (hmem==NULL) return(0);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // ���� �� ������
	DWORD size=GetSize(hmem, err); if (size<=0 || err!=0) return(-2); // �������� ������
	memsetX(view, b, size);
	return(size);
}
//------------------------------------------------------------------	Grows
HANDLE64 CMemMapApi::Grows(HANDLE64 hmem, LPTSTR path, DWORD newsize, DWORD &err)
{
	if (hmem==NULL) { err=-1; return(0); } // ���� ��������� ��������
	DWORD size=GetSize(hmem, err); if (newsize<=size || err!=0) return(hmem); // ��������� ������
	HANDLE64 hnew=Open(path, newsize, modeCreate, err); if (hnew==NULL || err!=0) { CloseHandleX(hnew); return(0); } // ���� ������ ��������
	CloseHandleX(hmem); // ��������� ����������
	return(hnew); // ������� �����
}
struct _byte8 { uchar b[8]; };
struct _longStruct { long b; };

//------------------------------------------------------------------	GetSize
DWORD CMemMapApi::GetSize(HANDLE64 hmem, DWORD &err)
{
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // �������� ��������
	int sz=sizeof(DWORD);
	_byte8 dest; // �������� ��������� �� ������
	memcpyX(dest.b, view, sz);
	_longStruct _size=(_longStruct)dest;
	UnViewFile(view); // ��������� ��������
	return((DWORD)_size.b); // ���������� ������
}
//------------------------------------------------------------------	SetSize
int CMemMapApi::SetSize(HANDLE64 hmem, DWORD size, DWORD &err)
{
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // �������� ��������
	int sz=sizeof(DWORD);
	_longStruct _size; _size.b=size;
	_byte8 src=(_byte8)_size; // �������� ��������� �� ������
	memcpyX(view, src.b, sz);
	UnViewFile(view); // ��������� ��������
	return(0); // ���������� ��
}

//------------------------------------------------------------------	ViewFile
PBYTE64	CMemMapApi::ViewFile(HANDLE64 hmem, DWORD &err) // �������� �����
{
	err=0;
	if (hmem==NULL) { err=-1; return(NULL); }// ���� �� ������
	PBYTE64 view=(PBYTE64)MapViewOfFileX(hmem, FILE_MAP_ALL_ACCESS, 0, 0, 100000); // �������� ������������� �����
	if (view==NULL) { err=kernel32::GetLastError(); return(NULL); } // ���� ������ �������������
	return(view); // ���������� ��������� �� �������� ��������
}
//------------------------------------------------------------------	UnViewFile
void CMemMapApi::UnViewFile(PBYTE64 view) // ��������� �����
{
	if (view!=NULL) UnmapViewOfFileX(view); view=NULL; // ��������� �����
}

//------------------------------------------------------------------	Write
int CMemMapApi::Write(HANDLE64 hmem, const uchar &buf[], DWORD pos, int sz, DWORD &err) // ������ � ������ ��������� ����� ����
{
	if (hmem==NULL) return(-1);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // ���� �� ������
	DWORD size=GetSize(hmem, err); if (pos+sz>size) { UnViewFile(view); return(-2); }; // ���� ������ ������, �� �������
	uchar src[]; ArrayResize(src, size+HEAD_MEM); memcpyX(src, view, size+HEAD_MEM); // ����� ���������
	for(int i=0; i<sz; i++)
	   src[pos+i+HEAD_MEM]=buf[i]; // �������� � ������
	memcpyX(view, src, size); // ����������� �������
	UnViewFile(view); // ������� ��������
	return(0); // ������� ��
}
//------------------------------------------------------------------	Read
int CMemMapApi::Read(HANDLE64 hmem, uchar &buf[], DWORD pos, int sz, DWORD &err) // ������ �� ������ ��������� ����� ����
{
	if (hmem==NULL) return(-1);
	PBYTE64 view=ViewFile(hmem, err); if (view==0 || err!=0) return(-1); // ���� �� ������
	DWORD size=GetSize(hmem, err); // �������� ������
	uchar src[]; ArrayResize(src, size+HEAD_MEM); memcpyX(src, view, size+HEAD_MEM); // ����� ���������
	ArrayResize(buf, sz);
	int i=0;
	for(i=0; i<sz && pos+i<size; i++)
	   buf[i]=src[pos+i+HEAD_MEM]; // ������ �����
	
	UnViewFile(view); // ������� �������� 
	return(i); // ����� ������������� ����
}



//------------------------------------------------------------------	class CMemMapApi
class CMemMapFile: public CMemMapApi
{
public:
	HANDLE64 m_hmem; // ����������
	LPTSTR m_path; // ��� � �����
	DWORD m_size; // ����� �����
	DWORD m_pos; // ������� ������� ���������
	int m_mode; // ����� ��������
	//PBYTE m_buf; // ��������� �� ����� ������
	DWORD err;
	
public:
	CMemMapFile();
	~CMemMapFile();

public:
	virtual HANDLE64 Open(LPTSTR path, DWORD size, int mode); // ��������
	virtual void Close(); // �������� � ����� �������
	virtual int Fill(BYTE b); // ��������� ������ ��������� ���������
	virtual int Seek(DWORD pos, int orig); // ��������� ��������� �� ���� ������
	virtual int Grows(DWORD size); // �������� ������
	virtual int IsEOF() { if (m_pos>=m_size) return(1); return(0); }; // ���������
	virtual DWORD Tell() { return(m_pos); }; // ���������

	virtual int Write(const uchar &buf[], int sz); // ������ � ������ ��������� ����� ����
	virtual int Read(uchar &buf[], int sz); // ������ �� ������ ��������� ����� ����
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
	m_size=size; m_path=path; m_mode=mode; m_pos=0; // ��������� ���������
	if (m_path=="") return(-1);
	m_hmem=Open(m_path, size, mode, err);
	if (m_hmem==NULL) return(err); // ���� ������ ��������
	return(0);
}
//------------------------------------------------------------------	Close
void CMemMapFile::Close()
{
	if (m_hmem!=NULL) CloseHandleX(m_hmem); m_path=""; m_hmem=NULL; m_size=0; m_pos=0; m_mode=-1; // ��������� �����
}
//------------------------------------------------------------------	Fill
int CMemMapFile::Fill(BYTE b) // ��������� ������ ��������� ���������
{
	if (m_hmem==NULL) return(-1); // ���� �� ������
	return(Fill(m_hmem, b, err));
}
//------------------------------------------------------------------	Grows
int CMemMapFile::Grows(DWORD size)
{
	if (m_hmem==NULL || m_path=="" || size<=0) return(-1);
	if (size<=m_size) return(0);
	HANDLE64 hnew=Grows(m_hmem, m_path, size, err);
	if (hnew==NULL) return(err); // ���� ������ ��������
	m_hmem=hnew; m_size=size;
	return(0);
}
//------------------------------------------------------------------	Seek
int CMemMapFile::Seek(DWORD pos, int seek=SEEK_SET) // ��������� ��������� �� ���� ������
{
	if (seek==SEEK_SET) m_pos=pos;
	if (seek==SEEK_CUR) m_pos+=pos;
	if (seek==SEEK_END) m_pos=m_size-pos;
	// ���������
	m_pos=(m_pos<0)?0:m_pos;
	m_pos=(m_pos>m_size)?m_size:m_pos;
	return(0);
}
//------------------------------------------------------------------	Write
int CMemMapFile::Write(const uchar &buf[], int sz) // ������ � ������ ��������� ����� ����
{
	if (m_hmem==NULL) return(-1); // ���� �� ������
	if (m_pos+sz>m_size) if (Grows(m_pos+sz)!=0) return(-2);
	int w=CMemMapApi::Write(m_hmem, buf, m_pos, sz, err);
	if (w==0) m_pos+=sz; // ��������� ���������
	return(w); // ������ ���������
}
//------------------------------------------------------------------	Read
int CMemMapFile::Read(uchar &buf[], int sz) // ������ �� ������ ��������� ����� ����
{
	if (m_hmem==NULL) return(-1); // ���� �� ������
	int r=CMemMapApi::Read(m_hmem, buf, m_pos, sz, err);
	if (r>0) m_pos+=r; // ��������� ���������
	return(r); // ������� ���������
}