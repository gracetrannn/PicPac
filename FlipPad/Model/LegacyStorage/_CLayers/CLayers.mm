//
//  CLayers.m
//  FlipPad
//
//  Created by Alex on 04.09.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

//#include "CScene.h"
#include "CLayers.h"
#include "CCell.h"
#include "zlib.h"
#include "clevtbl.h"
#include "CLevel.h"
#include "math.h"
//#include "patterns.h"

#ifdef PATTERNS
typedef struct {
    UINT    m_w;
    UINT    m_h;
    UINT    m_pitch;
    BYTE *    m_pData;
} Pattern;

#define TILING
extern Pattern * Patterns(int index);
#endif
#define MAXUNDO 20
#define MAGIC_COLOR 240

typedef struct {
    char Id[16];
    UINT version;
    UINT    width;
    UINT height;
    UINT nLays;
} MDLHEADER;

class CLayer
{
public:
    UINT    kind;
    UINT    flags;    // 1 is modified, 2 is active
    BYTE *    pData;
};

class CUndo
{
public:
    UINT    layer;
    BYTE *    pData;
};

class CPixels
{
public:
    BYTE * m_pPaint;
    BYTE * m_pInk;
    UINT m_width;
    UINT m_height;
    UINT m_pitch;
    UINT m_color;
    UINT m_offset;
    UINT m_size;
inline void Ink(int delta, BYTE v, BYTE a = 255)
            {m_pInk[delta+m_offset] = a;m_pInk[m_size+delta+m_offset] = v;};
inline     BOOL Paint(int delta = 0)
        {return m_pPaint[m_offset+delta] && !m_pInk[m_offset+delta] &&
            (m_pPaint[m_size+m_offset+delta] == m_color) ? TRUE : FALSE;};

inline     BOOL Ink(int delta = 0) {return m_pInk[m_offset+delta] ? TRUE : FALSE;};
};


#define FLAG_MODIFIED 1
#define FLAG_ACTIVE 2

#define TQ(a) (a < 7 ? a - 1 : a - 2)


//#define LAY_UNDO   0
//#define LAY_SHADOW 1
//#define LAY_PAINT  2
//#define LAY_INK    3
//#define LAY_TINT   4

//#define NLAY_PAINT  6
//#define NLAY_INK    7

static int dx[8] = {-1, 0, 1, 1, 1, 0,-1,-1};
static int dy[8] = {-1,-1,-1, 0, 1, 1, 1, 0};


typedef struct {
        UINT kind;
        COLORREF c1;
        COLORREF c2;
        CPoint    p1;
        CPoint    p2;
} CINFO;

typedef struct {
    BYTE map[256];
    UINT count;
    CINFO info[256]; // always enough
} CCOLORS;

static UINT kindex = 0;
static UINT kcolor = 0;
//#ifndef FLIPBOOK_MAC
//static COLORREF c0 = RGB(255,0,0) | 0xff000000;
//static COLORREF c1 = RGB(0,255,0) | 0xff000000;
//#endif
//static CPoint p0 = CPoint(100,100);
//static CPoint p1 = CPoint(300,300);

/*
class CColors : public CCOLORS
{
public:
    CColors();
};

CColors::CColors()
{
    memset(map,0,256);
    count = 0;
}

*/

CLayers::CLayers()
{
    m_pLayers = 0;
    m_pUndo = 0;
    m_pOverlay = 0;
    m_pControl = 0;
    m_nLayers = 0;
    m_pTable = 0;
//    m_pColors = new CColors;
    m_width = m_height = 0;
    m_nFillMax = m_nFillCount = 0;
    m_pFillStack = 0;
}

CLayers::~CLayers()
{
    EmptyUs();
}


CLevelTable * CLayers::LevelTable(BOOL bPut /* = 0 */)
{
    if (bPut)
        m_pScene->LevelTable(m_level, m_pTable, 1);
    return m_pTable;
}

BYTE * CLayers::InitPalette()
{
    m_pScene->LevelTable(m_level, m_pTable, 0); // get a copy
    return &m_pTable->pals[0];
}

void CLayers::EmptyUs()
{
    UINT i;
    for (i = 0; i < m_nLayers; i++)
        delete [] m_pLayers[i].pData;
    delete[] m_pLayers;
    m_pLayers = 0;
    if (m_pUndo)
        {
        for (i = 0; i < MAXUNDO; i++)
            delete [] m_pUndo[i].pData;
        delete[] m_pUndo;
        m_pUndo = 0;
        }
    delete [] m_pOverlay;
    m_pOverlay = 0;
    delete [] m_pControl;
    m_pControl = 0;
    delete m_pTable;
    m_pTable = 0;
//    delete m_pColors;
//    m_pColors = 0;
    delete [] m_pFillStack;
    m_pFillStack = 0;
    m_nFillMax = m_nFillCount = 0;
}

#define MAX_RADIUS 80
#define MAX_MASK (1 + 2 * MAX_RADIUS) * (1 + 2 * MAX_RADIUS)

UINT CLayers::CreateLayers()
{
    m_nCurLayer = 0;
    m_pTable = new CLevelTable;
    m_pLayers = new CLayer[m_nLayers];
    m_pUndo = new CUndo[MAXUNDO];
//    delete m_pColors;
//    m_pColors = new CColors;
    UINT i;

    for (i = 1; i < m_nLayers; i++)
        {
        UINT size;
        if ((m_nLayers < 3) || ( i == 6) || ( i == 7))
            size = 2 * m_pitch * m_height;
        else
            size = 4 * m_pitch * m_height;
        m_pLayers[i].flags = 0;
        m_pLayers[i].pData = new BYTE[size];
        memset(m_pLayers[i].pData,0,size);
        }
    if (m_nLayers < 3)
        {
        m_nPaint = 0;
        m_nInk = 1;
        m_pLayers[m_nInk].kind = CCell::LAYER_INK;
        }
    else if (m_nLayers < 4)
        {
        m_nPaint = 1;
        m_nInk = 2;
        m_pLayers[m_nInk].kind = CCell::LAYER_INK;
        m_pLayers[m_nPaint].kind = CCell::LAYER_PAINT;
        }
    else
        {
ASSERT(m_nLayers == 13);
        m_nPaint = 6;
        m_nInk = 7;
        for (i = 0; i < 5; i++)
            m_pLayers[1 + i].kind = CCell::LAYER_MATTE0 + i;
        m_pLayers[m_nInk].kind = CCell::LAYER_INK;
        m_pLayers[m_nPaint].kind = CCell::LAYER_PAINT;
        for (i = 7; i < 12; i++)
            m_pLayers[1 + i].kind = CCell::LAYER_MATTE5 + i - 7;
        }
    m_nRedo = m_nUndo = 0;
    m_nPushCount = 0;
    m_pLayers[0].flags = 0;
    m_pLayers[0].kind = 99; // undo
    m_pLayers[0].pData = 0;

    for (i = 0; i < MAXUNDO; i++)
        {
        m_pUndo[i].layer = 0;
        m_pUndo[i].pData = new BYTE[2 * m_pitch * m_height];
        }
    return 0;
}

UINT CLayers::Setup(CScene * pScene, BOOL bScene, UINT Level /* = -1 */)
{
    EmptyUs();
    m_pScene = pScene;
    if (Level != -1)
        {
        m_level = Level;
        UINT result = LoadModel(Level, TRUE);
        if (result)
            return result;
        }
    else
        {
        if (bScene)
            m_pScene->SetLayer(this);
        m_width = m_pScene->Width();
        m_height = m_pScene->Height();
        m_pitch = 4 * ((m_width + 3) / 4);
        if (m_pScene->ColorMode() || !bScene)
            m_nLayers = 13;
        else
            m_nLayers = 2;    // just ink and undo
        CreateLayers();
        }
    return 0;
}

UINT CLayers::SelectLayer(UINT Layer)
{
    if (m_pTable->layer = Layer)
        {
        if (m_pTable->layer > 5)
            m_nCurLayer = 2 + m_pTable->layer;
        else
            m_nCurLayer = m_pTable->layer;
        }
    else
        m_nCurLayer = 0;
    return m_nCurLayer;
}

UINT CLayers::Select(UINT Frame, UINT Level)
{
    UINT i;
    m_frame = Frame;
    m_level = Level;
//    m_pPalette = m_pScene->PalAddr(Level);
    m_maxx = m_width-1;
    m_minx = 0;
    m_maxy = m_height-1;
    m_miny = 0;
    m_bNeedFake = m_bModified = FALSE;
DPF("clayer sel:%d,%d",m_frame, m_level);
    m_cellkey = m_pScene->GetCellKey(Frame,Level);
    DWORD key;
    m_pScene->GetImageKey(key, Frame, Level, CCell::LAYER_OVERLAY);
    if (key)
        {
        if (!m_pOverlay)
            {
            UINT pitch;
            if (m_pScene->ColorMode())
                pitch = 4 * m_width;
            else
                pitch = 4 * ((m_width+3)/4);
            m_pOverlay = new BYTE[m_height*pitch];
            }
        m_pScene->FetchCell(m_pOverlay, Frame,Level,1,1);
        return 0;
        }
    delete [] m_pOverlay;
    m_pOverlay = 0;
    for (i = 1; i < m_nLayers; i++)
        {
        if (m_pLayers[i].kind >= CCell::LAYER_MATTE0)
            memset(m_pLayers[i].pData,0,4*m_height*m_pitch);
        else
            memset(m_pLayers[i].pData,0,2*m_height*m_pitch);
        if (!m_pScene->GetLayer(m_pLayers[i].pData, m_frame, m_level,
                            m_pLayers[i].kind))
            m_pLayers[i].flags = FLAG_ACTIVE;
        else
            {
//            memset(m_pLayers[i].pData,0,2*m_height*m_pitch);
            m_pLayers[i].flags = 0;    // clear modified
            }
        }
    m_nRedo = m_nUndo = 0;
    m_nPushCount = 0;
    return 0;
}

