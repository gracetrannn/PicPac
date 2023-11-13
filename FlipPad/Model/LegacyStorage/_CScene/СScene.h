//
//  СScene.h
//  FlipPad
//
//  Created by Alex on 19.08.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#ifndef _Scene_h
#define _Scene_h

#include "Support.h"
#include "CString.h"
#include "CObject.h"
#include "CIO.h"
#include <string>

#define CHECKING
#ifdef CHECKING
typedef struct {
    DWORD   dwKey;
    DWORD   dwStat;
    DWORD   dwSize;
    DWORD   dwAdr;
    DWORD   dwKind;
    DWORD   dwCount;
    DWORD   dwLink;
} CHKENTRY;
#endif

typedef struct {
    DWORD   dwKey;
    DWORD   dwCount;
} LINKENTRY;


typedef struct {
    int offx;
    int offy;
    int blur;
    UINT flags;
} ACTLAY;

typedef struct {
    BYTE pals[1024];
    ACTLAY lays[11];
} LEVELINFO;

typedef struct {
    DWORD   dwKey;
    UINT    iw;
    UINT    ih;
    UINT    id;
    LEVELINFO info;
    BYTE *    pData;
} CELLENTRY;

#define FEAT_STD  1
#define FEAT_LITE 2
#define FEAT_PT   3
#define FEAT_PRO  4


//class CLevels;
//class CCamera;
//class CLevel;
//class CCell;
//class CLayers;
//class CLevelTable;

