//
//  CScene.m
//  FlipPad
//
//  Created by Alex on 19.08.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#include "СScene.h"
#include "Resource.h"
#include "SceneOpt.h"

//#define MAGIC_FACTOR_FIX

//#define FIXSCENES

//#define NOCOMPRESS
#define CELLCACHESIZE 40

//#define MAGIC_COLOR 254
//#define NEWTHUMBS
//#define DOBROADCAST
#define KEY_SCENE 0x398
#define KEY_LEVELS 0x397
#define KEY_LINKS 0x396
#define KEY_OPTIONS 0x395
#define KEY_LEVELINFO 0x394
#define KEY_PALETTE 0x393
#define KEY_TOOLS 0x392
#define KEY_AVI 0x391
#define KEY_CAMERA 0x390
#ifdef _DISNEY
#define KEY_DISPAL 0x389
#endif

void BlurX(BYTE * pDst, BYTE * pSrc, UINT w, UINT h,
        UINT r, UINT f, UINT z, UINT pitch);

//#define MAKEWATERMARK
#define IMPRINT_ALPHA 140 // over 100
#define TGA
//#define THE_DISC
//#undef MYBUG
#define AUTONAME
#pragma pack(push,2)
typedef struct {
    DWORD   dwId;
    DWORD   dwKind;
    WORD    wWidth;
    WORD    wHeight;
    WORD    wScale;
    WORD    wFlags;
    DWORD    dwMyId;
    WORD    wFrameCount;
    WORD    wLevelCount;
} SCENEHEADER;

typedef struct {
    DWORD   dwId;
    WORD    wWidth;
    WORD    wHeight;
    WORD    wDepth;
    WORD    wFrameCount;
    DWORD    dwCode;
} CACHEHEADER;

 
#pragma pack(pop)
#ifndef mmioFOURCC
#define mmioFOURCC( ch0, ch1, ch2, ch3 ) \
    ( (DWORD)(BYTE)(ch0) | ( (DWORD)(BYTE)(ch1) << 8 ) |    \
    ( (DWORD)(BYTE)(ch2) << 16 ) | ( (DWORD)(BYTE)(ch3) << 24 ) )
#endif
#define DGCID    mmioFOURCC('D', 'G', 'C', 26)
#define DGQID    mmioFOURCC('D', 'G', 'Q', 26)

#ifdef _NEEDSWAP
void SwapHdr(BYTE * p)
{
    SwapEm(p, 8);
    p += 8;
    SwapEm(p, 2);
    p += 2;
    SwapEm(p, 2);
    p += 2;
    SwapEm(p, 2);
    p += 2;
    SwapEm(p, 2);
    p += 2;
    SwapEm(p, 4);
    p += 4;
    SwapEm(p, 2);
    p += 2;
    SwapEm(p, 2);
}
#endif

//
//    Flag()
//    0 is thumb dirty (historical)
//    1 is color
//    2 is red box mode
//    3 is enlarge
//    4 is disable auto composite
//    5 is grid
//    14 is 00 is always preview
//    15 is 01 is broadcast when publish, 10 is broadcast always

//CCamera * CScene::Camera()
//{ return m_pCamera;}

CScene::CScene(CIO * pIO) : CObject(pIO)
{
DPF("scene construct");
//    memset(this,0,sizeof(this));// cant.cause m_pio
    m_origfactor = m_factor = 2;
//    m_scale = 1;//5;
    m_width = 640;
    m_height = 480;
    m_frames = 0;
    m_levels = 0;
    m_CurLevel = 1;
    m_CurFrame = 0;
    m_bOptLock = 0;
    m_flags = 0x4002;
    m_pLevels = 0;
    m_pLevel = 0;
    m_nLevel = -1;
    m_pCamera = 0;
    m_pInfo = 0;
    m_pCache = 0;
    m_pBG = 0;
    m_nStack = 0;
//    m_pSaveLevel = 0;
    m_pCellCache = 0;
    m_pLayers = 0;
    m_pLinks = 0;
    m_links = 0;
    m_pImprint = 0;
    m_pScenePalette = 0;
    m_pLog = 0;
    m_pXY = 0;
    m_pFlags = 0;
    m_thumbw = 71;
    m_thumbh = 53;
    m_MinBG = 100;
    m_snip = 3;
    m_bBlind = 0;
    m_kind = KIND_SCENE;
    m_key = KEY_SCENE;
    m_info = 0;
    m_depth = 3;
    m_OptFlags = 0;
    m_xcellname[0] = 0;
    m_wave[0] = 0;
    m_nBuddy0 = m_nBuddy1 = m_nBuddy2 = m_nBuddy3 = 0;
}

CScene::~CScene()
{
DPF("scene destruct");
    delete m_pLevels;
    m_pLevels = 0;
    delete m_pLevel;
    m_pLevel = 0;
    delete [] m_pInfo;
    m_pInfo = 0;
    UINT i;
    if (m_pImprint)
        delete [] m_pImprint;
    if (m_pScenePalette)
        delete [] m_pScenePalette;
    if (m_pFlags)
        delete [] m_pFlags;
    if (m_pLinks)
        delete [] m_pLinks;
    if (m_pCache)
        {
        for (i = 0; i < m_frames; i++)
            delete [] m_pCache[i];
        delete [] m_pCache;
        }
    if (m_pCellCache)
        {
        for (i = 0; i < m_nCells; i++)
            delete [] m_pCellCache[i].pData;
        delete [] m_pCellCache;
        }
    delete [] m_pBG;
    delete m_pCamera;
    delete [] m_pXY;
    delete [] m_pLog;
}

void CScene::CompositePiece(BYTE * pBuf, UINT Frame,
            UINT x1, UINT y1, UINT x2, UINT y2)
{
    UINT x = m_x;
    UINT y = m_y;
    UINT w = m_w;
    UINT h = m_h;
    m_x = x1;
    m_y = y1;
    m_w = x2 + 1 - m_x;
    m_h = y2 + 1 - m_y;

    UINT ow = ComW();
    UINT oh = ComH();
    UINT op = 4 * ((m_depth * ow + 3) / 4);
    UINT oy, ox;
    for (oy = m_y; oy < (m_y + m_h);oy++)
    for (ox = m_x; ox < (m_x + m_w);ox++)
        {
        UINT ty = oh - 1 - oy;
        pBuf[ty*op+3*ox+0] = 128;
        pBuf[ty*op+3*ox+1] = 128;
        pBuf[ty*op+3*ox+2] = 128;
        }
//    CompositeFrame(pBuf, 0, m_levels - 1, Frame,0);

    m_x = x;
    m_y = y;
    m_w = w;
    m_h = h;
}

void CScene::PublishSizes(UINT & w, UINT & h)
{
    UINT f = m_factor;
    if (Broadcast())
        m_factor = m_origfactor;
    w = ComW();
    h = ComH();
    m_factor = f;
}

void CScene::CompositeFrame32(BYTE * pBuf, UINT StartLevel, UINT EndLevel,
                            UINT Frame, BOOL b32)
{
/*
    if (StartLevel == 9999)
        {
        CheckComposite(Frame);
        memmove(pBuf, m_pCache[Frame],m_size);
        return;
        }
*/
    UINT zfact = m_factor;
    UINT zw = ComW();
    UINT zh = ComH();
    UINT zize = m_size;
    UINT zpp = m_depth;
    if (Broadcast())
        {
        m_factor = m_origfactor;
        m_w = ComW();
        m_h = ComH();
        }
    if (b32)
        m_depth = 4;
    m_size = m_h * m_depth * m_w;
    CompositeFrame(pBuf,StartLevel,EndLevel,Frame,TRUE);
    m_depth = zpp;
    m_size = zize;
    m_factor = zfact;
    m_w = ComW();
    m_h = ComH();
}

#define GDOT(x,y) pBuf[(y)*dp+3*(x)+0] = 0;\
                pBuf[(y)*dp+3*(x)+1] = 255;\
                pBuf[(y)*dp+3*(x)+2] = 0;
#define RDOT(x,y) pBuf[(y)*dp+3*(x)+0] = 0;\
                pBuf[(y)*dp+3*(x)+1] = 0;\
                pBuf[(y)*dp+3*(x)+2] = 255;
#define MDOT(x,y) pBuf[(y)*dp+(x)] = 128;
#define NDOT(x,y) pBuf[(y)*dp+(x)] = 192;

void CScene::CompositeFrame(BYTE * pBuf, UINT StartLevel, UINT EndLevel,
                            UINT Frame, BOOL bBroadcast)
{
    m_bFirst = 0;
    UINT Level;
    if (!Broadcast())
        bBroadcast = 0;
    if (!StartLevel && (LevelFlags(0) & 1))
        {
        GetLevel0(pBuf,Frame,1,m_MinBG,1,bBroadcast);
        StartLevel++;
        }
    else
        {
        if (m_depth == 1) // no bg so fill with white and no alpha
            memset(pBuf, 255, m_size);
        else if (m_depth == 3)
            memset(pBuf, 255, m_size);
        else
            {
//            memset(pBuf,0,m_size);    // 4/9/200e no bg bug
            m_bFirst = TRUE;
            UINT w = ComW();
            UINT h = ComH();
            UINT x, y;
            for (y = 0; y < h; y++)
            for (x = 0; x < w; x++)
                {
                pBuf[4*(y*w+x) + 0] = 255;
                pBuf[4*(y*w+x) + 1] = 255;
                pBuf[4*(y*w+x) + 2] = 255;
                pBuf[4*(y*w+x) + 3] = 0;
                }
            }
        }
    for (Level = StartLevel; Level <= EndLevel;Level++)
        if (LevelFlags(Level) & 1)
            {
            ApplyCell(pBuf, Frame,Level,1, bBroadcast);
            m_bFirst = 0;
            }
    if (Flag(5))
        {
        UINT w = ComW();
        UINT h = ComH();
        UINT dp = 4 * ((m_depth*w+3)/4);
        UINT x,y,xx,yy;
        UINT ww = w / 2;
        UINT hh = h / 2;
        UINT z = 12;
        if (Flag(2))
            z = 24;
        if (m_pCamera)
            z = (UINT)(((double)z * 100.0) / m_pCamera->CamScale());
        UINT www = ww * z;
        UINT hhh = hh * z;
        if (m_depth == 3)
            {
            for (yy = 0; yy < hhh;yy+=hh)
                {
                y = yy / z;
                for (x = 0; x < w; x++)
                    {
                    GDOT(x,hh+y);
                    GDOT(x,hh-1-y);
                    }
                }
            for (xx = 0; xx < www; xx += ww)
                {
                x = xx / z;
                for (y = 0; y < h; y++)
                    {
                    GDOT(ww+x,y);
                    GDOT(ww-1-x,y);
                    }
                }
            }
        else
            {
            for (yy = 0; yy < hhh;yy+=hh)
                {
                y = yy / z;
                for (x = 0; x < w; x++)
                    {
                    NDOT(x,hh+y);
                    NDOT(x,hh-1-y);
                    }
                }
            for (xx = 0; xx < www; xx += ww)
                {
                x = xx / z;
                for (y = 0; y < h; y++)
                    {
                    NDOT(ww+x,y);
                    NDOT(ww-1-x,y);
                    }
                }
            }
        }
    if (Flag(2))
        {
        UINT w = ComW();
        UINT h = ComH();
        UINT dp = 4 * ((m_depth*w+3)/4);
        UINT x,y,x1,x2,y1,y2;
        y1 = h/4-1;
        y2 = 3*h/4;
        x1 = w /4-1;
        x2 = 3*w/4;
        if (m_depth == 3)
            {
            for (x = x1; x < x2; x++)
                {
                RDOT(x,y1);
                RDOT(x,y2);
                }
            for (y = y1; y < y2; y++)
                {
                RDOT(x1,y);
                RDOT(x2,y);
                }
            }
        else
            {
            for (x = x1; x < x2; x++)
                {
                MDOT(x,y1);
                MDOT(x,y2);
                }
            for    (y = y1; y < y2; y++)
                {
                MDOT(x1,y);
                MDOT(x2,y);
                }
            }
        }

    if (m_uState)
        ApplyImprint(pBuf);
}

BOOL CScene::Modified(BOOL bClear)
{
    if (bClear)
        m_bModified = FALSE;
    return m_bModified;
}
/*
    needed to allocate larger buffers
*/
void CScene::Broadcasting(BOOL bBroadcast)
{
    if (Broadcast() != 1)
        return;            // not necessary
    if (!m_uState)
        return;
    UINT ow,oh;
    if (bBroadcast)
        {
        ow = m_width;
        oh = m_height;
        }
    else
        {
        ow = ComW();
        oh = ComH();
        }
    int z = ForgeImprint(ow,oh);
    if (z)    // create gauze
        {
        UINT i,c;
        c = ow * oh * m_depth;
        for (i = 0; i < c;i++)
            m_pImprint[i] = 128 + (i & 127);
        }
    DPF("imprintz:%d",z);
}

UINT CScene::Broadcast(UINT v /*=-1*/)
{
    if (v != -1)
        {
        UINT old = (m_flags >> 14) & 3;
        if (v != old)
            {
            if ((v == 2) || (old == 2))
                {
                SetupCache(FALSE, FALSE);
//                for (UINT Frame = 0; Frame < m_frames; m_pFlags[Frame++] = 1);
                }
            m_flags = (m_flags & 0x3fff) | (v << 14);
            Write();
            }
        }
    return (m_flags >> 14) & 3;
}

BOOL CScene::Flag(UINT zwhich, BOOL bSet /*=FALSE */ , BOOL bValue /*=FALSE */)
{
    UINT which = 1 << zwhich;
    if (bSet)
        {
        BOOL bCur = (m_flags & which) ? 1 : 0;
        if (bCur != bValue)
            {
            m_flags ^= which;
            Write();
            if ((zwhich == 1) || (zwhich == 5))
                UpdateCache();
            }
        }
    return m_flags & which ? 1 : 0;
}

int CScene::CheckComposite(UINT zFrame,
            UINT Force /* = 0 */, BOOL bBroadcast /* = 0 */)
{
    UINT Frame;
    int nResult = 0;
    if (!Force && (Broadcast() == 2))
        bBroadcast = 1;
    if (Flag(2))
        bBroadcast = 0;
    if (Force == 2)
        {
        for (Frame = 0; Frame < m_frames; m_pFlags[Frame++] = 1);
            if (zFrame == -1)
                return 0;
        }
    if (zFrame != -1)
        {
//if (!m_pFlags[zFrame]) return 0;
ASSERT(zFrame < m_frames);
        if (m_pLayers && m_pLayers->NeedFake(zFrame))
            Force = 1;
DPF("got zframe:%d",zFrame);
        if (m_pFlags[zFrame] || Force)
            {
            CompositeFrame(m_pCache[zFrame],0, m_levels - 1, zFrame,
                    bBroadcast);
            m_pFlags[zFrame] = 0;
            nResult = 50;
            }
        return nResult;
        }
    for (Frame = m_start; Frame <= m_stop; Frame++)
        {
        if (m_pFlags[Frame])
            {
DPZ("dirty:%d",Frame);
    //        CompositeFrame(m_pCache[Frame],0, m_levels - 1, Frame,m_cache_state);
    CompositeFrame(m_pCache[Frame],0, m_levels - 1, Frame,bBroadcast);
            m_pFlags[Frame] = 0;
            nResult = MulDiv(100, m_frames - Frame, m_frames);
            break;
            }
        }
    if (Flag(2))
        return nResult;        // no sense doing broadcast if red box mode
#ifdef DOBROADCAST
    if (!nResult && !m_cache_state)
        {
        for (Frame = m_start; Frame <= m_stop; Frame++)
            m_pFlags[Frame] = 1;
        m_cache_state = 1;
        nResult = 100;
        }
#endif
//DPF("cache clean:%d",Frame);
    return nResult;
}

UINT CScene::Zoom(UINT zoom )
{
    if ((zoom < 8) && (zoom != m_zoom))
        {
        m_zoom = zoom;
        Write();
        }
    return m_zoom;
}

UINT CScene::SetFactor(UINT Factor)
{
    if ((Factor * m_origfactor) != m_factor)
        {
        m_factor = m_origfactor * Factor;
        Write();
        }
    SetupCache(FALSE, FALSE);
    return m_factor;
}

UINT CScene::SetupCache(BOOL bRead, BOOL bInit /* = TRUE */)
{
    UINT i;
    BOOL bFactoring = 0;
    if (!bRead && !bInit)
        {
        bFactoring = TRUE;
        bRead = TRUE;
        }
DPZ("setup cache:%d",bFactoring);
    m_w = ComW();
    m_h = ComH();
    m_x = 0;
    m_y = 0;
    m_size = m_h * 4 * ((m_depth*m_w+3)/4);
    if (m_pCache)
        {
        for (i = 0; i < m_frames; i++)
            {
            if (m_pCache[i])
                delete [] m_pCache[i];
            m_pCache[i] = 0;
            }
        delete [] m_pCache;
        m_pCache = 0;
        }
    if (m_pCellCache && !bFactoring)
        {
        for (i = 0; i < m_nCells; i++)
            delete [] m_pCellCache[i].pData;
        delete [] m_pCellCache;
        m_pCellCache = 0;
        }
    if (m_pFlags)
        delete [] m_pFlags;
    m_pFlags = new UINT[m_frames];
    m_cache_state = 0;
    m_pCache = new BYTE * [m_frames];
    for (i = 0; i < m_frames; i++)
        m_pCache[i] = 0;
    TRY
        {
        for (i = 0; i < m_frames; i++)
            {
            if (bRead)
                m_pFlags[i] = 1;
            else
                m_pFlags[i] = 0;
            m_pCache[i] = new BYTE[m_size];
            memset(m_pCache[i], 255, m_size);
            }
        }
    CATCH (CMemoryException, e)
        {
        e->ReportError();
        e->Delete();
        return TRUE;
        }
    END_CATCH
//    UINT siz = m_depth == 1 ? 1 : 4;
//    siz *= m_height * m_width;
    if (!m_pCellCache)
        {
        m_nCells = CELLCACHESIZE;
        m_pCellCache = new CELLENTRY[m_nCells];
        for (i = 0; i < m_nCells; i++)
            {
            m_pCellCache[i].dwKey = -1;
            m_pCellCache[i].pData = 0;//new BYTE[siz];
            }
        }
    delete [] m_pXY;
    UINT pw, ph;
    PublishSizes(pw,ph);
    m_pXY = new UINT[2 * pw * ph]; // for export w/o preview
    if (bInit)
        {
        if (m_pScenePalette)
            delete [] m_pScenePalette;
        m_pScenePalette = new BYTE[1024+1024]; // plus def
        if (LoadScenePalette())
            {
            for (i = 0; i < 256;i++)
                {
                m_pScenePalette[4*i+0] = i;
                m_pScenePalette[4*i+1] = i;
                m_pScenePalette[4*i+2] = i;
                m_pScenePalette[4*i+3] = 255;
                }
            }
        }
    if (m_uState)
        {
        int z = ForgeImprint(m_w,m_h);
        if (z)    // create gauze
            {
        UINT i;
        for (i = 0; i < m_size;i++)
        m_pImprint[i] = 128 + (i & 127);
            }
        DPF("imprintz:%d",z);
        }
    return 0;
}