void CLayers::DupCell(UINT Frame, UINT Level)
{
//    Put();            // write out current
    m_frame = Frame;    // change frame
    m_level = Level;
//    Put(1);            // create new cell
    m_cellkey = m_pScene->GetCellKey(Frame,Level);
}

UINT CLayers::Put(BOOL bForce /* = 0 */)
{
    if (!bForce && !m_bModified)
        return 0;
    UINT layer, j;
    j = 0;
    for (layer = 1; layer < m_nLayers;layer++)
        {
        if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
            continue;
        if ((m_pLayers[layer].flags & FLAG_MODIFIED) || bForce)
            {
            j = 1;
            m_pScene->PutLayer(m_pLayers[layer].pData, m_frame, m_level,
                            m_pLayers[layer].kind);
            m_pLayers[layer].flags = FLAG_ACTIVE;    // clear modified
            }
        }
    m_bNeedFake = m_bModified = FALSE;
    return j;
}


LPCSTR CLayers::LayerName(int layer)
{
    return (LPCSTR)m_pTable->table[layer].name;
}
UINT CLayers::DisPaint(UINT x, UINT y)
{
    if (x >= m_width || y >= m_height)
        return 0;
    y = m_height - 1 - y;
    UINT z = y * m_pitch + x;
    if (!(m_pLayers[m_nPaint].flags & FLAG_ACTIVE))
        return 0;
    if (m_pLayers[m_nPaint].pData[z])
        return m_pLayers[m_nPaint].pData[m_pitch * m_height + z];
    return 0;
}

UINT CLayers::HaveAlpha(UINT x, UINT y, UINT * pLayer , BYTE * p)
{
    UINT layer;
    if (x >= m_width || y >= m_height)
        return 0;
    y = m_height - 1 - y;
    UINT z = y * m_pitch + x;
#ifdef MYBUG
    if (p)
    {
    UINT c = 4 * y * ((3*m_width + 3) / 4);
    UINT q = z + m_pitch * m_height;
//DPF("x:%4d,y:%4d,i:(%3d:%3d),p:(%3d:%3d),t:(%3d:%3d),%3d,%3d,%3d",x,y,
//        m_pLayers[LAY_INK].pData[z], m_pLayers[LAY_INK].pData[q],
//        m_pLayers[LAY_PAINT].pData[z], m_pLayers[LAY_PAINT].pData[q],
//        m_pLayers[LAY_TINT].pData[z], m_pLayers[LAY_TINT].pData[q],
//        p[c+3*x+0],p[c+3*x+1],p[c+3*x+2]);
    }
#endif
/*
    for (layer = 1; layer < m_nLayers; layer++)
        {
        if (m_pLayers[layer].pData[z])
            break;
        }
    return layer >= m_nLayers ? 0 : 1;
*/
    for (layer = m_nLayers; layer-- > 1;)
        {
        if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
            continue;
        UINT xx = x;
        UINT yy = y;
        UINT qq = TQ(layer);
        if ((layer != m_nPaint) && (layer != m_nInk))
            {
//            UINT qq = TQ(layer);
            if (!(m_pTable->table[qq].flags & 0x200)) // active
                continue;
            xx -= m_pTable->table[qq].dx;
            yy -= m_pTable->table[qq].dy;
            }
        if (xx >= m_width || yy >= m_height)
            continue;
        UINT z = yy * m_pitch + xx;
        if (m_pLayers[layer].pData[z])
            {
            if (pLayer)
                *pLayer = qq;
//            index = m_pLayers[layer].pData[m_pitch * m_height + z];
            break;
            }
        }
    return layer ? 1 : 0;
}

UINT CLayers::GetIndex(UINT x, UINT y)
{
    UINT layer;
    UINT index = -1;
    y = m_height - 1 - y;
//    UINT z = y * m_pitch + x;
//    for (layer = 1; layer < m_nLayers;layer++)
    for (layer = m_nLayers; layer-- > 1;)
        {
        if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
            continue;
        UINT xx = x;
        UINT yy = y;
        if ((layer != m_nPaint) && (layer != m_nInk))
            {
            UINT qq = TQ(layer);
            if (!(m_pTable->table[qq].flags & 0x200)) // active
                continue;
            xx -= m_pTable->table[qq].dx;
            yy -= m_pTable->table[qq].dy;
            }
        if (xx >= m_width || yy >= m_height)
            continue;
        UINT z = yy * m_pitch + xx;
        if (m_pLayers[layer].pData[z])
            {
            index = m_pLayers[layer].pData[m_pitch * m_height + z];
            break;
            }
        }
    return index;
}

UINT CLayers::GetInk(UINT xx, UINT yy)
{
    if (xx >= m_width || yy >= m_height)
        return 255; // so it is xparent
    yy = m_height - 1 - yy;
    UINT z = yy * m_pitch + xx;
    return 255 - m_pLayers[m_nInk].pData[z];
}

void CLayers::PutInk(UINT xx, UINT yy, BYTE v)
{
    if (xx >= m_width || yy >= m_height)
        return;
    yy = m_height - 1 - yy;
    UINT z = yy * m_pitch + xx;
    m_pLayers[m_nInk].pData[z] = 255 - v;
}

UINT CLayers::GetAlpha(UINT x, UINT y)
{
    UINT layer;
    UINT index = -1;
    y = m_height - 1 - y;
//    UINT z = y * m_pitch + x;
//    for (layer = 1; layer < m_nLayers;layer++)
    for (layer = m_nLayers; layer-- > 1;)
        {
        if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
            continue;
        UINT xx = x;
        UINT yy = y;
        if ((layer != m_nPaint) && (layer != m_nInk))
            {
            UINT qq = TQ(layer);
            if (!(m_pTable->table[qq].flags & 0x200)) // active
                continue;
            xx -= m_pTable->table[qq].dx;
            yy -= m_pTable->table[qq].dy;
            }
        if (xx >= m_width || yy >= m_height)
            continue;
        UINT z = yy * m_pitch + xx;
        if (m_pLayers[layer].pData[z])
            {
            index = m_pLayers[layer].pData[z];
            break;
            }
        }
    return index;
}

UINT CLayers::GetRGB(int x, int y, UINT &r,UINT &g,UINT &b)
{
    UINT layer;
    if ((UINT)x >= m_width || (UINT)y >= m_height)
        return 0;
    y = m_height - 1 - y;
    UINT z = y * m_pitch + x;
#ifdef QMYBUG
    if (p)
    {
    UINT c = 4 * y * ((3*m_width + 3) / 4);
    UINT q = z + m_pitch * m_height;
//DPF("x:%4d,y:%4d,i:(%3d:%3d),p:(%3d:%3d),t:(%3d:%3d),%3d,%3d,%3d",x,y,
//        m_pLayers[LAY_INK].pData[z], m_pLayers[LAY_INK].pData[q],
//        m_pLayers[LAY_PAINT].pData[z], m_pLayers[LAY_PAINT].pData[q],
//        m_pLayers[LAY_TINT].pData[z], m_pLayers[LAY_TINT].pData[q],
//        p[c+3*x+0],p[c+3*x+1],p[c+3*x+2]);
    }
#endif
/*
    for (layer = 1; layer < m_nLayers; layer++)
        {
        if (m_pLayers[layer].pData[z])
            break;
        }
    return layer >= m_nLayers ? 0 : 1;
*/
    for (layer = m_nLayers; layer-- > 1;)
        {
        if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
            continue;
        UINT xx = x;
        UINT yy = y;
        UINT qq = TQ(layer);
        if ((layer != m_nPaint) && (layer != m_nInk))
            {
//            UINT qq = TQ(layer);
            if (!(m_pTable->table[qq].flags & 0x200)) // active
                continue;
            xx -= m_pTable->table[qq].dx;
            yy -= m_pTable->table[qq].dy;
            }
        if (xx >= m_width || yy >= m_height)
            continue;
        UINT z = yy * m_pitch + xx;
        if (m_pLayers[layer].pData[z])
            {
//            index = m_pLayers[layer].pData[m_pitch * m_height + z];
            break;
            }
        }
    if (layer)
        {
        int index = m_pLayers[layer].pData[m_pitch * m_height + z];
        BYTE * pPalette = &m_pTable->pals[0];
        r = pPalette[4*index+0];
        g = pPalette[4*index+1];
        b = pPalette[4*index+2];
        }
//    else
//        {
//        y = m_height - 1 - y;
//        r = m_pBG[m_pitch*y+3*x+2];
//        g = m_pBG[m_pitch*y+3*x+1];
//        b = m_pBG[m_pitch*y+3*x+0];
//        }
    return layer ? 1 : 0;
}

void Blur(BYTE * pDst, BYTE * pSrc, UINT w, UINT h, UINT r, UINT f, UINT pitch);