class CScene : public CObject
{
public:
    CScene(CIO * pIO);
    ~CScene();
//    int Read(BOOL bPreview, DWORD dwFeatures= 0, DWORD id = 0);
    int Write();
    int Check();
    BYTE * LoggedData(BOOL bClear);
//    UINT Make(DWORD id, DWORD features,
//            UINT width, UINT height, UINT rate, UINT frames, UINT levels, UINT factor);
    HDIB GetBG();
    UINT FrameCount() { return m_frames;};
    UINT Selection_Start() { return m_start;};
    UINT Selection_Stop() { return m_stop;};
    UINT MaxFrameCount() { return m_max_frames;};
    UINT LevelCount() { return m_levels;};
    UINT FrameRate();
    UINT ComW() { return 2 * m_width / m_factor;};
    UINT ComH() { return 2 * m_height / m_factor;};
    void PublishSizes(UINT & w, UINT & h);
    BOOL ColorMode(UINT Mode = NEGONE);
    BOOL RedBox(UINT Mode = NEGONE);
    void SetFrameCount(UINT count);
    void SetSelection(UINT start, UINT stop);
    void SetLevelCount(UINT count);
    void SetFrameRate(UINT rate);
    UINT ChangeFrames(UINT Start, UINT End);
    UINT ChangeLevels(UINT Start, UINT Count);
    UINT SlideCells(UINT StartF, UINT EndF, UINT StartL, UINT EndL, UINT Count=0);
    UINT BlankCell(UINT Frame, UINT Level);
    UINT DeleteCell(UINT Frame, UINT Level, BOOL bDelete = TRUE);
    UINT DeleteCell(DWORD dwKey);
    DWORD SceneId() { return m_dwId;};
//
//    0 is release, 1 is release opened with demo, 2 is demo/demo
//
    UINT SceneState() { return m_uState;};
    UINT Width() { return m_width;};// / m_scale;};
    UINT Height() { return m_height;};// / m_scale;};
//    UINT QScale() { return m_scale;};
    UINT SetFactor(UINT Factor);
    UINT Zoom(UINT zoom = 1000);
    UINT ZFactor(int bOrig = 0) {
        if (bOrig > 1)
            return m_factor / m_origfactor;
        else if (bOrig)
            return m_origfactor;
        else
            return m_factor;};
    void SetThumbSize(UINT w, UINT h)
        {m_thumbw = w; m_thumbh = h;};
    BOOL GetBackground(HPBYTE hpDst,UINT Frame,UINT min);
    void GetMono(HPBYTE hpDst, UINT Frame, UINT Level);
    void GetGray(HPBYTE hpDst, UINT Frame, UINT Level);
    UINT GetLayer(HPBYTE hpDst, UINT Frame, UINT Level, UINT Which, DWORD key=0);
    HPBYTE GetCacheP(UINT Frame);
//    void PutFrame(HANDLE hMono, HANDLE hGray, UINT Frame, UINT grayoffset);
    void PutMono(HPBYTE hpMono, UINT Frame, UINT Level);
    void PutGray(HPBYTE hpGray, UINT Frame, UINT Level);
    void SetLayer(CLayers * pLayer);
    void PutLayer(HPBYTE hpGray, UINT Frame, UINT Level, UINT Which);
    void ProcessCellLabel(std::string & label, UINT hold);
    UINT zCreateCell(UINT Frame, UINT Level, LPBITMAPINFOHEADER  lpbi,
                UINT Rotation, BOOL bMakeMono, UINT nHold);
    void ApplyImprint(HPBYTE hpDst, UINT d = 0);
//    void CompositeFrame(BYTE * pBuf,
//                    UINT StartLevel, UINT EndLevel, UINT Frame, BOOL bBroadcast);
    void CompositeFrame32(BYTE * pBuf,
                    UINT StartLevel, UINT EndLevel, UINT Frame, BOOL b32);
    void CombineLayers(BYTE * pBuf, UINT StartLevel, UINT EndLevel, UINT Frame);
    void CompositePiece(BYTE * pBuf, UINT Frame,
            UINT x1, UINT y1, UINT x2, UINT y2);
    void MakeGray(HPBYTE hpDst);
    void MakeMono(HPBYTE hpDst);
    UINT GetThumb(HPBYTE hpDst, UINT Frame, UINT Level,
                UINT w, UINT h, UINT bpp, BOOL bForge = 0);
    void FetchCell(HPBYTE hpDst, UINT Frame, UINT Level,
                BOOL b32, BOOL bUseGray, BOOL bHold = 0);
    UINT CellInfo(HPBYTE hpDst, UINT Frame, UINT Level, BOOL bHold,
                    UINT & w, UINT & h, UINT & key);
    UINT MakeThumb(HPBYTE hpDst, UINT Frame, UINT Level);
    UINT BlankThumb(UINT Frame, UINT Level);
    void LevelName(LPSTR name, UINT level, BOOL bPut = FALSE);
    void LevelPalName(LPSTR name, UINT level, BOOL bPut = FALSE);
    void LevelModelName(LPSTR name, UINT level, BOOL bPut = FALSE);
    DWORD LevelFlags(UINT Level,DWORD val = NEGONE);
    void CellName(LPSTR name, UINT frame, UINT level, BOOL bPut = 0);
    BOOL Modified(BOOL bClear = FALSE);
    UINT Broadcast(UINT v = NEGONE);
    void Broadcasting(BOOL bBroadcast);
    BOOL Flag(UINT which, BOOL bSet = FALSE, BOOL bValue = FALSE);
    void SceneOptionLock(BOOL bLock);
    int    SceneOptionInt(int Id, int op = 0, int val = 0);
    int    SceneOptionStr(int Id, LPSTR arg, int op = 0);
    UINT UpdateCache(UINT Frame = 0, UINT Level = 9999, UINT Count = 1);
    int        CheckComposite(UINT Frame = NEGONE,
                UINT Force = 0, BOOL bBrodcast = FALSE);
    DWORD    GetCellKey(UINT Frame, UINT Level, BOOL bHold = FALSE);
    BOOL    FindNextCell(UINT & Frame, UINT Level);
    BOOL    FindPrevCell(UINT & Frame, UINT Level);
    UINT    SetCellKey(UINT Frame, UINT Level, DWORD key);
    int         GetImageKey(DWORD& key, UINT Frame,
                    UINT Level, UINT Which, BOOL bMake = FALSE);
    int         GetImageKey(DWORD& key, DWORD cellkey, UINT Which);
    void SetMinBG(UINT min, BOOL bInit = 0);
    UINT  LinkCellRecord(DWORD key, int inc = 0, BOOL bForce = 0);
    DWORD LinkCell(UINT Frame, UINT Level);
    void    MakeModified() { m_bModified = TRUE;};
    void LevelTable(UINT Level, CLevelTable * tbl, BOOL bPut = 0);
    void    PutLevelWidth(UINT Level,UINT width){PutLevelInfo(0,Level,width);};
    UINT    GetLevelWidth(UINT Level,UINT def)
                    { return GetLevelInfo(0,Level,def);};
    int        AVIInfo(void * pInfo, UINT size, BOOL bPut = FALSE);
//    BYTE *  PalAddr(UINT Level, BOOL bPut = FALSE);
    UINT    Pals(BYTE * pPals, UINT Level, BOOL bPut = FALSE);
    BYTE * ScenePals() { return m_pScenePalette;};
    BYTE * DefPals() { return m_pScenePalette + 1024;};
    int    Tools(void * pTools, UINT size, BOOL bPut = FALSE);
    UINT PaletteIO(LPCSTR name, BYTE * pals, BOOL bPut = 0);
    UINT PegFindLevel(UINT Level);
    UINT PegAttach(UINT Level, UINT Peg = 0);    // 0 is detach
    UINT PegName(LPSTR Name, UINT Peg = 9999, BOOL bPut = 0); // 999 is add
    BYTE * MakeWireFrame(UINT& w, UINT& h, UINT frame, UINT peg);
//    CCamera * Camera();
    void zApplyGray(HPBYTE hpDst,UINT factor,UINT Frame,UINT Level, BOOL bHold=1);
    UINT BlowCell(UINT key);
    UINT BlowCell(UINT Frame, UINT Level);
    UINT WrapCell(CFile &file, UINT Key);
    UINT UnWrapCell(CFile &file);
    UINT SaveCache(LPCSTR name);
    UINT LoadCache(LPCSTR name);
    int      ReadImage(HPBYTE hpDst, DWORD key);
    int      ImageInfo(UINT & w, UINT &h, UINT & d, DWORD key);
    void ThumbMinMax(UINT & min, UINT & max, UINT Frame, UINT Level);
    UINT Before(UINT * pList, UINT max, UINT Frame, UINT Level);
    int     TopLevel(UINT frame);
#ifdef _DISNEY
    UINT DisPalIO(BYTE * p, UINT size, BOOL BPut);
#endif
#ifdef MYBUG
    void Display();
#endif
protected:
//    BYTE *  PalAddr(UINT Level, BOOL bPut = FALSE);
//    UINT    Pals(BYTE * pPals, UINT Level, BOOL bPut = FALSE);
    void LogIt(int Id, UINT level, LPCSTR name=0);
    int  CheckExternals(int v, int c);
    void XThumb(HPBYTE hpDst, UINT w, UINT h, UINT bpp, UINT Level);
    UINT GetLayer32(HPBYTE hpDst, UINT Frame, UINT Level, DWORD key);
    UINT GetOverlay(HPBYTE hpDst, UINT key);
    void CompositeFrame(BYTE * pBuf,
                    UINT StartLevel, UINT EndLevel, UINT Frame, BOOL bBroadcast);
    UINT ConvertGray(HPBYTE hpDst, LPBITMAPINFOHEADER  lpbi,
                UINT Rotation, UINT nHold);
    UINT ConvertColor(HPBYTE hpDst, LPBITMAPINFOHEADER lpbi, UINT Od,
                UINT Rotation, UINT nFit);
    void GetCell(HPBYTE hpDst, UINT Frame, UINT Level);
    UINT GetCell32(UINT Frame, UINT Level, BOOL bSearch);
    void ApplyCell(HPBYTE hpDst,
            UINT Frame, UINT Level, BOOL bCamera = FALSE, BOOL bBradcast = 0);
    void Apply32(BYTE * hpDst, BYTE * hpSrc, UINT iw, UINT ih);
    void Apply24(BYTE * hpDst, BYTE * hpSrc, UINT iw, UINT ih,
                    BOOL bCamera, BOOL bBroadcast);
    void Apply24c(BYTE * hpDst, BYTE * hpSrc, UINT iw, UINT ih);
    void Apply24g(BYTE * hpDst, BYTE * hpSrc, UINT iw, UINT ih, BOOL bBG);
    void ApplyCell32(HPBYTE hpDst, UINT Frame, UINT Level, BOOL bFill);
    void ApplyBuff(HPBYTE hpDst, HPBYTE hpSrc, UINT w, UINT h, UINT factor);
    BOOL GetLevel0(HPBYTE hpDst,UINT Frame,BOOL bHold, UINT min,
                BOOL bCamera, BOOL bBroadcast);