//UINT CScene::Make(DWORD id,  DWORD features,
//        UINT width, UINT height, UINT rate, UINT frames, UINT levels, UINT Factor)
//{
//    DPF("making scene");
//    m_bLoading = FALSE;
//    m_factor = 2 + Factor;
//    m_width = width * m_factor / 2;
//    m_height = height * m_factor / 2;
//    m_frames = frames;
//    m_levels = levels;
//    m_start = 0;
//    m_stop = m_frames - 1;
//    m_dwId = id;
//    m_uState = features & 15 ? 0 : 2;
//#ifdef _THEDISC
//    m_max_frames = 300;
//#else
//    m_max_frames = (features & 15) == FEAT_LITE ? 300 : 1500;
//#endif
//    m_links = 0;
//    m_smark = 0;
//    m_vmark = 1;
//    m_rate = rate;
//    m_origfactor = m_factor;
//    m_zoom = 0;
//    m_wave[0] = 0;
//    delete [] m_pLinks;
//    delete m_pLevels;
//    delete m_pLevel;
//    delete m_pCamera;
//    delete [] m_pInfo;
//    m_info = 0;
//    m_pLevel = new CLevel(m_pIO);
//    m_pLevels = new CLevels(m_pIO);
//    if (!m_pLevels || !m_pLevel) return 7;
//    if (((features & 15) == FEAT_PRO) || !(features & 15) || (features & 0x100))
//        {
//        m_pCamera = new CCamera(m_pIO, KEY_CAMERA);
//        if (!m_pCamera) return 8;
//        m_pCamera->Setup(this);
//        }
//    else
//        m_pCamera = 0;
//    m_pLevels->SetKey(KEY_LEVELS);
//    int nResult = Write();
//    if (!nResult)
//        m_pLevels->Write();
//    m_bOptLock = 0;
//    GetPutOptions(TRUE);
//    if (m_pCamera)
//        m_pCamera->Flush();
////    DPF("insert frames:%d",wResult);
//    SetupCache(FALSE);
//    m_bModified = TRUE;
//    return nResult;
//}
#ifdef _DEBUG
#define CHECKLOG
#endif
#ifdef CHECKING
#ifdef CHECKLOG
void FARCDECL dpc(LPSTR szFormat, ...)
{
    char amsg[280];
    CFile file;
    DWORD mode = CFile::modeWrite;// | CFile::modeCreate;
    if (szFormat[0] == 'Z')
        mode |= CFile::modeCreate;
//    strcpy(amsg,name);
//    strcpy(amsg,"h:\\sketch32");
    strcpy(amsg,"c:");
    strcat(amsg,"\\check.txt");
    if (!file.Open(amsg, mode))
        {
        mode |= CFile::modeCreate;
        if (!file.Open(amsg, mode))
            return;
        }
    wvsprintf(amsg, szFormat,(LPSTR)(&szFormat+1));
//DPF("log:%s",amsg);
    strcat(amsg, "\r\n");
    file.SeekToEnd();
    file.Write(amsg, strlen(amsg));
    file.Close();
}
#endif
#endif
int CScene::Bump(DWORD key, int which /* = 0 */)
{
    UINT i;
    m_pEntry[m_nEntries].dwKey = key;
    for(i = 0;m_pEntry[i].dwKey != key;i++);
    if (i >= m_nEntries)
        {
//dpc("nofnd key:%d, for bump,which:%d",key,which);
        return 1;
        }
    else if (which == 0)
        m_pEntry[i].dwCount++;
    else if (which == 1)
        m_pEntry[i].dwLink++;
    else if (which == 2)
        return i + 2; // to skip over error rteurn
    return 0;
}
int CScene::Check()
{
    UINT Level, Frame, Layer;
    int result = 0;
DPF("checking");
    m_nEntries = m_pIO->RecordCount(0);
    if (!m_nEntries) return 0;
//dpc("count:%d",m_nEntries);
    DWORD key,adr,size,kind;
    m_pEntry = new CHKENTRY[m_nEntries+1];
    if (!m_pEntry)
        return 1;
    UINT i;
    for (i = 0; i < m_nEntries; i++)
        {
        m_pEntry[i].dwCount = 0;
        if (m_pEntry[i].dwStat = m_pIO->RecordInfo(key,size,adr,kind,i,2))
            result++;
        m_pEntry[i].dwKey= key;
        m_pEntry[i].dwAdr = adr;
        m_pEntry[i].dwSize = size;
        m_pEntry[i].dwKind = kind;
        m_pEntry[i].dwLink = 1 + LinkCellRecord(key);
#ifdef CHECKLOG
dpc("i:%4d,key:%5d(%4x),stat:%3d,size:%5d,adr:%5d,kind:%8X,link:%d",i,
        m_pEntry[i].dwKey,
        m_pEntry[i].dwKey,m_pEntry[i].dwStat,
        m_pEntry[i].dwSize,m_pEntry[i].dwAdr,
        m_pEntry[i].dwKind, m_pEntry[i].dwLink);
#endif
//DPF("i:%4d,key:%5d,link:%d",i,key,link);
        }
    result += Bump(KEY_SCENE);
    result += Bump(KEY_LEVELS);
    if (result)
    {
        return result;
    }
    Bump(KEY_LINKS);
    Bump(KEY_OPTIONS);
    Bump(KEY_LEVELINFO);
    Bump(KEY_PALETTE);
    Bump(KEY_TOOLS);
    Bump(KEY_AVI);
    Bump(KEY_CAMERA);
#ifdef _DISNEY
    Bump(KEY_DISPAL);
#endif

    if (m_pLevels->Check())
        {
        result += 999;
//        dpc("Level Check failure");
        m_bModified = TRUE;
        }

    for (Level = 0; Level < m_levels; Level++)
        {
        if (SelectLevel(Level))
            {
//dpc("missing level:%3d",Level);
//if (Level == m_levels - 1)
//    m_levels--;
//        result += 999;
//        m_bModified = TRUE;
            continue;
            }
        result += Bump(m_pLevel->GetKey());
        if (m_pLevel->Cleanup(m_frames))
            {
            result += 99;
//            dpc("Level(%d) Cleanup",Level);
            m_bModified = TRUE;
            }
        for (Frame = 0; Frame < m_frames; Frame++)
            {
            CCell * pCell = (CCell *)GetCellPtr(m_pLevel, Frame, 0);
            if (!pCell )
                continue;
            DWORD cellkey = pCell->GetKey();
            UINT cellcnt = LinkCellRecord(cellkey);
            result += Bump(cellkey);
//dpc("frm:%5d,lvl:%5d,cell key:%4X,cnt:%d",Frame,Level,cellkey,cellcnt);
            if (cellcnt)
                {
                int j = Bump(cellkey,2);
                if (j >= 2)
                    {
                    if (m_pEntry[j-2].dwCount != 1) // if not first
                        cellcnt = 0;
                    }
                }
            for (Layer = 0; Layer < 20; Layer++)
                {
                DWORD key = pCell->Select(Layer);
                if (key)
                    {
//dpc("   layer:%d,key:%4X",Layer,key);
                    DWORD size;
                    int zresult = m_pIO->GetSize(size,key);
//DPF("lvl:%3d,frm:%3d,lay:%d,key:%4X,res:%d",Level,Frame,Layer,key,zresult);
                    if (zresult)
                        {
pCell->DeleteLayer(Layer);
                        result += 10000;
//dpc("bad layer, lvl:%3d,frm:%3d,lay:%d,key:%4X,res:%d",Level,Frame,Layer,key,zresult);
                        
                        }
                    result += Bump(key);
                    UINT q;
                    for (q = 0; q < cellcnt;q++)
                        result += Bump(key,1);
                    }
                }
            delete pCell;
            }
        SelectLevel();
        }
//dpc("cleanup:%d,res:%d",m_nEntries,result);
for (i = 0; i < m_nEntries;i++)
    if ((m_pEntry[i].dwCount != m_pEntry[i].dwLink) ||
        m_pEntry[i].dwStat)
        {
result = 2;
#ifdef CHECKLOG
//dpc("i:%4d,key:%5d,stat:%3d,size:%5d,adr:%5d,kind:%8X,cnt:%3d,link:%d",i,
        m_pEntry[i].dwKey,m_pEntry[i].dwStat,
        m_pEntry[i].dwSize,m_pEntry[i].dwAdr,
        m_pEntry[i].dwKind, m_pEntry[i].dwCount, m_pEntry[i].dwLink);
#endif
if (!m_pEntry[i].dwCount && !m_pEntry[i].dwStat)
    {
//dpc("i:%4d,key:%5d, deleting",i,m_pEntry[i].dwKey);
    m_pIO->DelRecord(m_pEntry[i].dwKey);
    m_bModified = TRUE;
    }
else if ((m_pEntry[i].dwCount != m_pEntry[i].dwLink) &&
                    (m_pEntry[i].dwKind == 4))
    {
//dpc("setting link count,%u",m_pEntry[i].dwCount-1);
    LinkCellRecord(m_pEntry[i].dwKey, m_pEntry[i].dwCount-1,1);
    }
        }
    delete [] m_pEntry;
    m_pEntry = 0;
    return result;
}

BYTE * CScene::LoggedData(BOOL bClear)
{
    if (bClear)
        {
        delete [] m_pLog;
        m_pLog = 0;
        m_logsize = 0;
        }
    return m_pLog;
}

void CScene::LogIt(int Id, UINT level, LPCSTR name /*=0 */)
{
    CString txt;
    txt.LoadString(Id);
    char buf[300];
    if (level == -1)
        {
        if (name)
            sprintf(buf,"%s : %s", (LPCSTR)txt, name);
        else
            sprintf(buf,"%s", (LPCSTR)txt);
        }
    else if (!Id && name)
        strcpy(buf, name);
    else if (name)
        sprintf(buf,"lvl:%d,%s : %s", level, (LPCSTR)txt, name);
    else
        sprintf(buf,"lvl:%d,%s", level, (LPCSTR)txt);
    UINT c = strlen(buf);
    UINT i;
    if (((5 + c + m_logsize+999) / 1000) > ((m_logsize+999) / 1000))
        {
DPZ("grow log,size:%d,c:%d",m_logsize,c);
        i = 1000 * ((5 + c + m_logsize+999) / 1000);
        BYTE * tp = new BYTE[i];
        for (i = 0; i < m_logsize; i++)
            tp[i] = m_pLog[i];
        delete m_pLog;
        m_pLog = tp;
        }
    for (i = 0; i < c; i++)
        m_pLog[m_logsize++] = buf[i];
    m_pLog[m_logsize++] = 13;
    m_pLog[m_logsize++] = 10;
    m_pLog[m_logsize] = 0;
}

int CScene::CheckExternals(int v, int xc)
{
    UINT rc = m_pIO->RecordCount(1);
    UINT level;
    char name[300];
    CLevelTable tbl;
    BYTE xpals[1024];
    for (level = 0; level < m_levels; level++)
        {
        LevelPalName(name, level);
DPZ("name:%s|",name);
        UINT t;
        if (!name[0]) t = 2;
        else if (name[0] == 1) t = 3;
        else if (!strcmp(name,"Unknown")) t = 1;
        else if (!strcmp(name,"Default")) t = 0;
        else
            {
            t = 4;
            if (PaletteIO(name, xpals))
                LogIt(IDS_EXT_PALS,level,name);
            else
                {
                LevelTable(level,&tbl);
                int i;
                for (i = 0; i < 1024; i++)
                    if (tbl.pals[i] != xpals[i])
                        break;
                if (i < 1024)
                    {
                    memmove(tbl.pals,xpals,1024);
                    LevelTable(level,&tbl,TRUE);
                    LogIt(IDS_EXT_PALDIFF,level);
                    }
                }
            }
        if (t < 2)
            {
            v += 10;
            name[0] = t;
            name[1] = 0;
            LevelPalName(name, level, TRUE);
            }
        DPZ("pal,t:%d",t);
        LevelModelName(name, level);
        if (name[0])
            {
            if (TestModel(name, m_width, m_height))
                LogIt(IDS_EXT_MODEL,level,name);
            }
        }
    DPZ("q");
    SceneOptionStr(SCOPT_WAVE,name);
    if (name[0])
        {
        if (TestSound(name))
            {
            LogIt(IDS_EXT_WAVE,-1,name);
            }
        }
    DPZ("qq,v:%d,rc:%d",v,rc);
    if (v)
        LogIt(IDS_EXT_CHECK,-1);
    if (rc > (UINT)(1 + xc))
        return 0x1000;
    else
        return 0;
}

//int CScene::Read(BOOL bPreview , DWORD dwFeatures, DWORD id)
//{
//    m_stop = m_start = 0;
//    LoggedData(TRUE);
//    DPZ("reading scene,features:%x,preview:%d",dwFeatures,bPreview);
//    SCENEHEADER header;
//    if (m_pIO->GetRecord(&header, sizeof(header), KEY_SCENE))
//        return 1;
//    #ifdef _NEEDSWAP
//    SwapHdr((BYTE *)&header);
//    #endif
//    if (header.dwId != DGCID)
//        return 2;
//DPZ("header kind:%d",header.dwKind);
//dpc("Zheader kind:%d",header.dwKind);
//    if ((header.dwKind != 6) &&
//            (header.dwKind != 7) &&
//            (header.dwKind != 8) &&
//            (header.dwKind != 9) &&
//            (header.dwKind != 10) &&
//            (header.dwKind != 11))
//        return 2;
//    BOOL bChanged = FALSE;
//    m_uState = 2;
//    UINT aptype = dwFeatures & 15;
//DPZ("aptype:%d",aptype);
//dpc("aptype:%d",aptype);
//
//    if (aptype)    // release version of ap
//        {
//        if (header.dwKind == 6)
//            {
//            header.dwKind = 7 + aptype;
//            header.dwMyId = id;
//            bChanged = TRUE;
//            m_uState = 0;
//            }
//        else if (header.dwKind > 7)
//            m_uState = 0;
//#ifdef FIXSCENES
//        else
//            {
//            header.dwKind = 8;
//            bChanged = TRUE;
//            m_uState = 0;
//            }
//#endif
///* per Kent 6/20/01
//        else if ((header.dwMyId == id) || !header.dwMyId)
//            {
//            header.dwKind = 7 + aptype;
//            bChanged = TRUE;
//            m_bDemo = FALSE;
//            }
//*/
//        }
//    else            // restricted ap
//        {
//        if (header.dwKind == 6)
//            {
//            bChanged = TRUE;
//            header.dwKind = 7;
//            header.dwMyId = id;
//            m_uState = 1;
//            }
//        else if (header.dwKind > 7)
//            m_uState = 1;
//        }
//DPZ("new kind:%d, state:%d,changed:%d",header.dwKind,m_uState,bChanged);
//    UINT scale  = header.wScale % 256;
//    m_factor = header.wScale / 256;
//    m_origfactor = m_factor & 7;
//    if (!m_origfactor)
//        m_origfactor = 1;
//    else if (m_origfactor > 5)
//        m_origfactor = 5;
//    else if (m_origfactor > 4)
//        m_origfactor = 3;
//    else
//        m_origfactor *= 2;
//    m_zoom = m_factor >> 5;
//    m_factor = (m_factor >> 3) & 3;
//    m_factor = m_origfactor * (1 + m_factor);
//#ifdef MAGIC_FACTOR_FIX
//    m_factor = 2;
//    bChanged = TRUE;
//#endif
////    m_origfactor = 2;
////    m_factor = 8;
////    bChanged = TRUE;
//    m_width = header.wWidth / scale;
//    m_height = header.wHeight / scale;
//    m_flags = header.wFlags;
//    m_dwId = header.dwMyId;
//    if (m_flags & 2)
//        m_depth = 3;
//    else
//        m_depth = 1;
//    m_rate = 24;
//    m_frames = header.wFrameCount;
//    m_levels = header.wLevelCount;
//    m_start = 0;
//    m_stop = m_frames - 1;
//    m_bModified = FALSE;
////    BOOL bHaveCamera = CheckCamera(m_pIO, KEY_CAMERA);
////    BOOL bBadCamera;
////DPZ("have camera:%d", bHaveCamera);
////    if ((aptype == FEAT_PRO) || !aptype || (dwFeatures & 0x100))
////        bBadCamera = 0;
////    else
////        bBadCamera = bHaveCamera;
//    m_max_frames = 1500;
//    UINT max_levels = 6;
//#ifdef _THEDISC
//    m_max_frames = 300;
//    max_levels = 2;
//#else
//    if (aptype == FEAT_LITE)
//        {
//// perKent 1/29/02 final answer
//        m_max_frames = 300;
//        max_levels = 2;
//        }
//    else if (aptype == FEAT_PT)
//        {
//        m_max_frames = 1000;
//        if (m_depth != 1)
//            {
//            bChanged = TRUE;
//            m_depth = 1;
//            LogIt(0,0,"Cannot Do Color");
//            }
//        }
//    else if (aptype == FEAT_STD)
//        {
//        m_max_frames = 1000;
//        }
//    else if (aptype == FEAT_PRO)
//        {
//        max_levels = 100;
////        if (header.dwKind != 11)
////            {
////            header.dwKind = 11;
////            bChanged = TRUE;
////            }
//        }
//#endif
//    if (m_frames > m_max_frames)
//        return 21; // too many frames;
//    if (m_levels > max_levels)
//        {
//        LogIt(IDS_TOO_MANY_LEVELS,m_levels);
//        header.wLevelCount = m_levels = max_levels;
//        bChanged = TRUE;
//        }
//    if (bChanged)
//        {
//        #ifdef _NEEDSWAP
//        SwapHdr((BYTE *)&header);
//        m_pIO->PutRecord(&header, sizeof(header), KEY_SCENE); // update header
//        SwapHdr((BYTE *)&header);
//        #else
//        m_pIO->PutRecord(&header, sizeof(header), KEY_SCENE); // update header
//        #endif
//        }
////m_levels = 3;
////    WORD    wLevelCount;
////    if (header.wDepth != 8)
////        return 3;
//    WORD wResult = 0;
//    delete m_pLevels;
//    m_pLevels = new CLevels(m_pIO);
//    delete m_pLevel;
//    m_pLevel = new CLevel(m_pIO);
//    m_nLevel = -1;
//    if (!m_pLevels || !m_pLevel) return 7;
//    m_pLevels->SetKey(KEY_LEVELS);
//    int result = m_pLevels->Read();
////    m_pLevels->Display();
////    m_levels = m_pLevels->Count();
//DPF("frames:%d,levels:%d,hdr:%d",m_frames,m_levels,header.wLevelCount);
////    if (m_levels < header.wLevelCount)
////        m_levels = header.wLevelCount;
//    delete m_pCamera;
////    if (bHaveCamera)
//    if ((aptype == FEAT_PRO) || !aptype || (dwFeatures & 0x100))
//        {
//DPZ("read camera");
//        m_pCamera = new CCamera(m_pIO, KEY_CAMERA);
//        if (!m_pCamera) return 8;
//        m_pCamera->Setup(this);
//        result = m_pCamera->Read();
//        }
//    else
//        {
//        m_pCamera = 0;
//        result = 0;
//        }
//    delete [] m_pInfo;
//    m_pInfo = 0;
//    m_info = 0;
//    m_links = 0;
//    delete [] m_pLinks;
//    DWORD size;
//    m_pLinks = 0;
//    if (!m_pIO->GetSize(size,KEY_LINKS))
//        {
//        m_links = size / sizeof(LINKENTRY);
//        m_pLinks = new LINKENTRY[m_links];
//        m_pIO->GetSwapRecord(m_pLinks, m_links * sizeof(LINKENTRY),KEY_LINKS);
//        if (m_links) m_links--;
//        }
//    GetPutOptions();
//    int cres = Check();
//DPZ("cres:%d",cres);
//    if (bPreview)
//        return cres;
//    m_bLoading = TRUE;
//    SetupCache(TRUE);
//    cres = CheckExternals(cres,bChanged ? 2 : 0);
//    m_bLoading = FALSE;
//    return cres;
//}

BOOL CScene::ColorMode(UINT mode /* = -1 */)
{
    if (mode != -1)
        {
        UINT d,oldd;
        if (mode)
            d = 3;
        else
            d = 1;
        if (d != m_depth)
            {
            oldd = m_depth;
            Flag(1,TRUE, mode);
            m_depth = d;
            delete [] m_pBG;
            m_pBG = 0;
            if (SetupCache(TRUE, FALSE))
                return oldd > 1 ? FALSE : TRUE;
            }
        }
    return m_depth > 1 ? TRUE : FALSE;
}

BOOL CScene::RedBox(UINT mode /* = -1 */)
{
    BOOL bWas = Flag(2);
    if (mode != -1)
        {
        BOOL bIs =  mode ? TRUE : FALSE;
        if (bWas != bIs)
            {
            bWas = bIs;
            Flag(2,TRUE, bIs);
//            UpdateCache();    // nw if flag(
            }
        }
    return bWas;
}

void CScene::SetFrameRate(UINT rate)
{
    if (rate != m_rate)
        m_bModified = TRUE;
    m_rate = rate;
}