void CLayers::ApplyLayer(BYTE *pDst, BYTE * pSrc, BYTE * pPaint, BYTE * pInk,
                BYTE * pPals, UINT kind, UINT qq)
{
    BYTE * pAlpha = pSrc;
    UINT dx = 0;
    UINT dy = 0;
    if (kind >= CCell::LAYER_MATTE0)
        {
        pAlpha +=  2 * m_pitch * m_height;
        int r = m_pTable->table[qq].blur;
        int c = m_pTable->table[qq].color;
        int ff = r / 256;
        r &= 255;
        memmove(pAlpha,pSrc,2 * m_pitch*m_height);
        if (r)
            Blur(pAlpha,pSrc, m_width, m_height, r, ff, m_pitch);
        dx = m_pTable->table[qq].dx;
        dy = m_pTable->table[qq].dy;
        }
    BYTE * pIndex = pAlpha + m_pitch * m_height;
#ifdef PATTERNS
    UINT zq = rand();
    zq = 0;
#endif
    UINT y,x;
    UINT op = 4 * m_width;
    for (y = 0; y < m_height; y++)
        {
        UINT sy = y + dy;
        if ((UINT)sy >= m_height)
            continue;
        for (x = 0; x < m_width ; x++)
            {
            UINT sx = x - dx;
            if (sx >= m_width)
                continue;
            UINT z,i;
            z = pAlpha[m_pitch*sy+sx];
            if (z && (m_pTable->table[qq].flags & 1) && !pPaint[y*m_pitch+x])
                z = pInk[m_pitch*y+x];
            if (!z)
                continue;
            UINT q = pDst[op*y+4*x+3];
            i = pIndex[m_pitch*sy+sx];
            BYTE * pColor;
#ifdef PATTERNS
            Pattern * pPat = Patterns(i);
            if (pPat)
                {
                UINT ssx,ssy,w,h;
#ifdef TILING
                w = pPat->m_w;
                h = pPat->m_h;
                ssx = (sx+zq) % (2 * w);
                ssy = (sy+zq) % (2 * h);
                if (ssx >= w)
                    ssx = w + w - 1 - ssx;
                if (ssy >= h)
                    ssy = h + h - 1 - ssy;
#else
                ssx = (sx+zq) % pPat->m_w;
                ssy = (sy+zq) % pPat->m_h;
#endif
                pColor = pPat->m_pData+pPat->m_pitch*ssy+3 * ssx;
                }
//            else
            UINT cc;
            if (cc = AdvIndex(i))
                pColor = GetGrad(cc -1,sx,sy);
            else
#endif
                
                pColor = pPals + 4 * i;
                
            z =    z * pColor[3] / 255;
            UINT j;
            if ((z == 255) || !q)
                {
                pDst[op*y+4*x+3] = z;
                for (j = 0; j < 3; j++)
                    pDst[op*y+4*x+j] = pColor[2-j];
                }
            else if (z)
                {
                WORD v = (255 - z) * q;
                v += z * 255;//pPals[4*i+3];
                pDst[op*y+4*x+3] = v / 255;
                for (j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * pDst[op*y+4*x+j];
                    v += z * pColor[2-j];
                    pDst[op*y+4*x+j] = v / 255;
                    }
                }
            }
        }

}
void CLayers::ApplyCell(BYTE * pDst, DWORD dwKey, CScene * pScene,
                    CLevel * pLevel, CMyIO * pIO)
{
    ASSERT(dwKey != 0);
    CCell * pCell = new CCell(pIO);
    if (pCell == NULL)
        {
DPF("new failure");
        return;
        }
    pCell->SetKey(dwKey);
    if (pCell->Read())
        {
DPF("read failure");
        delete pCell;
        return;
        }
    m_width = pScene->Width();
    m_height = pScene->Height();
    m_pitch = 4 * ((m_width + 3) / 4);
    if (!pScene->ColorMode())
        {
        BYTE * pAlpha = new BYTE[2 * m_pitch * m_height];
        DWORD key = (pCell)->Select(CCell::LAYER_INK);
        if (key > 1)
            {
            pScene->ReadImage(pAlpha, key);
            memmove(pDst, pAlpha, m_pitch * m_height);
            }
        if (!key)
            {
            if (key = (pCell)->Select(CCell::LAYER_GRAY))
                {
                pScene->ReadImage(pAlpha, key);
                for (UINT i = 0; i < m_width * m_height; i++)
                    pDst[i] = pAlpha[i] ^ 255;
                }
            }
        delete pCell;
        delete [] pAlpha;
        return;
        }
    BOOL bActive = 0;
    m_pTable = new CLevelTable;
    pLevel->Table(m_pTable,pScene);
    if ((m_pTable->table[0].name[0] == 0 ) &&
                (m_pTable->table[0].name[1] == (char)255))
        bActive = TRUE;
    BYTE * pPals = &m_pTable->pals[0];
    BYTE * hpTmp = new BYTE[8 * m_pitch * m_height];
    UINT i;
    BYTE * pPaint = hpTmp + 4 * m_pitch * m_height;
    BYTE * pInk = hpTmp + 6 * m_pitch * m_height;
    DWORD key = pCell->Select(CCell::LAYER_PAINT);
    if (key > 1)
        pScene->ReadImage(pPaint, key);
    else
        memset(pPaint,0, m_pitch * m_height);
    key = pCell->Select(CCell::LAYER_INK);
    if (key > 1)
        pScene->ReadImage(pInk, key);
    else
        memset(pInk,0, m_pitch * m_height);
    UINT f = 1;
    for (i = 0; i < 12; i++)
        {
        UINT kind, qq;
        qq = TQ(i+1);
        if (!bActive && !(m_pTable->table[qq].flags & 0x100)) // active
            continue;
        if (i < 5)
            kind = CCell::LAYER_MATTE0 + i;
        else if (i == 5)
            kind = CCell::LAYER_PAINT;
        else if (i == 6)
            kind = CCell::LAYER_INK;
        else
            kind = CCell::LAYER_MATTE5 + i - 7;
        if (kind == CCell::LAYER_PAINT)
            memmove(hpTmp, pPaint, 2 * m_pitch * m_height);
        else if (kind == CCell::LAYER_INK)
            memmove(hpTmp, pInk, 2 * m_pitch * m_height);
        else
            {
            DWORD key = pCell->Select(kind);
            if (key > 1)
                pScene->ReadImage(hpTmp, key);
            else if (!key && (i == 6))
                {
                key = pCell->Select(CCell::LAYER_GRAY);
                if (!key) continue;
                pScene->ReadImage(hpTmp, key);
                UINT s = m_pitch * m_height;
                UINT z;
                for (z = 0; z < s; hpTmp[z++] ^= 255);
                memset(hpTmp+s,0,s);
                }
            else
                continue;
            }
        ApplyLayer(pDst, hpTmp, pPaint,pInk,pPals, kind, qq);
        f = 0;
        }
    delete pCell;
    delete [] hpTmp;
DPZ("clayers,apply cell:%d",f);
    return; //f;
}

BOOL CLayers::NeedFake(UINT Frame)
{
    BOOL bResult = 0;
    if (m_frame == Frame)
        bResult = m_bNeedFake;
//    m_bNeedFake = 0;
    return bResult;
}
BOOL CLayers::UseFake(UINT cellkey)
{
    BOOL bResult = 0;
    if (m_cellkey == cellkey)
        {
        bResult = m_bNeedFake;
        m_bNeedFake = 0;
        }
    return bResult;
}

BOOL CLayers::FakeIt(BYTE * pDst)
{
    UINT ox,oy,op;
    if (m_pScene->ColorMode())
        {
        op = 4 * m_width;
        memset(pDst, 255, m_height * op);
        for (oy = 0; oy < m_height; oy++)
        for (ox = 0; ox < m_width ; ox++)
            pDst[op*oy+4*ox+3] = 0;
        }
    else
        {
        op = m_pitch;
        memset(pDst, 0, m_height * m_pitch);
        }
    if (m_pOverlay)
        {
return 0;
        for (int yy = m_miny; yy <= m_maxy;yy++)
            {
            int y = m_height - 1 - yy;
            for (int x = m_minx; x <= m_maxx; x++)
                {
                WORD z;
                z = m_pOverlay[4*(y*m_width+x)+3];
                if (!z)
                    continue;
                for (int j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * pDst[op*y+4*x+j];
                    v += z * m_pOverlay[4*(y*m_width+x)+j];
                    pDst[op*y+4*x+j] = v / 255;
                    }
                }
            }
        return 0;
        }
    if (m_pScene->ColorMode())
        {
        BYTE * pPals = &m_pTable->pals[0];
        BYTE * pPaint = m_pLayers[m_nPaint].pData;
        BYTE * pInk = m_pLayers[m_nInk].pData;
        UINT layer;
        for (layer = 1; layer < m_nLayers;layer++)
            {
            UINT kind, qq;
            if (!(m_pLayers[layer].flags & FLAG_ACTIVE))
                continue;
            qq = TQ(layer);
            if (!(m_pTable->table[qq].flags & 0x100)) // active
                continue;
            kind = m_pLayers[layer].kind;
            BYTE * pSrc = m_pLayers[layer].pData;
            ApplyLayer(pDst, pSrc, pPaint,pInk,pPals, kind, qq);
            }
        }
    else
        {
        BYTE * pAlpha = m_pLayers[1].pData;
        for (UINT i = 0; i < m_width * m_height; i++)
                pDst[i] = pAlpha[i];
        }
    return 0;
}