    inline void  Magic4(UINT off, UINT zz, UINT * s, BYTE *pBuf)
            {
            pBuf += off;
            if (pBuf[3])
                {
                s[0] += zz * *pBuf++;
                s[1] += zz * *pBuf++;
                s[2] += zz * *pBuf++;
                s[3] += zz * *pBuf++;
                s[4] += zz;
                }
            }
    inline void MagicColumn4(UINT x,UINT y1,UINT y2,
                UINT xf, UINT q, UINT yf1, UINT yf2,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y1 + 4 * x;
            UINT off2 = ip * y2 + 4 * x;
            Magic4(off1,xf*yf1,s,pBuf);
            for (off1 += ip; off1 < off2; off1 += ip)
                Magic4(off1,xf * q,s,pBuf);
            Magic4(off1,xf*yf2,s,pBuf);
            }
    inline void MagicLine4(UINT x1,UINT x2,UINT y,
                UINT xf1, UINT xf2, UINT yf, UINT q,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y + 4 * x1;
            UINT off2 = off1 + 4 * (x2 - x1);
            Magic4(off1,yf*xf1,s,pBuf);
            for (off1 += 4; off1 < off2;off1 += 4)
                Magic4(off1,yf*q,s,pBuf);
            Magic4(off1,yf*xf2,s,pBuf);
            }