UINT CScene::FrameRate()
{
    return m_rate;
    if (m_bStory)
        return SceneOptionInt(SCOPT_SRATE);
    else
        return SceneOptionInt(SCOPT_RATE);
}

void CScene::SetSelection(UINT start, UINT stop)
{
    if ((start >= m_frames) || (stop >= m_frames))
        return;
    m_start = start;
    m_stop  = stop;
}

void CScene::SetFrameCount(UINT count)
{
    UINT i;
    if (count < m_start)
        {
        m_start = 0;
        m_stop = count - 1;
        }
    else if (count < m_stop)
        m_stop = count - 1;
    if (count > m_frames)
        {
        InsertCache(m_frames,count);
        return;
        }
    UINT * pFlags = new UINT[count];
    LPBYTE * pCache = new BYTE * [count];
    if (count > m_frames)
        {
        m_cache_state = 0;
        for (i = 0; i < m_frames; i++)
            {
            pFlags[i] = m_pFlags[i];
            pCache[i] = m_pCache[i];
            }
        for (;i < count;i++)
            {
            pFlags[i] = 1;
            UINT w = m_width;// / m_scale;
            UINT h = m_height;// / m_scale;
            UINT p = 4 * ((w+3)/4);
            pCache[i] = new BYTE[p * h];
            memset(pCache[i], 255, p * h);
            }
        delete [] m_pFlags;
        delete [] m_pCache;
        m_pFlags = pFlags;
        m_pCache = pCache;
        }
    m_frames = count;
    if (m_pCamera)
        m_pCamera->Update();
//        m_pCamera->Setup(this);
    Write();
}

void CScene::SetLevelCount(UINT count)
{
    if (m_pInfo && (count > m_levels))
        {
        UINT * tp = new UINT[count+1];
        UINT i;
        for (i = 0; i <= m_levels; i++)
            tp[i] = m_pInfo[i];
        for (; i <= count; i++)
            tp[i] = 9999;
        delete [] m_pInfo;
        m_pInfo = tp;
        }
    m_levels = count;
//    m_pLevels->Count(m_levels);
    if (m_pCamera)
        m_pCamera->Update();
    m_info = 0;
    Write();
}

int CScene::Write()
{
    SCENEHEADER header;
    header.dwId = DGCID;
    header.dwKind = m_uState ? 7 : 8;
    header.wWidth = m_width;
    header.wHeight = m_height;
    UINT zz;
    if (m_origfactor == 3)
        zz = 5;
    else if (m_origfactor == 5)
        zz = 6;
    else
        zz = m_origfactor / 2;
    UINT ff = (m_factor / m_origfactor) - 1;
    zz += (m_zoom << 5) + (ff << 3);
    header.wScale = 256 * zz + 1;// + m_scale;
    header.wFlags = m_flags;
    header.dwMyId = m_dwId;
    header.wFrameCount = FrameCount();
    header.wLevelCount = LevelCount();
    #ifdef _NEEDSWAP
    SwapHdr((BYTE *)&header);
    #endif
    if (m_pIO->PutRecord(&header, sizeof(header), KEY_SCENE))
        return 1;
    m_bModified = TRUE;
    return 0;
}

void CScene::LevelName(LPSTR name, UINT Level, BOOL bPut)
{
    if (!bPut)
        name[0] = 0;
    if (!SelectLevel(Level, bPut))
        {
        m_pLevel->Name(name,bPut);
        if (bPut)
            m_bModified = TRUE;
        SelectLevel();
        }
    else
        {
        if (Level)
            sprintf(name,"%d",Level);
        else
            strcpy(name,"BG");
        }
}

void CScene::LevelPalName(LPSTR name, UINT Level, BOOL bPut /* = 0 */)
{
    if (!bPut)
        name[0] = 0;
    if (!SelectLevel(Level, bPut))
        {
        m_pLevel->PalName(name,bPut);
        if (bPut)
            m_bModified = TRUE;
        SelectLevel();
        }
}

void CScene::LevelModelName(LPSTR name, UINT Level, BOOL bPut /* = 0 */)
{
    if (!bPut)
        name[0] = 0;
    if (!SelectLevel(Level, bPut))
        {
        m_pLevel->ModelName(name,bPut);
        if (bPut)
            m_bModified = TRUE;
        SelectLevel();
        }
}

DWORD CScene::LevelFlags(UINT Level, DWORD val /* = -1 */)
{
    BOOL bMake = val != -1 ? TRUE : FALSE;
    DWORD v = 1;    // default to enabled
    if (!SelectLevel(Level, bMake))
        {
        v = m_pLevel->Flags(val);
        if (bMake)
            m_bModified = TRUE;
        SelectLevel();
        }
    return v;
}

DWORD CScene::GetCellKey(UINT Frame, UINT Level, BOOL bHold /* = 0 */)
{
    if (SelectLevel(Level))
        return 0;
DPF("getcellkey,f:%d,l:%d",Frame,Level);
    DWORD key = m_pLevel->Select(Frame,bHold);
DPF("getcellkey,f:%d,l:%d,k:%d",Frame,Level,key);
    SelectLevel();
    return key;
}

DWORD CScene::LinkCell(UINT Frame, UINT Level)
{
    DWORD key = GetCellKey(Frame, Level);
    LinkCellRecord(key, 1);
    return key;
}

UINT CScene::LinkCellRecord(DWORD key, int inc, BOOL bForce /* = 0 */)
{
    UINT i;
    UINT result;
//DPF("linkcellrec,k:%d,inc:%d",key,inc);
    for (i = 0; i < m_links; i++)
        {
//ASSERT(m_pLinks[i].dwCount);
        if (m_pLinks[i].dwKey == key)
            break;
        }
    if (bForce)
        {
        if (i < m_links)
            {
            if (!(m_pLinks[i].dwCount = inc))
                {
                m_links--;
                for (; i < m_links;i++)
                    m_pLinks[i] = m_pLinks[i+1];
                }
            m_pIO->PutSwapRecord(m_pLinks, (m_links+1) * sizeof(LINKENTRY), KEY_LINKS);
            m_bModified = TRUE;
            }
        else if (inc > 0)
            {
            LINKENTRY * pTemp = new LINKENTRY[m_links+2];
            if (!pTemp)
                return 0;
            for (i = 0; i < m_links;i++)
                pTemp[i] = m_pLinks[i];
            delete [] m_pLinks;
            m_pLinks = pTemp;
            m_links++;
            m_pLinks[i].dwKey = key;
            m_pLinks[i].dwCount = inc;
            m_pIO->PutSwapRecord(m_pLinks, (m_links+1) * sizeof(LINKENTRY), KEY_LINKS);
            m_bModified = TRUE;
            }
        return 0;
        }
    if (i >= m_links)
        {
        if ((inc != 1) && (!bForce))
            return 0;
        LINKENTRY * pTemp = new LINKENTRY[m_links+2];
        if (!pTemp)
            return 0;
        for (i = 0; i < m_links;i++)
            pTemp[i] = m_pLinks[i];
        delete [] m_pLinks;
        m_pLinks = pTemp;
        m_links++;
        m_pLinks[i].dwKey = key;
        m_pLinks[i].dwCount = 0;
        }
    if (inc == 1)
        m_pLinks[i].dwCount += inc;
    if ((inc < 0) && (m_pLinks[i].dwCount))
        {
        result = m_pLinks[i].dwCount--;
        if (!result)
            {
            m_links--;
            for (; i < m_links;i++)
                m_pLinks[i] = m_pLinks[i+1];
            }
        }
    else
        result = m_pLinks[i].dwCount;
    if (inc)
        {
        m_pIO->PutSwapRecord(m_pLinks, (m_links+1) * sizeof(LINKENTRY), KEY_LINKS);
        m_bModified = TRUE;
        }
    return result;
}

UINT CScene::SetCellKey(UINT Frame, UINT Level, DWORD key)
{
    if (SelectLevel(Level, 1))
        return 0;
    DWORD cellkey = m_pLevel->Select(Frame);
    UINT result = 0;
    if (!cellkey && key)
        {
        m_bModified = TRUE;
        LinkCellRecord(key, 1);
        result = m_pLevel->Insert(Frame, key);
        }
ASSERT(Frame < m_frames);
    m_pFlags[Frame] = 1;
    m_cache_state = 0;
    SelectLevel();
    return result;
}

void CScene::ProcessCellLabel(CString & alabel, UINT hold)
{
    if (!alabel.GetLength())
        return;
    char label[20];
    strncpy(label,(LPCSTR)alabel,19);
    label[19] = 0;
    int j,l,v,f;
    l = 99;
    for (j = 0; label[j]; j++)
        if ((label[j] >= '0' ) && (label[j] <= '9'))
            l = j;
    if (l == 99)
        {
        alabel = "";
        return;
        }
    strcpy(m_xcellname,label);
    f = 1;
    v = 0;
    for (j = l;;j--)
        {
        if ((label[j] < '0' ) || (label[j] > '9'))
            {
            j++;
            break;
            }
        v = v + f * (label[j] & 15);
        f *= 10;
        if (!j)
            break;
        }
    sprintf(label+j,"%d",v + hold);
    label[19] = 0;
    alabel = label;
}

void CScene::CellName(LPSTR name, UINT Frame, UINT Level, BOOL bPut)
{
    if (!bPut)
        name[0] = 0;
    if (SelectLevel(Level, bPut))
        return;
    CCell * pCell = (CCell *)GetCellPtr(m_pLevel, Frame, 0);
    if (pCell)
        {
        if (!bPut)
            {
            pCell->Name(name,bPut);
            if (!name[0])
                {
                m_pLevel->Name(name);

                bPut = 1;
                }
            }
        if (bPut)
            {
            pCell->Name(name,bPut);
            m_bModified = TRUE;
            pCell->Write();
            }
        delete pCell;
        }
    SelectLevel();
}

UINT CScene::InsertCache(UINT Start, UINT End)
{
    UINT i;
    m_cache_state = 0;
    if (End > Start)
        {
//ASSERT(Start == m_frames);
        BOOL bAppend = Start == m_frames ? 1 : 0;
        UINT count = End - Start;
        m_frames += count;
        if ((m_start + 1) >= Start)
            m_start += count;
        if ((m_stop + 1) >= Start)
            m_stop += count;
        UINT * pFlags = new UINT[m_frames];
        LPBYTE * pCache = new BYTE * [m_frames];
        for (i = 0; i < Start; i++)
            {
            pFlags[i] = m_pFlags[i];
            pCache[i] = m_pCache[i];
            }
        for (; i < End; i++)
            {
            pCache[i] = new BYTE[m_size];
            if ((count > i) || bAppend)
                {
                pFlags[i] = 1;
                memset(pCache[i], 255, m_size);
                }
            else
                {
                pFlags[i] = m_pFlags[i-count];
                memcpy(pCache[i], m_pCache[i-count], m_size);
                }
            }
        for (; i < m_frames; i++)
            {
            pFlags[i] = m_pFlags[i - count];
            pCache[i] = m_pCache[i - count];
            }
        delete [] m_pFlags;
        delete [] m_pCache;
        m_pFlags = pFlags;
        m_pCache = pCache;
        Write();
        }
    else
        {
        UINT count = Start - End;
        m_frames -= count;
        if (m_start >= Start)
            m_start -= count;
        if (m_stop >= m_frames)
            m_stop = m_frames - 1;
        else if (m_stop >= Start)
            m_stop -= count;
        UINT * pFlags = new UINT[m_frames];
        LPBYTE * pCache = new BYTE * [m_frames];
        for (i = 0; i < End; i++)
            {
            pFlags[i] = m_pFlags[i];
            pCache[i] = m_pCache[i];
            }
        for (; i < Start; i++)
            delete [] m_pCache[i];
        i = End;
        for (; i < m_frames; i++)
            {
            pFlags[i] = m_pFlags[i + count];
            pCache[i] = m_pCache[i + count];
            }
        delete [] m_pFlags;
        delete [] m_pCache;
        m_pFlags = pFlags;
        m_pCache = pCache;
        Write();
        }
    if (m_pCamera)
        m_pCamera->Update();
    return 0;
}

UINT CScene::ChangeFrames(UINT Start, UINT End)
{
DPZ("chg frm,%d,%d",Start,End);
    UINT Save = m_nLevel;
    UINT Level;
    if (Start == End)
        Start = m_frames;
//    else if ((Start + 1) < m_frames)
    else if (Start < m_frames)
        {
        for (Level = 0; Level < m_levels; Level++)
            {
            if (!SelectLevel(Level, 0))
                {
                m_pLevel->MoveFrames(Start,End);
                SelectLevel();
                }
            }
        }
    InsertCache(Start, End);
    if (m_pCamera)
        m_pCamera->Update();
    return 0;
}


UINT CScene::ChangeLevels(UINT Start, UINT Count)
{
    if (m_pCamera)
        m_pCamera->Update();
    return 0;
}

UINT CScene::SlideCells(UINT From, UINT To,
            UINT StartL, UINT EndL, UINT Count)
{
    UINT Level, Low, High;
    UINT Save = m_nLevel;
    if (From < To)
        {
        Low = From;
        High = To;
        High = To + Count;
        }
    else
        {
        Low = To;
        High = From;
        }
    if (!Count)
        Count = m_frames - High;
    else if ((High + Count) >= m_frames)
        Count = m_frames - High;
    for (Level = StartL; Level <= EndL; Level++)
        {
        if (!SelectLevel(Level))
            {
            m_pLevel->MoveFrames(From, To, Count);
            UpdateCache(Low, Level, High + Count - Low);
            SelectLevel();
            }
        }
    m_bModified = TRUE;
    return 0;
}

UINT CScene::BlankCell(UINT Frame, UINT Level)
{
DPF("blank cell,frm:%d,lvl:%d",Frame,Level);
    if (SelectLevel(Level))
        return 1;
DPF("modified");
    m_bModified = TRUE;
    CCell * pCell = (CCell *)GetCellPtr(m_pLevel, Frame, TRUE);
    SelectLevel();
    if (!pCell)
        return 2;
    BlowCell(Frame,Level);    // from cell cache
//    pCell->DeleteLayer(CCell::LAYER_MONO);
    pCell->DeleteLayer();
    delete pCell;
/*
    UINT size = 4 * m_height * ((m_width +3) / 4);
    BYTE * tbuf = new BYTE[size];
    memset(tbuf, 255, size);        // this will stop composite
    if (Level == -1)
        Level = m_CurLevel;
    PutImage(tbuf, Frame,Level,CCell::LAYER_GRAY);
    UpdateCache(Frame, Level);
    delete [] tbuf;
*/
//    BlankThumb(Frame, Level);
    return 0;
}

UINT CScene::DeleteCell(DWORD dwKey)
{
    DPF("deleting cell:%d",dwKey);
    if (!dwKey) return 0;
    if (LinkCellRecord(dwKey, -1))
        return 0;
    m_bModified = TRUE;
    CCell * pCell = new CCell(m_pIO);
    if (pCell == NULL)
        {
DPF("new failure");
        return 1;
        }
    pCell->SetKey(dwKey);
    if (pCell->Read())
        {
DPF("read failure");
        delete pCell;
        return 2;
        }
    pCell->DeleteLayer();
    delete pCell;
    m_pIO->DelRecord(dwKey);
    return 0;
}

UINT CScene::DeleteCell(UINT Frame, UINT Level, BOOL bDelete)
{
DPF("delete cell,frm:%d,lvl:%d,bd:%d",Frame,Level,bDelete);
//    if (Frame == m_GrayFrame)
//        m_GrayFrame = -1;
    if (SelectLevel(Level))
        return 1;
DPF("modified");
    m_bModified = TRUE;
    if (bDelete)
        {
        CCell * pCell = (CCell *)GetCellPtr(m_pLevel, Frame, 0);
        if (pCell)
            {
            DWORD key = pCell->GetKey();
            if (!LinkCellRecord(key, -1))
                {
                pCell->DeleteLayer();
                m_pIO->DelRecord(key);
                }
            delete pCell;
            }
        }
    m_pLevel->DeleteCell(Frame);
    SelectLevel();
    return 0;
}

BOOL CScene::GetBackground(HPBYTE hpDst, UINT Frame, UINT min)
{
    if (m_depth != 1)
        min = 100;
    return GetLevel0(hpDst,Frame,1, min,0,1);// using broad cast to thwart fill
}

BOOL CScene::GetLevel0(HPBYTE hpDst, UINT Frame,
                        BOOL bHold, UINT min, BOOL bCamera, BOOL bBroadcast)
{
    UINT OrigFrame = Frame;
    BYTE * hpTemp = 0;
    BYTE * hpSrc = 0;
    UINT w = ComW();
    UINT h = ComH();
    UINT siz;
    if (bCamera)
        siz = m_size;
    else
        siz = m_height * 4 * ((m_depth*m_width+3) / 4);
memset(hpDst,255,siz);
    if (!min)
        {
//        memset(hpDst,255,siz);
        return TRUE;
        }
    UINT which;
    DWORD key;
    for (;;)
        {
        which = CCell::LAYER_BG;
        GetImageKey(key, Frame, 0, which);
        if (key)
            break;
//        which = CCell::LAYER_GRAY;
//        GetImageKey(key, Frame, 0, which);
//        if (key)
//            break;
        if (!bHold)
            break;
        if (!Frame)
            break;
        Frame--;
        }
    if (!key)
        {
        if (bCamera || !bBroadcast)    // from edit
            memset(hpDst,255,siz);
        return 0;
        }
    UINT iw, ih, idd;
    if (m_pBG && (m_BGk == key) && (m_BGmin == min) && (m_BGd == m_depth))
        {
        iw = m_BGw;
        ih = m_BGh;
        idd = 24;//m_BGd;
        }
    else
        {
        UINT id;
        if (ImageInfo(iw,ih,id, key))
            {
DPZ("bad info");
        return 0;
            }
//DPZ("info iw:%d,ih:%d,id:%d",iw,ih,id);
        if (iw > 8192)
            return 0;
        if (id != 24)
            return 0;
        UINT size = ih;
        if (!m_pBG || (m_BGh != ih) || (m_BGw != iw) || (m_BGd != m_depth))
            {
            int ip;//,tp;
            delete [] m_pBG;
////            ip = 4 * ((m_depth * iw + 3) / 4);
            ip = 4 * ((3 * iw + 3) / 4);
            size *= ip;
            m_pBG = new BYTE[size];
            m_BGw = iw;
            m_BGh = ih;
            m_BGmin = min;
            m_BGd = m_depth;
            }
        m_BGk = key;
        m_BGmin = min;
        if (m_depth == 1)
            {
            UINT ip = 4 * ((3 * iw + 3) / 4);
            UINT op = 4 * ((iw + 3) / 4);
            UINT x, y;
            BYTE * pTemp = new BYTE[ih * ip];
            ReadImage(pTemp, key);
            for (y = 0; y < ih; y++)
            for (x = 0; x < iw; x++)
                {
                UINT v = 30 * pTemp[y*ip+3*x+0] +
                         59 * pTemp[y*ip+3*x+1] +
                         11 * pTemp[y*ip+3*x+2];
                v /= 100;
                v = 255 - ((255 - v) * min) / 100;
                m_pBG[y*op+x] = v;
                }
            delete [] pTemp;
            }
        else
            ReadImage(m_pBG, key);
        }
    if (!bCamera)    // just fetch for edit, or thumb
        {
        UINT x,y;
         if ((m_depth == 3) || (m_depth== 1))
            {
            w = m_width;
            h = m_height;
            UINT op = 4 * ((m_depth * w + 3) / 4);
            UINT ip = 4 * ((m_depth * iw + 3) / 4);
            UINT cx = m_depth * min(w, iw);
            UINT cy = min(h, ih);
            BYTE * pDst = hpDst;
            BYTE * pSrc = m_pBG;

            if (h > ih)
                pDst += op * ((h - ih) / 2);
            else
                pSrc += ip * ((ih - h) / 2);
            if (w > iw)
                pDst += m_depth * ((w - iw) / 2);
            else
                pSrc += m_depth * ((iw - w) / 2);

            for (y = 0; y < cy; y++)
                {
                memmove(pDst, pSrc, cx);
                pDst += op;
                pSrc += ip;
                }
            }
        else if (m_depth == 4)
            {
            w = m_width;
            h = m_height;
            UINT op = 4 * ((4 * w + 3) / 4);
            UINT ip = 4 * ((3 * iw + 3) / 4);
            UINT cx = min(w, iw);
            UINT cy = min(h, ih);
            BYTE * pDst = hpDst;
            BYTE * pSrc = m_pBG;
            if (h > ih)
                pDst += op * (h - ih) / 2;
            else
                pSrc += ip * (ih - h) / 2;
            if (w > iw)
                pDst += 4 * ((w - iw) / 2);
            else
                pSrc += 4 * ((iw - w) / 2);
            for (y = 0; y < cy; y++)
                {
                for (x = 0; x < cx; x++)
                    {
                    pDst[4*x+0] = pSrc[3*x+0];
                    pDst[4*x+1] = pSrc[3*x+1];
                    pDst[4*x+2] = pSrc[3*x+2];
                    pDst[4*x+3] = 255;
                    }
                pDst += op;
                pSrc += ip;
                }
            }
        return 1;
        }
    if (m_pCamera)
        bCamera = m_pCamera->SetupCell(OrigFrame, 0);
    else
        bCamera = 0;
    Apply24(hpDst, m_pBG, iw, ih, bCamera, bBroadcast);
    return 1;
}