void CLayers::Update(BYTE * pBits, BYTE * pBG, UINT pitch, BOOL bAll /* = 0 */)
{
    if (bAll)
        {
        m_minx = m_miny = 0;
        m_maxx = m_width - 1;
        m_maxy = m_height - 1;
        }
//    if (m_bDirty && (m_pLayers[m_nCurLayer].kind >= CCell::LAYER_MATTE0))
//        {
//        BlurIt();
//        }
    if (m_nLayers < 3)
        {
        UpdateGray(pBits, pBG, pitch);
        }
    else
        {
        int x, y,yy;
        if (pBG)
        {
        for (yy = m_miny; yy <= m_maxy;yy++)
            {
            y = m_height - 1 - yy;
            for (x = m_minx; x <= m_maxx; x++)
                {
                pBits[pitch*y+3*x+0] = pBG[pitch*y+3*x+0];
                pBits[pitch*y+3*x+1] = pBG[pitch*y+3*x+1];
                pBits[pitch*y+3*x+2] = pBG[pitch*y+3*x+2];
                }
            }
        }
        if (!(m_nFlags & 1))
            UpdateInk(pBits,pitch);
        else
        UpdateColor(pBits,pitch);
        }
//    m_maxx = m_maxy = 0;
//    m_minx = m_width - 1;
//    m_miny = m_height - 1;
    m_bDirty = FALSE;
}

void CLayers::UpdateColor(BYTE * pBits, UINT pitch)
{
    UINT tbl[12];
    UINT flags[12];
    UINT cnt;
    UINT i;
#ifdef PATTERNS
    UINT qq = rand();
#endif
    for (i = 1, cnt = 0;i < m_nLayers;i++)
        {
        UINT j = TQ(i);
        if ((m_pLayers[i].flags & FLAG_ACTIVE) &&
                (m_pTable->table[j].flags & 0x200)) // displayable
            {
            flags[cnt] = m_pTable->table[j].flags;
            tbl[cnt++] = i;
            }
        }
for (i = 0; i < cnt; i++)
    {
    DPF("i:%d,tbl:%d,%x",i,tbl[i],flags[i]);
    }
    if (m_pOverlay)
        {
        for (int yy = m_miny; yy <= m_maxy;yy++)
            {
            int y = m_height - 1 - yy;
            for (int x = m_minx; x <= m_maxx; x++)
                {
                WORD z;
                z = m_pOverlay[4*(y*m_width+x)+3];
                if (!z)
                    continue;
                for (int j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * pBits[pitch*y+3*x+j];
                    v += z * m_pOverlay[4*(y*m_width+x)+j];
                    pBits[pitch*y+3*x+j] = v / 255;
                    }
                }
            }
        return;
        }
//    BYTE * pPalette = m_pScene->PalAddr(m_level);//&m_pTable->pals[0];
    BYTE * pPalette = &m_pTable->pals[0];
    BYTE * pPaint = m_pLayers[m_nPaint].pData;
    BYTE * pInk = m_pLayers[m_nInk].pData;
    for (i = 0; i < cnt; i++)
        {
        UINT dx = 0;
        UINT dy = 0;
        UINT l = tbl[i];
DPF("i:%d,l:%d,k:%d",i,l,m_pLayers[l].kind);
        BYTE * pAlpha = m_pLayers[l].pData;
        if (m_pLayers[l].kind >= CCell::LAYER_MATTE0)
            {
            BlurIt(l);
            pAlpha += 2 * m_pitch * m_height;
            dx = m_pTable->table[TQ(l)].dx;
            dy = m_pTable->table[TQ(l)].dy;
            }
        BYTE * pIndex = pAlpha + m_pitch * m_height;
        UINT csize = 2 * m_height * m_pitch;
        for (int yy = m_miny; yy <= m_maxy;yy++)
            {
            int y = m_height - 1 - yy;
            UINT sy = y + dy;
            if ((UINT)sy >= m_height)
                continue;
            for (int x = m_minx; x <= m_maxx; x++)
                {
                UINT sx = x - dx;
                if (sx >= m_width)
                    continue;
                WORD z,p;
                z = pAlpha[sy*m_pitch+sx];
                if (z && (flags[i] & 1) && !pPaint[y*m_pitch+x])
                        z = pInk[y*m_pitch+x];
                if (!z)
                    {
                    if (((cnt>1)&&(m_pLayers[l].kind != CCell::LAYER_INK))
                                || !m_pControl || (m_nFlags & 2))
                        continue;
                    z = m_pControl[csize +sy*m_pitch+sx];
                    if (!z)
                        continue;
//                    p = m_pControl[csize + m_pitch * (m_height+sy)+sx];
//                p = pIndex[sy*m_pitch+sx];
//                z = (z * pPalette[4*p+3]) / 255;
                    int j;
                    BYTE q[3];
                    q[0] = 190;
                    q[1] = 190;
                    q[2] = 255;
                    for (j = 0; j < 3; j++)
                        {
                        WORD v = (255 - z) * pBits[pitch*y+3*x+j];
                        v += z * q[j];
                        pBits[pitch*y+3*x+j] = v / 255;
                        }
                    continue;
                    }
                else
                    p = pIndex[sy*m_pitch+sx];
                BYTE * pColor;
#ifdef PATTERNS
            Pattern * pPat = Patterns(p);
            if (pPat)
                {
                UINT ssx,ssy,w,h;
#ifdef TILING
                w = pPat->m_w;
                h = pPat->m_h;
                ssx = (sx+qq) % (2 * w);
                ssy = (sy+qq) % (2 * h);
                if (ssx >= w)
                    ssx = w + w - 1 - ssx;
                if (ssy >= h)
                    ssy = h + h - 1 - ssy;
#else
                ssx = (sx+qq) % pPat->m_w;
                ssy = (sy+qq) % pPat->m_h;
#endif
                pColor = pPat->m_pData+pPat->m_pitch*ssy+3 * ssx;
                }
            else
#endif
                {
#ifdef PATTERNS
                UINT cc;
                if (cc = AdvIndex(p))
                    pColor = GetGrad(cc-1,sx,sy);
                else
#endif
                    pColor = pPalette+ 4 * p;
                z = (z * pColor[3]) / 255;
                }
                int j;
                for (j = 0; j < 3; j++)
                    {
                    WORD v = (255 - z) * pBits[pitch*y+3*x+j];
                    v += z * pColor[2-j];
                    pBits[pitch*y+3*x+j] = v / 255;
                    }
                }
            }
        }
}

void CLayers::UpdateInk(BYTE * pBits, UINT pitch)
{
    BYTE * pPalette = &m_pTable->pals[0];
    BYTE * pInk = m_pLayers[m_nInk].pData;
    BYTE * pIndex = pInk + m_pitch * m_height;
    UINT csize = 2 * m_height * m_pitch;
    for (int yy = m_miny; yy <= m_maxy;yy++)
        {
        int y = m_height - 1 - yy;
        UINT sy = y;
        if ((UINT)sy >= m_height)
            continue;
        for (int x = m_minx; x <= m_maxx; x++)
            {
            UINT sx = x;
            if (sx >= m_width)
                continue;
            WORD z,p;
            z = pInk[sy*m_pitch+sx];
            if (!z)
                continue;
            p = pIndex[sy*m_pitch+sx];
            BYTE * pColor;
            pColor = pPalette+ 4 * p;
            z = (z * pColor[3]) / 255;
            int j;
            for (j = 0; j < 3; j++)
                {
                WORD v = (255 - z) * pBits[pitch*y+3*x+j];
                v += z * pColor[2-j];
                pBits[pitch*y+3*x+j] = v / 255;
                }
            }
        }
}


//#define ZQ
void CLayers::UpdateGray(BYTE * pBits, BYTE * pSkin, UINT pitch)
{
    int x,y,yy;
    BYTE * pSrc;
    if (m_pOverlay)
        pSrc = m_pOverlay;
    else
        pSrc = m_pLayers[1].pData;
    for (yy = m_miny; yy <= m_maxy;yy++)
        {
        y = m_height - 1 - yy;
        for (x = m_minx; x <= m_maxx; x++)
            {
            UINT v1 = pSkin[m_pitch*y+x];
            UINT v2 = pSrc[m_pitch*y+x];
            if (v2 == 255)
                v1 = 0;
            else if (v2)
                v1 = (v1*(255-v2)) / 255;
            pBits[pitch*y+x] = v1;
            }
        }
}


int CLayers::CDespeckle(int count)
{
    DPF("despeckle,%d",count);
    UINT size = 2 * m_height * m_pitch;
    BYTE * pInk = m_pLayers[m_nInk].pData;
    BYTE * pUndo= PushUndo(m_nInk,1);
    int dx[300];
    int dy[300];
    m_minx = m_width;
    m_maxx = 0;
    m_miny = m_height;
    m_maxy = 0;
    int x, y,c;
    int r,i,j;
    int xx,yy;
    c = 0;
    r = count;
    for (i = -r; i <= r; i++)
        {
        dx[c] = i;
        dy[c++] = -r;
        dx[c] = i;
        dy[c++] = r;
        }
    for (i = 1-r; i < r; i++)
        {
        dx[c] = r;
        dy[c++] = i;
        dx[c] = -r;
        dy[c++] = i;
        }
    for (x = 0; x < c; x++)
        {
DPF("%d, %d,%d",x,dx[x],dy[x]);
        }
    memmove(pUndo,pInk,size);
    for (y = 0; y < (int)m_height; y++)
    for (x = 0; x < (int)m_width; x++)
        {
        if (!pUndo[y * m_pitch + x])
            continue;
        for (i = 0; i < (int)c; i++)
            {
            xx = x + dx[i];
            yy = y + dy[i];
            if (((UINT)xx < m_width) &&
                    ((UINT)yy < m_height) &&
                    pUndo[yy * m_pitch + xx])
                break;
            }
        if (i < (int)c)
            continue;
        for (i = 1-r; i< r;i++)
        for (j = 1-r; j< r;j++)
            {
            xx = x + i;
            yy = y + j;
            if (((UINT)(xx) < m_width) &&
                    ((UINT)(yy) < m_height))
                {
                pInk[yy * m_pitch + xx] = 0;
                if (xx < m_minx) m_minx = xx;
                if (xx > m_maxx) m_maxx = xx;
                yy = m_height - 1 - yy;
                if (yy < m_miny) m_miny = yy;
                if (yy > m_maxy) m_maxy = yy;
                }
            }
        }
    if ((UINT)m_minx < m_width)
        {
        m_bNeedFake = m_bModified = TRUE;
        m_bDirty = TRUE;
        m_pLayers[m_nInk].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        }
    return m_bDirty;
}

