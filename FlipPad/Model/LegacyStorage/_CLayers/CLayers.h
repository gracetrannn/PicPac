//
//  CLayers.h
//  FlipPad
//
//  Created by Alex on 04.09.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#ifndef CLayers_h
#define CLayers_h

#include "Support.h"
#include "CIO.h"

UINT TestModel(LPCSTR name, UINT width, UINT height);
class CScene;
class CLayer;
class CUndo;
class CLevel;
class CLevelTable;
//class CColors;
class CLayers
{
public:
    CLayers();
    ~CLayers();
    UINT Layer(int which = -1);
    UINT Setup(CScene * pScene, BOOL bScene, UINT Level = NEGONE);
    UINT LoadModel(UINT Level, BOOL bCreate = 0);
    UINT SaveModel(LPCSTR name = 0);
    BOOL IsOverlay() { return m_pOverlay ? TRUE : FALSE;};
    void DupCell(UINT Frame, UINT Level);
    BOOL    CanModel() { return (m_nLayers < 3) || m_pOverlay ? FALSE : TRUE;};
    UINT Select(UINT Frame, UINT Level);
    UINT SelectLayer(UINT Layer);
    void MakeDeltaMask(UINT newrad);
    UINT Get(UINT Frame, UINT Level);
    UINT Put(BOOL bForce = FALSE);
    BOOL Modified() { return m_bModified;};
    BOOL NeedFake(UINT Frame);
    BOOL UseFake(UINT cellkey);
    UINT HaveAlpha(UINT x, UINT y, UINT * pLayer = 0, BYTE * p = 0);
    UINT DisPaint(UINT x, UINT y);
    UINT GetRGB(int x, int y, UINT &r,UINT &g,UINT &b);
    UINT GetIndex(UINT x, UINT y);
    UINT GetAlpha(UINT x, UINT y);
    UINT GetInk(UINT x, UINT y);
    void PutInk(UINT x, UINT y, BYTE v);
    BOOL CanUndo();
    BOOL CanRedo();
    void Undo(UINT index = NEGONE);
    void Redo();
    void CleanUp(UINT code);
    BYTE * LastUndo();
    UINT  LastUndoIndex();
    void DrawInit(UINT color, UINT type, BOOL bErasing);
    void DrawMono(UINT x, UINT y);
    void MonoMask(int dx, int dy, UINT x, UINT y);
    void DrawDot(int x, int y, BYTE alpha);
    void Change(UINT which, UINT v);
    void Flipper(UINT mask);
    UINT FillOffset(int x, int y, UINT index, BOOL bErase, UINT kind);
    UINT Fill(int x, int y, UINT index, BOOL bErase, UINT kind);
    UINT Blend(int x, int y, UINT radius);
    void DoDot(int x, int y, int c1, int c2);
    UINT Flood(UINT index, int kind);
    UINT Clear();
    int  CDespeckle(int count);
    int  UnCranny(int count);
    int  Speckle(int count);
    int     Magical();
    int     DeGapper(int count,UINT color);
    void ApplyLayer(BYTE *pDst, BYTE * pSrc, BYTE * pPaint,BYTE * pInk,
                    BYTE * pPals, UINT kind, UINT qq);
    void ApplyCell(BYTE * pDst, DWORD dwKey, CScene * pScene,
                CLevel * pLevel, CIO * pIO);
//    BOOL FakeIt(BYTE * hpDst, UINT Frame, UINT Level);
    BOOL FakeIt(BYTE * hpDst);
    void Update(BYTE * pBits, BYTE * pBg, UINT pitch, BOOL BAll = 0);
    void LoadControl(UINT Frame, UINT Level, BOOL bClear = FALSE);
    BOOL    m_bDirty; // needs update
    BOOL    m_bFirstDot;
    BOOL    m_nFlags;// 1 is for paint, 2 is for buddy paint, 4 is for FG
    int        m_minx;
    int        m_miny;
    int        m_maxx;
    int        m_maxy;
    UINT     Width() { return m_width;};
    UINT     Height() { return m_height;};
    BYTE *     InitPalette();
    BYTE *  m_pControl;        // fill control
    CLevelTable * LevelTable(BOOL bPut = 0);
    LPCSTR LayerName(int layer);
    UINT FillStack(UINT pos);
    UINT    m_zx;
    UINT    m_zy;
#ifdef PATTERNS
// adv index returns 0 if normal color
// else 1 + complex index
// setting value to zero makes it simple
// else adding a new one
    UINT AdvIndex( UINT palindex, int v = -1);
    void AdvKind(UINT index, UINT & kind, BOOL bSet = 0);
    void AdvColor(UINT index, UINT which, COLORREF & color, BOOL bSet = 0);
    void AdvPoint(UINT index, UINT which, CPoint & point, BOOL bSet = 0);
    BYTE * GetGrad(UINT index, UINT x, UINT y);
#endif
protected:
    BYTE * PushUndo(UINT Layer, BOOL bSkip = 0);
    void UpdateColor(BYTE * pBits, UINT pitch);
    void UpdateInk(BYTE * pBits, UINT pitch);
    void UpdateGray(BYTE * pBits, BYTE * pSkin,UINT pitch);
#ifdef DOMONO
    UINT MakeMono();
    void MakeMonoMask();
    void UpdateMono();//BYTE * pBits, BYTE * pSkin,UINT pitch);
    void InitMono();
    void MonoToInk();
    void MonoLine(UINT x, UINT y);
#endif
    UINT CreateLayers();
    void InitPatterns();
    void BlurIt(UINT layer);
    int  Findruns(int x, int y, int z, int py);
    int  Findruns2(int x, int y, int z, int py);
    int  Try(int x, int y, int px, int py);
    void    EmptyUs();
    void MonoDots(UINT x, UINT y, UINT v);
    UINT m_nCurLayer;
    UINT    m_color;
    UINT    m_dot_type;
    UINT    m_width;
    UINT    m_height;
    UINT    m_pitch;
    BYTE *    m_pOverlay;
    BOOL    m_bModified;
    BOOL    m_bNeedFake;
    UINT    m_cellkey;
    UINT    m_frame;
    UINT    m_level;
    UINT    m_nLayers;
    UINT m_nInk;
    UINT m_nPaint;
    UINT     m_nUndo;
    UINT     m_nRedo;
    UINT     m_nPushCount;
    BOOL    m_bErasing;
    BOOL    m_bSolid;
#ifdef DOMONO
    UINT    m_nMono;        // scale factor for mono
    BYTE * m_pMono;            // mono buffer
    BOOL    m_bMonoModified;
#endif
//    CColors * m_pColors;
    UINT    m_prevx;
    UINT    m_prevy;
    BYTE  * m_pFillStack;
    UINT    m_nFillMax;
    UINT    m_nFillCount;
    UINT    m_nFillIndex;
    CLayer * m_pLayers;
    CUndo * m_pUndo;
    CScene * m_pScene;
    CLevelTable * m_pTable;
    char    m_name[300];
};

#endif /* CLayers_h */