BOOL CScene::SelectLevel(UINT Level /* = 9999 */, BOOL bMake /* = 0 */)
{
    if (Level == 9999)
        {
        ASSERT(m_nStack > 1);
        m_nStack--;
        Level = m_Stack[m_nStack];
        m_nStack--;
        if (m_nLevel != Level)
            {
            m_nLevel = Level;//m_Stack[m_nStack];
            delete m_pLevel;
            m_pLevel = (CLevel *)m_Stack[m_nStack];
            }
        return 0;
        }
ASSERT(m_nStack < 18);
    if (Level == m_nLevel)
        {
        m_Stack[m_nStack++] = 0;
        m_Stack[m_nStack++] = m_nLevel;
        return 0;
        }
//    if (Level >= m_levels)
//        {
//        m_nLevel = -1;
//        return 0;
//        }
    DWORD levelkey = m_pLevels->Select(Level);
    if (!levelkey && !bMake)
        {
//ASSERT(0);
        return 1;
        }
    m_Stack[m_nStack++] = (UINT)m_pLevel;
    m_Stack[m_nStack++] = m_nLevel;
    m_pLevel = new CLevel(m_pIO);
    m_nLevel = Level;
    if (!levelkey)
        {
        levelkey = m_pLevels->Insert(Level);
        if (!levelkey)
            {
DPZ("insert level failure");
ASSERT(0);
            SelectLevel();    // pop stack
            return 1;
            }
        char buf[20];
        if (Level)
            sprintf(buf,"%d", Level);
        else
            strcpy(buf,"BG");
//        m_pLevel->Name(buf,TRUE);
        m_pLevel->SetKey(levelkey);
        m_pLevel->Flags(1,1);        // enable it
        m_pLevel->Name(buf,TRUE);
//        pLevel->Write();
        m_bModified = TRUE;
        }
    else
        {
        m_pLevel->SetKey(levelkey);
        if (m_pLevel->Read())
            {
DPZ("sl read failure");
//ASSERT(0);
            SelectLevel();    // pop stack
            return 1;
            }
#ifdef AUTONAME
        char buf[20];
        m_pLevel->Name(buf);
        if (!buf[0])
            {
            sprintf(buf,"%c", 'A'+Level);
DPF("making level:%s",buf);
            m_pLevel->Name(buf,TRUE);
//            pLevel->Write();
            m_bModified = TRUE;
            }
#endif
        }
    return 0;
}


CCell * CScene::GetCellPtr(CLevel * pLevel, UINT Frame, BOOL bMake)
{
    DWORD cellkey = ((CLevel *)pLevel)->Select(Frame);
    if (!cellkey && !bMake)
        return 0;
    CCell * pCell = new CCell(m_pIO);
    if (pCell == NULL)
        {
DPF("new failure");
ASSERT(0);
        return 0;
        }
    if (!cellkey)
        {
        cellkey = pLevel->Insert(Frame);
        if (!cellkey)
            {
DPF("insert failure");
            delete pCell;
            return 0;
            }
        char buf[30];
        char lvl[30];
        ((CLevel*)pLevel)->Name(lvl);
        if (m_xcellname[0])
            sprintf(buf,"%s - %s", lvl, m_xcellname);
        else
            sprintf(buf,"%s - %d", lvl, Frame+1);
        m_xcellname[0] = 0; //disable further use
        pCell->Name(buf, TRUE);
        pCell->SetKey(cellkey);
        pCell->Write();
        }
    else
        {
        pCell->SetKey(cellkey);
        if (pCell->Read())
            {
DPF("read failure");
ASSERT(0);
            delete pCell;
            return 0;
            }
#ifdef AUTONAME
        char buf[30];
        pCell->Name(buf);
        if (!buf[0])
            {
            char lvl[30];
            ((CLevel*)pLevel)->Name(lvl);
            ((CLevel*)pLevel)->Name(lvl);
            if (m_xcellname[0])
                sprintf(buf,"%s - %s", lvl, m_xcellname);
            else
                sprintf(buf,"%s - %d", lvl, Frame+1);
            m_xcellname[0] = 0; //disable further use
            pCell->Name(buf, TRUE);
            pCell->Write();
            }
#endif
        }
    return pCell;
}

int     CScene::GetImageKey(DWORD& key, UINT Frame,
                    UINT Level, UINT Which, BOOL bMake)
{
    if (SelectLevel(Level,bMake))
        {
//DPF("no level");
        if (bMake)
            {
ASSERT(0);
DPF("error 1");
            }
        key = 0;
//        SelectLevel(Save);
        return 0;
        }
    CCell * pCell = GetCellPtr(m_pLevel, Frame, bMake);
    SelectLevel();
    if (pCell == NULL)
        {
//DPF("no cell");
        if (bMake)
            {
DPF("error 2");
ASSERT(0);
            }
        key = 0;
        return 0;
        }
//    CImage * pImage = (CImage *)GetImagePtr(pCell, Which, bMake);
    key = pCell->Select(Which);
    if ((key < 2) && !bMake)
        {
        delete pCell;
        return 0;
        }
    if (!key)
        {
        key = pCell->Insert(Which);
        if (!key)
            {
DPF("insert image failure");
ASSERT(0);
            return 0;
            }
        }
    delete pCell;
    return 0;
}

int     CScene::GetImageKey(DWORD& key, DWORD cellkey, UINT Which)
{
    CCell * pCell = new CCell(m_pIO);
    if (!cellkey || pCell == NULL)
        {
DPF("new failure");
ASSERT(0);
        return 0;
        }
    pCell->SetKey(cellkey);
    if (pCell->Read())
        {
DPF("read failure");
ASSERT(0);
        delete pCell;
        return 0;
        }
    key = ((CCell *)pCell)->Select(Which);
    if (!key)
        {
        delete pCell;
        return 0;
        }
    delete pCell;
    return 1;
}

int  CScene::ForgeImage(HPBYTE hpDst, UINT which)
{
    WORD x, y, p,w,h,s,v;
    if (which == CCell::LAYER_GRAY)
        s = 1;//m_scale;
    else
        s = 1;
    w = m_width / s;
    h = m_height /s;
    p = w;
    if (which == CCell::LAYER_INK)
        {
        p = 4 * (( w + 3) / 4);
        h *= 2;
        v = 0;
        }
    else
        v = 255;
    DPF("forge,w:%d,h:%d,which:%d",w,h,which);
    for (y = 0; y < h; y++)
        for (x = 0; x < w;x++)
            hpDst[p * y + x] = (BYTE)v;
    return 0;
}

int  CScene::ImageInfo(UINT & w, UINT &h, UINT & d, DWORD key)
{
    CImage * pImage = new CImage(m_pIO);
    if (pImage == NULL)
        {
DPZ("new read failure");
        return 0;
        }
    pImage->SetKey(key);
    int result = pImage->Read(0);
    w = pImage->Width();
    h = pImage->Height();
    d = pImage->Depth();
    delete pImage;
    return result;
}

int  CScene::ReadImage(HPBYTE hpDst, DWORD key)
{
    CImage * pImage = new CImage(m_pIO);
    if (pImage == NULL)
        {
DPF("new read failure");
ASSERT(0);
        return 0;
        }
    pImage->SetKey(key);
    int result = pImage->Read(hpDst);
    delete pImage;
    return result;
}

int  CScene::WriteOverlay(HPBYTE hpDst, UINT Frame, UINT Level, UINT w, UINT h)
{
    DWORD key;
//    DeleteCell(Frame,Level,TRUE);
    GetImageKey(key, Frame, Level,
            Level ? CCell::LAYER_OVERLAY : CCell::LAYER_BG, TRUE);
    if (key == 0)
        {
DPF("wrt overly, null key after bmake");
        return 9;
        }
    CImage * pImage = new CImage(m_pIO);
    if (pImage == NULL)
        {
DPF("new write failure");
ASSERT(0);
        return 2;
        }
    pImage->SetKey(key);
    int result;
    UINT d = Level ? 32 : 24;
#ifdef NOCOMPRESS
    pImage->Setup(w, h, d, 0);
#else
    pImage->Setup(w, h, d, 1);
#endif
    result = pImage->Write(hpDst);
    m_bModified = TRUE;
    delete pImage;
    return result;
}

int  CScene::WriteImage(HPBYTE hpDst, DWORD key, UINT which)
{
    DWORD w,h,f,d;
    f = 0;
    d = 8;
    switch (which) {
    case CCell::LAYER_MONO:
        f = 1;
        w = m_width;
        h = m_height;
        break;
    case CCell::LAYER_THUMB:
        w = m_thumbw;
        h = m_thumbh;
        break;
    case CCell::LAYER_GRAY:
        w = m_width;// / m_scale;
        h = m_height;// / m_scale;
        f = 1;
        break;
    case CCell::LAYER_INK:
    case CCell::LAYER_PAINT:
        d = 16;
        f = 1;
        w = m_width;// / m_scale;
        h = m_height;// / m_scale;
        break;
    case CCell::LAYER_MATTE0:
    case CCell::LAYER_MATTE1:
    case CCell::LAYER_MATTE2:
    case CCell::LAYER_MATTE3:
    case CCell::LAYER_MATTE4:
    case CCell::LAYER_MATTE5:
    case CCell::LAYER_MATTE6:
    case CCell::LAYER_MATTE7:
    case CCell::LAYER_MATTE8:
    case CCell::LAYER_MATTE9:
        d = 16;
        f = 1;
        w = m_width;// / m_scale;
        h = m_height;// / m_scale;
        break;
    case CCell::LAYER_BG:
        f = 1;
        d = 24;
        w = m_width;// / m_scale;
        h = m_height;// / m_scale;
        break;
    default:
DPF("doing blank, which:%d",which);
        f = 0;
        w = 1;
        h = 1;
        break;
    }
#ifdef NOCOMPRESS
    f = 0;
#endif
    CImage * pImage = new CImage(m_pIO);
    if (pImage == NULL)
        {
DPF("new write failure");
ASSERT(0);
        return 2;
        }
    pImage->SetKey(key);
    int result;
    pImage->Setup(w, h, d, f);
    result = pImage->Write(hpDst);
    m_bModified = TRUE;
    delete pImage;
    return result;
}

void CScene::GetImage(HPBYTE hpDst, UINT Frame, UINT Level, UINT Which)
{
    if (Level == -1)
        Level = m_CurLevel;
DPF("get image,f:%d,l:%d,w:%d",Frame,Level,Which);
    DWORD key;
    GetImageKey(key, Frame, Level,Which);
    if (key == 0)
        {

        if (Which == CCell::LAYER_MONO)
            {
            GetImageKey(key, Frame, Level,CCell::LAYER_GRAY);
            if (key != 0)
                {
                ReadImage(hpDst, key);
                MakeMono(hpDst);
                return;
                }
            }

        ForgeImage(hpDst, Which);
        return;
        }
    else
        ReadImage(hpDst, key);
    return ;
}

void CScene::GetMono(HPBYTE hpDst, UINT Frame, UINT Level)
{
    GetImage(hpDst,Frame,Level,CCell::LAYER_MONO);
}

HPBYTE CScene::GetCacheP(UINT Frame)
{
    if (m_pFlags[Frame] && (m_depth == 3))
        {
        UINT w = ComW();
        UINT h = ComH();
        UINT y;
        UINT cx, cy;
        cx = w / 2;
        cy = h / 2;
        UINT hh = h / 3;
        UINT pp = 4 * ((3 * w + 3) / 4);
        BYTE * p = m_pCache[Frame];
        for (y = 0; y < hh; y++)
            {
            p[pp * (cy - y) + 3 * (cx - y)+2] = 255;
            p[pp * (cy - y) + 3 * (cx - y)+1] = 0;
            p[pp * (cy - y) + 3 * (cx - y)+0] = 0;
            p[pp * (cy - y) + 3 * (cx + y)+2] = 255;
            p[pp * (cy - y) + 3 * (cx + y)+1] = 0;
            p[pp * (cy - y) + 3 * (cx + y)+0] = 0;
            p[pp * (cy + y) + 3 * (cx - y)+2] = 255;
            p[pp * (cy + y) + 3 * (cx - y)+1] = 0;
            p[pp * (cy + y) + 3 * (cx - y)+0] = 0;
            p[pp * (cy + y) + 3 * (cx + y)+2] = 255;
            p[pp * (cy + y) + 3 * (cx + y)+1] = 0;
            p[pp * (cy + y) + 3 * (cx + y)+0] = 0;
            }
        }
    return m_pCache[Frame];
}

void CScene::GetGray(HPBYTE hpDst, UINT Frame, UINT Level)
{
    if (Level == -1)
        Level = m_CurLevel;
//    GetImage(hpDst,Frame,Level,CCell::LAYER_GRAY);
    if (GetCell32(Frame, Level, TRUE))
        return;
    BYTE * hpTmp = m_pCellCache[0].pData;
    UINT x,y,p,z;
    ASSERT(m_depth == 1);
    UINT w = m_width;
    UINT h = m_height;
    z = 255;
    p = 4 * ((w + 3) / 4);
    for (y = 0; y < h; y++)
        {
        for (x = 0; x < w; x++)
            {
            hpDst[x] = z ^ hpTmp[x];
            }
        hpDst += p;
        hpTmp += p;
        }
}

UINT CScene::CellInfo(HPBYTE hpDst, UINT Frame, UINT Level, BOOL bHold,
                UINT & w, UINT & h, UINT & kkey)
{
    if (Level)
        {
        if (GetCell32(Frame, Level,bHold))
            return 0;
        w = m_pCellCache[0].iw;
        h = m_pCellCache[0].ih;
        UINT d = m_depth == 3 ? 4 : 1;
        kkey = 0;
        if (hpDst)
            {
            BYTE * hpTmp = m_pCellCache[0].pData;
            memmove(hpDst, hpTmp, d * w * h);
            }
        return 1;
        }
    UINT which;
    DWORD key;
    for (;;)
        {
        which = CCell::LAYER_BG;
        GetImageKey(key, Frame, 0, which);
        if (key)
            break;
        if (!bHold)
            break;
        if (!Frame)
            break;
        Frame--;
        }
    if (!key)
        return 0;
    UINT iw,ih,id;
    if (ImageInfo(iw,ih,id, key))
        {
DPZ("bad info");
        return 0;
        }
    if (iw > 8192)
        return 0;
    if ((id != 24) && !Level)
        return 0;
    w = iw;
    h = ih;
    kkey = key;
    return 1;
}

void CScene::FetchCell(HPBYTE hpDst, UINT Frame, UINT Level, BOOL b32,
                        BOOL bUseGray, BOOL bHold /* = 0 */)
{
    if (Level == -1)
        Level = m_CurLevel;
    if (!Level)
        {
        if (!b32)
            {
            GetLevel0(hpDst,Frame,1, 100,0,0);
            }
        return;
        }
    if (GetCell32(Frame, Level,bHold))
        return;
    BYTE * hpTmp = m_pCellCache[0].pData;
    UINT w = m_width;
    UINT h = m_height;
    UINT iw = m_pCellCache[0].iw;
    UINT ih = m_pCellCache[0].ih;
    UINT ow,oh,offx, offy;
    ow = w;
    oh = h;
    if (w * ih > h * iw)
        {
        offy = 0;
        ow = MulDiv(h, iw, ih);
        offx = (w - ow) / 2;
        }
    else
        {
        offx = 0;
        oh = MulDiv(ih, ow, iw);
        offy = (h - oh) / 2;
        }

    UINT op,ip;
    UINT d;
    if (m_depth == 1)
        {
        d = 1;
        UINT x, y;
        ip = 4 * ((iw + 3) / 4);
        op = 4 * ((w + 3) / 4);
        for (y = 0; y < oh; y++)
        for (x = 0; x < ow; x++)
            {
            UINT ix, iy;
            ix = (x * iw) / ow;
            iy = (y * ih) / oh;
            if (bUseGray)
                hpDst[(y+offy)*op+x+offx] = hpTmp[iy*ip+ix];
            else
                hpDst[(y+offy)*op+x+offx] = 255 - hpTmp[iy*ip+ix];
            }
        }
    else
        {
        UINT x, y;
        if (b32)
            d = 4;
        else
            d = 3;
        op = 4 * ((d * w + 3) / 4);
        ip = 4 * iw;
        for (y = 0; y < oh; y++)
        for (x = 0; x < ow; x++)
            {
            UINT ix, iy;
            ix = (x * iw) / ow;
            iy = (y * ih) / oh;
            hpDst[(y+offy)*op+d*(x+offx)+0] = hpTmp[iy*ip+4*ix+0];
            hpDst[(y+offy)*op+d*(x+offx)+1] = hpTmp[iy*ip+4*ix+1];
            hpDst[(y+offy)*op+d*(x+offx)+2] = hpTmp[iy*ip+4*ix+2];
            if (b32)
                hpDst[(y+offy)*op+d*(x+offx)+3] = hpTmp[iy*ip+4*ix+3];
            }
        }
    if (m_uState && !bUseGray)
        ApplyImprint(hpDst,d);
}

void CScene::GetCell(HPBYTE hpDst, UINT Frame, UINT Level)
{
    if (Level == -1)
        Level = m_CurLevel;
    if (!Level) return;
    ApplyCell32(hpDst, Frame,Level,0);
}

void CScene::SetLayer(CLayers * pLayer)
{
    m_pLayers = pLayer;
}

UINT CScene::GetLayer(HPBYTE hpDst, UINT Frame, UINT Level,
            UINT Which, DWORD kkey /* = 0 */)
{
    if (Level == -1)
        Level = m_CurLevel;
    DWORD key;
//    if (m_pLayers && m_pLayers->Fetch(hpDst, Frame, Level, Which))
//        return 0;
    if (kkey)
        GetImageKey(key, kkey, Which);
    else
        GetImageKey(key, Frame, Level, Which);
    if (key)
        {
        ReadImage(hpDst, key);
        return 0;
        }
        /*
    if (!bForge)
        {
        GetImageKey(key, Frame, Level,CCell::LAYER_GRAY);
        if (!key)
            return 1;
        }
        */
    UINT w = m_width;// / m_scale;
    UINT p = 4 * (( w + 3)/ 4);
    UINT h = m_height;// / m_scale;
    UINT s = p * h;
    UINT x,y;
    if (Which == CCell::LAYER_PAINT)
        {
        for (y = 0; y < h; y++)
            for (x = 0; x < w; x++)
                {
                hpDst[p*y+x] = 0;    // alpha
                hpDst[s + p*y+x] = 0; // index
                }
        return 0;
        }
    return 1;
    if (Which != CCell::LAYER_INK)
        return 1;
    GetGray(hpDst,Frame,Level);
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++)
            {
            hpDst[p*y+x] ^= 255;
            hpDst[s + p*y+x] = 0;
            }
    return 0;
}