void CLayers::DrawInit(UINT color, UINT type, BOOL bErasing)
{
    FillStack(-2);
    m_color = color;
    m_bErasing = bErasing;
    m_dot_type = type;    // 0 is pencil, 1 is trace, 2 is brush
    m_bFirstDot = TRUE;
    m_bDirty = FALSE;
    m_bSolid = FALSE;
    if (m_nLayers < 3)
        m_nCurLayer = 1;
    else if (type == 3)
        {
        m_bSolid = 1;
        m_nCurLayer = m_nInk;
        }
    else if (type == 2)
        {
        m_nCurLayer = m_nPaint;
        m_bSolid = TRUE;
        }
    else if (type == 4)
        {
        type = 2;
        m_nCurLayer = m_nPaint;
        }
    else
        m_nCurLayer = m_nInk;
    if (m_pTable->layer)
        {
        if (m_pTable->layer > 5)
            m_nCurLayer = 2 + m_pTable->layer;
        else
            m_nCurLayer = m_pTable->layer;
        UINT j = TQ(m_nCurLayer);
        m_pTable->table[j].color = m_color;
if (type)
        m_bSolid = TRUE;
        }
    UINT size = m_height * 2 * m_pitch;
    PushUndo(m_nCurLayer);
    m_pLayers[m_nCurLayer].flags = FLAG_ACTIVE | FLAG_MODIFIED;    // set modified
    m_bNeedFake = m_bModified = TRUE;
}

void CLayers::DrawDot(int x, int y, BYTE alpha)
{
//DPF("draw dot,x:%d,y:%d",x,y);
    if ((UINT)x >= m_width)
        return;
    if ((UINT)y >= m_height)
        return;
//    alpha /= 4;
//    m_bDirty = TRUE;
    if (m_bFirstDot)
        {
        m_minx = x;
        m_maxx = x;
        m_miny = y;
        m_maxy = y;
        m_bFirstDot = FALSE;
        }
    else
        {
        if (x > m_maxx)
            m_maxx = x;
        else if (x < m_minx)
            m_minx = x;
        if (y > m_maxy)
            m_maxy = y;
        else if (y < m_miny)
            m_miny = y;
        }
    if (m_pLayers[m_nCurLayer].kind >= CCell::LAYER_MATTE0)
        {
        x -= m_pTable->table[TQ(m_nCurLayer)].dx;
        y -= m_pTable->table[TQ(m_nCurLayer)].dy;
        if ((UINT)x >= m_width)
            return;
        if ((UINT)y >= m_height)
            return;
        }
    BYTE * pAlpha = m_pLayers[m_nCurLayer].pData;
    BYTE * pIndex = pAlpha + m_pitch * m_height;
    UINT yyy = m_height - 1 - y;
    if (m_dot_type == 1) // trace
        {
        if (m_pLayers[m_nCurLayer].kind >= CCell::LAYER_MATTE0)
            {
            BYTE * pPAlpha = m_pLayers[m_nPaint].pData;
//            BYTE * pPIndex = pAlpha + m_pitch * m_height;
            if (pPAlpha[m_pitch*yyy+x])
                {
                if (m_bErasing)
                    pAlpha[m_pitch*yyy+x] = 0;
                else
                    {
                    pAlpha[m_pitch*yyy+x] = 255;//pPAlpha[m_pitch*yyy+x];
                    pIndex[m_pitch*yyy+x] = m_color;//pPIndex[m_pitch*yyy+x];
                    }
                m_bDirty = TRUE;
                }
            }
        else if (pAlpha[m_pitch*yyy+x])
            {
            if (m_bErasing)
                pIndex[m_pitch*yyy+x] = 0;
            else
                pIndex[m_pitch*yyy+x] = m_color;
            m_bDirty = TRUE;
            }
        }
    else if (m_dot_type == 3) // untrace
        {
        if (!pAlpha[m_pitch*yyy+x])
            {
//            if (m_bErasing)
//                pIndex[m_pitch*yyy+x] = 0;
//            else
                pIndex[m_pitch*yyy+x] = m_color;
            pAlpha[m_pitch*yyy+x] = alpha;
            m_bDirty = TRUE;
            }
        }
    else
        {
        UINT v;
        if (m_bErasing)
            v = 0;
        else if (m_bSolid)
            v = 255;
        else
            {
            v = pAlpha[m_pitch*yyy+x];
            v = v + alpha - (v * alpha) / 255;
            }
        pAlpha[m_pitch*yyy+x] = v;
        pIndex[m_pitch*yyy+x] = m_color;
        m_bDirty = TRUE;
        }
}


UINT CLayers::Flood(UINT index, int kind)
{
    UINT layer;
    if (!kind)
        {
        if (!(layer = m_pTable->layer))
            {
            if (!m_pScene->ColorMode())
                layer = 1;
            else
                layer = m_nPaint;
            }
        else if (layer > 5)
            layer += 2;
        m_bDirty = TRUE;    // needs display update
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        BYTE * pAlpha = m_pLayers[layer].pData;
        UINT size = m_height * m_pitch;
        if (m_pLayers[layer].kind >= CCell::LAYER_MATTE0)
            {
            memcpy(pAlpha+m_height*m_pitch, pAlpha, size);     //save tone matte
            }
        memset(pAlpha, 255, size);
        BYTE * pIndex = pAlpha + size;
        memset(pIndex, index, size);
        }
    else if ((kind & 3) == 1)
        {
        BYTE * pPaint = m_pLayers[m_nPaint].pData;
        layer = m_pTable->layer;
        if (layer > 5)
            layer += 2;
//        UINT j = TQ(m_nCurLayer);
//        m_pTable->table[j].color = m_color;
        m_bDirty = TRUE;    // needs display update
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        BYTE * pAlpha = m_pLayers[layer].pData;
        BYTE * pIndex = pAlpha + m_pitch * m_height;
        ASSERT(m_pLayers[layer].kind >= CCell::LAYER_MATTE0);
        UINT i;
        if (kind & 4)
            for (i = 0; i < m_pitch * m_height; i++)
                {
                if (!pPaint[i])
                    {
                    pAlpha[i] = 255;
                    pIndex[i] = index;
                    }
                }
        else
            for (i = 0; i < m_pitch * m_height; i++)
                {
                if (pPaint[i])
                    {
                    pAlpha[i] = 255;
                    pIndex[i] = index;
                    }
                }
        }
    else if (kind == 2)
        {
        layer = m_pTable->layer;
        if (layer > 5)
            layer += 2;
//        UINT j = TQ(m_nCurLayer);
//        m_pTable->table[j].color = m_color;
        m_bDirty = TRUE;    // needs display update
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        BYTE * pAlpha = m_pLayers[layer].pData;
        BYTE * pIndex = pAlpha + m_pitch * m_height;
        ASSERT(m_pLayers[layer].kind >= CCell::LAYER_MATTE0);
        BYTE desired;
        UINT i;
        if (!index)
            {
            desired = 1;
            for (i = 0; i < m_pitch * m_height; i++)
                if (!pIndex[i])
                    pIndex[i] = desired;
            }
        else
            desired = 0;
        for (i = 0; i < m_pitch * m_height; i++)
            {
            if (!pAlpha[i] || (pIndex[i] != desired))
                {
                pAlpha[i] = 255;
                pIndex[i] = index;
                }
            }
        }
    else
        {
        layer = m_pTable->layer;
        if (layer > 5)
            layer += 2;
//        UINT j = TQ(m_nCurLayer);
//        m_pTable->table[j].color = m_color;
        m_bDirty = TRUE;    // needs display update
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        BYTE * pAlpha = m_pLayers[layer].pData;
        BYTE * pIndex = pAlpha + m_pitch * m_height;
        ASSERT(m_pLayers[layer].kind >= CCell::LAYER_MATTE0);
        UINT i;
        BYTE desired;
        if (!index)
            {
            desired = 1;
            }
        else
            desired = 0;
        for (i = 0; i < m_pitch * m_height; i++)
            {
            if (pAlpha[i] && (pIndex[i] == desired))
                {
                pAlpha[i] = 255;
                pIndex[i] = index;
                }
            }
        }
    return 0;
}