    inline void  Magic3(UINT off, UINT zz, UINT * s, BYTE *pBuf)
            {
            pBuf += off;
            s[0] += zz * *pBuf++;
            s[1] += zz * *pBuf++;
            s[2] += zz * *pBuf++;
            }
    inline void MagicColumn3(UINT x,UINT y1,UINT y2,
                UINT xf1, UINT xf2, UINT yf1, UINT yf2,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y1 + 3 * x;
            UINT off2 = ip * y2 + 3 * x;
            Magic3(off1,xf1*yf1,s,pBuf);
            for (off1 += ip; off1 < off2; off1 += ip)
                Magic3(off1,xf1 * xf2,s,pBuf);
            Magic3(off1,xf1*yf2,s,pBuf);
            }
    inline void MagicLine3(UINT x1,UINT x2,UINT y,
                UINT xf1, UINT xf2, UINT yf, UINT q,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y + 3 * x1;
            UINT off2 = off1 + 3 * (x2 - x1);
            Magic3(    off1,yf*xf1,s,pBuf);
            for (off1 += 3; off1 < off2;off1 += 3)
                Magic3(off1,yf*  q,s,pBuf);
            Magic3(    off1,yf*xf2,s,pBuf);
            }

    inline void  Magic1(UINT off, UINT zz, UINT * s, BYTE *pBuf)
            {
            pBuf += off;
            s[0] += zz * *pBuf++;
//            s[1] += zz;
            }
    inline void MagicColumn1(UINT x,UINT y1,UINT y2,
                UINT xf1, UINT xf2, UINT yf1, UINT yf2,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y1 + x;
            UINT off2 = ip * y2 + x;
            Magic1(off1,xf1*yf1,s,pBuf);
            for (off1 += ip; off1 < off2; off1 += ip)
                Magic1(off1,xf1 * xf2,s,pBuf);
            Magic1(off1,xf1*yf2,s,pBuf);
            }
    inline void MagicLine1(UINT x1,UINT x2,UINT y,
                UINT xf1, UINT xf2, UINT yf1, UINT yf2,
                UINT ip, UINT * s, BYTE * pBuf)
            {
            UINT off1 = ip * y + x1;
            UINT off2 = off1 + (x2 - x1);
            Magic1(off1,yf1*xf1,s,pBuf);
            for (off1 += 1; off1 < off2;off1 += 1)
                Magic1(off1,yf1*yf2,s,pBuf);
            Magic1(off1,yf1*xf2,s,pBuf);
            }