UINT CScene::GetOverlay(HPBYTE hpDst, UINT Key)
{
    UINT iw,ih,id;
    if (ImageInfo(iw,ih,id, Key))
        return 9;
    if (id != 32)
        return 8;
    if (m_depth == 1)
        {
        UINT op = 4 * ((iw + 3) / 4);
        UINT ip = 4 * iw;
        BYTE * tp = new BYTE[ih * ip];
        ReadImage(tp, Key);
        UINT y,x;
        for (y = 0; y < ih; y++)
        for (x = 0; x < iw ; x++)
            {
            UINT z;
            if (z = tp[y * ip + 4 * x + 3])
                {
                UINT v = 30 * tp[y*ip + 4 * x + 0]
                        + 59 * tp[y*ip + 4 * x + 1]
                        + 11 * tp[y*ip + 4 * x + 2];
                v /= 100;
                v = 255 - v;
                hpDst[op*y+x] = v*z/255;
                }
            else
                hpDst[op*y+x] = 0;
            }
        delete [] tp;
        }
    else
        ReadImage(hpDst, Key);
    return 0;
}

UINT CScene::GetLayer32(HPBYTE hpDst, UINT Frame, UINT Level, DWORD cellkey)
{
    if (SelectLevel(Level))
        return 1;
    COLORREF * pColor = (COLORREF *)hpDst;
    UINT ip = 4 * ((m_width + 3) / 4);
    UINT op;
    if (m_depth == 1)
        op = ip;
    else
        op = 4 * m_width;
    UINT size = m_height * op;
    UINT ox,oy;
    if (m_depth == 1)
        {
        memset(hpDst, 0, size);
        }
    else
        {
        memset(hpDst, 255, size);
        for (oy = 0; oy < m_height; oy++)
        for (ox = 0; ox < m_width ; ox++)
            {
            hpDst[op*oy+4*ox+3] = 0;
            }
        }
//    if (!m_pLayers || m_pLayers->FakeIt(hpDst,Frame, Level))
        {
        CLayers * pLayers = new CLayers;
        pLayers->ApplyCell(hpDst, cellkey,this, m_pLevel, m_pIO);
        delete pLayers;
        }
    SelectLevel();
    return 0;
}

void CScene::ApplyBuff(HPBYTE hpDst, HPBYTE hpSrc, UINT w, UINT h, UINT factor)
{
//    ASSERT(m_depth == 1);
    if (m_depth == 1)
        {
        UINT x,y,p,v,q,z;
        if (factor >= 1000)
            {
            z = 255;
            factor -= 1000;
            }
        else
            z = 0;
        p = 4 * ((w + 3) / 4);
        for (y = 0; y < h; y++)
            {
            for (x = 0; x < w; x++)
                {
                v = z ^ hpSrc[x];
                if (factor == 100)
                    {
                    q = hpDst[x];
                    v = (v * q) / 255;
                    hpDst[x] = (BYTE)v;
                    }
                else  if (v < 255)
                    {
                    q = hpDst[x];
                    v = 255 - (factor * (255 - v)) / 100;
                    v = (v * q) / 255;
                    hpDst[x] = (BYTE)v;
                    }
                }
            hpDst += p;
            hpSrc += p;
            }
        }
    else
        {
        UINT x,y,sp,dp;
        dp = 4 * ((3 * w + 3) / 4);
        sp = 4 * w;
        for (y = 0; y < h; y++)
            {
            for (x = 0; x < w; x++)
                {
                UINT z;
                if (z = hpSrc[4*x+3])
                    {
                    hpDst[3*x+0] = hpSrc[4*x+0];
                    hpDst[3*x+1] = hpSrc[4*x+1];
                    hpDst[3*x+2] = hpSrc[4*x+2];
                    }
                }
            hpDst += dp;
            hpSrc += sp;
            }
        }
}

void CScene::zApplyGray(HPBYTE hpDst, UINT factor, UINT Frame, UINT Level,
                                BOOL bHold /* = 1 */)
{
    if (GetCell32(Frame, Level, bHold))
        return;
    BYTE * hpTmp = m_pCellCache[0].pData;
    ApplyBuff(hpDst, hpTmp, m_width, m_height,factor+1000);
}

BOOL CScene::FindNextCell(UINT & Frame, UINT Level)
{
    if (SelectLevel(Level))
        return 0;
    BOOL bResult = 1;
    UINT start = Frame;
    for (;Frame < m_frames;Frame++)
        {
        if (m_pLevel->Select(Frame))
            break;
        }
    SelectLevel();
    if (Frame >= m_frames)
        {
        bResult = 0;
        Frame = start;
        }
    return bResult;
}

BOOL CScene::FindPrevCell(UINT & Frame, UINT Level)
{
    BOOL bResult = 1;
    if (SelectLevel(Level))
        return 0;
    UINT start = Frame;
    for (;;Frame--)
        {
        if (m_pLevel->Select(Frame))
            break;
        if (!Frame)
            {
            Frame = start;
            bResult = 0;
            break;
            }
        }
    SelectLevel();
    return bResult;
}

void CScene::Apply24(BYTE * hpDst, BYTE * hpSrc, UINT iw, UINT ih,
                BOOL bCamera, BOOL bBroadcast)
{
    UINT w,h,dp,ip;
//    bBroadcast = 0;
//    BYTE * hpTmp;
    UINT code = 0;
    UINT ialpha = 255;
    if (bCamera && m_pCamera)
        ialpha = m_pCamera->m_alpha;
    w = ComW();
    h = ComH();
    dp = 4 * ((m_depth *  w + 3)/4);
    ip = 4 * ((m_depth * iw + 3) / 4);
    UINT r, q, fact;
    int yy,oy,ox, offx, offy, scale;
    memset(hpDst, 255, dp * h);
    offx = 0;
    offy = 0;
    if (bCamera && m_pCamera)
        {
        code = m_pCamera->Table(m_pXY,w,h,iw,ih,bBroadcast);
        if (code == 1)
            {
            offx = m_pCamera->m_offx;
            offy = m_pCamera->m_offy;
            scale = (int)(100.0 * m_pCamera->Scale());
            }
        else
            {
            q = m_pCamera->m_factor;
            r = m_pCamera->m_radius;
            }
        }
    else if (m_factor != 2)
        {
        fact = m_factor;
        code = 3;
        offx = 0;
        offy = 0;
        }
    if ((code == 2) && bBroadcast)
        {
        if (m_depth == 1)
            Apply24g(hpDst,hpSrc,iw,ih,1);
        else
            Apply24c(hpDst,hpSrc,iw,ih);
        return;
        }
    BYTE * hpBlur = 0;
    if (Broadcast() && bCamera && m_pCamera && m_pCamera->Blur())
        {
        UINT blur = (UINT)((0.0 + m_pCamera->Blur()) / 2);
        if (blur)
            {
            hpBlur = new BYTE[ip * ih];
            BlurX(hpBlur, hpSrc,iw,ih,blur,1,m_depth == 1 ? 1 : 3,ip);
            hpSrc = hpBlur;
            }
        }
    UINT z;
    for (yy = m_y; yy < (int)(m_y+m_h);yy++)
        {
        oy = h - 1 - yy;
        for (ox = m_x; ox < (int)(m_x+m_w); ox++)
            {
            int ax, ay;
            if (code > 2)
                {
                ax = offx + ox * fact;
                ay = offy + oy * fact;
                }
            else if (code > 1)
                {
                ax = m_pXY[yy*w+ox] / q;
                ay = m_pXY[w*h+yy*w+ox] / q;
                }
            else if (code)
                {
                ax = (10000 * ox + offx);
                ay = (10000 * oy + offy);
                ax /= scale;
                ay /= scale;
                }
            else
                {
                ay = oy;
                ax = ox;
                }
            if (((UINT)ax >= iw) || ((UINT)ay >= ih))
                continue;
            z = ialpha;
            if (m_depth == 1)
                {
                if (z == 255)
                    hpDst[dp*oy+ox] = hpSrc[ip*ay+ax];
                else
                    {
                    WORD v = (255 - z) * hpDst[dp*oy+ox];
                    v += z * hpSrc[ip*ay+ax];
                    hpDst[dp*oy+ox] = v / 255;
                    }
                }
            else
                {
                int j;
                if (z == 255)
                    {
                    for (j = 0; j < 3; j++)
                        hpDst[dp*oy+3*ox+j] = hpSrc[ip*ay+3*ax+j];
                    }
                else if (z)
                    for (j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * hpDst[dp*oy+3*ox+j];
                    v += z * hpSrc[ip*ay+3*ax+j];
                    hpDst[dp*oy+3*ox+j] = v / 255;
                    }
                }
            }
        }
    delete [] hpBlur;
}


void CScene::Apply24c(BYTE * hpDst, BYTE * pBuf, UINT iw, UINT ih)
{
    ASSERT(m_depth == 3);
    UINT j,w,h;
    UINT dp;
    UINT s[4];
    UINT yy,oy,ox;
    UINT z;
//    UINT x1,x2,y1,y2,f;
    int x1, y1, x2, y2;
    int xx1, xx2, yy1, yy2;
    int maxx, maxy;
    UINT f, xf, yf, xf1, xf2,yf1,yf2;
    UINT q = m_pCamera ? m_pCamera->m_factor : 1;
    UINT R = m_pCamera ? m_pCamera->m_radius : 1;
//    UINT D = R + R + 1;
    UINT ialpha = m_pCamera ? m_pCamera->m_alpha : 255;
    if (!ialpha)
        return;
    maxx = iw * q - 1;
    maxy = ih * q - 1;
    w = ComW();
    h = ComH();
    UINT ip = 4 * ((3 * iw+3) / 4);
    dp = 4 * ((m_depth*w+3)/4);
    for (yy = m_y; yy < (int)(m_y+m_h);yy++)
        {
        oy = h - 1 - yy;
        for (ox = m_x; ox < (int)(m_x+m_w); ox++)
            {
            int ax, ay;
            s[0] = 0;
            s[1] = 0;
            s[2] = 0;
            ax = m_pXY[yy*w+ox];
            ay = m_pXY[w*h+yy*w+ox];
            x1 = ax - R;
            x2 = ax + R;
            y1 = ay - R;
            y2 = ay + R;
            if ((ax > maxx) || (ay > maxy) || (x2 < 0) || (y2 < 0)
                || (x1 > maxx) || (y1 > maxy))
                {
                hpDst[dp*oy+3*ox+0] = 255;
                hpDst[dp*oy+3*ox+1] = 255;
                hpDst[dp*oy+3*ox+2] = 255;
                continue;
                }
            if (x1 < 0) x1 = 0;
            if (y1 < 0) y1 = 0;
            if (x2 > maxx) x2 = maxx;
            if (y2 > maxy) y2 = maxy;
            xx1 = x1 / q;
            xx2 = x2 / q;
            yy1 = y1 / q;
            yy2 = y2 / q;
            xf = x2 + 1 - x1;
            yf = y2 + 1 - y1;
            f = xf * yf;
            if ((xx1 == xx2) && (yy1 == yy2))
                {
                Magic3(ip*yy1+3*xx1,f,s,pBuf);
                }
            else if (xx1 == xx2)
                {
                yf1 = q - (y1 % q);
                yf2 = 1 + y2  % q;
                MagicColumn3(xx1,yy1,yy2,xf,q,yf1,yf2,ip,s,pBuf);
                }
            else if (yy1 == yy2)
                {
                xf1 = q - (x1 % q);
                xf2 =  1 + x2 % q;
                MagicLine3(xx1,xx2,yy1,xf1,xf2,yf,q,ip,s,pBuf);
                }
            else
                {
                xf1 = q - (x1 % q);
                xf2 = 1 + x2 % q;
                yf1 = q - (y1 % q);
                yf2 = 1 + y2 % q;
                MagicLine3(    xx1,xx2,yy1,xf1,xf2,yf1,q,ip,s,pBuf);
                for (yy1++; yy1 < yy2; yy1++)
                    MagicLine3(xx1,xx2,yy1,xf1,xf2,q  ,q,ip,s,pBuf);
                MagicLine3(    xx1,xx2,yy2,xf1,xf2,yf2,q,ip,s,pBuf);
                }
            s[0] /= f;
            s[1] /= f;
            s[2] /= f;

            z = ialpha;
            if (z == 255)
                {
                hpDst[dp*oy+3*ox+0] = s[0];
                hpDst[dp*oy+3*ox+1] = s[1];
                hpDst[dp*oy+3*ox+2] = s[2];
                }
            else
                {
                for (j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * hpDst[dp*oy+3*ox+j];
                    v += z * s[j];
                    hpDst[dp*oy+3*ox+j] = v / 255;
                    }
                }
            }
        }
}

void CScene::Apply24g(BYTE * hpDst, BYTE * pBuf, UINT iw, UINT ih, BOOL bBG)
{
    UINT w,h;
    UINT dp;
//    UINT s[2];
    UINT s[1];
    UINT yy,oy,ox;
    UINT z;
    int x1,x2,y1,y2,xx1,xx2,yy1,yy2,maxx,maxy;
    UINT f,xf,yf,xf1, xf2,yf1,yf2;
    UINT q = m_pCamera ? m_pCamera->m_factor : 1;
    UINT R = m_pCamera ? m_pCamera->m_radius : 1;
//    UINT D = R + R + 1;
    maxx = q * iw - 1;
    maxy = q * ih - 1;
    UINT ialpha = m_pCamera ? m_pCamera->m_alpha : 255;
    w = ComW();
    h = ComH();
    UINT ip = 4 * ((iw+3) / 4);
    dp = 4 * ((m_depth*w+3)/4);
    for (yy = m_y; yy < (int)(m_y+m_h);yy++)
        {
        oy = h - 1 - yy;
        for (ox = m_x; ox < (int)(m_x+m_w); ox++)
            {
            int ax, ay;
            s[0] = 0;
//            s[1] = 0;
            
            ax = m_pXY[yy*w+ox];
            ay = m_pXY[w*h+yy*w+ox];
            x1 = ax - R;
            y1 = ay - R;
            x2 = ax + R;
            y2 = ay + R;
            if ((ax > maxx) || (ay > maxy) || (x2 < 0) || (y2 < 0)
                || (x1 > maxx) || (y1 > maxy))
                {
                if (bBG)
                    hpDst[dp*oy+ox] = 0;
                continue;
                }
            if (x1 < 0) x1 = 0;
            if (y1 < 0) y1 = 0;
            if (x2 > maxx) x2 = maxx - 1;
            if (y2 > maxy) y2 = maxy - 1;
            xf = x2 + 1 - x1;
            yf = y2 + 1 - y1;
            xx1 = x1 / q;
            yy1 = y1 / q;
            xx2 = x2 / q;
            yy2 = y2 / q;
            xf = x2 + 1 - x1;
            yf = y2 + 1 - y1;
            f = xf * yf;
            if ((xx1 == xx2) && (yy1 == yy2))
                {
                Magic1(ip*yy1+xx1,f,s,pBuf);
                }
            else if (xx1 == xx2)
                {
                yf1 = q - (y1 % q);
                yf2 = 1 + y2 % q;
                MagicColumn1(xx1,yy1,yy2,xf,q,yf1,yf2,ip,s,pBuf);
                }
            else if (yy1 == yy2)
                {
                xf1 = q - (x1 % q);
                xf2 = 1 + x2 % q;
                MagicLine1(xx1,xx2,yy1,xf1,xf2,yf,q,ip,s,pBuf);
                }
            else
                {
                xf1 = q - (x1 % q);
                xf2 = 1 + x2 % q;
                yf1 = q - (y1 % q);
                yf2 = 1 + y2 % q;
                MagicLine1(    xx1,xx2,yy1,xf1,xf2,yf1,q,ip,s,pBuf);
                for (yy1++; yy1 < yy2; yy1++)
                    MagicLine1(xx1,xx2,yy1,xf1,xf2,q  ,q,ip,s,pBuf);
                MagicLine1(    xx1,xx2,yy2,xf1,xf2,yf2,q,ip,s,pBuf);
                }
//            UINT qq = s[1];
//            if (!qq)
//                {
//continue;
//                }
//            z = s[0] / qq;
            z = s[0] / f;
            if (bBG)
                hpDst[dp*oy+ox] = (BYTE)z;
            else
                {
                z = (UINT)(ialpha * z) / 255;
                if (!z)
                    continue;
                UINT q = hpDst[dp*oy+ox];
                q = ((255-z) * q) / 255;
                hpDst[dp*oy+ox] = (BYTE)q;
                }
            }
        }
}

void CScene::Apply32(BYTE * hpDst, BYTE * pBuf, UINT iw, UINT ih)
{
    ASSERT(m_depth > 2);
    UINT j,w,h;
    UINT dp;
    UINT s[5];
    UINT yy,oy,ox;
    UINT z;
    UINT f;
    int x1, x2, y1, y2;
    int xx1, xx2, yy1, yy2;
    UINT xf1, xf2,yf1,yf2;
    UINT xf, yf;
    int q = m_pCamera ? m_pCamera->m_factor : 1;
    int maxy, maxx;
    maxx = q * iw - 1;
    maxy = q * ih - 1;
    int R = m_pCamera ? m_pCamera->m_radius:1;
//    int d = R + R + 1;
    UINT ialpha = m_pCamera ? m_pCamera->m_alpha : 255;
    w = ComW();
    h = ComH();
    UINT ip = 4 * iw;
    dp = 4 * ((m_depth*w+3)/4);
    for (yy = m_y; yy < (int)(m_y+m_h);yy++)
        {
        oy = h - 1 - yy;
        for (ox = m_x; ox < (int)(m_x+m_w); ox++)
            {
            int ax, ay;
            s[0] = 0;
            s[1] = 0;
            s[2] = 0;
            s[3] = 0;
            s[4] = 0;
            ax = m_pXY[yy*w+ox];
            ay = m_pXY[w*h+yy*w+ox];
            x1 = ax - R;
            y1 = ay - R;
            x2 = ax + R;
            y2 = ay + R;
            if ((ax > maxx) || (ay > maxy) || (x2 < 0) || (y2 < 0)
                || (x1 > maxx) || (y1 > maxy))
                    continue;
            if (x1 < 0) x1 = 0;
            if (y1 < 0) y1 = 0;
            if (x2 > maxx) x2 = maxx - 1;
            if (y2 > maxy) y2 = maxy - 1;
            xf = x2 + 1 - x1;
            yf = y2 + 1 - y1;
            xx1 = x1 / q;
            yy1 = y1 / q;
            xx2 = x2 / q;
            yy2 = y2 / q;
            xf = x2 + 1 - x1;
            yf = y2 + 1 - y1;
            f = xf * yf;
            if ((xx1 == xx2) && (yy1 == yy2))
                {
                Magic4(ip*yy1+4*xx1,f,s,pBuf);
                }
            else if (xx1 == xx2)
                {
                yf1 = q - (y1  % q);
                yf2 = 1 + y2 % q;
                MagicColumn4(xx1,yy1,yy2,xf,q,yf1,yf2,ip,s,pBuf);
                }
            else if (yy1 == yy2)
                {
                xf1 = q - (x1 % q);
                xf2 = 1 + x2 % q;
                MagicLine4(xx1,xx2,yy1,xf1,xf2,yf,q,ip,s,pBuf);
                }
            else
                {
                xf1 = q - (x1 % q);
                xf2 = 1 + x2 % q;
                yf1 = q - (y1 % q);
                yf2 = 1 + y2 % q;
                MagicLine4(    xx1,xx2,yy1,xf1,xf2,yf1,q,ip,s,pBuf);
                for (yy1++; yy1 < yy2; yy1++)
                    MagicLine4(xx1,xx2,yy1,xf1,xf2,q  ,q,ip,s,pBuf);
                MagicLine4(    xx1,xx2,yy2,xf1,xf2,yf2,q,ip,s,pBuf);
                }
            UINT qq = s[4];
            if (!qq)
                continue;
            s[0] /= qq;
            s[1] /= qq;
            s[2] /= qq;
            s[3] /= f;

            z = ialpha * s[3] / 255;
            if (!z)
                continue;
            if (z == 255 || (m_bFirst))
                {
                hpDst[dp*oy+m_depth*ox+0] = s[0];
                hpDst[dp*oy+m_depth*ox+1] = s[1];
                hpDst[dp*oy+m_depth*ox+2] = s[2];
                if (m_bFirst && (m_depth == 4))
                    hpDst[dp*oy+m_depth*ox+3] = z;
                }
            else
                {
                if (m_depth != 4)
                    {
                    for (j = 0; j < 3; j++)
                        {
                        WORD v = (255 - z) * hpDst[dp*oy+m_depth*ox+j];
                            v += z * s[j];
                        hpDst[dp*oy+m_depth*ox+j] = v / 255;
                        }
                    }
                else
                    {
                    int t;
                    UINT b_alpha = hpDst[dp*oy+4*ox+3];
                    if (!b_alpha)
                        {
                        for (j = 0; j < 4; j++)
                            hpDst[dp*oy+4*ox+j] = s[j];
                        }
                    else
                        {
                        for (j = 0; j < 3; j++)
                            {
                            UINT back = (UINT)hpDst[dp*oy+4*ox+j] * b_alpha;
                            t = (UINT)s[j] * z;
                            if (back)
                                t +=  back - back * z / 255;
                            t /= 255;
                            hpDst[dp*oy+4*ox+j] = t;
                            }
                        t = z + b_alpha - (z * b_alpha) / 255;
                        hpDst[dp*oy+4*ox+3] = t;
                        }
                    }
                }
            }
        }
}