void CLayers::Flipper(UINT mask)
{
    UINT layer;
    BYTE * pAlpha;
//    BYTE * pIndex;
    for (layer = 1; layer < m_nLayers;layer++)
        {
        pAlpha = m_pLayers[layer].pData;
        UINT x, hw;
        UINT y, hh;
        hw = m_width / 2;
        hh = m_height / 2;
        for (int q = 0; q < 2; q++)
        {
        for (y = 0; y < hh;y++)
            {
            UINT y1,y2;
            if (mask & 2)
                {
                y2 = y;
                y1 = m_height - 1 - y;
                }
            else
                {
                y1 = y;
                y2 = m_height - 1 - y;
                }
            for (x = 0; x < hw; x++)
                {
                BYTE a,b,c,d;
                if (mask & 1)
                    {
                    b = pAlpha[y1*m_pitch+x];
                    a = pAlpha[y1*m_pitch+m_width-1-x];
                    d = pAlpha[y2*m_pitch+x];
                    c = pAlpha[y2*m_pitch+m_width-1-x];
                    }
                else
                    {
                    a = pAlpha[y1*m_pitch+x];
                    b = pAlpha[y1*m_pitch+m_width-1-x];
                    c = pAlpha[y2*m_pitch+x];
                    d = pAlpha[y2*m_pitch+m_width-1-x];
                    }
                pAlpha[y*m_pitch+x] = a;
                pAlpha[y*m_pitch+m_width-1-x] = b;
                pAlpha[(m_height-1-y)*m_pitch+x] = c;
                pAlpha[(m_height-1-y)*m_pitch+m_width-1-x] = d;

//                v = pIndex[y*m_pitch+x];
//                pIndex[y*m_pitch+x] = pIndex[y*m_pitch + m_width - 1 - x];
//                pIndex[y*m_pitch + m_width - 1 - x] = v;
                }
            }
        pAlpha +=  m_pitch * m_height; // now index
        }
    }
}


UINT CLayers::Clear()
{
    UINT layer;
    UINT size = m_pitch * m_height;
    m_bNeedFake = m_bModified = TRUE;
    for (layer = 1; layer < m_nLayers;layer++)
        {
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        memset( m_pLayers[layer].pData,0,size+size);
        }
    return 0;
}

BOOL CLayers::CanUndo()
{
    return m_nUndo ? 1 : 0;
}

BOOL CLayers::CanRedo()
{
    return m_nRedo ? 1 : 0;
}

BYTE * CLayers::PushUndo(UINT layer, BOOL bSkip)
{
    UINT size = m_height * 2 * m_pitch;
    UINT index = m_nPushCount;
    m_nPushCount = (m_nPushCount + 1) % MAXUNDO;
    BYTE * pp = m_pUndo[index].pData;
    m_pUndo[index].layer = layer;
    if (!bSkip)
        memmove(pp,m_pLayers[layer].pData,size);
    m_nUndo++;
    if (m_nUndo >= MAXUNDO)
        m_nUndo = MAXUNDO;
    m_nRedo = 0;
    return pp;
}

void CLayers::Undo(UINT zindex  /* = NEGONE */)
{
    UINT size = m_height * 2 * m_pitch;
    UINT index;
    if (zindex == NEGONE)
        {
        FillStack(-2);
        m_nPushCount = (m_nPushCount + MAXUNDO - 1) % MAXUNDO;
        m_nUndo--;
        m_nRedo++;
        index = m_nPushCount;
        }
    else
        index = zindex;
    UINT layer = m_pUndo[index].layer;
    BYTE * p1;
    BYTE * p2;
    UINT i;
    BYTE v;
    p1 = m_pUndo[index].pData;
    p2 = m_pLayers[layer].pData;
    if (zindex != NEGONE)
        memmove(p2,p1,size);
    else
        for (i = 0; i < size; i++)
            {
            v = *p1;
            *p1++ = *p2;
            *p2++ = v;
            }
}


void CLayers::Redo()
{
    FillStack(-2);
    UINT index = m_nPushCount;
    m_nPushCount = (m_nPushCount + 1) % MAXUNDO;
    UINT size = m_height * 2 * m_pitch;
    BYTE * pp = m_pUndo[index].pData;
    m_nRedo--;
    m_nUndo++;
    UINT layer = m_pUndo[index].layer;
    UINT i;
    BYTE v;
    BYTE * p1 = m_pUndo[index].pData;
    BYTE * p2 = m_pLayers[layer].pData;
    for (i = 0; i < size; i++)
        {
        v = *p1;
        *p1++ = *p2;
        *p2++ = v;
        }
}

UINT CLayers::SaveModel(LPCSTR name /* = 0 */)
{
    LPCSTR pname;
    if (name)
        pname = name;
    else
        pname = (LPCSTR)&m_name;
DPF("save model:%s|",pname);
    CFile f;
    UINT result = 1;
    MDLHEADER header;
    UINT lays[16];
    DWORD mode = CFile::modeCreate | CFile::modeReadWrite;
    if (!f.Open(pname, mode))
        return result;
    BYTE * tbuf = 0;
    for (;;)
        {
        memset(&header, 0, sizeof(header));
        strcpy(header.Id, "DIGICEL MODEL");
        header.width = m_width;
        header.height= m_height;
        header.version = 1;
        header.nLays = 0;
        UINT layer;
        for (layer = 1; layer < m_nLayers; layer++)
            {
            if (m_pLayers[layer].flags & FLAG_ACTIVE)
                lays[header.nLays++] = layer ^ 4;
            }
        f.Write(&header, sizeof(header));
        f.Write(&lays, header.nLays * sizeof(UINT));
        UINT i,size;
        size = 2 * m_pitch * m_height;    // alpha and index
        DWORD ddsize = 20 + (size * 102) / 100;
        tbuf = new BYTE[ddsize];
        for (i = 0; i < header.nLays; i++)
            {
            DWORD dsize = ddsize;
            UINT q = compress(tbuf,&dsize,m_pLayers[lays[i]^4].pData, size);
            if (q)
                {
                DPF("compression failure:%d",q);
//                delete tbuf;
                result = 2;
                break;
                }
            f.Write(&dsize, sizeof(UINT));
            f.Write(tbuf, dsize);
            }
        if (i >= header.nLays)
            result = 0;
        break;
        }
    delete [] tbuf;
    f.Close();
    return result;
}

UINT CLayers::LoadModel(UINT Level, BOOL bCreate)
{
    CFile f;
    UINT result = 1;
    m_pScene->LevelModelName((LPSTR)&m_name,Level);
    if (!m_name[0])
        return 7;
//    m_pPalette = m_pScene->PalAddr(Level);
    MDLHEADER header;
    UINT lays[16];
    DWORD mode = CFile::modeReadWrite;
    if (!f.Open(m_name, mode))
        return result;
    BYTE * tbuf = 0;
    for (;;)
        {
        f.Read(&header, sizeof(header));
        f.Read(&lays, header.nLays * sizeof(UINT));
        if (_stricmp(header.Id, "DIGICEL MODEL"))
            break;
        UINT i;
        for (i = 0; i < header.nLays; i++)
            {
            lays[i] ^= 4;        // translate from old to new
            }
        result++;
        if (header.version != 1)
            break;
        if (bCreate)
            {
            m_width = header.width;
            m_height = header.height;
            m_pitch = 4 * ((m_width + 3) / 4);
            m_nLayers = 13;
            CreateLayers();
            }
        else
            {
            if ( header.width != m_width ||
                    header.height!= m_height)
                break;
            }
        result++;
        UINT size = 2 * m_pitch * m_height;    // alpha and index
        DWORD ddsize = 20 + (size * 102) / 100;
        tbuf = new BYTE[ddsize];
        for (i = 0; i < header.nLays; i++)
            {
            UINT dsize;
            f.Read(&dsize, sizeof(UINT));
            if (dsize > ddsize)
                break;
            f.Read(tbuf, dsize);
            DWORD vc = size;
            UINT q = uncompress(m_pLayers[lays[i]].pData,&vc,tbuf,dsize);

            DPF("uncom,%d,%d",vc,size);
            if (q)
                {
DPF("decompress error:%d",q);
                break;
                }
            m_pLayers[lays[i]].flags = FLAG_ACTIVE;
//            if (!m_firstlayer)
//                m_firstlayer = lays[i];
//            else
//                m_pLayers[j].link = lays[i];
//            j = lays[i];
            }
        if (i >= header.nLays)
            result = 0;
        break;
        }
    delete [] tbuf;
    f.Close();
    return result;
}

UINT TestModel(LPCSTR Name, UINT width, UINT height)
{
    CFile f;
    UINT result = 1;
    MDLHEADER header;
    DWORD mode = CFile::modeReadWrite;
    if (!f.Open(Name, mode))
        return result;
    BYTE * tbuf = 0;
    for (;;)
        {
        f.Read(&header, sizeof(header));
        if (_stricmp(header.Id, "DIGICEL MODEL"))
            break;
        result++;

        if (
/*
            header.width != width ||
            header.height!= height ||
*/
            header.version != 1)
            break;
        result = 0;
        break;
        }
    f.Close();
    return result;
}