    int        GetPutOptions(BOOL bPut = FALSE);
    int     MakeImprint();
    int        LoadScenePalette();
    int     ForgeImage(HPBYTE hpDst, UINT which);
    int        ForgeImprint(UINT ow, UINT oh);
    UINT     InsertCache(UINT Start, UINT End);
//    CLevel * GetLevelPtr(UINT Level, BOOL bMake);
    BOOL        SelectLevel(UINT Level=9999, BOOL bMake = 0);
    CCell * GetCellPtr(CLevel * pLevel, UINT Frame, BOOL bMake);
//    CImage * GetImagePtr(CCell * pCell, UINT Which, BOOL bMake);
    int      WriteImage(HPBYTE hpDst, DWORD key, UINT which);
    int      WriteOverlay(HPBYTE hpDst, UINT Frame, UINT Level,UINT w, UINT h);
    void      GetImage(HPBYTE hpDst, UINT Frame, UINT Level, UINT which);
    void      PutImage(HPBYTE hpDst, UINT Frame, UINT Level, UINT which);
    UINT    SetupCache(BOOL bRead, BOOL bInit = TRUE);
    void    MakeInfo(BOOL bRead);
    UINT    GetLevelInfo(UINT what, UINT level, UINT def);
    void    PutLevelInfo(UINT what, UINT level, UINT value);

#ifdef CHECKING
    int Bump(DWORD key, int which = 0);
    CHKENTRY * m_pEntry;
    UINT    m_nEntries;
#endif
    BOOL    m_bFirst; // major kludge for first level alpha
    UINT    m_depth;
    UINT    m_width;
    UINT    m_height;
    UINT    m_size;
    UINT     m_start;
    UINT     m_stop;
    UINT    m_thumbw;
    UINT    m_thumbh;
    UINT    m_x;
    UINT    m_y;
    UINT    m_w;
    UINT    m_h;
//    UINT    m_scale;
    UINT    m_factor;
    UINT    m_origfactor;
    UINT    m_zoom;
    UINT    m_frames;
    UINT    m_max_frames;
    UINT    m_levels;
    BOOL    m_bOptLock;    // if set don't write options to dbase
    UINT    m_flags;    // 0 is thumb dirty, 1 is color mode, 2 is red
    UINT     m_uState;
    BOOL    m_bModified;
    DWORD    m_dwId;
    UINT    m_CurFrame;
    UINT    m_CurLevel;
    UINT    m_MinBG;

    UINT    m_rate;
    UINT    m_vmark;
    UINT    m_smark;
    UINT    m_snip;
    BOOL    m_bStory;
    BOOL    m_bBlind;
    BOOL m_bLoading;
    UINT    m_srate;
    BOOL    m_bSound;
    UINT    m_nBuddy0;
    UINT    m_nBuddy1;
    UINT    m_nBuddy2;
    UINT    m_nBuddy3;
    UINT    m_OptFlags; // 1 is Quiet, 2 is save cache,
                  // 4 & 8 are telecine value,
    char    m_xcellname[20];
    char    m_wave[300];

    DWORD    m_levelskey;
    UINT    m_cache_state;
    LPBYTE * m_pCache;
    BYTE *  m_pScenePalette;
    BYTE    * m_pImprint;
    BYTE * m_pLog;
    UINT        m_logsize;
    UINT    * m_pFlags;
    UINT    m_nCells;
    BYTE *  m_pBG;
    UINT    m_BGw;
    UINT    m_BGh;
    UINT    m_BGd;
    UINT    m_BGk;
    UINT    m_BGmin;
    CELLENTRY *  m_pCellCache;
    CLayers *  m_pLayers;
    CLevels *  m_pLevels;
    CLevel * m_pLevel;
    UINT m_nLevel; // matches m_pLevel
//    CLevel * m_pSaveLevel;
//    UINT m_nSaveLevel;
//    CCamera * m_pCamera;
    UINT *    m_pXY;
    UINT *    m_pInfo;
    UINT    m_info;
    LINKENTRY *    m_pLinks;
    UINT    m_links;
    UINT    m_nStack;
    UINT    m_Stack[20];
friend class CLayers;
};

#endif /* _Scene_h */