UINT CScene::GetCell32(UINT Frame, UINT Level, BOOL bSearch)
{
    if (SelectLevel(Level))
        return 1;
    DWORD    cellkey = m_pLevel->Select(Frame, bSearch);
    CLevelTable tbl;
    m_pLevel->Table(&tbl,this);
    SelectLevel();
DPF("getcell32,b:%d,f:%d,l:%d,k:%d",bSearch,Frame,Level,cellkey);

    if (!cellkey)
        return 2;
    BOOL bFake = 0;
    if (m_pLayers && m_pLayers->UseFake(cellkey))
        bFake = TRUE;
    DWORD * pddpals = (DWORD *)&tbl.pals;
    UINT i;
    for (i = 0; i < m_nCells; i++)
        {
//continue;
        if (m_pCellCache[i].dwKey != cellkey)
            continue;
        if (m_pCellCache[i].id != m_depth)
            continue;
        if (m_depth == 1)
            break;                // no need if gray
        UINT j;
        DWORD * pdpals = (DWORD *)&m_pCellCache[i].info.pals;
        for (j = 0; (j < 256) && (pdpals[j] == pddpals[j]);j++);
        if (j < 256)
            continue;
        for (j = 0; j < 11; j++)
            {
            if ((m_pCellCache[i].info.lays[j].offx != tbl.table[j].dx) ||
                (m_pCellCache[i].info.lays[j].offy != tbl.table[j].dy) ||
                (m_pCellCache[i].info.lays[j].blur != tbl.table[j].blur) ||
                (m_pCellCache[i].info.lays[j].flags != tbl.table[j].flags))
                break;
            }
        if (j >= 11)
            break;
        }
    if (i < m_nCells)    // found it, move it to front
        {
        if (i)
            {
            CELLENTRY t = m_pCellCache[i];
            for (; i > 0; i--)
                m_pCellCache[i] = m_pCellCache[i-1];
            m_pCellCache[0] = t;
            }
DPZ("found");
        if (bFake)
            {
            m_pLayers->FakeIt(m_pCellCache[0].pData);
            }
        return 0;
        }
    i = m_nCells - 1;
    CELLENTRY t = m_pCellCache[i];
    for (; i > 0; i--)
        m_pCellCache[i] = m_pCellCache[i-1];

    m_pCellCache[0] = t;

    UINT iw,ih,id;
    DWORD ikey;
    GetImageKey(ikey, cellkey, CCell::LAYER_OVERLAY);
    if (ikey)
        {
        DPZ("overlay");
        if (ImageInfo(iw,ih,id, ikey))
                return 9;
        if (id != 32)
            return 8;
        }
    else
        {
        iw = m_width;
        ih = m_height;
        }
    m_pCellCache[0].dwKey = cellkey;
    if (!m_pCellCache[0].pData ||
                (m_pCellCache[0].id != m_depth) ||
                (m_pCellCache[0].iw != iw) ||
                (m_pCellCache[0].ih != ih))
        {
        delete [] m_pCellCache[0].pData;
        m_pCellCache[0].iw = iw;
        m_pCellCache[0].ih = ih;
        m_pCellCache[0].id = m_depth;
        UINT siz;
        if (m_depth == 1)
            siz = 4 * ((m_pCellCache[0].iw +3) / 4);
        else
            siz = 4 * m_pCellCache[0].iw;
        siz *= m_pCellCache[0].ih;
        m_pCellCache[0].pData = new BYTE[siz];
        }
    if (m_depth != 1)
        memcpy(m_pCellCache[0].info.pals, tbl.pals, 1024);
    for (UINT j = 0; j < 11; j++)
        {
        m_pCellCache[0].info.lays[j].offx = tbl.table[j].dx;
        m_pCellCache[0].info.lays[j].offy = tbl.table[j].dy;
        m_pCellCache[0].info.lays[j].blur = tbl.table[j].blur;
        m_pCellCache[0].info.lays[j].flags = tbl.table[j].flags;
        }
    if (bFake)
        {
        m_pLayers->FakeIt(m_pCellCache[0].pData);
        }
    else if (ikey)
        GetOverlay(m_pCellCache[0].pData, ikey);
    else
        GetLayer32(m_pCellCache[0].pData, Frame, Level, cellkey);
DPZ("not found");
    return 0;
}

UINT CScene::BlowCell(UINT cellkey)
{
    UINT i;
    UINT result = 0;
    for (i = 0; i < m_nCells; i++)
        {
        if (m_pCellCache[i].dwKey == cellkey)
            {
            result = cellkey;
            m_pCellCache[i].dwKey = -1;
            }
        }
    return result;
}

UINT CScene::BlowCell(UINT Frame, UINT Level)
{
    if (Frame == -1)
        {
        UINT i;
        for (i = 0; i < m_nCells; i++)
            m_pCellCache[i].dwKey = -1;
        return 0;
        }
    DWORD cellkey = GetCellKey(Frame, Level);
DPZ("blowcell,f:%d,l:%d,k:%d",Frame,Level,cellkey);
    if (cellkey)
        BlowCell(cellkey);
    return cellkey;
}

void CScene::ApplyCell(HPBYTE hpDst,
            UINT Frame, UINT Level,
                BOOL bCamera /* = FALSE */, BOOL bBroadcast/* = 0 */)
{
//DPF("apply cell,frm:%d,lev:%d,fac:%d",Frame,Level,factor);
    UINT w,h,dp,ip;
//    bBroadcast = 0;
//    bCamera = 0;
    if (GetCell32(Frame, Level, TRUE))
        return;
    BYTE * hpTmp = m_pCellCache[0].pData;
    UINT code = 0;
    UINT ialpha = 255;
    if (bCamera && m_pCamera)
        bCamera = m_pCamera->SetupCell(Frame, Level);
    if (bCamera && m_pCamera)
        ialpha = m_pCamera->m_alpha;
    UINT iw = m_pCellCache[0].iw;
    UINT ih = m_pCellCache[0].ih;
    if (m_depth == 1)
        ip = 4 * ((iw +3)/4);
    else
        ip = 4 * iw;
    w = ComW();
    h = ComH();
    dp = 4 * ((m_depth*w+3)/4);
    UINT r, q, fact;
    int yy,oy,ox, offx, offy, scale;
//    UINT ww, hh;
//            COLORREF * pColor = (COLORREF *)hpTmp;
    offx = 0;
    offy = 0;
    if (bCamera && m_pCamera)
        {
        code = m_pCamera->Table(m_pXY,w,h,iw,ih,bBroadcast);
        if (code == 1)
            {
            offx = m_pCamera->m_offx;
            offy = m_pCamera->m_offy;
            scale = (int)(100.0 * m_pCamera->Scale());
//if (!scale)
//    {
//    scale = 10;
//    }
            }
        else
            {
            q = m_pCamera->m_factor;
            r = m_pCamera->m_radius;
            }
        }
    else if (m_factor != 2)
        {
        fact = m_factor;
        code = 3;
        offx = 0;
        offy = 0;
        }
    if ((code == 2) && bBroadcast)
        {
        if (m_depth == 1)
            Apply24g(hpDst,hpTmp,iw,ih,0);
        else
            Apply32(hpDst,hpTmp,iw,ih);
        return;
        }
DPZ("applying");
    BYTE * hpBlur = 0;
    if (Broadcast() && bCamera && m_pCamera && m_pCamera->Blur())
        {
        UINT blur = (UINT)((0.0 + m_pCamera->Blur()) / 2);
        if (blur)
            {
            hpBlur = new BYTE[ip * ih];
            BlurX(hpBlur, hpTmp,iw,ih,blur,1,m_depth == 1 ? 1 : 4,ip);
            hpTmp = hpBlur;
            }
        }
    UINT z;
    for (yy = m_y; yy < (int)(m_y+m_h);yy++)
        {
        oy = h - 1 - yy;
        for (ox = m_x; ox < (int)(m_x+m_w); ox++)
            {
            int ax, ay;
            if (code > 2)
                {
                ax = offx + ox * fact;
                ay = offy + oy * fact;
                }
            else if (code > 1)
                {
                ax = m_pXY[yy*w+ox] / q;
                ay = m_pXY[w*h+yy*w+ox] / q;
                }
            else if (code)
                {
                ax = (10000 * ox + offx);
                ay = (10000 * oy + offy);
                ax /= scale;
                ay /= scale;
                }
            else
                {
                ay = oy;
                ax = ox;
                }
            if (((UINT)ax >= iw) || ((UINT)ay >= ih))
                continue;
            if (m_depth == 1)
                {
                z = (UINT)(ialpha * hpTmp[ip*ay+ax]) / 255;
                if (!z)
                    continue;
                UINT q = hpDst[dp*oy+ox];
                q = ((255-z) * q) / 255;
                        hpDst[dp*oy+ox] = (BYTE)q;
//                        hpDst[dp*oy+ox] = 255-z;
                }
            else
                {
                int j;
                z = (UINT)(ialpha * hpTmp[ip*ay+4*ax+3]) / 255;
                if (!z)
                    continue;
                if ((z == 255) || m_bFirst)
                    {
//                    for (j = 0; j < 3; j++)
//                        hpDst[dp*oy+m_depth*ox+j] = hpTmp[ip*ay+4*ax+j];
                    hpDst[dp*oy+m_depth*ox+0] = hpTmp[ip*ay+4*ax+0];
                    hpDst[dp*oy+m_depth*ox+1] = hpTmp[ip*ay+4*ax+1];
                    hpDst[dp*oy+m_depth*ox+2] = hpTmp[ip*ay+4*ax+2];
                    if (m_bFirst && (m_depth == 4))
                        hpDst[dp*oy+m_depth*ox+3] = z;
                    }
                else
                    {
                    for (j = 0; j < 3; j++)
                        {
                        WORD v = (255 - z) * hpDst[dp*oy+m_depth*ox+j];
                            v += z * hpTmp[ip*ay+4*ax+j];
                            hpDst[dp*oy+m_depth*ox+j] = v / 255;
                        }
                    }
                }
            }
        }
    delete [] hpBlur;
}

void CScene::CombineLayers(BYTE * pBuf,
                UINT StartLevel, UINT EndLevel, UINT Frame)
{
    if (!StartLevel)
        StartLevel++;
    BOOL bFill = 1;
    for (; StartLevel <= EndLevel;StartLevel++)
        if (LevelFlags(StartLevel) & 1)
            {
            ApplyCell32(pBuf, Frame, StartLevel,bFill);
            bFill = 0;
            }
    if (m_uState)
        ApplyImprint(pBuf,m_depth == 1 ? 1 : 4);
}

void CScene::ApplyCell32(HPBYTE hpDst, UINT Frame, UINT Level, BOOL bFill)
{
    UINT w,h,op,ip,x,y;
    if (GetCell32(Frame, Level, TRUE))
        return;
    BYTE * hpTmp = m_pCellCache[0].pData;
    UINT iw = m_pCellCache[0].iw;
    UINT ih = m_pCellCache[0].ih;
    w = m_width;
    h = m_height;
    if (m_depth == 1)
        {
        ip = 4 * ((iw+3)/4);
        op = 4 * ((w+3)/4);
        UINT z,q;
        for (y = 0; y < h; y++)
        for (x = 0; x < w; x++)
            {
            if ((y >= ih) || (x >= iw))
                continue;
            z = hpTmp[ip*y+x];
            if (!z)
                continue;
            q = hpDst[op*y+x];
            q = ((255-z) * q) / 255;
            hpDst[op*y+x] = (BYTE)q;
            }
        }
    else
        {
        ip = 4 * iw;
        op = 4 * w;
//bFill = 0;
        for (y = 0; y < h;y++)
        for (x = 0; x < w; x++)
            {
if ((x >= iw) || (y >= ih))
    continue;
            UINT f_alpha;
            if (bFill)
                {
                if(hpTmp[ip*y+4*x+3])
                    {
                    hpDst[op*y+4*x+0] = hpTmp[ip*y+4*x+0];
                    hpDst[op*y+4*x+1] = hpTmp[ip*y+4*x+1];
                    hpDst[op*y+4*x+2] = hpTmp[ip*y+4*x+2];
                    hpDst[op*y+4*x+3] = hpTmp[ip*y+4*x+3];
                    }
                else
                    {
                    hpDst[op*y+4*x+0] = 255;
                    hpDst[op*y+4*x+1] = 255;
                    hpDst[op*y+4*x+2] = 255;
                    hpDst[op*y+4*x+3] = 0;
                    }
                }
            else if (f_alpha = hpTmp[ip*y+4*x+3])
                {
                int j,t;
                UINT b_alpha = hpDst[op*y+4*x+3];
                if (!b_alpha)
                    {
                    for (j = 0; j < 4; j++)
                        hpDst[op*y+4*x+j] = hpTmp[ip*y+4*x+j];
                    }
                else
                    {
                    for (j = 0; j < 3; j++)
                        {
                        UINT back = (UINT)hpDst[op*y+4*x+j] * b_alpha;
                        t = (UINT)hpTmp[ip*y+4*x+j] * f_alpha;
                        if (back)
                            t +=  back - back * f_alpha / 255;
                        t /= 255;
                        hpDst[op*y+4*x+j] = t;
                        }
                    t = f_alpha + b_alpha - (f_alpha * b_alpha) / 255;
                    hpDst[op*y+4*x+3] = t;
                    }
                }
            }
        }
}

void CScene::PutImage(HPBYTE hpDst, UINT Frame, UINT Level, UINT Which)
{
    if (Level == -1)
        Level = m_CurLevel;
DPF("put image,f:%d,l:%d,w:%d",Frame,Level,Which);
    DWORD key;
    GetImageKey(key, Frame, Level,Which,TRUE);
    if (key == 0)
        {
DPF("null key after bmake");
        return;
        }
    else
        WriteImage(hpDst, key, Which);
    return ;
}

void CScene::PutMono(HPBYTE hpDst, UINT Frame, UINT Level)
{
    PutImage(hpDst, Frame,Level,CCell::LAYER_MONO);
}


void CScene::SetMinBG(UINT min, BOOL bInit)
{
    m_MinBG = min;
    if ((LevelFlags(0) & 1) && !bInit)
        UpdateCache();
}
UINT CScene::UpdateCache(UINT Frame /* = 0 */, UINT Level /* = 9999 */,
            UINT Count /* = 1 */)
{
    if (Level == 9999)
        {
        m_cache_state = 0;
DPF("update entire cache");
        for (; Frame < m_frames; m_pFlags[Frame++] = 1);
        return Frame;
        }
    if (Level == 9998)
        {
        Count++;
        if (Count     >= m_frames)
            Count = m_frames;
        m_cache_state = 0;
        for (; Frame < Count; m_pFlags[Frame++] = 1);
        return Frame;
        }
    if ((Count != 9999) && !(LevelFlags(Level) & 1))
        return Frame;
    if ((Frame + Count) >= m_frames)
        Count = m_frames - Frame;
    UINT i;
    m_cache_state = 0;
    for (i = 0; i < Count;i++)
        m_pFlags[Frame++] = 1;
    DWORD key;
    for (;Frame < m_frames;Frame++)
        {
        GetImageKey(key, Frame, Level, CCell::LAYER_GRAY);
        if (key)
            break;
        GetImageKey(key, Frame, Level, CCell::LAYER_INK);
        if (key)
            break;
        m_pFlags[Frame] = 1;    // dirty
        m_cache_state = 0;
        }
    return Frame;
}

void CScene::PutLayer(HPBYTE hpDst, UINT Frame, UINT Level, UINT Which)
{
    PutImage(hpDst, Frame,Level,Which);
}

UINT CScene::zCreateCell(UINT Frame, UINT Level,
        LPBITMAPINFOHEADER  lpbi, UINT Rotation,
                BOOL bMakeMono, UINT nHold)
{
//    bScaleColor = TRUE;
//    nHold is 2 for no apsect hold, 1 for scale to fit
//    > 2 is crop flag plus offset
//
    UINT alpha_key = Rotation >> 16;
    UINT layer = Rotation / 256;    // low byte for roation
    BOOL bCvt24 = Rotation & 128 ? 1 : 0;    // flag to create alpha
    Rotation &= 7;
    UINT result;
    if (Frame >= m_frames)
        InsertCache(m_frames,Frame+1);
//    DeleteCell(Frame, Level,1);
    BlowCell(Frame, Level);
    
    bMakeMono = FALSE;
    UINT w = lpbi->biWidth;
    UINT h = lpbi->biHeight;
    UINT d = lpbi->biBitCount;
    if (Level && (d == 24) && bCvt24)
        d = 32;
    else
        bCvt24 = 0;
    if (!Level || (d == 32))
        {
        DeleteCell(Frame, Level,1);
        if (nHold & 5)
            {
            w = m_width;
            h = m_height;
            }
        else if (Rotation & 1)
            {
            h = lpbi->biWidth;
            w = lpbi->biHeight;
            }
        UINT c,od;
        if (w > h)
            c = w;
        else
            c = h;
        if (Level)
            od = 32;
        else
            od = 24;
//        UINT size = h * 4 * ((d * w + 31) / 32);
        UINT size = c * 4 * ((od * c + 31) / 32);
        BYTE * temp = new BYTE[size];
        memset(temp,0,size);
        ConvertColor(temp, lpbi, od,
                (alpha_key << 16) + Rotation + (bCvt24 ? 128 : 0),nHold);
        WriteOverlay(temp,Frame,Level,w,h);
        delete [] temp;
//        UpdateCache(Frame, Level);
        return 0;
        }
//    nHold &= 3; // remove aspect hold flag
    DWORD gw = m_width;// / m_scale;
    DWORD gh = m_height;// / m_scale;
    
    BYTE * hpDst = 0;
    DWORD bw = lpbi->biWidth;
    DWORD bh = lpbi->biHeight;
//
//    the following is disabled temporarily, until
//     we decide about the postponed scaling
//
    UINT p;
    if (hpDst && bMakeMono && (bw > gw) && (bh > gh))
        {
        p = 4 * ((m_width + 3) / 4);
        h = 4 * ((m_height + 3) / 4);    // for rotation
        hpDst = new BYTE[p * h];
        if (!(result = ConvertGray(hpDst, lpbi, Rotation,nHold)))
            {
            PutMono(hpDst,Frame,Level);
            MakeGray(hpDst);
//            PutGray(hpDst,Frame,Level);
            }
        }
    else
        {
        if (bMakeMono)
            {
            p = 4 * ((m_width + 3) / 4);
            h = 4 * ((m_height + 3) / 4);    // for rotation
            }
        else
            {
            p = 4 * ((gw + 3) / 4);
            h = 4 * ((gh + 3) / 4);    // for rotation
            }
        hpDst = new BYTE[2 * p * h];
//        if (layer)
//            memset(hpDst,MAGIC_COLOR,2* p * h);
        if (!(result = ConvertGray(hpDst, lpbi, Rotation, nHold)))
            {
            UINT i;
            if (!layer)
                {
                for (i = 0; i < p * gh;i++)
                    {
                    hpDst[i] ^= 255;
                    hpDst[i+p*gh] = 0;
                    }
                PutLayer(hpDst,Frame,Level, CCell::LAYER_INK);
                memset(hpDst, 0, 2 * p * h);
                PutLayer(hpDst,Frame,Level, CCell::LAYER_PAINT);
                }
            else
                {
                for (i = 0; i < p * gh; i++)
                    {
                    if (hpDst[i] != 255)
                        hpDst[i] = 255;
                    else
                        hpDst[i] = 0;
                    hpDst[i+p*gh] = 0;//MAGIC_COLOR;
                    }
                PutLayer(hpDst,Frame,Level, layer - 1 + CCell::LAYER_MATTE0);
                }
//            UpdateCache(Frame, Level);
//            PutGray(hpDst,Frame,Level);
            if (bMakeMono)
                {
                MakeMono(hpDst);
                PutMono(hpDst,Frame,Level);
                }
            }
        }
    if (hpDst)
        delete [] hpDst;
    return result;
}