int CLayers::UnCranny(int count)
{
    DPF("uncranny,%d",count);
    UINT layer = m_nPaint;
    if (!m_pScene->ColorMode())
        return 0;
    BYTE * pInk = m_pLayers[m_nInk].pData;
    BYTE * pPaint = m_pLayers[m_nPaint].pData;
    BYTE * pUndo= PushUndo(layer,1);
    m_minx = m_width;
    m_maxx = 0;
    m_miny = m_height;
    m_maxy = 0;
    UINT size = m_pitch * m_height;
    memset(pUndo,0,size + size);
    int x, y;
    for (y = 0; y < (int)m_height; y++)
    for (x = 0; x < (int)m_width; x++)
        {
        UINT offset = m_pitch * y + x;
//        if (!pInk[offset])
//            continue;
        if (!pPaint[offset])
            {
            int z,c;
            UINT q,a;
            c = 0;
            for (z = 0; z < 8; z++)
                {
                int xx = x + dx[z];
                int yy = y + dy[z];
                if (((UINT)xx >= m_width) || ((UINT)yy >= m_height))
                    continue;
                if (!pPaint[m_pitch * yy + xx])
                    continue;
                q = pPaint[size + m_pitch * yy + xx];
                a = pPaint[m_pitch * yy + xx];
                c++;
                }
            if ((c + count)> 6)
                {
                pUndo[offset] = a;
                pUndo[offset+size] = q;
                if (x < m_minx) m_minx = x;
                if (x > m_maxx) m_maxx = x;
                int yy = m_height - 1 - y;
                if (yy < m_miny) m_miny = yy;
                if (yy > m_maxy) m_maxy = yy;
                }
            }
/*
        else
            {
            UINT v = pPaint[offset + size];
            int z;
            UINT q,a;
            for (z = 0; z < 8; z++)
                {
                UINT xx = x + dx[z];
                UINT yy = y + dy[z];
                if ((xx >= m_width) || (yy >= m_height))
                    continue;
                if (!pPaint[m_pitch * yy + xx])
                    continue;
                q = pPaint[size + m_pitch * yy + xx];
                if (q == v)
                    break;
                a = pPaint[m_pitch * yy + xx];
                }
            if (z >= 9)//8)
                {
                pUndo [offset] = pPaint[offset];
                pUndo [offset+size] = pPaint[offset+size];
                pPaint[offset] = a;
                pPaint[offset+size] = q;
                if (x < m_minx) m_minx = x;
                if (x > m_maxx) m_maxx = x;
                int yy = m_height - 1 - y;
                if (yy < m_miny) m_miny = yy;
                if (yy > m_maxy) m_maxy = yy;
                }
            }
*/
    }
    for (x = 0; (UINT)x < size; x++)
        {
        UINT a, v;
        if (pUndo [x])
            {
            a = pUndo[x];
            v = pUndo[x+size];
            pUndo[x] = pPaint[x];
            pUndo[x+size] = pPaint[x+size];
            pPaint[x] = a;
            pPaint[x+size] = v;
            }
        else
            {
            pUndo[x] = pPaint[x];
            pUndo[x+size] = pPaint[x+size];
            }
        }
    if ((UINT)m_minx < m_width)
        {
        m_bNeedFake = m_bModified = TRUE;
        m_bDirty = TRUE;
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        }
//    EchoIt();
    return m_bDirty;
    return 0;
}

int CLayers::Speckle(int count)
{
    DPF("speckle,%d",count);
    if (count > 1)
        return Magical();
    UINT layer = m_nPaint;
    if (!m_pScene->ColorMode())
        return 0;
    BYTE * pPaint = m_pLayers[m_nPaint].pData;
    BYTE * pUndo= PushUndo(layer,1);
    m_minx = m_width;
    m_maxx = 0;
    m_miny = m_height;
    m_maxy = 0;
    UINT size = m_pitch * m_height;
    memset(pUndo,0,size + size);
    int x, y;
    int ww, hh;
    ww = m_width - 1;
    hh = m_height - 1;
    int t[4];
    t[0] = -1;
    t[1] = 1;
    t[2] = m_pitch;
    t[3] = -(int)m_pitch;
    UINT offset = 1 + m_pitch;
    for (y = 1; y < hh; y++, offset += m_pitch - m_width - 1)
        {
        for (x = 1; x < ww; x++, offset++)
            {
            if (pPaint[offset])
                continue;
            int c, d;
            UINT cc, cv;
            for (c = 0, d = 0; d < 4; d++)
                {
                if (pPaint[offset+t[d]])
                    {
                    cc = pPaint[offset+t[d]];
                    cv = pPaint[size + offset+t[d]];
                    c++;
                    }
                }
            if (c > 2)
                {
                if (x < m_minx) m_minx = x;
                if (x > m_maxx) m_maxx = x;
                int yy = m_height - 1 - y;
                if (yy < m_miny) m_miny = yy;
                if (yy > m_maxy) m_maxy = yy;
                pUndo[offset] = cc;
                pUndo[offset+size] = cv;
                }
            }
        }
    for (x = 0; (UINT)x < size; x++)
        {
        UINT a,v;
        if (pUndo [x])
            {
            a = pUndo[x];
            v = pUndo[x+size];
            pUndo[x] = 0;
            pUndo[x+size] = 0;
            pPaint[x] = a;
            pPaint[x+size] = v;
            }
        else
            {
            pUndo[x] = pPaint[x];
            pUndo[x+size] = pPaint[x+size];
            }
        }
    if ((UINT)m_minx < m_width)
        {
        m_bNeedFake = m_bModified = TRUE;
        m_bDirty = TRUE;
        m_pLayers[layer].flags = FLAG_ACTIVE | FLAG_MODIFIED;
        }
//    EchoIt();
    return m_bDirty;
    return 0;
}

UINT CLayers::Layer(int which /* = -1 */)
{
    if (which != -1)
        {
        m_pTable->layer = which;
        }
    else if (!m_pTable)
        return 0;
    return m_pTable->layer;
}

void CLayers::LoadControl(UINT Frame, UINT Level, BOOL bClear /* = FALSE */)
{
    UINT size = 2 * m_pitch * m_height;
    if (!m_pControl)
        m_pControl = new BYTE[ size + size + size];
    if (bClear)
        {
DPF("clearing control");
        memset(m_pControl+size, 0, size);
        return;
        }
DPF("loading control,lvl:%d",Level);
//    DWORD key  = m_pScene->GetCellKey(Frame,Level,TRUE);
    DWORD key  = m_pScene->GetCellKey(Frame,Level);
    if (!key)
        return;
    if (m_pScene->GetLayer(m_pControl+size+size,Frame, Level,
                CCell::LAYER_INK, key))
        return;
    UINT i,c;
    c = m_pitch * m_height;
    for (i = 0; i < c; i++)
        {
        if (m_pControl[i+size+size])
            {
            m_pControl[i+size] = m_pControl[i+size+size];
            m_pControl[i+size+c] = m_pControl[i+size+size+c];
            }
        }

}

int CLayers::Magical()
{
    DPF("magical");
    UINT layer = m_nPaint;
    if (!m_pScene->ColorMode())
        return 0;
    BYTE * pPaint = m_pLayers[m_nPaint].pData;
    BYTE * pUndo= PushUndo(layer,1);
    m_pLayers[0].kind = layer;
    m_pLayers[0].flags = FLAG_ACTIVE | FLAG_MODIFIED;
    m_minx = m_width;
    m_maxx = 0;
    m_miny = m_height;
    m_maxy = 0;
    UINT size = m_pitch * m_height;
    memset(pUndo,0,size + size);
    int x, y;
    int ww, hh;
    ww = m_width - 1;
    hh = m_height - 1;
//        UINT offset = m_pitch * y + x;
    if (!pPaint[0])
        FillOffset(0,0,256+MAGIC_COLOR,0,0);
    if (!pPaint[ww])
        FillOffset(ww,0,256+MAGIC_COLOR,0,0);
    if (!pPaint[hh*m_pitch])
        FillOffset(0,hh,256+MAGIC_COLOR,0,0);
    if (!pPaint[hh*m_pitch+ww])
        FillOffset(ww,hh,256+MAGIC_COLOR,0,0);
    UINT t[8];
    t[0] = -1;
    t[1] = 1;
    t[2] = m_pitch;
    t[3] = -(int)m_pitch;
    t[4] = -(int)m_pitch-1;
    t[5] = 1-m_pitch;
    t[6] = m_pitch-1;
    t[7] = 1+m_pitch;
    for (y = 1; y < hh; y++)
        {
        for (x = 1; x < ww; x++)
            {
            UINT offset = x + y * m_pitch;
            if (pPaint[offset])
                continue;
            int i;
            for (i = 0; i < 8; i++)
                {
                if (pPaint[offset+t[i]] && (pPaint[offset+size+t[i]] != MAGIC_COLOR))
                    break;
                }
            if (i < 8)
                {
                pPaint[offset] = pPaint[offset+t[i]];
                pPaint[offset+size] = pPaint[size + offset+t[i]];
                y-=2;
                break;
                }
            }
        }

    for (y = 0; y < (int)m_height; y++)
        {
        for (x = 0; x < (int)m_width; x++)
            {
            UINT offset = x + y * m_pitch;
            if (pPaint[offset] && (pPaint[offset+size] == MAGIC_COLOR))
                {
                pPaint[offset] = 0;
                pPaint[offset+size] = 0;
                }
            }
        }


    return m_bDirty;
}

#define PAINTA(o) pPaint[offset+o]
#define PAINTI(o) pPaint[size + offset+o]
#define PAINT(d) (PAINTA(m_pitch*dy[d]+dx[d]) && \
                    (PAINTI(m_pitch*dy[d]+dx[d]) == color))
#define INKA(o) pPaint[offset+o]
#define INKI(o) pPaint[size + offset+o]
#define INK(d) INKA(m_pitch*dy[d]+dx[d])