void CScene::XThumb(HPBYTE hpDst, UINT w, UINT h, UINT bpp, UINT Level)
{
    UINT j,i,p,v,q;
    DPZ("got blank,w:%d,h:%d",w,h);
    p = 4 * ((w * bpp + 3) / 4);
    if (bpp == 1 || !Level)
        v = 255;
    else
        v = 0;
    memset(hpDst, v, h*p);
    for (q = 0; q < 4; q++)
        {
        int x,y,dx, dy;
        dx = 1 - 2 * (q & 1);
        dy = 1 - (q & 2);
        x = w / 2;
        y = h / 2;
        for (i = 0; i < (h / 3); i++)
            {
            for (j = 0; j < bpp; j++)
                {
                if (j == 3)
                    v = 255;
                else
                    v = 0;
                hpDst[p * y + bpp*x + j] = v;
                hpDst[p * y + bpp*(x+dx) + j] = v;
                }
            x += dx;
            y += dy;
            }
        }
    return;
}

void CScene::ThumbMinMax(UINT & min, UINT & max, UINT Frame, UINT Level)
{
    min = -1;
    max = m_frames;
    if (!SelectLevel(Level))
        {
        m_pLevel->MinMax(min, max, Frame);
        SelectLevel();
        }
}
/*
    routine for finds cells for lightbox in straight ahead mode
*/
UINT CScene::Before(UINT * pList, UINT max, UINT Frame, UINT Level)
{
    UINT res = 0;
    if (!SelectLevel(Level))
        {
        res = m_pLevel->Before(pList,max,Frame);
        SelectLevel();
        }
    return res;
}

int CScene::TopLevel(UINT Frame)
{
    int level = m_levels;
    for (;level-- > 0;)
        {
        if (!SelectLevel(level))
            {
            DWORD key = m_pLevel->Select(Frame,0);
            SelectLevel();
            if (key)
                break;
            }
        }
    return level;
}


UINT CScene::GetThumb(HPBYTE hpDst, UINT Frame, UINT Level,
            UINT w, UINT h, UINT bpp, BOOL bForge /* = 0 */)
{
//return 0;
    if (Level == -1)
        Level = m_CurLevel;
//    Level = 1;
DPF("get thumb,f:%d,l:%d,w:%d,h:%d,bpp:%d,forge:%d",Frame,Level,w,h,bpp, bForge);
    DWORD key;
#ifdef _DEBUG
    if (Frame == 1 && Level == 0)
    {
        w = w;
    }
#endif
//    GetImageKey(key, Frame, Level,CCell::LAYER_THUMB);
    GetImageKey(key, Frame, Level,99);
    if (key == 1)
        {
        XThumb(hpDst, w, h, bpp, Level);
        return 0;
        }
    if ((key == 0) && bForge)
        {
        if (Level)
            {
//            GetImageKey(key, Frame, Level,CCell::LAYER_INK);
            GetImageKey(key, Frame, Level,98);
            if (!key)
                GetImageKey(key,Frame,Level,CCell::LAYER_OVERLAY);
            }
        else
            GetImageKey(key, Frame, Level,CCell::LAYER_BG);
        if (!key && GetCellKey(Frame, Level))
            {
            XThumb(hpDst, w, h, bpp, Level);
            return 0;
            }
        if (key)
            GetImageKey(key, Frame, Level,CCell::LAYER_THUMB,1);
        }
    if (key == 0)
        {
//return 0;
        UINT z = 0;
        UINT p = bpp > 1 ? 3 : 1;
        UINT y,v;
        UINT min, max;
/*
        min = max = Frame;
        for (;min--;)
            {
            GetImageKey(key, min, Level,CCell::LAYER_THUMB);
            if (key)
                break;
            }
        if (key)
            {
            UINT w,h,d;
            ImageInfo(w,h,d,key);
            if (w > 1)
                z = 1;
            }
        if (z)
            {
        key = 0;
        for (;++max < m_frames;)
            {
            GetImageKey(key, max, Level,CCell::LAYER_THUMB);
            if (key)
                break;
            }
            if (key)
                max--;
            }
*/
        
        z = 1;
        ThumbMinMax(min, max, Frame, Level);
        if (bpp == 1 || !Level)
            {
            p = 4 * ((w * p + 3) / 4);
            v = 255;
            }
        else
            {
            v = 0;
            p = 4 * w;
            }
        if (Frame == (min+1))
            min = h / 3;
        else
            min = 0;
        if ((Frame + 1) == max)
            max = h - h / 3;
        else
            max = h;
//return 0;
        UINT ww = w / 2;
        for (y = 0; y < h; y++)
            {
            memset(hpDst, v, p);
            if (z && ((h-1-y) >= min) && ((h-1-y) < max))
                {
                if (!v)
                    hpDst[4 * ww + 3] = 255;
                else if (bpp > 1)
                    {
                    hpDst[3 * ww + 0] = 0;
                    hpDst[3 * ww + 1] = 0;
                    hpDst[3 * ww + 2] = 0;
                    }
                else
                    hpDst[ww + 0] = 0;
                }
            hpDst += p;
            }
        return 0;
        }
DPF("reading thumb");
    CImage * pImage = new CImage(m_pIO);
    if (pImage == NULL)
        {
DPF("new thumb read failure");
        return 0;
        }
    pImage->SetKey(key);
    if (pImage->Read(NULL))
        {
DPF("read thumb header failure");
        delete pImage;
        return 0;
        }
#ifndef NEWTHUMBS
    if ((pImage->Width() == w) && (pImage->Height() == h) &&
            (pImage->Depth() == 8*bpp) && !bForge)
        {
DPF("reading existing thumb");
        int result = pImage->Read(hpDst);
        delete pImage;
        return result;
        }
    else
#endif
        {
DPF("no match,w:%d,h:%d",pImage->Width(),pImage->Height());
        }

/*
    read header
    if w and h match read it
    else
        get gray
        make thumb
*/
    UINT gw = m_width;// / m_scale;
    UINT gh = m_height;// / m_scale;
    UINT size = gh * 4 * ((bpp*gw+3)/ 4);
    BYTE * buf = new BYTE[size];
UINT zize = m_size;
UINT zpp = m_depth;
m_depth = bpp;
m_size = size;
    if (!Level)
        GetLevel0(buf,Frame,0,100,0,0);
    else
        {
        memset(buf, bpp == 1 ? 255 : 0, m_size);
        GetCell(buf,Frame, Level);
        }
m_depth = zpp;
m_size = zize;

    CGScaler scale;
    if (scale.Init(gw,gh,8*bpp,w,h))
        {
DPF("scale failure");
        delete pImage;
        return 0;
        }
    int p = 4 * ((bpp*w + 3) / 4);
    int q = scale.Custom(hpDst, buf, p);
DPF("after custom:%d",q);
    int z = scale.Copy();
DPF("after scale:%d",z);
    pImage->Setup(w, h, 8*bpp);
    pImage->Write(hpDst);
    m_bModified = TRUE;

    delete [] buf;
    delete pImage;
    return 0;

}
/*
UINT CScene::MakeThumb(HPBYTE hpSrc, UINT Frame, UINT Level)
{
DPF("making thumb,f:%d,l:%d",Frame,Level);
    UINT p = 4 * ((m_thumbw + 3) / 4);
    UINT size = m_thumbh * p;
    BYTE * buf = new BYTE[size];
    HPBYTE hpTmp = buf;
    CGScaler scale;
    UINT w = m_width;// / m_scale;
    UINT h = m_height;// / m_scale;
    if (scale.Init(w, h,1,m_thumbw,m_thumbh))
        {
DPF("scale failure");
        delete [] buf;
        return 0;
        }
    int q = scale.Custom(buf, hpSrc, p);
DPF("after custom:%d",q);
    int z = scale.Copy();
DPF("after scale:%d",z);
    PutImage(buf, Frame,Level,CCell::LAYER_THUMB);
    delete [] buf;
    return 0;
}
*/
UINT CScene::BlankThumb(UINT Frame, UINT Level)
{
    return 0;
DPF("blanking thumb,f:%d,l:%d",Frame,Level);
    BYTE  buf[10];
    DWORD key;
    GetImageKey(key, Frame, Level,CCell::LAYER_THUMB,TRUE);
    if (key == 0)
        {
DPF("null key after bmake");
        return 1;
        }
    else
        WriteImage(buf, key, 99);    // kludge for blank
    return 0;
}

#ifdef MAKEWATERMARK
int CScene::MakeImprint()
{
    CFile file;

    DWORD mode = CFile::modeRead;
#ifdef TGA
//    if (!file.Open("c:\\flipbook\\camskt\\watermark432.tga", mode))
#ifdef THE_DISC
    if (!file.Open("c:\\flipbook\\camskt\\Th DISC! 2007RP_startup.tga", mode))
#else
    if (!file.Open("c:\\flipbook\\camskt\\newwatermark.tga", mode))
#endif
#else
    if (!file.Open("h:\\newskt\\watermar\\watermark.bmp", mode))
#endif
        {
DPF("no open");
        return 88;
        }
    DWORD ss = file.GetLength();
    BYTE * fp = new BYTE[ss];
    if (!fp)
        {
        file.Close();
DPF("no mem");
        return 87;
        }
    UINT osiz = file.ReadHuge(fp, ss);
    file.Close();
#ifndef TGA
    osiz -= 14;
#endif
    DWORD dsize = 20 + (osiz * 102) / 100;
    BYTE * tbuf = new BYTE[dsize];
    if (tbuf == NULL)
        {
        delete [] fp;
DPF("compress mem failure ");
        return 85;
        }
    DWORD * dp = (DWORD *)tbuf;
    dp[0] = 0;
    dp[1] = osiz;
#ifdef TGA
    UINT cq = compress(tbuf+12,&dsize,fp,osiz);
#else
    UINT cq = compress(tbuf+12,&dsize,fp+14,osiz);
#endif
    delete fp;
    if (cq)
        {
DPF("compression failure:%d",cq);
        delete tbuf;
        return 1;
        }
    dp[2] = dsize;
DPF("compressed size:%d",dsize);
    mode = CFile::modeWrite | CFile::modeCreate;
    if (!file.Open("c:\\flipbook\\camskt\\watermk4.xyz", mode))
        {
DPF("no create");
        delete [] tbuf;
        return 86;
        }
    file.WriteHuge(tbuf, dsize+12);
    file.Close();
    delete [] tbuf;
    return 66;
}
#endif