int CLayers::DeGapper(int count,UINT color)
{
//    int t[5][10];
//    int c;
    DPF("de gapper:%d",count);
    if (!m_pScene->ColorMode())
        return 0;
    CPixels cp;
    UINT layer = m_nInk;
    cp.m_pPaint = m_pLayers[m_nPaint].pData;
    cp.m_pInk   = m_pLayers[m_nInk].pData;
    cp.m_color = m_color;
    cp.m_width = m_width;
    cp.m_height = m_height;
    cp.m_pitch = m_pitch;
    cp.m_size = m_pitch * m_height;
//    BYTE * pUndo= PushUndo(layer,1);
    m_pLayers[0].kind = layer;
    m_pLayers[0].flags = FLAG_ACTIVE | FLAG_MODIFIED;
    m_minx = m_width;
    m_maxx = 0;
    m_miny = m_height;
    m_maxy = 0;
    count = 2;
    PushUndo(m_nInk);
    UINT size = m_pitch * m_height;
//    memset(pUndo,0,size + size);
    int x, y;
    int ww, hh;
    ww = m_width - 1 - count;
    hh = m_height - 1 - count;
    for (y = 1; y < hh; y++)
        {
        for (x = 1; x < ww; x++)
            {
            cp.m_offset = y * m_pitch + x;
            if (!cp.Paint())
                continue;
            int delta = 0;
            if (cp.Ink(-1) && cp.Ink(m_pitch) &&
                        cp.Paint(m_pitch - 1))
                {
                if (cp.Paint(1) && cp.Paint(2) && cp.Paint(3))
                    delta = m_pitch - 1;
                else if (cp.Paint(-(int)m_pitch) && cp.Paint(-2*(int)m_pitch))
                    delta = m_pitch - 1;
                else if (cp.Paint(m_pitch - 2) && cp.Paint(m_pitch - 3))
                    delta = m_pitch - 1;
                else if (cp.Paint(2 * m_pitch-1) && cp.Paint(3*m_pitch-1))
                    delta = m_pitch - 1;
                }
            else if (cp.Ink(1) && cp.Ink(m_pitch) &&
                        cp.Paint(m_pitch + 1))
                {
                if (cp.Paint(-1) && cp.Paint(-2) && cp.Paint(-3))
                    delta = m_pitch + 1;
                else if (cp.Paint(-(int)m_pitch) && cp.Paint(-2*(int)m_pitch))
                    delta = m_pitch + 1;
                else if (cp.Paint(m_pitch + 2) && cp.Paint(m_pitch + 3))
                    delta = m_pitch + 1;
                else if (cp.Paint(2 * m_pitch+1) && cp.Paint(3*m_pitch+1))
                    delta = m_pitch + 1;
                }
            else if (cp.Ink(-(int)m_pitch) && cp.Ink(m_pitch) &&
                    cp.Paint(1) && cp.Paint(2) && cp.Paint(-1) && cp.Paint(-2))
                    delta = 9999;
            if (delta)
                {
DPF("found,x:%d,y:%d,d:%d",x,y,delta);
                int i,z,a,b;
                b = 0;
                for (i = 0; i < 8;i++)
                    {
                    a = cp.m_pInk[x+dx[i] + (y+dy[i]) * m_pitch];
                    if (a > b)
                        {
                        z = i;
                        b = a;
                        }
                    }
                a = cp.m_pInk[cp.m_size+ x+dx[z] + (y+dy[z]) * m_pitch];
b = 1;
                cp.Ink(0,a,b);
                if (delta != 9999)
                    cp.Ink(delta,a,b);
                m_bDirty = TRUE;
                }
            }
        }
    return m_bDirty;
}

UINT CLayers::LastUndoIndex()
{
    return (m_nPushCount + MAXUNDO - 1) % MAXUNDO;
}

BYTE * CLayers::LastUndo()
{
    UINT size = m_height * 2 * m_pitch;
    UINT index = (m_nPushCount + MAXUNDO - 1) % MAXUNDO;
    BYTE * pp = m_pUndo[index].pData;
#ifdef _DEBUG
    DPF("last undo,layer:%d",m_pUndo[index].layer);
#endif
    return pp;
}


void CLayers::CleanUp(UINT code)
{
    if (code)
        return;
    BYTE * pInk = m_pLayers[m_nInk].pData;
    BYTE * pOld = LastUndo();
    UINT size, c;
    size = m_height * m_pitch;
    for (c = 0; c < size; c++)
        {
        if (pInk[c] != pOld[c])
            {
//            ASSERT(pInk[c] == 255);
            pInk[c] = 1;
            pInk[c+size] = 0;
            UINT y = c / m_pitch;
            UINT x = c % m_pitch;
            }
        }
}

#ifdef PATTERNS
static BYTE grad[4];
BYTE * CLayers::GetGrad(UINT index, UINT xx, UINT yy)
{
    CPoint p1;
    CPoint p2;
    COLORREF c1;
    COLORREF c2;
    UINT kind;
    AdvKind (index, kind);
    AdvPoint(index, 0, p1);
    AdvPoint(index, 1, p2);
    AdvColor(index, 0, c1);
    AdvColor(index, 1, c2);
    int x3 = xx;
    int y3 = yy;
    int dx = p2.x - p1.x;
    int dy = p2.y - p1.y;
    int d = (int)sqrt((double)(dx * dx) + (double)(dy * dy));
    int f;
//    kind = 0;
    if (kind)
    {
    double ddb = dx * dx + dy * dy;
    double ddt1 = dx * dx * (x3 - p1.x) + dx * dy * (y3 - p1.y);
    double ddt2 = dy * dy * (y3 - p1.y) + dx * dy * (x3 - p1.x);
    double q = ddt1 * ddt1 + ddt2 * ddt2;
    q = q / (ddb * ddb);
    q = sqrt(q);
    int d1 = (int)q;
    ddt1 = dx * dx * (x3 - p2.x) + dx * dy * (y3 - p2.y);
    ddt2 = dy * dy * (y3 - p2.y) + dx * dy * (x3 - p2.y);
    q = ddt1 * ddt1 + ddt2 * ddt2;
    q = q / (ddb * ddb);
    q = sqrt(q);
    int d2 = (int)q;
    if ((d1 > d2) && (d1 > d))
        f = 255;
    else if ((d2 > d1) && (d2 > d))
        f = 0;
    else
        {
ASSERT(d1 <= d);
        f = 255 * d1 / d;
        }
    }
    else
    {
    int ddx = x3 - p1.x;
    int ddy = y3 - p1.y;
    int d1 = (int)sqrt((double)(ddx * ddx) + (double)(ddy * ddy));
    if (d1 > d)
        f = 255;
    else
        f = 255 * d1 / d;
    }
    int f2 = 255 - f;
    grad[0] = (f2 * GetRValue(c1) + f * GetRValue(c2)) / 255;
    grad[1] = (f2 * GetGValue(c1) + f * GetGValue(c2)) / 255;
    grad[2] = (f2 * GetBValue(c1) + f * GetBValue(c2)) / 255;
    grad[3] = (BYTE)((f2 * (c1 >> 24) + f * (c2 >> 24)) / 255);
    return grad;
}

UINT CLayers::AdvIndex( UINT palindex, int value)
{
    ASSERT(palindex < 256);
    if (value == -1)
        return m_pColors->map[palindex];
    if (!value) // removing color
        {
        UINT j = m_pColors->map[palindex];
        m_pColors->map[palindex] = 0;
        ASSERT(j != 0);
        UINT i;
        for (i = 0; i < 256; i++)
            if (m_pColors->map[i] > j)
                m_pColors->map[i]--;// it would be better to have link in info
        for (; (j < m_pColors->count);j++)
            {
            m_pColors->info[j-1] = m_pColors->info[j];
            }
        m_pColors->count--;
        return 0;
        }
    else
        {
        UINT i;
        ASSERT(m_pColors->map[palindex] == 0);
        i = m_pColors->count++;
        m_pColors->map[palindex] = i + 1;
        m_pColors->info[i].kind = 0;
        m_pColors->info[i].p1 = CPoint(m_width / 2,m_height / 2);
        m_pColors->info[i].p2 = CPoint(0,0);
        BYTE * pPal = &m_pTable->pals[4 * palindex];
        m_pColors->info[i].c1 = RGB(pPal[0],pPal[1],pPal[2]) | 0xff000000;
        m_pColors->info[i].c2 = RGB(255,255,255) | 0xff000000;
        return i + 1;
        }
}

void CLayers::AdvKind(UINT index, UINT & kind, BOOL bSet)
{
    ASSERT(index < m_pColors->count);
    UINT * pkind = &m_pColors->info[index].kind;
    if (bSet)
        * pkind = kind;
    else
        kind = * pkind;
}

void CLayers::AdvColor(UINT index, UINT which, COLORREF & color, BOOL bSet)
{
    ASSERT(index < m_pColors->count);
    COLORREF * pcolor = which ? &m_pColors->info[index].c2 :
                            &m_pColors->info[index].c1;
    if (bSet)
        *pcolor = color;
    else
        color = *pcolor;
}

void CLayers::AdvPoint(UINT index, UINT which, CPoint & point, BOOL bSet)
{
    ASSERT(index < m_pColors->count);
    CPoint * ppoint = which ? &m_pColors->info[index].p2 :
                            &m_pColors->info[index].p1;
    if (bSet)
        *ppoint = point;
    else
        point = *ppoint;
}
#endif