int CScene::ForgeImprint(UINT ow, UINT oh)
{
//    UINT ow = ComW();
//    UINT oh = ComH();
    if (m_pImprint)
        delete [] m_pImprint;
#ifdef TGA
    if (m_depth == 1)
        m_pImprint = new BYTE[oh*ow*m_depth];
    else
        m_pImprint = new BYTE[oh * ow * 4];
#else
    m_pImprint = new BYTE[oh*ow*m_depth;
#endif
#ifdef MAKEWATERMARK
    MakeImprint();
    return 99;
#endif
    int result = 0;
    HRSRC hRes = FindResource(AfxGetApp()->m_hInstance, "IMPRINT", "DGCRES");
    if (!hRes)
        {
        DPF("cannot find imprint");
        return 11;
        }
    HGLOBAL hand = LoadResource(AfxGetApp()->m_hInstance , hRes);
    if (!hand)
        {
        DPF("cannot load imprint");
        return 12;
        }
    BYTE * hpSrc = (BYTE *) LockResource(hand);
    if (!hpSrc)
        {
        DPF("cannot lock imprint");
        return 13;
        }
    UINT * pData = (UINT *)hpSrc;
    UINT t = SWAPV(pData[0]);
    UINT ins = SWAPV(pData[1]);
    UINT outs = SWAPV(pData[2]);
    if (t)
        {
        UnlockResource(hand);
        return 14;
        }
    DPF("imprint,ins:%d,outs:%d",ins,outs);
    BYTE * hpDst = new BYTE[ins];
    if (!hpDst)
        {
        UnlockResource(hand);
        return 15;
        }
    DWORD vc = ins;
    UINT qq = uncompress(hpDst,&vc,hpSrc+12,outs);
    if (qq)
        {
DPF("decompress error:%d",qq);
        delete [] hpDst;
        UnlockResource(hand);
        return 16;
        }
    UINT iw;
    UINT ih;
    UINT Depth;
#ifdef TGA
//    WORD * pw = (WORD *)hpDst;
    Depth = 0;
    iw = hpDst[12] + 256 * hpDst[13];//pw[6];
    ih = hpDst[14] + hpDst[15] * 256;//pw[7];
//    if ((pw[1] == 2) && ((pw[8] / 256) == 8))
    if ((hpDst[2] == 2) && (hpDst[17] == 8))
        Depth = hpDst[16];//pw[8] & 255;
#else
    LPBITMAPINFOHEADER lpBI = (LPBITMAPINFOHEADER)hpDst;
    iw = lpBI->biWidth;
    ih = lpBI->biHeight;
    Depth = lpBI->biBitCount;
#endif
    DPF("src %d,%d,%d", iw,ih,Depth);
    if ((Depth != 8) && (Depth != 24) && (Depth != 32))
        {
DPF("bad depth:%d",Depth);
        delete [] hpDst;
        UnlockResource(hand);
        return 19;
        }
    UINT bpp = Depth / 8;
    CGScaler scale;
    BYTE * pTemp;
    if (m_depth != 3)
#ifdef TGA
        pTemp = new BYTE[oh * 4 * ow];
#else
        pTemp = new BYTE[oh * 4 * ((3 * ow + 3) / 4)];
#endif
    else
        pTemp = m_pImprint;
    if (scale.Init(iw,ih,Depth,ow,oh))
        {
DPF("scale failure");
        delete [] hpDst;
        UnlockResource(hand);
        return 17;
        }
    int p = 4 * ((bpp*ow + 3) / 4);
    BYTE * pdst = hpDst;
#ifdef TGA
    pdst += 18;
#else
    pdst += 40;
    if (bpp == 1)
        pdst += 1024;
#endif
    int q = scale.Custom(pTemp, pdst, p, 4 * ((bpp*iw+3)/ 4));
DPF("after custom:%d",q);
    int z = scale.Copy();
DPF("after scale:%d",z);
    delete [] hpDst;
    UnlockResource(hand);
    UINT ip;
#ifdef TGA
        ip = 4 * ow;
#else
        ip = 4 * ((3 * ow + 3) / 4);
#endif
    if (m_depth != 3)
        {
        UINT x, y, op;
        op = 4 * ((m_depth * ow + 3) / 4);
        for (y = 0; y < oh; y++)
        for (x = 0; x < ow; x++)
            {
#ifdef TGA
            m_pImprint[y*op+x] = 255 -
                    pTemp[y*ip+4*x+3] * IMPRINT_ALPHA / 100;
#else
            UINT v = 30 * pTemp[y*ip+3*x+1] +
                    59 * pTemp[y*ip+3*x+0] +
                    11 * pTemp[y*ip+3*x+2];
            m_pImprint[y*op+x] = v / 100;
#endif
            }
        delete [] pTemp;
        }
    else
        {
        UINT x, y;
        for (y = 0; y < oh; y++)
        for (x = 0; x < ow; x++)
            {
            m_pImprint[y*ip+4*x+3] =
                m_pImprint[y*ip+4*x+3] * IMPRINT_ALPHA / 100;
            }
        }
    return result;
}

int CScene::LoadScenePalette()
{
    int result = 0;
    int i;
    BYTE * pDefault = m_pScenePalette + 1024;
    for (;;)
    {
    result = 11;
    HRSRC hRes = FindResource(AfxGetApp()->m_hInstance, "PALETTE", "DGCRES");
    if (!hRes)
        {
        DPF("cannot find palette");
        break;
        }
    HGLOBAL hand = LoadResource(AfxGetApp()->m_hInstance , hRes);
    if (!hand)
        {
        result = 12;
        DPF("cannot load palette");
        break;
        }
    BYTE * hpSrc = (BYTE *) LockResource(hand);
    if (!hpSrc)
        {
        result = 13;
        DPF("cannot lock palette");
        break;
        }
    result = 0;
    for (i = 0; i < 1024; i++)
        pDefault[i] = hpSrc[i+2];
    UnlockResource(hand);
    for (i = 240; i < 255; i++)
        pDefault[4*i+3] = 128;
    pDefault[1020] = 255;
    pDefault[1021] = 255;
    pDefault[1022] = 255;
    pDefault[1023] = 255;
    break;
    }
    if (result)
        {
        for (i = 0; i < 256; i++)
            {
            pDefault[4*i+0] = i;
            pDefault[4*i+1] = i;
            pDefault[4*i+2] = i;
            pDefault[4*i+3] = 255;
            }
        }
    if (m_pIO->GetRecord(m_pScenePalette, 1024, KEY_PALETTE))
        {
        memmove(m_pScenePalette, pDefault, 1024);
        m_pIO->PutRecord(m_pScenePalette, 1024, KEY_PALETTE);
        }
    return result;
}

UINT CScene::PaletteIO(LPCSTR name, BYTE * pals, BOOL bPut /* = 0 */)
{
    UINT result = 0;
    if (bPut)
        {
        CFile file;
        DWORD mode = CFile::modeCreate | CFile::modeWrite;
        if (!file.Open(name, mode))
            return 1;
        char buf[80];
        sprintf(buf,"DGC-PAL\r\n");
        file.Write(buf,strlen(buf));
        int i;
        for (i = 0; i < 256; i++)
            {
            sprintf(buf,"%3d,%3d,%3d,%3d,%3d\r\n", i,
                pals[4*i+0], pals[4*i+1], pals[4*i+2],pals[4*i+3]);
            file.Write(buf,strlen(buf));
            }
        file.Close();
        }
    else
        {
        CFile file;
        DWORD mode = CFile::modeRead;
        if (!file.Open(name, mode))
            return 1;
        CArchive arPal(&file, CArchive::load);
        char buf[80];
        int i;
        for(i = -1; i < 256; i++)
            {
            arPal.ReadString(buf, 80);
            DPF("i:%d,%s",i,buf);
            if (i == -1)
                {
                if (buf[0] != 'D' || buf[1] != 'G' || buf[2] != 'C')
                    break;
                }
            else
                {
                int j,r,g,b,o;
                if (sscanf(buf,"%d,%d,%d,%d,%d\n",&j,&r,&g,&b,&o) != 5)
                    break;
                if (j != i)
                    break;
                pals[4*i+0] = r;
                pals[4*i+1] = g;
                pals[4*i+2] = b;
                pals[4*i+3] = o;
                }
            }
        arPal.Close();
        file.Close();
        DPF("i:%d",i);
        if (i < 256)
            result = 2;
        }
    return result;
}


int     CScene::Tools(void * pTools, UINT size, BOOL bPut/*= FALSE*/)
{
    UINT stat;
    if (bPut)
        {
        stat = m_pIO->PutSwapRecord(pTools, size, KEY_TOOLS);
        m_bModified = TRUE;
        }
    else
        stat = m_pIO->GetSwapRecord(pTools, size, KEY_TOOLS);
    return stat;
}

UINT   CScene::Pals(BYTE * pPals, UINT Level, BOOL bPut /* = 0 */)
{
    BOOL bLevel = !SelectLevel(Level);
    if (bLevel && bPut)
        {
        BOOL bUpdate = 0;
        char name[300];
        m_pLevel->PalName(name);
DPZ("palname0:%d",name[0]);
        if (!name[0])
            memmove(m_pScenePalette, pPals, 1024);
        m_pLevel->Pals(pPals,0);
        m_bModified = TRUE;
        if (!m_bLoading)
            {
            if (name[0] != 1) // see if other levels have the same palette name
                {
                 for (UINT Lev = 0; Lev < m_levels; Lev++)
                    {
                    if ((Lev != Level) && !SelectLevel(Lev))
                        {
                        char name2[300];
                        m_pLevel->PalName(name2);
                        if (!strcmp(name,name2))
                            {
                            m_pLevel->Pals(pPals,0); // write its pals, also
                            m_bModified = TRUE;
                            if (m_pLevel->Flags() & 1)
                                bUpdate = 1;
                            }
                        }
                    }
                m_pIO->PutRecord(m_pScenePalette, 1024, KEY_PALETTE);
                }
            else if (m_pLevel->Flags() & 1)
                bUpdate = 1;
            if (bUpdate)
                UpdateCache();
            }
        }
    else if (bLevel)
        {
        m_pLevel->Pals(pPals,this);
        }
    if (bLevel)
        SelectLevel();
    return 0;
}

void    CScene::SceneOptionLock(BOOL bLock)
{
    if (bLock)
        m_bOptLock = 1;
    else
        {
ASSERT(m_bOptLock);
        m_bOptLock = 0;            // remove lock
        GetPutOptions(TRUE);    // write options
        }
}

#define DOIT(a) oldval=a;if (op == 2) a ^= 1; else if (op == 1) a=val; val=a
int    CScene::SceneOptionInt(int Id, int op, int val)
{
    int oldval;
    UINT bit, shift, mask;
    switch (Id) {
    case SCOPT_VMARK:
        DOIT(m_vmark);
        break;
    case SCOPT_SMARK:
        DOIT(m_smark);
        break;
    case SCOPT_RATE:
        DOIT(m_rate);
        break;
    case SCOPT_SOUND:
        DOIT(m_bSound);
        break;
    case SCOPT_BUD0:
        DOIT(m_nBuddy0);
        break;
    case SCOPT_BUD1:
        DOIT(m_nBuddy1);
        break;
    case SCOPT_BUD2:
        DOIT(m_nBuddy2);
        break;
    case SCOPT_BUD3:
        DOIT(m_nBuddy3);
        break;
    case SCOPT_QUIET:
    case SCOPT_SCACHE:
    case SCOPT_NEXT:
    case SCOPT_PREV:
    case SCOPT_NEXT1:
    case SCOPT_PREV1:
    case SCOPT_PAINT:
        if (Id == SCOPT_PREV)
            bit = 64;
        else if (Id == SCOPT_NEXT)
            bit = 128;
        else if (Id == SCOPT_PREV1)
            bit = 0x10000;
        else if (Id == SCOPT_NEXT1)
            bit = 0x20000;
        else if (Id == SCOPT_PAINT)
            bit = 0x40000;
        else if (Id == SCOPT_QUIET)
            bit = 1;
        else
            bit = 2;
        oldval = m_OptFlags;
        if (op == 2)
            m_OptFlags ^= bit;
        else if (op)
            {
                m_OptFlags |= bit;
            if (!val)
                m_OptFlags ^= bit;
            val = m_OptFlags;
            }
        else
            {
            if (m_OptFlags & bit)
                val = 1;
            else
                val = 0;
            }
        break;
    case SCOPT_MRU:
    case SCOPT_TELECINE:
        if (Id == SCOPT_MRU)
            {
            shift = 4;
            mask = 3;
            }
        else
            {
            shift = 2;
            mask = 3;
            }
        oldval = m_OptFlags;
        if (op == 2)
            val = 0;
        else if (op)
            {
            val = val << shift;
            mask = mask << shift;
            m_OptFlags |= mask;    // all on
            m_OptFlags ^= mask;    // all off
            m_OptFlags |= val & mask;
            val = m_OptFlags;
            }
        else
            {
            val = (m_OptFlags >> shift) & mask;
            }
        break;
    case SCOPT_HOLD:
        oldval = m_OptFlags;
        if (op == 2)
            break;
        else if (op)
            {
            if (val) val--;    // normalize from 1..256 to 0..255
            m_OptFlags &= 0xffff00ff;
            m_OptFlags |= ((val & 255) << 8);
            val = m_OptFlags;
            }
        else
            {
            val = 1 + ((m_OptFlags >> 8) & 255);
            }
        break;
    case SCOPT_SNIP:
        DOIT(m_snip);
        break;
    case SCOPT_BLIND:
        DOIT(m_bBlind);
        break;
    }
    if (op && !m_bOptLock && (val != oldval))
        GetPutOptions(TRUE);
    return val;
}

int    CScene::SceneOptionStr(int Id, LPSTR arg, int op)
{
    if (Id == SCOPT_WAVE)
        {
        if (op)
            {
            strcpy(m_wave, arg);
            GetPutOptions(TRUE);
            }
        else
            strcpy(arg, m_wave);
        }
    return 0;
}

int CScene::GetPutOptions(BOOL bPut)
{
//    history
//    version 1 oct 6, 2000
//    version 2 oct 8, 2000
//
//    Kludge with capital K, July 10, 2006
//    need 40 bits for 4 buddy levels in lightbox
//    using top 20 bits of bgmin and bSound
//    please forgive me
//

typedef struct {
    UINT    version;
    UINT    rate;
    UINT    vmark;
    UINT    smark;
    UINT    bgmin;
    UINT    bSound;
    UINT    OptFlags; // 1 is quiet, 2 is save cache
//                    telecine is 4 and 8
//                    hold is 00ff00
//                        16 is MRU, 32 is next, 64 is prev
    char    wave[300];
    UINT    snip;
    BOOL    blind;                // version 2

/*
    BOOL    bStory;                // version 3
    UINT    StoryRate;
    UINT    vc_black;
    UINT    vc_white;
    UINT    vc_gamma;

    UINT    tool;
    UINT    pen_radius;
    UINT    pen_density;
    UINT    pen_color;
    UINT    pencil_radius;
    UINT    pencil_density;
    UINT    pencil_color;
    UINT    eraser_radius;
    UINT    eraser_density;
    UINT    eraser_color;
*/
} OPTIONSREC;
    int res = 0;
    OPTIONSREC opt;
    if (bPut)
        {
        opt.version = 3;
        opt.rate = m_rate;
        opt.vmark = m_vmark;
        opt.smark = m_smark;
        opt.OptFlags = m_OptFlags ^ 192; //SCOPT_PREV | SCOPT_NEXT, defaults
        opt.bgmin = m_MinBG + (m_nBuddy0 << 8) + ( m_nBuddy1 << 18);
        opt.bSound= m_bSound+ (m_nBuddy2 << 8) + ( m_nBuddy3 << 18);
        opt.snip = m_snip;
        opt.blind = m_bBlind;
        strcpy(opt.wave, m_wave);
        DOSWAPX((BYTE*)&opt,28,300,sizeof(opt));
        if (m_pIO->PutRecord(&opt, sizeof(opt), KEY_OPTIONS))
            res = 1;
        m_bModified = TRUE;
        }
    else
        {
        opt.version = 1;
        opt.rate = 24;
        opt.vmark = 0;
        opt.smark = 0;
        opt.snip = 3;
        opt.bSound = 0;
        opt.OptFlags = 0;
        opt.blind = 0;
        opt.bgmin = 0;
        opt.wave[0] = 0;
        m_nBuddy0 = m_nBuddy1 = m_nBuddy2 = m_nBuddy3 = 0;
        if (m_pIO->GetRecord(&opt, sizeof(opt), KEY_OPTIONS))
            res = 1;
        DOSWAPX((BYTE *)&opt,28,300,sizeof(opt));
        if (opt.version == 1)
            opt.blind = 0;
        else if (opt.version > 3)
            return 2;
        m_rate = opt.rate;
        m_vmark = opt.vmark;
        m_smark = opt.smark;
        m_nBuddy0 = min((opt.bgmin >> 8) & 0x3ff,m_levels-1);
        m_nBuddy1 = min((opt.bgmin >> 18) & 0x3ff,m_levels-1);
        m_nBuddy2 = min((opt.bSound >> 8) & 0x3ff,m_levels-1);
        m_nBuddy3 = min((opt.bSound >> 18) & 0x3ff,m_levels-1);
        m_bSound = opt.bSound & 1;
        m_OptFlags = opt.OptFlags ^ 192;//(SCOPT_PREV | SCOPT_NEXT); // defaults
        m_MinBG = opt.bgmin & 0xff;
        m_snip = opt.snip;
        m_bBlind = opt.blind;
        strcpy(m_wave, opt.wave);
        }
    return res;
}

void CScene::MakeInfo(BOOL bRead)
{
    if (!m_info)
        {
        m_info = 9999;
        delete [] m_pInfo;
        m_pInfo = new UINT[m_levels + 1];
        if (!m_pInfo)
            return;
        if (bRead)
            {
            if (!m_pIO->GetSwapRecord(m_pInfo,4*(1 + m_levels),KEY_LEVELINFO))
                {
DPF("info rec:%d",m_pInfo[0]);
                if (m_pInfo[0] == 1)
                    m_info = 1;
                }
            }
        if (m_info != 1)
            {
            UINT i;
            for (i = 0; i < m_levels; m_pInfo[++i] = 9999);
            m_info = 1;
            }
        }
}

UINT CScene::GetLevelInfo(UINT what, UINT level, UINT def)
{
    if (m_info != 1)
        MakeInfo(TRUE);
DPF("get info,%d,lvl:%d,v:%d",m_info,level,m_pInfo[1+level]);
    if (m_pInfo[1+level] == 9999)
        return def;
    else
        return m_pInfo[1+level];
}

void CScene::PutLevelInfo(UINT what, UINT level, UINT value)
{
DPF("put info,%d,%d",level,value);
    if (level == 9999)
        {
DPF("info:%d",m_info);
        if ((m_info == 1) && m_bModified)
            {
            m_pInfo[0] = 1;
            UINT z=m_pIO->PutRecord(m_pInfo, 4 * (1 + m_levels), KEY_LEVELINFO);
DPF("z:%d",z);
            }
        return;
        }
    if (m_info != 1)
        {
        MakeInfo(0);
        }
    if (m_info != 1)
        return;
    if (value != m_pInfo[level+1])
        {
        m_bModified = TRUE;
        m_pInfo[level+1] = value;
        }
}

int     CScene::AVIInfo(void * pInfo, UINT size, BOOL bPut/*= FALSE*/)
{
    UINT stat;
    if (bPut)
        {
        stat = m_pIO->PutRecord(pInfo, size, KEY_AVI);
        m_bModified = TRUE;
        }
    else
        stat = m_pIO->GetRecord(pInfo, size, KEY_AVI);
    return stat;
}

void CScene::ApplyImprint(HPBYTE pBuf, UINT d)
{
    UINT ow,oh;
    if (!d)
        {
        ow = ComW();
        oh = ComH();
        d = m_depth;
        }
    else
        {
        ow = m_width;
        oh = m_height;
        }
    if (m_depth == 1)
        d = 1;
    UINT f = ow / ComW();
    UINT x,y,z,op,zp;
    UINT ix,iy;
    op = 4 * ((d * ow + 3) / 4);
    if (d == 1)
        {
        zp = 4 * (((ComW()) + 3) / 4);
        for (y = 0; y < oh; y++)
        for (x = 0; x < ow; x++)
            {
            ix = x / f;
            iy = y / f;
            UINT v = m_pImprint[iy*zp+ix];
            UINT q = pBuf[op*y+x];
            v = (v * q) / 255;
            pBuf[op*y+x] = (BYTE)v;
            }
        return;
        }
    zp = 4 * ComW();
    for (y = 0; y < oh; y++)
        {
        for (x = 0; x < ow; x++)
            {
            ix = x / f;
            iy = y / f;
            UINT f_alpha = m_pImprint[iy*zp+4*ix+3];
            if (f_alpha)
                {
                if (d == 4)
                    {
                    UINT j,t;
                    UINT b_alpha = pBuf[op*y+4*x+3];
                    for (j = 0; j < 3; j++)
                        {
                        UINT back = (UINT)pBuf[op*y+4*x+j] * b_alpha;
                        t  = ((long)m_pImprint[zp*iy+4*ix+j] * f_alpha +
                                    back - back * f_alpha / 255) / 255;
                        pBuf[op*y+d*x+j] = t;
                        }
                    t = f_alpha + b_alpha - (f_alpha * b_alpha) / 255;
                    pBuf[op*y+d*x+3] = t;
                    }
                else
                    {
                    for (z = 0; z < 3; z++)
                        pBuf[y*op+d*x+z] =
                                ((UINT)pBuf[y*op+d*x+z] * (255 - f_alpha) +
                            (UINT)m_pImprint[iy*zp+4*ix+z] * f_alpha) / 255;
                    }
                }
            }
    }
}

UINT CScene::UnWrapCell(CFile &file)
{
    CCell * pCell = new CCell(m_pIO);
    UINT key = pCell->Get(file);
    delete pCell;
    return key;
}

UINT CScene::WrapCell(CFile &file, UINT Key)
{
    CCell * pCell = new CCell(m_pIO);
    pCell->SetKey(Key);
    if (!pCell->Read())
        {
        pCell->Put(file);
        }
    delete pCell;
    return 0;
}

UINT CScene::LoadCache(LPCSTR pname)
{
    DPZ("load cache");
    CACHEHEADER header;
    char name[300];
    strcpy(name,pname);
    int c = strlen(name);
    if (!c) return 1;
    name[c - 1] = 'Q';
    CFile file;
    DWORD mode = CFile::modeRead;
    if (!file.Open(name, mode))
        return 1;
    UINT w = ComW();
    UINT h = ComH();
    UINT d = m_depth;
    file.Read(&header,sizeof(header));
    if (header.dwId != DGQID ||
        header.wWidth != w ||
        header.wHeight != h ||
        header.wDepth != d ||
        header.wFrameCount != m_frames)
        {
DPZ("hdr mismatch");
        file.Close();
        return 2;
        }
    UINT pp = h * w;
    UINT p = 4 * ((w * d + 3) / 4);
    UINT size = h * p;
    UINT maxsize = (11 * d * pp) / 10;
    BYTE * temp = new BYTE[maxsize];
    BYTE * rgb = new BYTE[d * pp];
    if (!temp || !rgb)
        {
        delete []temp;
        delete []rgb;
        file.Close();
        return 3;
        }
    BYTE * buf;
    BYTE * ref;
    for (UINT frame = 0; frame < m_frames; frame++)
        {
        buf = m_pCache[frame];
if (header.dwCode)
    {
        UINT insize;
        file.Read(&insize,4);
        file.Read(temp,insize);
        DWORD vc = d * pp;
        UINT qq = uncompress(rgb,&vc,temp,insize);
        if (qq)
            {
DPZ("decompress error:%d",qq);
            break;
            }
    }
else
    {
        file.Read(rgb,d*pp);
    }
        UINT x,y,j;
        for (y = 0; y < h; y++)
            {
            for (x = 0; x < w; x++)
                {
                if (frame)
                    for (j = 0; j < d; j++)
                        buf[y*p+d*x+j] = ref[y*p+d*x+j] + rgb[pp*j+y*w+x];
                else
                    for (j = 0; j < d; j++)
                        buf[y*p+d*x+j] = rgb[pp*j+y*w+x];
                }
            }
        m_pFlags[frame] = 0;
        ref = buf;
        }
    delete [] rgb;
    delete [] temp;
    file.Close();
    return 0;
}

#define COMPRESSCACHE
UINT CScene::SaveCache(LPCSTR pname)
{
    DPZ("save cache");
    CACHEHEADER header;
    UINT w = ComW();
    UINT h = ComH();
    UINT d = m_depth;
    UINT pp = h * w;
    UINT p = 4 * ((w * d + 3) / 4);
    UINT size = h * p;
    UINT maxsize = (11 * d * pp) / 10;
    BYTE * temp = new BYTE[maxsize];
    BYTE * rgb = new BYTE[d * pp];
    if (!temp || !rgb)
        {
        delete temp;
        delete rgb;
        return 3;
        }
    CFile file;
    DWORD mode = CFile::modeWrite | CFile::modeCreate;
    if (!file.Open(pname, mode))
        {
        delete temp;
        delete rgb;
        return 2;
        }
    header.dwId = DGQID;
    header.wWidth = w;
    header.wHeight = h;
    header.wDepth = d;
    header.wFrameCount = m_frames;
#ifdef COMPRESSCACHE
    header.dwCode = 1;
#else
    header.dwCode = 0;
#endif
    file.Write(&header,sizeof(header));

    BYTE * buf;
    BYTE * ref;
    for (UINT frame = 0; frame < m_frames; frame++)
        {
        UINT x,y,j;
        buf = m_pCache[frame];
        for (y = 0; y < h; y++)
            {
            for (x = 0; x < w; x++)
                {
                if (frame)
                    for (j = 0; j < d; j++)
                        rgb[pp*j+y*w+x] = buf[y*p+d*x+j] - ref[y*p+d*x+j];
                else
                    for (j = 0; j < d; j++)
                        rgb[pp*j+y*w+x] = buf[y*p+d*x+j];
                }
            }
        ref = buf;
        DWORD dsize = maxsize;
#ifdef COMPRESSCACHE
        UINT cq = compress(temp,&dsize,rgb,d* pp);
        if (cq)
            {
DPZ("compress failure");
            break;
            }
        file.Write(&dsize,4);
        file.Write(temp,dsize);
#else
        file.Write(rgb,d * pp);
#endif
        }
    file.Close();
    delete [] rgb;
    delete [] temp;
    return 0;
}

void CScene::LevelTable(UINT Level, CLevelTable * tbl, BOOL bPut /*= 0 */)
{
    BOOL bLevel = !SelectLevel(Level,1);
    if (bLevel && bPut)
        {
        UINT flags;
        if (flags = m_pLevel->Table(tbl,0))
            m_bModified = TRUE;
        if (flags && !m_bLoading && (m_pLevel->Flags() & 1))
            UpdateCache();
//        BlowCell(-1,-1);
        }
    else if (bLevel)
        {
        m_pLevel->Table(tbl,this);
        if ((tbl->table[0].name[0] == 0 ) &&
                (tbl->table[0].name[1] == (char)255))
            {
            for (int i = 0; i < 11; i++)
                {
                if (i == 5)
                    sprintf(tbl->table[i].name,"Ink & Paint");
                else if (i > 5)
                    sprintf(tbl->table[i].name,"Above %d",i-5);
                else
                    sprintf(tbl->table[i].name,"Below %d",i+1);
                tbl->table[i].color = 0;
                tbl->table[i].blur = 0;
                tbl->table[i].flags = 0x300;//i == 5 ? 0x300 : 0;
                tbl->table[i].dx = 0;
                tbl->table[i].dy = 0;
                }
            }

        }
    if (bLevel)
        SelectLevel();
}


CLevelTable::CLevelTable()
{
    memset(this,0,sizeof(LEVTBL));
//    table[0].name[1] = (char)255; // make look like old
    for (int i = 0; i < 11; i++)
        {
        if (i == 5)
            sprintf(table[i].name,"Ink & Paint");
        else if (i > 5)
            sprintf(table[i].name,"Above %d",i-5);
        else
            sprintf(table[i].name,"Below %d",i+1);
        table[i].color = 0;
        table[i].blur = 0;
        table[i].flags = 0x300;//i == 5 ? 0x300 : 0;
        table[i].dx = 0;
        table[i].dy = 0;
        }
}

#ifdef _DISNEY
UINT CScene::DisPalIO(BYTE * p, UINT size, BOOL bPut)
{
    if (bPut)
        return m_pIO->PutRecord(p, size, KEY_DISPAL);
    else
        return m_pIO->GetRecord(p,size,KEY_DISPAL);
}
#endif
