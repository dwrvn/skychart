unit cu_plot;

{
Copyright (C) 2002 Patrick Chevalley

http://www.ap-i.net
pch@ap-i.net

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}
{
 Bitmap skychart drawing component
}

{$mode delphi}{$H+}

interface

uses
  LazUTF8, LazFileUtils, BGRABitmap, BGRABitmapTypes, BGRATransform, FPReadBMP,
  u_constant, u_util, PostscriptCanvas, process,
  SysUtils, Types, StrUtils, FPImage, LCLType, LCLIntf, IntfGraphics, FPCanvas,
  Menus, StdCtrls, Dialogs, Controls, ExtCtrls, Math, Classes, Graphics, u_translation,
  u_orbits, u_CacheBMP, UScaleDPI;

type

  TSide = (U, D, L, R);  // Up, Down, Left, Right
  TSideSet = set of TSide;
  TEditLabelPos = procedure(lnum, left, top, w, h: integer; moderadec: boolean) of object;
  Tintfunc = procedure(i: integer) of object;
  Tvoidfunc = procedure of object;

  TSplot = class(TComponent)
  private
    { Private declarations }
    outx0, outy0, outx1, outy1: integer;
    outlineclosed, outlineinscreen: boolean;
    outlinetype, outlinemax, outlinenum, outlinelw: integer;
    outlinecol: Tcolor;
    outlinepts: array of TPoint;
    ilabels: array [1..maxlabels] of TImage;
    editlabel, editlabelx, editlabely, selectedlabel: integer;
    editlabelmod: boolean;
    FlabelRaDec: boolean;
    FEditLabelPos: TEditLabelPos;
    FEditLabelTxt: TEditLabelPos;
    FDefaultLabel: Tintfunc;
    FDeleteLabel: Tintfunc;
    FDeleteAllLabel: Tvoidfunc;
    FLabelClick: Tintfunc;

    FCacheBMP: TCacheBMP;

    TransparentColor: TFPColor;
    bmpreader: TFPReaderBMP;
    obmp: TBitmap;
    Fstarshape: Tbitmap;
    starbmp: Tbitmap;
    Bstarbmp: array [0..6, 0..10] of TBGRABitmap;
    starbmpw: integer;
    function PlotStar0(x, y: single; ma, b_v: double): integer;
    function PlotStar1(x, y: single; ma, b_v: double): integer;
    function PlotStar2(x, y: single; ma, b_v: double): integer;
    procedure PlotPlanet1(xx, yy, flipx, flipy, ipla: integer;
      pixscale, diam, flatten, phase, pa, rot, poleincl, sunincl: double);
    procedure PlotPlanet3(xx, yy, flipx, flipy, ipla: integer;
      jdt, pixscale, diam, flatten, pa, gw: double; WhiteBg: boolean);
    procedure PlotPlanet4(xx, yy, ipla: integer; pixscale, phase: double; WhiteBg: boolean);
    procedure PlotPlanet5(xx, yy, flipx, flipy, ipla: integer;
      jdt, pixscale, diam, flatten, rot: double; WhiteBg: boolean; size, margin: integer);
    procedure PlotSatRing1(xx, yy: integer; pixscale, pa, rot, r1, r2, diam, be: double;
      WhiteBg: boolean);
    procedure BezierSpline(pts: array of Tpoint; n: integer);
    function ClipVector(var x1, y1, x2, y2: integer; var clip1, clip2: boolean): boolean;
    procedure editlabelmenuPopup(Sender: TObject);
    procedure labelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure labelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure labelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure labelMouseLeave(Sender: TObject);
    procedure Setstarshape(Value: Tbitmap);
    procedure InitXPlanetRender;
    procedure SetImage(Value: TCanvas);
    procedure InitStarBmp;
    procedure SetBGRATransparencyFromLuminance(bmp: TBGRABitmap;
      method: integer; whitebg: boolean = False; forcealpha: integer = 0; blacklevel: integer = 0);
    procedure PlotDSOOcl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOPNe(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOGCl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOBN(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOClNb(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSODStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSOTStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSOAst(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOHIIRegion(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor; alpha:byte);
    procedure PlotDSOGxyCl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor);
    procedure PlotDSODN(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor);
    procedure PlotDSOUnknown(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSOCircle(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSOlozenge(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    procedure PlotDSORectangle(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; forcecolor: boolean; col: Tcolor);
    function BGRATextOut(x, y, o: single; s: string; c: TBGRAPixel;
      abmp: TBGRABitmap; forceantialias: boolean = False): TRect;
    procedure BGRARectangle(x1, y1, x2, y2: single; c: TBGRAPixel;
      w: single; abmp: TBGRABitmap);
    procedure ClearImage;


    function GetBodyImage(ipla: integer; ds: integer;
      jdt, flatten, gw, pa: double): integer;

  protected
    { Protected declarations }
  public
    { Public declarations }
    cfgplot: Tconf_plot;
    cfgchart: Tconf_chart;
    cbmp: TBGRABitmap;
    Astarbmp: array [0..6, 0..10] of Tbitmap;
    cnv: Tcanvas;
    destcnv: Tcanvas;
    compassrose, compassarrow: TBGRAbitmap;
    editlabelmenu: Tpopupmenu;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Init(w, h: integer): boolean;
    function InitLabel: boolean;
    procedure FlushCnv;
    procedure BGRADrawLine(x1, y1, x2, y2: single; c: TBGRAPixel; w: single;
      abmp: TBGRABitmap; ps: TPenStyle = psSolid);
    procedure PlotBorder(LeftMargin, RightMargin, TopMargin, BottomMargin,
      HeaderHeight, FooterHeight: integer; whitebg: boolean);
    function PlotStar(xx, yy: single; ma, b_v: double): integer;
    function PlotVarStar(x, y: single; vmax, vmin: double): integer;
    function PlotDblStar(x, y, r: single; ma, sep, pa, b_v: double): integer;
    procedure PlotDeepSkyObject(Axx, Ayy: single; Adim, Ama, Asbr, Apixscale: double;
      Atyp: integer; Amorph: string; whitebg: boolean; forcecolor: boolean; col: Tcolor = clWhite; alpha:byte=255);
    procedure PlotDSOGxy(Ax, Ay: single;
      Ar1, Ar2, Apa, Arnuc, Ab_vt, Ab_ve, Ama, Asbr, Apixscale, sizeunit: double; Amorph: string;
      forcecolor: boolean; col: Tcolor; alpha:byte=255);
    procedure PlotCRose(rosex, rosey, roserd, rot: single; flipx, flipy: integer;
      WhiteBg: boolean; RoseType: integer);
    procedure PlotLine(x1, y1, x2, y2: single; lcolor, lwidth: integer;
      style: TFPPenStyle = psSolid);
    procedure PlotSimMark(x, y: single; mcolor: Tcolor);
    procedure PlotImage(xx, yy: single; iWidth, iHeight, Rotation: double;
      flipx, flipy: integer; WhiteBg, iTransparent: boolean;
      var bgraibmp: TBGRABitmap; TransparentMode: integer = 0; forcealpha: integer = 0);
    procedure PlotBGImage(ibmp: TBitmap; WhiteBg: boolean; alpha: integer = 200);
    procedure PlotPlanet(x, y: single; flipx, flipy, ipla: integer;
      jdt, pixscale, diam, flatten, magn, phase, pa, rot, poleincl, sunincl, w, r1, r2, be: double;
      WhiteBg: boolean; size: integer = 0; margin: integer = 0);
    procedure PlotEarthShadow(x, y: single; r1, r2, pixscale, flatten: double; forceline: boolean);
    procedure PlotSatel(x, y: single; ipla: integer; JD, pixscale, ma, diam, rot: double;
      hidesat, showhide, whitebg: boolean; flipx, flipy: integer);
    procedure PlotAsteroid(x, y: single; symbol: integer; ma: double);
    procedure PlotComet(x, y, cx, cy: single; symbol: integer; ma, diam, PixScale: double);
    function PlotLabel(i, labelnum, fontnum: integer; xxs, yys, rs, orient: single;
      Xalign, Yalign: TLabelAlign; WhiteBg, forcetextlabel: boolean; txt: string;
      var px, py: integer; sizex: single = 1): integer;
    function GetTextSize(fontnum: integer; txt: string; labelnum: integer = -1;
      lsize: single = 1): Tsize;
    procedure PlotText(xx, yy, fontnum, lcolor: integer; Xalign, Yalign: TLabelAlign;
      txt: string; WhiteBg: boolean; opaque: boolean = True; clip: boolean = False;
      marge: integer = 5; orient: integer = 0);
    procedure PlotTextCR(xx, yy, fontnum, labelnum: integer; txt: string;
      WhiteBg: boolean; opaque: boolean = True; orient: integer = 0);
    function  PlotOutline(x, y: single; op, lw, fs, closed: integer; r2: double; col: Tcolor; sbmp:TBGRABitmap=nil; salpha:integer=255):boolean;
    procedure PlotMWDot(x, y, r: single; col: TColor; WhiteBg: boolean);
    procedure PlotCircle(x1, y1, x2, y2: single; lcolor: integer; moving: boolean);
    procedure PlotCircleMask(x1, y1, r: single; whitebg: boolean);
    procedure PlotPolyLine(p: array of Tpoint; lcolor: integer; moving: boolean);
    procedure FloodFill(X, Y: integer; FillColor: TColor);
    procedure Movelabel(Sender: TObject);
    procedure MovelabelRaDec(Sender: TObject);
    procedure EditlabelTxt(Sender: TObject);
    procedure DefaultLabel(Sender: TObject);
    procedure Deletelabel(Sender: TObject);
    procedure DeleteAlllabel(Sender: TObject);

    property Starshape: TBitmap read Fstarshape write Setstarshape;
    property OnEditLabelPos: TEditLabelPos read FEditLabelPos write FEditLabelPos;
    property OnEditLabelTxt: TEditLabelPos read FEditLabelTxt write FEditLabelTxt;
    property OnDefaultLabel: Tintfunc read FDefaultLabel write FDefaultLabel;
    property OnDeleteLabel: Tintfunc read FDeleteLabel write FDeleteLabel;
    property OnDeleteAllLabel: Tvoidfunc read FDeleteAllLabel write FDeleteAllLabel;
    property OnLabelClick: Tintfunc read FLabelClick write FLabelClick;
    property Image: TCanvas write SetImage;

  published
    { Published declarations }

  end;

//  const cliparea = 10;

implementation

const
  emptysize = 10;

constructor TSplot.Create(AOwner: TComponent);
var
  i, j: integer;
  MenuItem: TMenuItem;
begin

  inherited Create(AOwner);

  FCacheBMP := TCacheBMP.Create;

  for i := 0 to 6 do
    for j := 0 to 10 do
    begin
      Astarbmp[i, j] := Tbitmap.Create;
      Bstarbmp[i, j] := TBGRABitmap.Create;
    end;

  starbmp := TBitmap.Create;
  cbmp := TBGRABitmap.Create;
  obmp := TBitmap.Create;
  bmpreader := TFPReaderBMP.Create;
  cnv := obmp.canvas;
  cfgplot := Tconf_plot.Create;
  cfgchart := Tconf_chart.Create;

  // set safe value
  starbmpw := 1;
  editlabel := -1;
  cbmp.SetSize(emptysize, emptysize);
  cfgchart.Width := emptysize;
  cfgchart.Height := emptysize;
  cfgchart.min_ma := 6;
  cfgchart.onprinter := False;
  cfgchart.drawpen := 1;
  cfgchart.drawsize := 1;
  cfgchart.fontscale := 1;
  TransparentColor.red := 0;
  TransparentColor.green := 0;
  TransparentColor.blue := 0;
  TransparentColor.alpha := 65535;
  InitXPlanetRender;

  editlabelmenu := Tpopupmenu.Create(self);
  editlabelmenu.AutoPopup := True;
  editlabelmenu.OnPopup := editlabelmenuPopup;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := '';
  MenuItem.Enabled := False;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := '-';
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsMoveLabel;
  MenuItem.OnClick := MovelabelRaDec;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsOffsetLabel;
  MenuItem.OnClick := Movelabel;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsEditLabel;
  MenuItem.OnClick := EditLabelTxt;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsDefaultLabel;
  MenuItem.OnClick := DefaultLabel;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsHideLabel;
  MenuItem.OnClick := DeleteLabel;
  MenuItem := TMenuItem.Create(editlabelmenu);
  editlabelmenu.Items.Add(MenuItem);
  MenuItem.Caption := rsResetAllLabe;
  MenuItem.OnClick := DeleteAllLabel;

  for i := 1 to maxlabels do
  begin
    ilabels[i] := TImage.Create(nil);
    ilabels[i].parent := TWinControl(AOwner);
    ilabels[i].tag := i;
    ilabels[i].Transparent := True;
    ilabels[i].Visible := false;
    ilabels[i].Font.CharSet := FCS_ISO_10646_1;
    ilabels[i].PopupMenu := editlabelmenu;
    ilabels[i].OnMouseDown := labelmousedown;
    ilabels[i].OnMouseUp := labelmouseup;
    ilabels[i].OnMouseMove := labelmousemove;
    ilabels[i].OnMouseLeave := labelmouseleave;
  end;

end;

destructor TSplot.Destroy;
var
  i, j: integer;

begin

  try

    FCacheBMP.Free;

    for i := 1 to maxlabels do
      ilabels[i].Free;

    for i := 0 to 6 do
      for j := 0 to 10 do
      begin
        Astarbmp[i, j].Free;
        Bstarbmp[i, j].Free;
      end;

    starbmp.Free;
    cbmp.Free;
    obmp.Free;
    bmpreader.Free;
    cfgplot.Free;
    cfgchart.Free;

    inherited Destroy;

  except
    writetrace('error destroy ' + Name);
  end;

end;

procedure TSplot.SetImage(Value: TCanvas);
begin
  destcnv := Value;
end;

procedure TSplot.ClearImage;
begin

  if cfgplot.UseBMP then
    cbmp.Fill(cfgplot.Color[0])
  else

  if cnv <> nil then
    with cnv do
    begin
      Brush.Color := cfgplot.Color[0];
      Pen.Color := cfgplot.Color[0];
      Brush.style := bsSolid;
      Pen.Mode := pmCopy;
      Pen.Style := psSolid;
      Rectangle(0, 0, cfgchart.Width, cfgchart.Height);
    end;

end;

function TSplot.Init(w, h: integer): boolean;
var
  bmp1, bmp2: TBGRABitmap;
begin

  cfgchart.Width := w;
  cfgchart.Height := h;

  if cfgplot.UseBMP then
  begin
    cbmp.SetSize(w, h);
    cnv := nil; // to be sure we no more use it!
  end
  else

  begin

    if cfgchart.onprinter then
      cnv := destcnv
    else
    begin
      obmp.FreeImage;
      obmp.Transparent := False;
      obmp.Width := w;
      obmp.Height := h;
      cnv := obmp.Canvas; // defered plot to bitmap
    end;

  end;

  ClearImage;

  if not cfgplot.UseBMP then
    if cnv <> nil then
      with cnv do
      begin
        Font.CharSet := FCS_ISO_10646_1;
      end;

  InitLabel;

  if (cfgplot.starplot > 0) and (cfgchart.drawsize <> starbmpw) and (Fstarshape <> nil) then
  begin
    starbmpw := cfgchart.drawsize;
    bmp1 := TBGRABitmap.Create(Fstarshape);
    bmp2 := bmp1.Resample(bmp1.Width * starbmpw, bmp1.Height * starbmpw) as TBGRABitmap;
    starbmp.Assign(bmp2);
    bmp1.Free;
    bmp2.Free;
    InitStarBmp;
  end;

  Result := True;
end;

procedure TSplot.PlotBorder(LeftMargin, RightMargin, TopMargin,
  BottomMargin, HeaderHeight, FooterHeight: integer; whitebg: boolean);
var
  xmin, xmax, ymin, ymax: integer;
  bcol, fcol: Tcolor;
  c: TBGRAPixel;
begin

  if ((LeftMargin > 0) or (RightMargin > 0) or (TopMargin > 0) or (BottomMargin > 0)) then
  begin
    xmin := 0;
    ymin := 0;
    xmax := cfgchart.Width;
    ymax := cfgchart.Height;

    if whitebg then
    begin
      fcol := clWhite;
      bcol := clBlack;
    end
    else
    begin
      fcol := cfgplot.backgroundcolor;
      bcol := fcol xor $FFFFFF;
    end;

    if cfgplot.UseBMP then
    begin
      c := ColorToBGRA(fcol, 0);
      cbmp.Rectangle(xmin, ymin, xmin + LeftMargin, ymax, c, c, dmSet);
      cbmp.Rectangle(xmax - RightMargin, ymin, xmax, ymax, c, c, dmSet);
      cbmp.Rectangle(xmin, ymin, xmax, ymin + TopMargin, c, c, dmSet);
      cbmp.Rectangle(xmin, ymax - BottomMargin, xmax, ymax, c, c, dmSet);
      c := ColorToBGRA(bcol, 0);
      cbmp.Rectangle(xmin + LeftMargin, ymin + TopMargin, xmax - RightMargin,
        ymax - BottomMargin, c, dmSet);

      if HeaderHeight > 0 then
        cbmp.Rectangle(xmin + LeftMargin, ymin + TopMargin - HeaderHeight,
          xmax - RightMargin, ymin + TopMargin, c, dmSet);

      if FooterHeight > 0 then
        cbmp.Rectangle(xmin + LeftMargin, ymax - BottomMargin + FooterHeight,
          xmax - RightMargin, ymax - BottomMargin, c, dmSet);
    end
    else

    begin

      if cnv <> nil then
        with cnv do
        begin
          Pen.Color := fcol;
          Pen.Width := 1;
          Pen.Mode := pmCopy;
          Brush.Color := fcol;
          Brush.Style := bsSolid;
          Rectangle(xmin, ymin, xmin + LeftMargin, ymax);
          Rectangle(xmax - RightMargin, ymin, xmax, ymax);
          Rectangle(xmin, ymin, xmax, ymin + TopMargin);
          Rectangle(xmin, ymax - BottomMargin, xmax, ymax);
          Pen.Color := bcol;
          Pen.Width := 2 * cfgchart.drawpen;
          Brush.Color := fcol;
          moveto(xmin + LeftMargin, ymin + TopMargin);
          lineto(xmin + LeftMargin, ymax - BottomMargin);
          moveto(xmin + LeftMargin, ymax - BottomMargin);
          // Postscriptcanvas do not move after line
          lineto(xmax - RightMargin, ymax - BottomMargin);
          moveto(xmax - RightMargin, ymax - BottomMargin);
          lineto(xmax - RightMargin, ymin + TopMargin);
          moveto(xmax - RightMargin, ymin + TopMargin);
          lineto(xmin + LeftMargin, ymin + TopMargin);

          if HeaderHeight > 0 then
          begin
            moveto(xmin + LeftMargin, ymin + TopMargin - HeaderHeight);
            lineto(xmax - RightMargin, ymin + TopMargin - HeaderHeight);
            moveto(xmin + LeftMargin, ymin + TopMargin - HeaderHeight);
            lineto(xmin + LeftMargin, ymin + TopMargin);
            moveto(xmax - RightMargin, ymin + TopMargin - HeaderHeight);
            lineto(xmax - RightMargin, ymin + TopMargin);
          end;

          if FooterHeight > 0 then
          begin
            moveto(xmin + LeftMargin, ymax - BottomMargin + FooterHeight);
            lineto(xmax - RightMargin, ymax - BottomMargin + FooterHeight);
            moveto(xmin + LeftMargin, ymax - BottomMargin + FooterHeight);
            lineto(xmin + LeftMargin, ymax - BottomMargin);
            moveto(xmax - RightMargin, ymax - BottomMargin + FooterHeight);
            lineto(xmax - RightMargin, ymax - BottomMargin);
          end;

        end;

    end;

  end;

end;

procedure TSplot.InitXPlanetRender;
begin
  Xplanetversion := GetXPlanetVersion;
  Xplanetrender := (Xplanetversion <> '0.0.0');
end;

procedure TSplot.FlushCnv;
begin

  if cfgplot.UseBMP then
  begin
    if (cbmp.Width = emptysize) and (cbmp.Height = emptysize) then
      exit;

    cbmp.LoadFromBitmapIfNeeded;

    {$ifdef darwin}
    cbmp.Draw(destcnv, 0, 0, False);
    // avoid error message: "CGBitmapContextCreate: invalid data bytes/row"
    {$else}
    cbmp.Draw(destcnv, 0, 0, True); // draw bitmap to screen
    {$endif}
  end
  else
  begin
    destcnv.CopyMode := cmSrcCopy;
    destcnv.Draw(0, 0, obmp);
  end;

  cnv := destcnv;           // direct plot to screen;
end;

procedure TSplot.Setstarshape(Value: Tbitmap);
begin
  Fstarshape := Value;
  starbmpw := 1;
  starbmp.Assign(Fstarshape);
  InitStarBmp;
end;

//todo: check if alpha transparency work
{$IFDEF LCLQT} {$DEFINE OLD_MASK_TRANSPARENCY} {$ENDIF}
procedure SetTransparencyFromLuminance(bmp: Tbitmap; method: integer;
  whitebg: boolean = False);
var
  memstream: Tmemorystream;
  IntfImage: TLazIntfImage;
  x, y: integer;
  newalpha: word;
  CurColor: TFPColor;
  ImgHandle, ImgMaskHandle: HBitmap;
begin

  try

    if (bmp.Width < 2) or (bmp.Height < 2) then
      exit;

    IntfImage := nil;

    try
      IntfImage := bmp.CreateIntfImage;

      for y := 0 to IntfImage.Height - 1 do
      begin

        for x := 0 to IntfImage.Width - 1 do
        begin
          CurColor := IntfImage.Colors[x, y];
          newalpha := (CurColor.red + CurColor.green + CurColor.blue) div 3;

          case method of

            0:
            begin  // linear for nebulae
             {$IF DEFINED(OLD_MASK_TRANSPARENCY)}
              if newalpha <= (0) then
                CurColor := colTransparent
              else
                CurColor.alpha := alphaOpaque;
             {$ELSE}
                {$IFDEF LCLGTK2}
              CurColor.alpha := MinIntValue([alphaOpaque, newalpha * 3]);
                {$ELSE}
              CurColor.alpha := newalpha;
                {$ENDIF}
             {$ENDIF}
            end;
            1:
            begin  // hard contrast for bitmap stars
              if newalpha < (50 * 255) then
                CurColor := colTransparent
              else
                CurColor.alpha := alphaOpaque;
            end;
            2:
            begin  // black transparent
              if newalpha <= (0) then
                CurColor := colTransparent
              else
                CurColor.alpha := alphaOpaque;
            end;
            3:
            begin  // White transparent
              if newalpha >= (65535) then
                CurColor := colTransparent
              else
                CurColor.alpha := alphaOpaque;
            end;
          end;

          if whitebg then
          begin
            CurColor.red := 65535 - CurColor.red;
            CurColor.green := 65535 - CurColor.green;
            CurColor.blue := 65535 - CurColor.blue;
          end;
          IntfImage.Colors[x, y] := CurColor;
        end;
      end;

      IntfImage.CreateBitmaps(ImgHandle, ImgMaskHandle);
      bmp.SetHandles(ImgHandle, ImgMaskHandle);

      memstream := Tmemorystream.Create;
      bmp.SaveToStream(memstream);
      memstream.position := 0;
      bmp.LoadFromStream(memstream);
      bmp.Transparent := True;

    finally
      IntfImage.Free;
      memstream.Free;
    end;

  except
  end;

end;

procedure TSplot.SetBGRATransparencyFromLuminance(bmp: TBGRABitmap;
  method: integer; whitebg: boolean = False; forcealpha: integer = 0; blacklevel: integer = 0);
var
  i: integer;
  newalpha: byte;
  p: PBGRAPixel;
  whitetr: boolean;
begin

  if (bmp.Width < 2) or (bmp.Height < 2) then
    exit;

  whitetr := blacklevel > 128;
  p := bmp.Data;

  for i := bmp.NbPixels - 1 downto 0 do
  begin

    newalpha := MaxIntValue([p^.red, p^.green, p^.blue]);

    case method of

      0: ;                      // 0: linear for nebulae

      1: if newalpha < 50 then    // 1: hard contrast for stars  and planets
          newalpha := 0
        else
          newalpha := 255;

      2: if newalpha <= 0 then    // 2: black transparent
          newalpha := 0
        else
          newalpha := 255;

      3: if (whitetr and (newalpha < blacklevel)) or ((not whitetr) and
          (newalpha > blacklevel)) then
          newalpha := forcealpha
        else
          newalpha := 0; // 3: fixed transparency, except bg transparent

      4: newalpha := p^.alpha;

    end;

    if whitebg then
    begin
      p^.red := 255 - p^.red;
      p^.green := 255 - p^.green;
      p^.blue := 255 - p^.blue;
    end;

    p^.alpha := newalpha;
    Inc(p);
  end;

  bmp.InvalidateBitmap;
end;

procedure TSplot.InitStarBmp;
var
  i, j, bw: integer;
  SrcR, DestR: Trect;
begin

  bw := 2 * cfgplot.starshapew * starbmpw;

  for i := 0 to 6 do
    for j := 0 to 10 do
    begin
      SrcR := Rect(j * cfgplot.starshapesize * starbmpw, i * cfgplot.starshapesize * starbmpw,
        (j + 1) * cfgplot.starshapesize * starbmpw, (i + 1) * cfgplot.starshapesize * starbmpw);
      DestR := Rect(0, 0, bw, bw);
      Astarbmp[i, j].Width := bw;
      Astarbmp[i, j].Height := bw;
{$IFNDEF OLD_MASK_TRANSPARENCY}
      Astarbmp[i, j].PixelFormat := pf32bit;
{$ENDIF}
      Astarbmp[i, j].canvas.CopyMode := cmSrcCopy;
      Astarbmp[i, j].canvas.CopyRect(DestR, starbmp.canvas, SrcR);
      SetTransparencyFromLuminance(Astarbmp[i, j], 1);
      Bstarbmp[i, j].Assign(Astarbmp[i, j]);
      SetBGRATransparencyFromLuminance(Bstarbmp[i, j], 1);
    end;

end;

function TSplot.InitLabel: boolean;
var
  i: integer;
begin

  editlabel := -1;

  for i := 1 to maxlabels do
    ilabels[i].Visible := False;

  Result := True;

end;

function TSplot.PlotStar1(x, y: single; ma, b_v: double): integer;  // bitmap image
var
  ds, Icol: integer;
  ico, isz, xx, yy: integer;
begin

  xx := round(x);
  yy := round(y);

  Icol := Round(b_v * 10);

  case Icol of
    -999.. -3: ico := 0;
    -2.. -1: ico := 1;
    0..2: ico := 2;
    3..5: ico := 3;
    6..8: ico := 4;
    9..13: ico := 5;
    14..900: ico := 6;
    else
      ico := 2;
  end;

  if ma < -5 then
    ma := -5;

  ds := round(1.5 * max(1, (cfgplot.starsize *
    (cfgchart.min_ma - ma * cfgplot.stardyn / 80) / cfgchart.min_ma)));

  case ds of
    1..2: isz := 9;
    3: isz := 9;
    4: isz := 8;
    5: isz := 7;
    6: isz := 6;
    7: isz := 5;
    8: isz := 4;
    9: isz := 3;
    10: isz := 2;
    11: isz := 1;
    else
      isz := 0;
  end;

  Result := round(ds / 3);

  if cfgplot.UseBMP then
    cbmp.PutImage(xx - cfgplot.starshapew * starbmpw, yy - cfgplot.starshapew *
      starbmpw, Bstarbmp[ico, isz], dmDrawWithTransparency)
  else
  if cnv <> nil then
    with cnv do
    begin
      CopyMode := cmSrcCopy;
      Draw(xx - cfgplot.starshapew * starbmpw, yy - cfgplot.starshapew * starbmpw,
        Astarbmp[ico, isz]);
    end;

end;

function TSplot.PlotStar0(x, y: single; ma, b_v: double): integer;  // draw ellipse
var
  ds, ds2, Icol, xx, yy: integer;
  co: Tcolor;
begin

  xx := round(x);
  yy := round(y);

  if b_v > 1000 then
    co := cfgplot.Color[trunc(b_v - 1000)]
  else
  begin

    Icol := Round(b_v * 10);

    case Icol of
      -999.. -3: co := cfgplot.Color[1];
      -2.. -1: co := cfgplot.Color[2];
      0..2: co := cfgplot.Color[3];
      3..5: co := cfgplot.Color[4];
      6..8: co := cfgplot.Color[5];
      9..13: co := cfgplot.Color[6];
      14..900: co := cfgplot.Color[7];
      else
        co := cfgplot.Color[11];
    end;

  end;

  if ma < -5 then
    ma := -5;

  ds := round(max(1, (cfgplot.starsize * (cfgchart.min_ma - ma * cfgplot.stardyn / 80) /
    cfgchart.min_ma)) * cfgchart.drawsize);
  ds2 := round(ds / 2);
  Result := ds2;

  if cfgplot.UseBMP then
  begin
    cbmp.EllipseAntialias(x, y, ds / 2, ds / 2, ColorToBGRA(cfgplot.Color[0]),
      (cfgchart.DrawPen / 2));
    cbmp.FillEllipseAntialias(x, y, ds / 2, ds / 2, ColorToBGRA(co));
  end
  else
  if cnv <> nil then
    with cnv do
    begin
      Pen.Color := cfgplot.Color[0];
      Pen.Width := max(1, cfgchart.DrawPen div 2);
      Pen.Mode := pmCopy;
      Brush.Color := co;
      Brush.style := bsSolid;

      case ds of
        1..2: Ellipse(xx, yy, xx + ds, yy + ds);
        3: Ellipse(xx - 1, yy - 1, xx + 2, yy + 2);
        4: Ellipse(xx - 2, yy - 2, xx + 2, yy + 2);
        5: Ellipse(xx - 2, yy - 2, xx + 3, yy + 3);
        6: Ellipse(xx - 3, yy - 3, xx + 3, yy + 3);
        7: Ellipse(xx - 3, yy - 3, xx + 4, yy + 4);
        else
          Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);
      end;

    end;

end;

function TSplot.PlotStar2(x, y: single; ma, b_v: double): integer;  // antialias sprite

const
  PointAlpha: single = 0.15;  // Transparency at Solid;

type
  TPos = single;

var
  LineWidth, AAWidth, Lum, R, G, B: TPos;
  Alpha, UseContrast, Distance, OutLevelR, OutLevelG, OutLevelB: TPos;
  DX, DY: TPos; // Distance elements
  XCount, YCount: integer;
  MinX, MinY, MaxX, MaxY, bmWidth: integer;
  ExistingPixelRed, ExistingPixelGreen, ExistingPixelBlue, NewPixelR,
  NewPixelG, NewPixelB: integer;
  Icol: integer;
  co: Tcolor;
  col: TBGRAPixel;

begin
  Result := 0;
  if not cfgplot.Usebmp then
  begin
    Result := PlotStar1(x, y, ma, b_v);
    exit;
  end;

  LineWidth := 0;

  if ma < 0 then
    ma := ma / 10;                               // avoid Moon and Sun be too big
  Lum := (1.1 * cfgchart.min_ma - ma) / cfgchart.min_ma;
  // logarithmic luminosity proportional to magnitude

  if Lum < 0.1 then
    Lum := 0.1;                             // for object fainter than the limit (asteroid)
  AAwidth := cfgchart.drawsize * cfgplot.partsize * power(cfgplot.magsize, Lum);
  // particle size also depend on the magnitude

  if b_v > 1000 then
    co := cfgplot.Color[trunc(b_v - 1000)]   // Use direct color table indice
  else
  begin
    Icol := Round(b_v * 10);                                  // Use color from B-V

    case Icol of
      -999.. -3: co := cfgplot.Color[1];
      -2.. -1: co := cfgplot.Color[2];
      0..2: co := cfgplot.Color[3];
      3..5: co := cfgplot.Color[4];
      6..8: co := cfgplot.Color[5];
      9..13: co := cfgplot.Color[6];
      14..900: co := cfgplot.Color[7];
      else
        co := cfgplot.Color[11];
    end;

  end;

  R := co and $FF;
  G := (co div $100) and $FF;
  B := (co div $10000) and $FF;
  R := ((R * cfgplot.Saturation) + (65536 - cfgplot.Saturation)) * 0.0035;
  G := ((G * cfgplot.Saturation) + (65536 - cfgplot.Saturation)) * 0.0035;
  B := ((B * cfgplot.Saturation) + (65536 - cfgplot.Saturation)) * 0.0035;

  UseContrast := (cfgplot.contrast * cfgplot.contrast) shr 6;

  if (AAWidth < 1) then
  begin
    Lum := Lum * AAWidth;
    AAWidth := 1;
  end;

  Result := round(AAWidth);
  MinX := RoundInt(X - LineWidth - AAWidth - 0.5);
  MaxX := RoundInt(X + LineWidth + AAWidth + 0.5);
  MinY := RoundInt(Y - LineWidth - AAWidth - 0.5);
  MaxY := RoundInt(Y + LineWidth + AAWidth + 0.5);

  with cbmp do
  begin
    bmWidth := Width;

    for YCount := MinY to MaxY do
    begin

      if (YCount >= 0) and (YCount < (Height)) then
      begin

        for XCount := MinX to MaxX do
        begin

          if (XCount >= 0) and (XCount < bmWidth) then
          begin

            DX := XCount - X;
            DY := YCount - Y;

            Distance := Hypot(DX, DY);

            if Distance < LineWidth then
              Alpha := PointAlpha * 0.75
            else
            begin

              if Distance > (LineWidth + AAWidth + 0.5) then
                Alpha := 0
              else
                Alpha := PointAlpha - PointAlpha * (Distance / (LineWidth + AAWidth + 0.5));

            end;

            col := GetPixel(XCount, YCount);
            ExistingPixelBlue := col.blue * 255;
            ExistingPixelGreen := col.green * 255;
            ExistingPixelRed := col.red * 255;

            OutLevelR := ExistingPixelRed * (1 - Alpha) + Lum * R * Alpha * UseContrast;
            NewPixelR := trunc(OutLevelR / 255);
            if NewPixelR > 255 then
              NewPixelR := 255;

            OutLevelG := ExistingPixelGreen * (1 - Alpha) + Lum * G * Alpha * UseContrast;
            NewPixelG := trunc(OutLevelG / 255);
            if NewPixelG > 255 then
              NewPixelG := 255;

            OutLevelB := ExistingPixelBlue * (1 - Alpha) + Lum * B * Alpha * UseContrast;
            NewPixelB := trunc(OutLevelB / 255);
            if NewPixelB > 255 then
              NewPixelB := 255;

            col.red := NewPixelR;
            col.green := NewPixelG;
            col.blue := NewPixelB;
            SetPixel(XCount, YCount, col);

          end;

        end; // XCount

      end;

    end; // YCount

  end;

end;

function TSplot.PlotStar(xx, yy: single; ma, b_v: double): integer;
begin

  Result := 0;

  if not cfgplot.Invisible then

    case cfgplot.starplot of
      0: Result := PlotStar0(xx, yy, ma, b_v);
      1: Result := PlotStar1(xx, yy, ma, b_v);
      2: Result := PlotStar2(xx, yy, ma, b_v);
    end;

end;

function TSplot.PlotVarStar(x, y: single; vmax, vmin: double): integer;
var
  ds, ds2, dsm, xx, yy: integer;
begin
  xx := round(x);
  yy := round(y);
  Result := 0;

  if not cfgplot.Invisible then
  begin

    // maxima
    ds := round(max(3, (cfgplot.starsize *
      (cfgchart.min_ma - vmax * cfgplot.stardyn / 80) / cfgchart.min_ma)) * cfgchart.drawsize) -
      cfgchart.drawpen;

    // minima
    dsm := round(max(3, (cfgplot.starsize *
      (cfgchart.min_ma - vmin * cfgplot.stardyn / 80) / cfgchart.min_ma)) * cfgchart.drawsize);

    if (ds - dsm) < 2 * cfgchart.drawpen then
      dsm := ds - 2 * cfgchart.drawpen;

    Result := trunc(ds / 2);

    if cfgplot.UseBMP then
    begin
      // external ellipse
      ds2 := trunc(ds / 2) + cfgchart.drawpen;
      cbmp.EllipseAntialias(x, y, ds2, ds2, ColorToBGRA(cfgplot.Color[0]), cfgchart.DrawPen);
      // external ellipse outline
      ds2 := trunc(ds / 2);
      cbmp.EllipseAntialias(x, y, ds2, ds2, ColorToBGRA(cfgplot.Color[11]), cfgchart.DrawPen);
      // internal ellipse
      ds2 := trunc(dsm / 2);
      cbmp.EllipseAntialias(x, y, ds2, ds2, ColorToBGRA(cfgplot.Color[0]), cfgchart.DrawPen);
    end
    else
    if cnv <> nil then
      with cnv do
      begin
        // external ellipse
        ds2 := trunc(ds / 2) + cfgchart.drawpen;
        Brush.Color := cfgplot.Color[0];
        Brush.style := bsSolid;
        Pen.Mode := pmCopy;
        Pen.Color := cfgplot.Color[0];
        Pen.Width := cfgchart.Drawpen;

        case ds of
          1..4: Ellipse(xx - 2 - cfgchart.drawpen, yy - 2 - cfgchart.drawpen, xx +
              2 + cfgchart.drawpen, yy + 2 + cfgchart.drawpen);
          5: Ellipse(xx - 2 - cfgchart.drawpen, yy - 2 - cfgchart.drawpen, xx + 3 +
              cfgchart.drawpen, yy + 3 + cfgchart.drawpen);
          6: Ellipse(xx - 3 - cfgchart.drawpen, yy - 3 - cfgchart.drawpen, xx + 3 +
              cfgchart.drawpen, yy + 3 + cfgchart.drawpen);
          7: Ellipse(xx - 3 - cfgchart.drawpen, yy - 3 - cfgchart.drawpen, xx + 4 +
              cfgchart.drawpen, yy + 4 + cfgchart.drawpen);
          else
            Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);
        end;

        // external ellipse outline
        ds2 := trunc(ds / 2);
        Pen.Color := cfgplot.Color[11];
        Pen.Width := 1;

        case ds of
          1..4: Ellipse(xx - 2, yy - 2, xx + 2, yy + 2);
          5: Ellipse(xx - 2, yy - 2, xx + 3, yy + 3);
          6: Ellipse(xx - 3, yy - 3, xx + 3, yy + 3);
          7: Ellipse(xx - 3, yy - 3, xx + 4, yy + 4);
          else
            Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);
        end;

        // internal ellipse
        ds2 := trunc(dsm / 2);
        Pen.Color := cfgplot.Color[0];
        Brush.Color := cfgplot.Color[11];

        case dsm of
          1..2: ;
          3: Ellipse(xx - 1, yy - 1, xx + 2, yy + 2);
          4: Ellipse(xx - 2, yy - 2, xx + 2, yy + 2);
          5: Ellipse(xx - 2, yy - 2, xx + 3, yy + 3);
          6: Ellipse(xx - 3, yy - 3, xx + 3, yy + 3);
          7: Ellipse(xx - 3, yy - 3, xx + 4, yy + 4);
          else
            Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);
        end;

      end;

  end;

end;

function TSplot.PlotDblStar(x, y, r: single; ma, sep, pa, b_v: double): integer;
var
  ds, xx, yy: integer;
begin
  Result := 0;

  xx := round(x);
  yy := round(y);

  if cfgplot.UseBMP then
  begin
    ds := PlotStar(x, y, ma, b_v);
    result:=ds;
    if r>max(5*cfgchart.drawsize,2*ds) then begin
       BGRADrawLine(x, y, x - round(r * sin(pa)), y - round(r * cos(pa)), ColorToBGRA(cfgplot.Color[15]), 1, cbmp)
    end
    else begin
       BGRADrawLine(x - ds-2*cfgchart.drawsize, y, x - ds, y , ColorToBGRA(cfgplot.Color[15]), 1, cbmp);
       BGRADrawLine(x + ds, y, x + ds+2*cfgchart.drawsize, y , ColorToBGRA(cfgplot.Color[15]), 1, cbmp);
    end;
  end
  else
  if cnv <> nil then
    with cnv do
    begin
      ds := PlotStar(x, y, ma, b_v);
      result:=ds;
      Pen.Width := 1;
      Pen.Color := cfgplot.Color[15];
      Brush.style := bsSolid;
      Pen.Mode := pmCopy;
      if r>max(5*cfgchart.drawsize,2*ds) then begin
        MoveTo(xx - round(r * sin(pa)), yy - round(r * cos(pa)));
        LineTo(xx, yy);
      end
      else begin
        Pen.Width := cfgchart.drawsize;
        MoveTo(xx - ds-2*cfgchart.drawsize, yy);
        LineTo(xx - ds, yy);
        MoveTo(xx + ds, yy);
        LineTo(xx + ds+2*cfgchart.drawsize, yy);
      end;
    end;
end;

procedure TSplot.PlotDeepSkyObject(Axx, Ayy: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; whitebg: boolean; forcecolor: boolean;
  col: Tcolor = clWhite; alpha:byte=255);
begin
{
  Here's where we break out the plot routines for each type of deep sky object
  we do it this way so that we can (in future) plot using different symbol sets
  it also clears the way for introducing more deep sky object types based on the CdS
  heirarchy.
}
  if not cfgplot.Invisible then  // if its above the horizon...
  begin
    case Atyp of
      -1: // special case equating to catalog entry of '-' or 'PD'
        PlotDSOUnknown(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      0: // unknown - general case where catalog entry is '?' or spaces
        PlotDSOUnknown(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      //        1:  // galaxy - not called from here, they are plotted back in cu_skychart.DrawDeepSkyObject
      2:  // open cluster
        PlotDSOOcl(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col, alpha);
      4:  // planetary
        PlotDSOPNe(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col, alpha);
      3:  // globular cluster
        PlotDSOGCl(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col, alpha);
      5:  // bright nebula (emission and reflection)
        PlotDSOBN(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col, alpha);
      6:  // cluster with nebula
        PlotDSOClNb(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col, alpha);
      7:  // star
        PlotDSOStar(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      8:  // double star
        PlotDSODStar(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      9:  // triple star
        PlotDSOTStar(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      10: // asterism
        PlotDSOAst(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col, alpha);
      11: // Knot (more accurately as an HII region e.g. in M101, M33 and the LMC)
        PlotDSOHIIRegion(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col, alpha);
      12: // galaxy cluster
        PlotDSOGxyCl(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col);
      13: // dark nebula
        PlotDSODN(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, Amorph, forcecolor, col);
      14: // Circle
        PlotDSOCircle(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      15: // Rectangle
        PlotDSORectangle(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      16: // lozenge
        PlotDSOlozenge(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
      17: // Duplicate
        ;// do not plot anything
      101..111: // Planet from ds2000
        PlotPlanet4(round(Axx), round(Ayy), Atyp - 100, Apixscale, 0, WhiteBg);
      112:  // Asteroid from ds2000
        PlotAsteroid(Axx, Ayy, 0, Ama);
      113: // Comet from ds2000
        PlotComet(Axx, Ayy, 0, 0, 0, Ama, 0, 0);
      114: // var star from ds2000
        PlotVarStar(Axx, Ayy, Ama, Ama + 1);
      115: // star from ds2000
        PlotStar(Axx, Ayy, Ama, 0);
      else
        PlotDSOUnknown(Axx, Ayy, Adim, Ama, Asbr, Apixscale, Atyp, forcecolor, col);
    end;

  end;

end;


procedure TSplot.PlotSimMark(x, y: single; mcolor: Tcolor);
var
  ds, xx, yy: integer;
  c: TBGRAPixel;
begin

  if (abs(x) > MaxInt) or (abs(y) > MaxInt) then
    exit;

  ds := 3 * cfgchart.drawsize;
  xx := round(x);
  yy := round(y);

  if cfgplot.UseBMP then
  begin
    ds:=DoScaleX(ds);
    c := ColorToBGRA(mcolor);
    cbmp.DrawHorizLine(xx - ds, yy, xx + ds, c);
    cbmp.DrawVertLine(xx, yy - ds, yy + ds, c);
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := mcolor;
    cnv.MoveTo(xx - ds, yy);
    cnv.LineTo(xx + ds, yy);
    cnv.MoveTo(xx, yy - ds);
    cnv.LineTo(xx, yy + ds);
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;
end;

procedure TSplot.PlotLine(x1, y1, x2, y2: single; lcolor, lwidth: integer;
  style: TFPPenStyle = psSolid);
begin

  if (abs(x1 - cfgchart.hw) < cfgplot.outradius) and
    (abs(y1 - cfgchart.hh) < cfgplot.outradius) and
    (abs(x2 - cfgchart.hw) < cfgplot.outradius) and
    (abs(y2 - cfgchart.hh) < cfgplot.outradius) then
  begin

    if lwidth = 0 then
      lwidth := 1
    else
      lwidth := lwidth * cfgchart.drawpen;

    if cfgplot.UseBMP then
      BGRADrawLine(x1, y1, x2, y2, ColorToBGRA(lcolor), lwidth, cbmp, style)
    else
    if cnv <> nil then
      with cnv do
      begin
        Pen.Width := lwidth;
        Brush.Style := bsClear;
        Brush.Color := cfgplot.backgroundcolor;
        Pen.Mode := pmCopy;
        Pen.Color := lcolor;
        Pen.Style := style;
      {$ifdef mswindows}
        if style <> psSolid then
          Pen.Width := 1;
      {$endif}
        MoveTo(round(x1), round(y1));
        LineTo(round(x2), round(y2));
        Pen.Style := psSolid;
        Pen.Width := 1;
      end;

  end;

end;

function TSplot.PlotOutline(x, y: single; op, lw, fs, closed: integer; r2: double; col: Tcolor; sbmp:TBGRABitmap=nil; salpha:integer=255): boolean;
var
  xx, yy, l: integer;
  outlineptsf,Spline: array of TPointf;

  function SingularPolygon: boolean;
  var
    i, j, k: integer;
    newpoint: boolean;
    x: array[1..3] of double;
    y: array[1..3] of double;
  begin

    Result := True;
    k := 1;

    for j := 1 to 3 do
    begin
      x[j] := maxdouble;
      y[j] := maxdouble;
    end;

    for i := 0 to outlinenum - 1 do
    begin

      newpoint := False;
      for j := 1 to 3 do
      begin
        if outlinepts[i].x <> x[j] then
          newpoint := True;
        if outlinepts[i].y <> y[j] then
          newpoint := True;
        if newpoint then
          break;
      end;

      if newpoint then
      begin
        x[k] := outlinepts[i].x;
        y[k] := outlinepts[i].y;
        Inc(k);
      end;

      if k > 3 then
      begin
        Result := False;
        break;
      end;

    end;

  end;

  procedure addpoint(x, y: integer);
  begin

    // add a point to the line
    if (outlinenum + 1) >= outlinemax then
    begin
      outlinemax := outlinemax + 100;
      setlength(outlinepts, outlinemax);
    end;

    outlinepts[outlinenum].x := x;
    outlinepts[outlinenum].y := y;
    Inc(outlinenum);
  end;

  function processpoint(xx, yy: integer): boolean;
  var
    x1, y1, x2, y2: integer;
    clip1, clip2: boolean;
  begin

    // find if we can plot this point
    if outlineinscreen and (abs(xx - cfgchart.hw) < cfgplot.outradius) and
      (abs(yy - cfgchart.hh) < cfgplot.outradius) and
      ((intpower(outx1 - xx, 2) + intpower(outy1 - yy, 2)) < r2) then
    begin

      // begin at last point
      addpoint(outx1, outy1);
      x1 := outx1;
      y1 := outy1;
      x2 := xx;
      y2 := yy;

      // find if clipping is necessary
      ClipVector(x1, y1, x2, y2, clip1, clip2);

      if clip1 then
        addpoint(x1, y1);
      if clip2 then
        addpoint(x2, y2);

      // set last point
      outx1 := xx;
      outy1 := yy;
      Result := True;

    end
    else
    begin
      // point outside safe area, ignore the whole object.
      outlineinscreen := False;
      Result := False;
    end;
  end;

begin
  result:=false;
  xx := RoundInt(x);
  yy := RoundInt(y);

  if not cfgplot.Invisible then
  begin

    case op of

      0:
      begin // init vector
        // set line options
        outlinetype := fs;
        outlinenum := 0;
        outlinecol := col;
        outlinelw := lw;
        outlineclosed := (closed = 1);
        outlineinscreen := True;
        outlinemax := 100;
        setlength(outlinepts, outlinemax);
        // initialize first point
        outx0 := xx;
        outy0 := yy;
        outx1 := xx;
        outy1 := yy;
      end;

      1:
      begin // close and draw vector
        // process last point
        if outlineclosed then
        begin
          processpoint(xx, yy);
          if processpoint(outx0, outy0) then
            addpoint(outx1, outy1);
        end
        else if processpoint(xx, yy) then
          addpoint(outx1, outy1);

        // only start and end point is defined
        if outlinenum=2 then
          addpoint(outx1, outy1);

        if outlineinscreen and (outlinenum >= 2) and (not SingularPolygon) then
        begin
          // object is to be draw
          Dec(outlinenum);
          if outlinecol = cfgplot.bgColor then
            outlinecol := outlinecol xor clWhite;
          outlinemax := outlinenum + 1;
          if (cfgplot.nebplot = 0) and ((outlinetype = 2)or(outlinetype = 3)) then
            outlinetype := 0;
          if (cfgchart.onprinter) and (outlinetype = 1) then
            outlinetype := 0;

          if cfgplot.UseBMP then
          begin

            setlength(outlinepts, outlinenum + 1);
            setlength(outlineptsf, outlinenum + 1);

            for l := 0 to outlinenum do
            begin
              outlineptsf[l].x := outlinepts[l].x;
              outlineptsf[l].y := outlinepts[l].y;
            end;

            case outlinetype of

              0:
              begin
                cbmp.DrawPolyLineAntialias(outlineptsf, ColorToBGRA(outlinecol), outlinelw * cfgchart.drawpen, True);
              end;
              1:
              begin
                Spline := cbmp.ComputeClosedSpline(outlineptsf,ssEasyBezier);
                cbmp.DrawPolygonAntialias(Spline, ColorToBGRA(outlinecol), outlinelw * cfgchart.drawpen);
              end;

              2:
              begin
                if sbmp=nil then begin
                  Spline := cbmp.ComputeClosedSpline(outlineptsf,ssEasyBezier);
                  cbmp.DrawPolygonAntialias(Spline, ColorToBGRA(outlinecol,salpha), outlinelw * cfgchart.drawpen, ColorToBGRA(outlinecol,salpha));
                end
                else begin
                  result:=true;
                  Spline := sbmp.ComputeClosedSpline(outlineptsf,ssEasyBezier);
                  sbmp.DrawPolygonAntialias(Spline, ColorToBGRA(outlinecol,salpha), outlinelw * cfgchart.drawpen, ColorToBGRA(outlinecol,salpha));
               end;
              end;
              3:
              begin
                cbmp.DrawPolygonAntialias(outlineptsf, ColorToBGRA(outlinecol,salpha), outlinelw * cfgchart.drawpen, ColorToBGRA(outlinecol,salpha));
              end;
            end;

          end
          else
          begin
            cnv.Pen.Mode := pmCopy;
            cnv.Pen.Width := outlinelw * cfgchart.drawpen;
            cnv.Pen.Color := outlinecol;
            cnv.Brush.Style := bsSolid;
            cnv.Brush.Color := outlinecol;

            case outlinetype of

              0:
              begin
                setlength(outlinepts, outlinenum + 1);
                cnv.polyline(outlinepts);
              end;

              1: Bezierspline(outlinepts, outlinenum + 1);

              2,3:
              begin
                setlength(outlinepts, outlinenum + 1);
                cnv.polygon(outlinepts);
              end;

            end;

          end;

        end;

      end;

      2:
      begin // add point
        processpoint(xx, yy);
      end;

    end; // case op

  end;  // not invisible

end;

procedure TSplot.BezierSpline(pts: array of Tpoint; n: integer);
var
  p: array of TPoint;
  pf: array of TPointF;
  i, m: integer;

  function LC(Pt1, Pt2: TPoint; c1, c2: extended): TPoint;
  begin

    Result := Point(round(Pt1.x * c1 + (Pt2.x - Pt1.x) * c2),
      round(Pt1.y * c1 + (Pt2.y - Pt1.y) * c2));
  end;

begin

  m := 3 * (n - 1);
  setlength(p, 1 + m);
  p[0] := pts[0];

  for i := 0 to n - 3 do
  begin
    p[3 * i + 1] := LC(pts[i], pts[i + 1], 1, 1 / 3);
    p[3 * i + 2] := LC(pts[i + 1], pts[i + 2], 1, -1 / 3);
    p[3 * i + 3] := pts[i + 1];
  end;

  p[m - 2] := LC(pts[n - 2], pts[n - 1], 1, 1 / 3);
  p[m - 1] := LC(pts[n - 1], pts[0], 1, 1 / 3);
  p[m] := pts[n - 1];

  if not cfgplot.UseBMP then
    cnv.PolyBezier(p)
  else
    raise(Exception.Create('Do not use TSplot.BezierSpline on BGRAbitmap'));

end;

procedure TSplot.PlotPlanet(x, y: single; flipx, flipy, ipla: integer;
  jdt, pixscale, diam, flatten, magn, phase, pa, rot, poleincl, sunincl, w, r1, r2, be: double;
  WhiteBg: boolean; size: integer = 0; margin: integer = 0);
var
  b_v: double;
  ds, n, xx, yy: integer;
begin

  xx := RoundInt(x);
  yy := RoundInt(y);

  if not cfgplot.Invisible then
  begin

    n := cfgplot.plaplot;
    ds := round(diam * pixscale / 2) * cfgchart.drawsize;

    if ((xx + ds) > 0) and ((xx - ds) < cfgchart.Width) and ((yy + ds) > 0) and
      ((yy - ds) < cfgchart.Height) then
    begin

      if ((n = 2) or (n = 1)) and (ds < 5) then
        n := 0;
      if ((not use_xplanet)) and (n = 2) then
        n := 1;

      case n of

        0:
        begin // magn

          if ipla < 11 then
            b_v := planetcolor[ipla]
          else
            b_v := 1020;

          PlotStar(x, y, magn, b_v);

        end;

        1:
        begin // diam

          PlotPlanet1(xx, yy, flipx, flipy, ipla, pixscale, diam, flatten,
            phase, pa, rot, poleincl, sunincl);

          if ipla = C_Saturn then
            PlotSatRing1(xx, yy, pixscale, pa, rot, r1, r2, diam, flipy * be, WhiteBg);

        end;

        2:
        begin // image

          rot := rot * FlipX * FlipY;

          if (ipla = C_Sun) and (size > 0) then
            PlotPlanet5(xx, yy, flipx, flipy, ipla, jdt, pixscale, diam,
              flatten, rot, WhiteBg, size, margin)
          else
            PlotPlanet3(xx, yy, flipx, flipy, ipla, jdt, pixscale, diam,
              flatten, pa + rad2deg * rot, r1, WhiteBg);

        end;

        3:
        begin // symbol

          PlotPlanet4(xx, yy, ipla, pixscale, phase, WhiteBg);

        end;

      end;

    end;

  end;

end;

procedure TSplot.PlotPlanet1(xx, yy, flipx, flipy, ipla: integer;
  pixscale, diam, flatten, phase, pa, rot, poleincl, sunincl: double); // ellipse
var
  ds, ico: integer;
  col: TBGRAPixel;
  p: array[0..23] of TPointF;
  pp: array[0..23] of TPoint;
  ds1, ds2, n, ex1, ey1, fx, fy: integer;
  th, ex, ey, sph: double;
  ci, si: extended;
  plotphase, fillphase: boolean;
begin

  ds := round(max(diam * pixscale / 2, 2 * cfgchart.drawpen));

  case Ipla of

    1: ico := 4;
    2: ico := 2;
    3: ico := 2;
    4: ico := 6;
    5: ico := 4;
    6: ico := 4;
    7: ico := 1;
    8: ico := 1;
    9: ico := 2;
    10: ico := 4;
    11: ico := 2;
    else
      ico := 2;
  end;

  plotphase := False;
  fillphase := False;
  fx := 0;
  fy := 0;
  p[0].x := 0;

  if (ipla = C_Moon) and (phase > -900) then
  begin
    ds1 := ds;
    ds2 := round(-cos(deg2rad * phase) * ds1);
    sincos(-(rot + deg2rad * (pa + sunincl)), si, ci);

    th := pi / 2;

    if phase < 180 then
      sph := -1
    else
      sph := 1;

    for n := 1 to 22 do
    begin
      ex := sph * ds2 * cos(th);
      ey := ds1 * sin(th);
      ey1 := round((ex * si - ey * ci) * flatten) + yy;
      ex1 := round(ex * ci + ey * si) + xx;
      p[n] := PointF(ex1, ey1);
      th := th + 0.15;
    end;

    p[0] := p[1];
    p[23] := p[22];
    if (phase > 180) then
    begin
      sincos(-(rot + deg2rad * (pa + sunincl)), si, ci);
      fx := round(xx + ds1 * ci);
      fy := round(yy + ds1 * si);
    end
    else
    begin
      sincos(pi - (rot + deg2rad * (pa + sunincl)), si, ci);
      fx := round(xx + ds1 * ci);
      fy := round(yy + ds1 * si);
    end;

    ex := fx - p[11].x;
    ey := fy - p[11].y;

    if sqrt(ex * ex + ey * ey) > 6 then
    begin
      fillphase := True;
      fx := round(fx - ex / 2);
      fy := round(fy - ey / 2);
    end
    else
      fillphase := False;

    if flipx <> flipy then
    begin

      if flipx < 0 then
      begin
        fx := 2 * xx - fx;
        for n := 0 to 23 do
          p[n].X := 2 * xx - p[n].X;
      end;

      if flipy < 0 then
      begin

        fy := 2 * yy - fy;
        for n := 0 to 23 do
          p[n].Y := 2 * yy - p[n].Y;

      end;

    end;

    plotphase := True;

  end;

  if cfgplot.UseBMP then
  begin

    if cfgplot.Color[11] > cfgplot.BgColor then
      col := ColorToBGRA(cfgplot.Color[ico + 1])
    else if cfgchart.onprinter then
      col := ColorToBGRA(cfgplot.BgColor)
    else
      col := ColorToBGRA(cfgplot.Color[11]);

    if cfgplot.TransparentPlanet then
      col := BGRAPixelTransparent
    else
      col.alpha := 255;

    cbmp.EllipseAntialias(xx, yy, ds, ds * flatten, ColorToBGRA(cfgplot.Color[11]),
      cfgchart.drawpen);
    cbmp.FillEllipseAntialias(xx, yy, ds, ds * flatten, col);

    if plotphase then
    begin
      col := ColorToBGRA(clGray);
      cbmp.DrawPolyLineAntialias(p, col, 2);

      if fillphase and (not cfgplot.TransparentPlanet) then
        cbmp.FloodFill(fx, fy, col, fmSet);
    end;

  end
  else
  if cnv <> nil then
    with cnv do
    begin

      if cfgplot.Color[11] > cfgplot.BgColor then
        Brush.Color := cfgplot.Color[ico + 1]

      else if cfgchart.onprinter then
        Brush.Color := cfgplot.BgColor
      else
        Brush.Color := cfgplot.Color[11];

      if cfgplot.TransparentPlanet then
        Brush.style := bsclear
      else
        Brush.style := bssolid;

      Pen.Width := cfgchart.drawpen;
      Pen.Color := cfgplot.Color[11];
      Pen.Mode := pmCopy;
      Ellipse(xx - ds, yy - round(ds * flatten), xx + ds, yy + round(ds * flatten));

      Pen.Color := cfgplot.Color[0];
      Brush.style := bsclear;
      ds := ds + cfgchart.drawpen;
      Ellipse(xx - ds, yy - round(ds * flatten), xx + ds, yy + round(ds * flatten));

      if plotphase then
      begin

        Pen.Color := clGray;
        for n := 0 to 23 do
        begin
          pp[n].X := round(p[n].X);
          pp[n].Y := round(p[n].Y);
        end;

        Polyline(pp);

      end;

    end;

end;

procedure TSplot.PlotImage(xx, yy: single; iWidth, iHeight, Rotation: double;
  flipx, flipy: integer; WhiteBg, iTransparent: boolean; var bgraibmp: TBGRABitmap;
  TransparentMode: integer = 0; forcealpha: integer = 0);
var
  zoom: single;
  DestX, DestY: integer;
  trWhiteBg: boolean;
  bgra1bmp: TBGRABitmap;
  transform: TBGRAAffineBitmapTransform;
begin

  if (iWidth < 2) or (iHeight < 2) then
    exit;

  zoom := iWidth / bgraibmp.Width;

  trWhiteBg := False;

  if cfgplot.UseBMP and WhiteBg then
  begin
    // invert color in SetBGRATransparencyFromLuminance
    WhiteBg := False;
    trWhiteBg := True;
  end;

  if (iWidth <= cfgchart.Width) or (iHeight <= cfgchart.Height) then
  begin
    // image smaller than chart, write in full

    if WhiteBg then
      bgraibmp.LinearNegative;

    // make new image with enough space for rotation
    bgra1bmp := TBGRABitmap.Create(round(1.5 * zoom * bgraibmp.Width),
      round(1.5 * zoom * bgraibmp.Height));
    transform := TBGRAAffineBitmapTransform.Create(bgraibmp, False);
    try
      // prepare transformation matrix
      // set rotation center
      transform.Translate(-bgraibmp.Width / 2, -bgraibmp.Height / 2);
      // rotate
      transform.RotateRad(Rotation);
      // put in center of new image
      transform.Translate(1.5 * bgraibmp.Width / 2, 1.5 * bgraibmp.Height / 2);
      if (flipx < 0) then
      begin
        // mirror x
        transform.scale(-1, 1);
        transform.Translate(1.5 * bgraibmp.Width, 0);
      end;
      if (flipy < 0) then
      begin
        // mirror y
        transform.scale(1, -1);
        transform.Translate(0, 1.5 * bgraibmp.Width);
      end;
      // zoom image
      transform.Scale(zoom);
      // apply transformation
      bgra1bmp.fill(transform);

      DestX := round(xx - bgra1bmp.Width / 2);
      DestY := round(yy - bgra1bmp.Height / 2);

      if cfgplot.UseBMP then
      begin

        if iTransparent then
        begin
          SetBGRATransparencyFromLuminance(bgra1bmp, TransparentMode,
            trWhiteBg, forcealpha);
          cbmp.PutImage(DestX, DestY, bgra1bmp, dmDrawWithTransparency);
        end
        else
          cbmp.PutImage(DestX, DestY, bgra1bmp, dmSet);

      end
      else
      begin

        cnv.CopyMode := cmSrcCopy;
        cnv.Draw(DestX, DestY, bgra1bmp.Bitmap);

      end;

    finally
      transform.Free;
      bgra1bmp.Free;
    end;

  end
  else
  begin

    // only a part of the image is displayed in the screen

    if WhiteBg then
      bgraibmp.LinearNegative;

    // make new image the size of the screen
    bgra1bmp := TBGRABitmap.Create(cfgchart.Width, cfgchart.Height);
    transform := TBGRAAffineBitmapTransform.Create(bgraibmp, False);
    try
      // prepare transformation matrix
      // set rotation center
      transform.Translate(-bgraibmp.Width / 2, -bgraibmp.Height / 2);
      // rotate
      transform.RotateRad(Rotation);
      // restore original center
      transform.Translate(bgraibmp.Width / 2, bgraibmp.Height / 2);
      if (flipx < 0) then
      begin
        // mirror x
        transform.scale(-1, 1);
        transform.Translate(bgraibmp.Width, 0);
      end;
      if (flipy < 0) then
      begin
        // mirror y
        transform.scale(1, -1);
        transform.Translate(0, bgraibmp.Width);
      end;
      // zoom image
      transform.Scale(zoom);
      // offset to request position
      transform.Translate(round(xx - bgraibmp.Width * zoom / 2), round(
        yy - bgraibmp.Height * zoom / 2));
      // apply transformation
      bgra1bmp.fill(transform);

      if cfgplot.UseBMP then
      begin

        if iTransparent then
        begin
          SetBGRATransparencyFromLuminance(bgra1bmp, TransparentMode,
            trWhiteBg, forcealpha);
          cbmp.PutImage(0, 0, bgra1bmp, dmDrawWithTransparency);
        end
        else
          cbmp.PutImage(0, 0, bgra1bmp, dmSet);

      end
      else
      begin

        cnv.CopyMode := cmSrcCopy;
        cnv.Draw(0, 0, bgra1bmp.Bitmap);

      end;

    finally
      transform.Free;
      bgra1bmp.Free;
    end;

  end;

end;

procedure TSplot.PlotBGImage(ibmp: TBitmap; WhiteBg: boolean; alpha: integer = 200);
var
  outbmp: TBGRABitmap;
  blacklevel: byte;
begin

  if cfgplot.UseBMP then
  begin

    outbmp := TBGRABitmap.Create(ibmp, False);

    if (outbmp.Width<>cbmp.Width)or(outbmp.Height<>cbmp.Height) then begin
      outbmp.ResampleFilter := rfBestQuality;
      BGRAReplace(outbmp,outbmp.Resample(cbmp.Width,cbmp.Height,rmFineResample));
    end;

    try
      blacklevel := MaxIntValue([cfgplot.backgroundcolor and $FF,
        (cfgplot.backgroundcolor div $100) and $FF, (cfgplot.backgroundcolor div
        $10000) and $FF]);

      if whitebg then
      begin
        // invert picture
        SetBGRATransparencyFromLuminance(outbmp, 3, WhiteBg, 255, -1);
      end;

      // set map transparency
      SetBGRATransparencyFromLuminance(cbmp, 3, False, alpha, blacklevel);

      // draw transparent map over the picture
      outbmp.PutImage(0, 0, cbmp, dmDrawWithTransparency);

      // draw the result back to the map
      cbmp.PutImage(0, 0, outbmp, dmSet);

    finally
      outbmp.Free;
    end;

  end
  else
  begin

    if DisplayIs32bpp then
      SetTransparencyFromLuminance(ibmp, 1, WhiteBg)
    else
      ibmp.TransparentColor := clBlack;

    cnv.CopyMode := cmSrcCopy;
    cnv.Draw(0, 0, ibmp);
  end;

end;

function TSplot.GetBodyImage(ipla: integer; ds: integer;
  jdt, flatten, gw, pa: double): integer;
var
  j, cpla, irc: integer;

  buf, searchdir, bsize: string;
  r: TStringList;
  XplanetImg, BGRA: TBGRABitmap;
  OutputFile, origin, target, config: string;
  f: TextFile;
  idx: integer;
  NewScan: boolean;

  procedure wrtconf(sats: array of integer);
  var
    i: integer;
  begin
    for i := low(sats) to high(sats) do
    begin
      buf := GetPlanetName(sats[i]);
      if sats[i] = ipla then
      begin
        WriteLn(f, '[' + buf + ']');
        WriteLn(f, 'image=' + buf + '.jpg');
        WriteLn(f, 'magnify=1');
        WriteLn(f, '');
      end
      else
      begin
        WriteLn(f, '[' + buf + ']');
        WriteLn(f, 'image=none');
        WriteLn(f, 'color={0,0,0}');
        WriteLn(f, 'magnify=0.001');
        WriteLn(f, '');
      end;
    end;
  end;

begin
  Result := -1;

  if not HasPlanetImage(ipla) then
    exit;

  idx := FCacheBMP.Search(IntToStr(ipla));

  if idx >= 0 then
  begin

    NewScan :=
      (abs(FCacheBMP.GetJD(idx) - jdt) > 0.000693) or
      (FCacheBMP.GetDiameter(idx) <> ds) or
      (abs(FCacheBMP.GetProt(idx) - pa) > 0.2) or
      ((idx = C_Jupiter) and (FCacheBMP.GetGRS(idx) <> gw));

    if NewScan then
    begin
      FCacheBMP.Delete(idx);
      idx := -1;
    end;

  end
  else
    NewScan := True;

  if NewScan then
  begin

    r := TStringList.Create;

    try

      searchdir := ScaledPlanetMapDir(ipla, ds);

      OutputFile := slash(Tempdir) + 'planet.png';

      bsize := Format('%dx%d', [ds, ds]);

      origin := GetPlanetName(C_Earth);
      target := GetPlanetName(ipla);

      // Special config to not show artefact around satellite during transit over main planet or during planet occultation
      cpla := GetPlanetParent(ipla);
      config := slash(TempDir) + 'tmp.config';
      AssignFile(f, config);
      Rewrite(f);
      WriteLn(f, '[default]');
      WriteLn(f, 'min_radius_for_label=10000');
      WriteLn(f, 'magnify=1');
      WriteLn(f, 'color={255,255,255}');
      WriteLn(f, '');
      wrtconf(Main_Bodies);
      case cpla of
        C_Mars: wrtconf(Mars_Sat);
        C_Jupiter: wrtconf(Jupiter_Sat);
        C_Saturn: wrtconf(Saturn_Sat);
        C_Uranus: wrtconf(Uranus_Sat);
        C_Neptune: wrtconf(Neptune_Sat);
        C_Pluto: wrtconf(Pluto_Sat);
      end;
      CloseFile(f);

      GetXplanet_Plain(
        Xplanetversion,
        searchdir,
        bsize,
        OutputFile,
        pa, gw, jdt, irc, r, '', 0, //Afov,
        True, False,     // UseOriginFile, UseLatLong,
        True, origin,    // UseOrigin, origin,
        True, target,    // UseTarget, target,
        0, 0,             // originLat, originLong,
        0, 0,             // targetLat, targetLong,
        '',
        '50',
        config,
        False,
        slash(Tempdir) + 'origin.txt'  // our origin file for parallax
        );

      if (irc = 0) and (FileExists(slash(Tempdir) + 'planet.png')) then
      begin

        xplanetimg := TBGRABitmap.Create(SysToUTF8(slash(Tempdir) + 'planet.png'));
        try

          chdir(appdir);

          if flatten = 1 then
            BGRA := TBGRABitmap.Create(XplanetImg)
          else
          begin
            BGRA := TBGRABitmap.Create(xplanetimg.Width, round(flatten * xplanetimg.Width));
            BGRA.StretchPutImage(rect(0, 0, BGRA.Width, BGRA.Height), XplanetImg, dmSet, 255);
          end;

          try

            // Limit to 8+1 images for now
            while FCacheBMP.Count > length(Saturn_Sat) + 1 do
              FCacheBMP.Delete(0);

            // Add new or replace existed
            idx := FCacheBMP.Add(IntToStr(ipla), BGRA, ds, jdt, gw, pa);

          finally
            BGRA.Free;
          end;

        finally
          XplanetImg.Free;
        end;

      end
      else
      begin // something go wrong with xplanet

        buf := '';

        if r.Count > 0 then

          for j := 0 to r.Count - 1 do
            buf := buf + r[j] + crlf;

        writetrace('Return code ' + IntToStr(irc) + ' from xplanet');
        writetrace(buf);

      end;

    finally
      r.Free;
    end;

  end;

  Result := idx;

end;

procedure TSplot.PlotPlanet3(xx, yy, flipx, flipy, ipla: integer;
  jdt, pixscale, diam, flatten, pa, gw: double; WhiteBg: boolean);
var
  ds, bds, mode: integer;
  ok: boolean;
  BGRA: TBGRABitmap;
  idx: integer;
begin

  ok := True;

  if ipla = C_Saturn then
    ds := round(max(2.2261 * diam * pixscale, 4 * cfgchart.drawpen))
  else
    ds := round(max(diam * pixscale, 4 * cfgchart.drawpen));

  // do not ask xplanet to make an image bigger than 1000x1000
  bds := min(ds, 1000);
  idx := GetBodyImage(ipla, bds, jdt, flatten, gw, pa);

  ok := idx >= 0;

  if ok then
  begin

    BGRA := FCacheBMP.GetBMP(idx);

    if BGRA <> nil then
    begin

      if cfgplot.TransparentPlanet then
        mode := 3
      else
        mode := 2;

      PlotImage(xx, yy, ds, ds * flatten, 0, flipx, flipy, WhiteBg, True, BGRA, mode, 200);

    end;

  end
  else
    PlotPlanet1(xx, yy, flipx, flipy, ipla, pixscale, diam, flatten, -999, 0, 0, 0, 0);

end;

procedure TSplot.PlotPlanet5(xx, yy, flipx, flipy, ipla: integer;
  jdt, pixscale, diam, flatten, rot: double; WhiteBg: boolean; size, margin: integer);
var
  ds, mode, dsf: integer;
  dt: double;
  rbmp: TBGRABitmap;
  fn: string;
  idx: integer;
  BGRA: TBGRABitmap;
  NewUpdate: boolean;
begin

  if size = 0 then
    exit;

  fn := slash(Tempdir) + 'sun.jpg';

  if not FileExists(fn) then
  begin  // use default image
    fn := slash(appdir) + slash('data') + slash('planet') + 'sun-0.jpg';
    size := 1024;
    margin := 107;
  end;

  if not FileExists(fn) then
  begin
    PlotPlanet1(xx, yy, flipx, flipy, ipla, pixscale, diam, flatten, -999, 0, 0, 0, 0);
    exit;
  end;

  ds := round(max(diam * pixscale, 4 * cfgchart.drawpen) * size / (size - 2 * margin));

  // check date of last downloaded image instead of current jd
  dt := FileAgeUTF8(fn);

  // check flattened diameter because the date do not change
  dsf := round(ds * flatten);

  try


    idx := FCacheBMP.Search(IntToStr(C_Sun));

    NewUpdate := idx < 0;

    if not NewUpdate then
      NewUpdate :=
        (FCacheBMP.GetJD(idx) <> dt) or (FCacheBMP.GetDiameter(idx) <> dsf);

    if NewUpdate then
    begin

      BGRA := TBGRABitmap.Create;

      try
        BGRA.LoadFromFileUTF8(SysToUTF8(fn));
        chdir(appdir);

        if flatten <> 1 then
        begin

          rbmp := BGRA.FilterRotate(pointf(BGRA.Width / 2, BGRA.Height / 2), rad2deg * rot) as
            TBGRABitmap;

          try

            BGRA.SetSize(size, round(flatten * BGRA.Width));
            BGRA.StretchPutImage(rect(0, 0, BGRA.Width, BGRA.Height), rbmp, dmSet, 255);

          finally

            rbmp.Free;
          end;

        end;

        FCacheBMP.Add(IntToStr(C_Sun), BGRA, dsf, dt);

      finally
        BGRA.Free;
      end;

    end;

    if cfgplot.TransparentPlanet then
      mode := 0
    else
      mode := 2;


    idx := FCacheBMP.Search(IntToStr(C_Sun));

    if idx >= 0 then
    begin

      BGRA := FCacheBMP.GetBMP(idx);

      if flatten <> 1 then
        rot := 0;

      PlotImage(xx, yy, ds, ds * flatten, rot, flipx, flipy, WhiteBg, True, BGRA, mode);

    end
    else
      PlotPlanet1(xx, yy, flipx, flipy, ipla, pixscale, diam, flatten, -999, 0, 0, 0, 0);

  except
    PlotPlanet1(xx, yy, flipx, flipy, ipla, pixscale, diam, flatten, -999, 0, 0, 0, 0);
    deletefile(fn);
  end;

end;

procedure TSplot.PlotPlanet4(xx, yy, ipla: integer; pixscale, phase: double; WhiteBg: boolean);
var
  symbol, ph: string;
  ds, mode: integer;
  sbmp: TBGRABitmap;
  path: string;
  PlanetBMP: TBGRAbitmap;

begin

  path := slash(appdir) + slash('data') + slash('planet') + 'symbol' + IntToStr(ipla);

  if ipla = C_Moon then
  begin

    ph := '';

    if (phase > 165) and (phase < 195) then
      ph := '_n'
    else if (phase > 50) and (phase <= 165) then
      ph := '_fq'
    else if (phase <= 50) or (phase > 310) then
      ph := '_f'
    else
      ph := '_lq';


    symbol := path + ph + '.png';

    if not fileexists(symbol) then
      symbol := path + '.png';

  end
  else
    symbol := path + '.png';

  if fileexists(symbol) then
  begin
    sbmp := TBGRABitmap.Create;
    planetbmp := TBGRABitmap.Create;
    try

      sbmp.LoadFromFile(symbol);

      PlanetBMP := sbmp.Resample(sbmp.Width * cfgchart.drawsize, sbmp.Height *
        cfgchart.drawsize) as TBGRABitmap;

    finally
      sbmp.Free;
    end;

    ds := PlanetBMP.Width;

    if cfgplot.TransparentPlanet then
      mode := 0
    else
    if ds = 20 then
      mode := 2
    else
      mode := 4;

    PlotImage(xx, yy, ds, ds, 0, 1, 1, WhiteBg, True, PlanetBMP, mode);

    planetbmp.Free;

  end;

end;

procedure TSplot.PlotEarthShadow(x, y: single; r1, r2, pixscale, flatten: double; forceline: boolean);
var
  ds1, ds2, xx, yy, xm, ym, mode: integer;
  mc: TBGRABitmap;
begin

  xx := round(x);
  yy := round(y);

  if not cfgplot.Invisible then
  begin

    ds1 := round(max(r1 * pixscale / 2, 2 * cfgchart.drawpen));
    ds2 := round(max(r2 * pixscale / 2, 2 * cfgchart.drawpen));

    if ((xx + ds2) > 0) and ((xx - ds2) < cfgchart.Width) and ((yy + ds2) > 0) and
      ((yy - ds2) < cfgchart.Height) then
    begin

      if cfgplot.UseBMP then
      begin

        if forceline then mode := 0
                     else mode := cfgplot.nebplot;

        case mode of

          0:

          begin
            cbmp.EllipseAntialias(x, y, ds1, ds1*flatten, ColorToBGRA(
              cfgplot.Color[11]), cfgchart.drawpen);
            cbmp.EllipseAntialias(x, y, ds2, ds2*flatten, ColorToBGRA(
              cfgplot.Color[11]), cfgchart.drawpen);
          end;

          1:

          begin

            mc := TBGRABitmap.Create(2 * ds2, 2 * ds2);

            try

              // mask=shadow to substract from the moon
              xm := ds2;
              ym := ds2;
              mc.Fill(BGRAPixelTransparent);
              mc.FillEllipseAntialias(xm, ym, ds2, ds2*flatten, ColorToBGRA(clRed, 5));
              mc.FillEllipseAntialias(xm, ym, ds1, ds1*flatten, ColorToBGRA(clRed, 10));
              // Apply the shadow
              cbmp.PutImage(xx - xm, yy - xm, mc, dmDrawWithTransparency);

            finally
              mc.Free;
            end;

          end;  // 1

        end; // case

      end
      else

      if cnv <> nil then
        with cnv do
        begin

          Pen.Width := cfgchart.drawpen;
          Pen.Color := clGray;
          Brush.style := bsClear;
          Ellipse(xx - ds1, yy - round(ds1*flatten), xx + ds1, yy + round(ds1*flatten));
          Brush.style := bsClear;
          Ellipse(xx - ds2, yy - round(ds2*flatten), xx + ds2, yy + round(ds2*flatten));
        end;

    end;  // if xx

  end;

end;

procedure TSplot.PlotSatel(x, y: single; ipla: integer; JD, pixscale, ma, diam, rot: double;
  hidesat, showhide, whitebg: boolean; flipx, flipy: integer);
var
  ds, ds2, xx, yy, n, mode: integer;
  ds1: single;
  idx: integer;
  b: TBGRABitmap;
begin

  ds := round(diam * pixscale / 2) * cfgchart.drawsize;

  n := cfgplot.plaplot;
  if ((n = 2) or (n = 1)) and (ds < 5) then
    n := 0;
  if ((not use_xplanet)) and (n = 2) then
    n := 1;
  if n = 3 then
    n := 0;

  xx := RoundInt(x);
  yy := RoundInt(y);

  if ((xx + ds) > 0) and ((xx - ds) < cfgchart.Width) and ((yy + ds) > 0) and
    ((yy - ds) < cfgchart.Height) then
  begin

    if not cfgplot.Invisible then

      if not (hidesat xor showhide) then
      begin
        ds := round(max(10, (cfgplot.starsize *
          (cfgchart.min_ma - ma * cfgplot.stardyn / 80) / cfgchart.min_ma)) * cfgchart.drawsize);
        ds2 := round(diam * pixscale);

        if (n <> 0) and (ds2 > ds) then
        begin
          ds1 := ds2 / 2;
          if cfgplot.UseBMP then
          begin

            rot := rad2deg * rot * flipx * flipy;

            if n = 2 then
              idx := GetBodyImage(ipla, ds2, JD, 1, 0, rot)
            else
              idx := -1;

            if idx >= 0 then
            begin
              b := FCacheBMP.GetBMP(idx);

              if cfgplot.TransparentPlanet then
                mode := 0
              else
                mode := 2;

              PlotImage(xx, yy, b.Width, b.Height, 0, flipx, flipy, whitebg, True, b, mode);

            end
            else
            begin
              cbmp.FillEllipseAntialias(x, y, ds1, ds1, ColorToBGRA(cfgplot.Color[20]));
              cbmp.EllipseAntialias(x, y, ds1, ds1, ColorToBGRA(cfgplot.Color[0]),
                cfgchart.drawpen);
            end;

          end
          else

          if cnv <> nil then
            with cnv do
            begin
              Pen.Color := cfgplot.Color[0];
              Pen.Width := cfgchart.drawpen;
              Brush.style := bsSolid;
              Pen.Mode := pmCopy;
              brush.color := cfgplot.Color[20];
              ds2 := round(ds / 2);

              if ((xx + ds) > 0) and ((xx - ds) < cfgchart.Width) and ((yy + ds) > 0) and
                ((yy - ds) < cfgchart.Height) then
              begin

                case ds of
                  1..2: Ellipse(xx, yy, xx + ds, yy + ds);
                  3: Ellipse(xx - 1, yy - 1, xx + 2, yy + 2);
                  4: Ellipse(xx - 2, yy - 2, xx + 2, yy + 2);
                  5: Ellipse(xx - 2, yy - 2, xx + 3, yy + 3);
                  6: Ellipse(xx - 3, yy - 3, xx + 3, yy + 3);
                  7: Ellipse(xx - 3, yy - 3, xx + 4, yy + 4);
                  else
                    Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);

                end;

              end;

            end;

        end
        else
          PlotStar(x, y, ma, 1020);

      end;
  end;

end;

procedure TSplot.PlotSatRing1(xx, yy: integer; pixscale, pa, rot, r1, r2, diam, be: double;
  WhiteBg: boolean);

const
  fr: array [1..5] of double = (1, 0.8801, 0.8599, 0.6650, 0.5486);

var
  step: double;
  ds1, ds2: integer;
  ex, ey, th: double;
  n, ex1, ey1, ir, R: integer;
  exf0, eyf0, exf1, eyf1: single;
  col, rcol: TBGRAPixel;

begin

  pa := deg2rad * pa + rot - pid2;
  ds1 := round(max(pixscale * r1 / 2, cfgchart.drawpen)) + cfgchart.drawpen;
  ds2 := round(max(pixscale * r2 / 2, cfgchart.drawpen)) + cfgchart.drawpen;
  R := round(diam * pixscale / 2);
  step := pi2 / 50;

  if cfgplot.UseBMP then
  begin
    col := ColorToBGRA(cfgplot.Color[5]);
    exf0 := 0;
    eyf0 := 0;

    if WhiteBg then
      col := ColorToBGRA(clBlack);

    for ir := 1 to 5 do
    begin
      th := 0;

      for n := 0 to 50 do
      begin
        ex := (ds1 * fr[ir]) * cos(th);
        ey := (ds2 * fr[ir]) * sin(th);
        exf1 := ex * sin(pa) - ey * cos(pa) + xx;
        eyf1 := ex * cos(pa) + ey * sin(pa) + yy;

        if n = 0 then
        begin
          exf0 := exf1;
          eyf0 := eyf1;
        end
        else
        begin

          if sqrt(ex * ex + ey * ey) < 1.1 * R then
            if be < 0 then
              if n <= 25 then
                rcol := ColorToBGRA(clBlack)
              else
                rcol := col
            else if n > 25 then
              rcol := ColorToBGRA(clBlack)
            else
              rcol := col
          else
            rcol := col;

          BGRADrawLine(exf0, eyf0, exf1, eyf1, rcol, cfgchart.drawpen, cbmp);
          exf0 := exf1;
          eyf0 := eyf1;
        end;

        th := th + step;
      end;

    end;

  end
  else
  if cnv <> nil then
    with cnv do
    begin

      Pen.Width := cfgchart.drawpen;
      Brush.Color := cfgplot.Color[0];
      Pen.Color := cfgplot.Color[5];

      if WhiteBg then
        Pen.Color := clBlack;

      Pen.mode := pmCopy;

      for ir := 1 to 5 do
      begin
        th := 0;

        for n := 0 to 50 do
        begin

          ex := (ds1 * fr[ir]) * cos(th);
          ey := (ds2 * fr[ir]) * sin(th);

          ex1 := round(ex * sin(pa) - ey * cos(pa)) + xx;
          ey1 := round(ex * cos(pa) + ey * sin(pa)) + yy;

          if n = 0 then
            moveto(ex1, ey1)
          else
          begin

            if cfgchart.onprinter and WhiteBg then
            begin   // !! pmNot not supported by some printer

              if sqrt(ex * ex + ey * ey) < 1.1 * R then
                if be < 0 then
                  if n <= 25 then
                    Pen.Color := clBlack
                  else
                    Pen.Color := clWhite
                else if n > 25 then
                  Pen.Color := clBlack
                else
                  Pen.Color := clWhite
              else
                Pen.Color := clBlack;
            end
            else
            if sqrt(ex * ex + ey * ey) < 1.1 * R then
              if be < 0 then
                if n <= 25 then
                  Pen.mode := pmNot
                else
                  Pen.mode := pmCopy
              else if n > 25 then
                Pen.mode := pmNot
              else
                Pen.mode := pmCopy
            else
              Pen.mode := pmCopy;

            lineto(ex1, ey1);

          end;

          th := th + step;
        end;

      end;

      Pen.mode := pmCopy;
    end;

end;

procedure TSplot.PlotAsteroid(x, y: single; symbol: integer; ma: double);
var
  ds, xx, yy: integer;
  diamond: array[0..3] of TPoint;
  diamondf: array[0..3] of TPointf;
begin

  case symbol of

    0:
    begin

      ds := 3 * cfgchart.drawsize;

      if cfgplot.UseBMP then
      begin
        ds := DoScaleX(ds);
        diamondf[0] := pointf(x, y - ds);
        diamondf[1] := pointf(x + ds, y);
        diamondf[2] := pointf(x, y + ds);
        diamondf[3] := pointf(x - ds, y);
        cbmp.FillPolyAntialias(diamondf, ColorToBGRA(cfgplot.Color[20]));
        cbmp.DrawPolygonAntialias(diamondf, ColorToBGRA(cfgplot.Color[0]),
          cfgchart.DrawPen);
      end
      else if cnv <> nil then
        with cnv do
        begin
          xx := round(x);
          yy := round(y);
          Pen.Color := cfgplot.Color[0];
          Pen.Width := cfgchart.DrawPen;
          Pen.Mode := pmCopy;
          Brush.Color := cfgplot.Color[20];
          Brush.style := bsSolid;
          diamond[0] := point(xx, yy - ds);
          diamond[1] := point(xx + ds, yy);
          diamond[2] := point(xx, yy + ds);
          diamond[3] := point(xx - ds, yy);
          Polygon(diamond);
        end;

    end;

    1:
    begin
      plotstar(x, y, ma, 1020);
    end;

  end;

end;

procedure TSplot.PlotComet(x, y, cx, cy: single; symbol: integer; ma, diam, PixScale: double);
var
  ds, ds1, xx, yy, cxx, cyy, i, j, co: integer;
  cp1, cp2: array[0..3] of TPoint;
  cpf1, cpf2: array[0..3] of TPointf;
  cr, cg, cb, ctr, ctg, ctb: byte;
  Col: Tcolor;
  colb: TBGRAPixel;
  dx, dy, a, r, k: double;
begin

  xx := round(x);
  yy := round(y);
  cxx := round(cx);
  cyy := round(cy);
  dx := cxx - xx;
  dy := cyy - yy;

  if (symbol = 1) and (cfgplot.nebplot = 0) then
    symbol := 2;

  if cfgplot.UseBMP then
  begin

    case symbol of

      0:
      begin
        colb := ColorToBGRA(cfgplot.Color[21]);
        ds := 2 * cfgchart.drawsize;
        cbmp.FillEllipseAntialias(x, y, ds, ds, colb);
        cbmp.EllipseAntialias(x, y, ds, ds, ColorToBGRA(cfgplot.Color[0]),
          cfgchart.DrawPen);
        BGRADrawLine(x, y, x - 4 * ds, y - 4 * ds, colb, cfgchart.DrawPen, cbmp);
        BGRADrawLine(x, y, x - 2 * ds, y - 4 * ds, colb, cfgchart.DrawPen, cbmp);
        BGRADrawLine(x, y, x - 4 * ds, y - 2 * ds, colb, cfgchart.DrawPen, cbmp);
      end;

      1:
      begin
        r := sqrt(dx * dx + dy * dy);
        r := max(r, 12 * cfgchart.drawpen);
        a := arctan2(dy, dx);

        if ma < 5 then
          k := 1
        else if ma > 18 then
          k := 0.5
        else
          k := 1 - (ma - 5) * 0.05;

        cr := round(k * (cfgplot.Color[21] and $FF));
        cg := round(k * ((cfgplot.Color[21] shr 8) and $FF));
        cb := round(k * ((cfgplot.Color[21] shr 16) and $FF));
        ctr := cr div 2;
        ctg := cg div 2;
        ctb := cb div 2;

        // tail
        if r > 30 then
        begin

          if (dx <> 0) or (dy <> 0) then
            for i := 0 to 9 do
            begin
              cpf1[2].X := x;
              cpf1[2].Y := y;
              cpf1[3].X := x;
              cpf1[3].Y := y;
              cpf2 := cpf1;
              r := 0.99 * r;

              for j := 0 to 19 do
              begin
                //          co:=max(0,255-i*20-j*13);
                co := max(0, round(200 - ln(i + j + 1) * 55));
                Col := (ctr * co div 255) + 256 * (ctg * co div 255) + 65536 * (ctb * co div 255);
                Col := Addcolor(Col, cfgplot.backgroundcolor);
                colb := ColorToBGRA(Col, Co);
                cpf1[0].X := cpf1[3].X;
                cpf1[0].Y := cpf1[3].Y;
                cpf1[1].X := cpf1[2].X;
                cpf1[1].Y := cpf1[2].Y;
                cpf1[2].X := x + ((j + 1) * r / 20 * cos(a + 0.015 * (i)));
                cpf1[2].Y := y + ((j + 1) * r / 20 * sin(a + 0.015 * (i)));
                cpf1[3].X := x + ((j + 1) * 0.99 * r / 20 * cos(a + 0.015 * (i + 1)));
                cpf1[3].Y := y + ((j + 1) * 0.99 * r / 20 * sin(a + 0.015 * (i + 1)));

                if (abs(cpf1[2].X - cpf1[3].X) > 1) or (abs(cpf1[2].Y - cpf1[3].Y) > 1) then
                  cbmp.FillPoly(cpf1, colb, dmDrawWithTransparency)
                else
                  BGRADrawLine(cpf1[0].X, cpf1[0].Y, cpf1[2].X, cpf1[2].Y,
                    colb, cfgchart.DrawPen, cbmp);

                cpf2[0].X := cpf2[3].X;
                cpf2[0].Y := cpf2[3].Y;
                cpf2[1].X := cpf2[2].X;
                cpf2[1].Y := cpf2[2].Y;
                cpf2[2].X := x + ((j + 1) * r / 20 * cos(a - 0.015 * (i)));
                cpf2[2].Y := y + ((j + 1) * r / 20 * sin(a - 0.015 * (i)));
                cpf2[3].X := x + ((j + 1) * 0.99 * r / 20 * cos(a - 0.015 * (i + 1)));
                cpf2[3].Y := y + ((j + 1) * 0.99 * r / 20 * sin(a - 0.015 * (i + 1)));

                if (abs(cpf2[2].X - cpf2[3].X) > 1) or (abs(cpf2[2].Y - cpf2[3].Y) > 1) then
                  cbmp.FillPoly(cpf2, colb, dmDrawWithTransparency)
                else
                  BGRADrawLine(cpf2[0].X, cpf2[0].Y, cpf2[2].X, cpf2[2].Y,
                    colb, cfgchart.DrawPen, cbmp);

              end;

            end;

        end;

        // coma
        ds := round(max(PixScale * diam / 2, 2 * cfgchart.drawpen));
        for i := 19 downto 0 do
        begin
          //         co:=max(0,255-i*13);
          co := max(0, round(200 - ln(i + 1) * 60));
          Col := (cr * co div 255) + 256 * (cg * co div 255) + 65536 * (cb * co div 255);
          Col := Addcolor(Col, cfgplot.backgroundcolor);
          colb := ColorToBGRA(Col, Co);
          ds1 := round((i + 1) * ds / 20);
          cbmp.FillEllipseAntialias(x, y, ds1, ds1, colb);
        end;

        // nucleus
        PlotStar(x, y, ma + 3, 1021);
      end;

      2:
      begin
        colb := ColorToBGRA(cfgplot.Color[21]);
        ds := round(max(3, (cfgplot.starsize *
          (cfgchart.min_ma - ma * cfgplot.stardyn / 80) / cfgchart.min_ma)) * cfgchart.drawsize / 2);
        cbmp.FillEllipseAntialias(x, y, ds, ds, colb);
        cbmp.EllipseAntialias(x, y, ds, ds, ColorToBGRA(cfgplot.Color[0]),
          cfgchart.DrawPen);
        ds := round(max(PixScale * diam / 2, 2 * cfgchart.drawpen));
        cbmp.EllipseAntialias(x, y, ds, ds, colb, cfgchart.DrawPen);
        ds := ds + cfgchart.drawpen;
        cbmp.EllipseAntialias(x, y, ds, ds, ColorToBGRA(cfgplot.Color[0]),
          cfgchart.DrawPen);
        r := sqrt(dx * dx + dy * dy);
        r := max(r, 12 * cfgchart.drawpen);
        a := arctan2(dy, dx);
        cxx := xx + round(r * cos(a));
        cyy := yy + round(r * sin(a));
        PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
          cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
        PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
        r := 0.9 * r;
        cxx := xx + round(r * cos(a + 0.18));
        cyy := yy + round(r * sin(a + 0.18));
        PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
          cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
        PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
        cxx := xx + round(r * cos(a - 0.18));
        cyy := yy + round(r * sin(a - 0.18));
        PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
          cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
        PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
      end;

    end;

  end
  else if cnv <> nil then
    with cnv do
    begin
      Pen.Color := cfgplot.Color[0];
      Pen.Width := cfgchart.DrawPen;
      Pen.Mode := pmCopy;
      Brush.Color := cfgplot.Color[21];
      Brush.style := bsSolid;

      case symbol of

        0:
        begin
          ds := 2 * cfgchart.drawsize;
          Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
          Pen.Color := cfgplot.Color[21];
          moveto(xx, yy);
          lineto(xx - 4 * ds, yy - 4 * ds);
          moveto(xx, yy);
          lineto(xx - 2 * ds, yy - 4 * ds);
          moveto(xx, yy);
          lineto(xx - 4 * ds, yy - 2 * ds);
        end;

        1:
        begin
          r := sqrt(dx * dx + dy * dy);
          r := max(r, 12 * cfgchart.drawpen);
          a := arctan2(dy, dx);
          if ma < 5 then
            k := 1
          else if ma > 18 then
            k := 0.5
          else
            k := 1 - (ma - 5) * 0.05;
          cr := round(k * (cfgplot.Color[21] and $FF));
          cg := round(k * ((cfgplot.Color[21] shr 8) and $FF));
          cb := round(k * ((cfgplot.Color[21] shr 16) and $FF));
          pen.Mode := pmCopy;
          brush.Style := bsSolid;
          ds := round(max(PixScale * diam / 2, 2 * cfgchart.drawpen));

          for i := 19 downto 0 do
          begin  // coma
            co := max(0, 255 - i * 13);
            Col := (cr * co div 255) + 256 * (cg * co div 255) + 65536 * (cb * co div 255);
            Col := Addcolor(Col, cfgplot.backgroundcolor);
            pen.Color := Col;
            brush.Color := Col;
            ds1 := round((i + 1) * ds / 20);
            Ellipse(xx - ds1, yy - ds1, xx + ds1, yy + ds1);
          end;

          if r > 30 then
          begin  // tail
            cr := cr div 2;
            cg := cg div 2;
            cb := cb div 2;

            if (dx <> 0) or (dy <> 0) then
              for i := 0 to 9 do
              begin
                cp1[2].X := xx;
                cp1[2].Y := yy;
                cp1[3].X := xx;
                cp1[3].Y := yy;
                cp2 := cp1;
                r := 0.99 * r;
                for j := 0 to 19 do
                begin
                  co := max(0, 255 - i * 20 - j * 13);
                  Col := (cr * co div 255) + 256 * (cg * co div 255) + 65536 * (cb * co div 255);
                  Col := Addcolor(Col, cfgplot.backgroundcolor);
                  pen.Color := Col;
                  brush.Color := Col;
                  cp1[0].X := cp1[3].X;
                  cp1[0].Y := cp1[3].Y;
                  cp1[1].X := cp1[2].X;
                  cp1[1].Y := cp1[2].Y;
                  cp1[2].X := xx + round((j + 1) * r / 20 * cos(a + 0.015 * (i)));
                  cp1[2].Y := yy + round((j + 1) * r / 20 * sin(a + 0.015 * (i)));
                  cp1[3].X := xx + round((j + 1) * 0.99 * r / 20 * cos(a + 0.015 * (i + 1)));
                  cp1[3].Y := yy + round((j + 1) * 0.99 * r / 20 * sin(a + 0.015 * (i + 1)));

                  if (abs(cp1[2].X - cp1[3].X) > 1) or (abs(cp1[2].Y - cp1[3].Y) > 1) then
                    polygon(cp1)
                  else
                    line(cp1[0].X, cp1[0].Y, cp1[2].X, cp1[2].Y);

                  cp2[0].X := cp2[3].X;
                  cp2[0].Y := cp2[3].Y;
                  cp2[1].X := cp2[2].X;
                  cp2[1].Y := cp2[2].Y;
                  cp2[2].X := xx + round((j + 1) * r / 20 * cos(a - 0.015 * (i)));
                  cp2[2].Y := yy + round((j + 1) * r / 20 * sin(a - 0.015 * (i)));
                  cp2[3].X := xx + round((j + 1) * 0.99 * r / 20 * cos(a - 0.015 * (i + 1)));
                  cp2[3].Y := yy + round((j + 1) * 0.99 * r / 20 * sin(a - 0.015 * (i + 1)));
                  if (abs(cp2[2].X - cp2[3].X) > 1) or (abs(cp2[2].Y - cp2[3].Y) > 1) then
                    polygon(cp2)
                  else
                    line(cp2[0].X, cp2[0].Y, cp2[2].X, cp2[2].Y);
                end;
              end;
          end;
          PlotStar(xx, yy, ma + 3, 1021);
        end;

        2:
        begin
          ds := round(max(3, (cfgplot.starsize *
            (cfgchart.min_ma - ma * cfgplot.stardyn / 80) / cfgchart.min_ma)) * cfgchart.drawsize / 2);
          Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
          ds := round(max(PixScale * diam / 2, 2 * cfgchart.drawpen));
          Brush.style := bsClear;
          Pen.Color := cfgplot.Color[21];
          Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
          Pen.Color := cfgplot.Color[0];
          ds := ds + cfgchart.drawpen;
          Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
          Brush.style := bsSolid;
          r := sqrt(dx * dx + dy * dy);
          r := max(r, 12 * cfgchart.drawpen);
          a := arctan2(dy, dx);
          cxx := xx + round(r * cos(a));
          cyy := yy + round(r * sin(a));
          PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
            cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
          PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
          r := 0.9 * r;
          cxx := xx + round(r * cos(a + 0.18));
          cyy := yy + round(r * sin(a + 0.18));
          PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
            cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
          PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
          cxx := xx + round(r * cos(a - 0.18));
          cyy := yy + round(r * sin(a - 0.18));
          PlotLine(xx + cfgchart.drawpen, yy + cfgchart.drawpen, cxx +
            cfgchart.drawpen, cyy + cfgchart.drawpen, cfgplot.Color[0], 1);
          PlotLine(xx, yy, cxx, cyy, cfgplot.Color[21], 1);
        end;
      end;

    end;

end;

function TSplot.PlotLabel(i, labelnum, fontnum: integer; xxs, yys, rs, orient: single;
  Xalign, Yalign: TLabelAlign; WhiteBg, forcetextlabel: boolean; txt: string;
  var px, py: integer; sizex: single = 1): integer;
var
  ts: TSize;
  mp: TRect;
  ATextStyle: TTextStyle;
  lcolor: Tcolor;
  cosa, sina: extended;
  xx, yy, r, offx, offy, lsp: integer;
  tbmp: TBGRABitmap;
begin

  xx := round(xxs);
  yy := round(yys);
  r := round(rs);

  if (abs(xx - cfgchart.hw) < cfgplot.outradius) and
    (abs(yy - cfgchart.hh) < cfgplot.outradius) then
  begin

    sincos(deg2rad * orient, sina, cosa);
    lsp := labspacing * cfgchart.drawpen;

    // If drawing to the printer force to plot the text label to the canvas
    // even if label editing is selected

    if (cfgchart.onprinter or forcetextlabel) then
    begin

      if cfgplot.UseBMP then
      begin

        cbmp.FontName := cfgplot.FontName[fontnum];
        lcolor := cfgplot.LabelColor[labelnum];

        if WhiteBg and (lcolor = cfgplot.Color[0]) then
          lcolor := cfgplot.Color[11];

        if lcolor = cfgplot.backgroundcolor then
          lcolor := (not lcolor) and $FFFFFF;
        if cfgplot.FontBold[fontnum] then
          cbmp.FontStyle := [fsBold]
        else
          cbmp.FontStyle := [];
        if cfgplot.FontItalic[fontnum] then
          cbmp.FontStyle := cbmp.FontStyle + [fsItalic];

        cbmp.FontHeight := trunc(sizex * cfgplot.LabelSize[labelnum] *
          cfgchart.fontscale * 96 / 72);
        ts := cbmp.TextSize(txt);

        if r >= 0 then
        begin

          case Xalign of

            laLeft:
            begin
              xxs := xxs + (lsp + rs) * cosa;
              yys := yys - (lsp + rs) * sina;
            end;

            laRight:
            begin
              xxs := xxs - (ts.cx + lsp + rs) * cosa;
              yys := yys + (ts.cx + lsp + rs) * sina;
            end;

            laCenter:
            begin
              xxs := xxs - (ts.cx div 2) * cosa;
              yys := yys + (ts.cx div 2) * sina;
            end;

          end;

          case Yalign of

            laTop:
            begin
              yys := yys - (ts.cy - rs) * cosa;
              xxs := xxs - (ts.cy - rs) * sina;
            end;

            laBottom:
            begin
              yys := yys + rs * cosa;
              xxs := xxs + rs * sina;
            end;

            laCenter:
            begin
              yys := yys - (ts.cy div 2) * cosa;
              xxs := xxs - (ts.cy div 2) * sina;
            end;

          end;

        end;

        BGRATextOut(xxs, yys, orient, txt, ColorToBGRA(lcolor), cbmp);
        px := round(xxs);
        py := round(yys);
      end
      else if cnv <> nil then
        with cnv do
        begin
          ATextStyle := TextStyle;
          ATextStyle.Opaque := False;
          TextStyle := ATextStyle;
          Brush.Style := bsClear;
          Pen.Mode := pmCopy;
          Font.Name := cfgplot.FontName[fontnum];
          Font.Color := cfgplot.LabelColor[labelnum];

          if cfgplot.FontBold[fontnum] then
            Font.Style := [fsBold]
          else
            Font.Style := [];

          if cfgplot.FontItalic[fontnum] then
            font.style := font.style + [fsItalic];

          Font.Size := round(sizex * cfgplot.LabelSize[labelnum] * cfgchart.fontscale);
          Font.Orientation := round(10 * orient);
          ts := TextExtent(txt);

          if r >= 0 then
          begin

            case Xalign of

              laLeft:
              begin
                xx := xx + round((lsp + rs) * cosa);
                yy := yy - round((lsp + rs) * sina);
              end;

              laRight:
              begin
                xx := xx - round((ts.cx + lsp + rs) * cosa);
                yy := yy + round((ts.cx + lsp + rs) * sina);
              end;

              laCenter:
              begin
                xx := xx - round((ts.cx div 2) * cosa);
                yy := yy + round((ts.cx div 2) * sina);
              end;
            end;

            case Yalign of
              laTop:
              begin
                yy := yy - round((ts.cy - rs) * cosa);
                xx := xx - round((ts.cy - rs) * sina);
              end;

              laBottom:
              begin
                yy := yy + round(rs * cosa);
                xx := xx + round(rs * sina);
              end;

              laCenter:
              begin
                yy := yy - round((ts.cy div 2) * cosa);
                xx := xx - round((ts.cy div 2) * sina);
              end;
            end;

          end;

          TextOut(xx, yy, txt);

          Font.Orientation := 0;
          px := xx;
          py := yy;
        end;

      // If drawing to the screen use movable label
    end
    else
    begin

      if i > maxlabels then
      begin
        Result := -1;
        exit;
      end;

      with ilabels[i] do
      begin
        tbmp := TBGRABitmap.Create;
        tbmp.FontName := cfgplot.FontName[fontnum];
        lcolor := cfgplot.LabelColor[labelnum];

        if WhiteBg and (lcolor = cfgplot.Color[0]) then
          lcolor := cfgplot.Color[11];
        if lcolor = cfgplot.backgroundcolor then
          lcolor := (not lcolor) and $FFFFFF;
        if cfgplot.FontBold[fontnum] then
          tbmp.FontStyle := [fsBold]
        else
          tbmp.FontStyle := [];
        if cfgplot.FontItalic[fontnum] then
          tbmp.FontStyle := tbmp.FontStyle + [fsItalic];

        tbmp.FontHeight := trunc(cfgplot.LabelSize[labelnum] * cfgchart.fontscale * 96 / 72);
        ts := tbmp.TextSize(txt);

        if orient = 0 then
        begin
          tbmp.SetSize(ts.cx, ts.cy);
          tbmp.FillRect(0, 0, tbmp.Width, tbmp.Height, ColorToBGRA(cfgplot.bgcolor), dmSet);
          BGRATextOut(0, 0, orient, txt, ColorToBGRA(lcolor), tbmp);
          mp := rect(0, 0, ts.cx, ts.cy);

          offx := 0;
          offy := 0;
        end
        else
        begin
          tbmp.SetSize(1000, 1000);
          tbmp.FillRect(0, 0, tbmp.Width, tbmp.Height, ColorToBGRA(cfgplot.bgcolor), dmSet);

          mp := BGRATextOut(500, 500, orient, txt, ColorToBGRA(lcolor), tbmp, True);

          offx := -500 - mp.Left;
          offy := -500 - mp.Top;
        end;

        Width := mp.Right;
        Height := mp.Bottom;

        Picture.Bitmap.Width := Width;
        Picture.Bitmap.Height := Height;

        tbmp.Draw(Picture.Bitmap.Canvas, offx, offy, True);

        if WhiteBg then
          SetTransparencyFromLuminance(Picture.Bitmap, 3)
        else
          SetTransparencyFromLuminance(Picture.Bitmap, 2);

        Caption := txt;
        tbmp.Free;

        if r >= 0 then
        begin

          case Xalign of

            laLeft:
            begin
              xxs := xxs + (lsp + rs) * cosa;
              yys := yys - (lsp + rs) * sina;
            end;

            laRight:
            begin
              xxs := xxs - (ts.cx + lsp + rs) * cosa;
              yys := yys + (ts.cx + lsp + rs) * sina;
            end;

            laCenter:
            begin
              xxs := xxs - (ts.cx div 2) * cosa;
              yys := yys + (ts.cx div 2) * sina;
            end;
          end;

          case Yalign of

            laTop:
            begin
              yys := yys - (ts.cy - rs) * cosa;
              xxs := xxs - (ts.cy - rs) * sina;
            end;

            laBottom:
            begin
              yys := yys + rs * cosa;
              xxs := xxs + rs * sina;
            end;

            laCenter:
            begin
              yys := yys - (ts.cy div 2) * cosa;
              xxs := xxs - (ts.cy div 2) * sina;
            end;
          end;

        end;

        left := round(xxs) + mp.Left;
        top := round(yys) + mp.Top;

        Visible := True;
        px := left;
        py := top;
      end;

    end;

  end;

  Result := 0;
end;

function TSplot.GetTextSize(fontnum: integer; txt: string; labelnum: integer = -1;
  lsize: single = 1): Tsize;
begin

  if (lsize < 0) or (lsize > 1.5) then
    lsize := 1;

  if cfgplot.UseBMP then
  begin
    cbmp.FontName := cfgplot.FontName[fontnum];

    if cfgplot.FontBold[fontnum] then
      cbmp.FontStyle := [fsBold]
    else
      cbmp.FontStyle := [];

    if cfgplot.FontItalic[fontnum] then
      cbmp.FontStyle := cbmp.FontStyle + [fsItalic];

    if labelnum > 0 then
      cbmp.FontHeight := trunc(lsize * cfgplot.LabelSize[labelnum] * cfgchart.fontscale * 96 / 72)
    else
      cbmp.FontHeight := trunc(lsize * cfgplot.FontSize[fontnum] * cfgchart.fontscale * 96 / 72);

    Result := cbmp.TextSize(txt);

  end
  else

  if cnv <> nil then
    with cnv do
    begin
      Font.Name := cfgplot.FontName[fontnum];

      if cfgplot.FontBold[fontnum] then
        Font.Style := [fsBold]
      else
        Font.Style := [];
      if cfgplot.FontItalic[fontnum] then
        font.style := font.style + [fsItalic];
      if labelnum > 0 then
        Font.Size := round(lsize * cfgplot.LabelSize[labelnum] * cfgchart.fontscale)
      else
        Font.Size := round(lsize * cfgplot.FontSize[fontnum] * cfgchart.fontscale);

      Result := cnv.TextExtent(txt);

    end
  else
    Result.cx := 0;
end;

procedure TSplot.PlotText(xx, yy, fontnum, lcolor: integer; Xalign, Yalign: TLabelAlign;
  txt: string; WhiteBg: boolean; opaque: boolean = True; clip: boolean = False;
  marge: integer = 5; orient: integer = 0);
var
  ts: TSize;
  arect: TRect;
  ATextStyle: TTextStyle;
begin

  if (abs(xx - cfgchart.hw) < cfgplot.outradius) and
    (abs(yy - cfgchart.hh) < cfgplot.outradius) then
  begin

    if cfgplot.UseBMP then
    begin

      ATextStyle.Opaque := opaque;
      cbmp.FontHeight := trunc(cfgplot.FontSize[fontnum] * cfgchart.fontscale * 96 / 72);

      if cfgplot.FontBold[fontnum] then
        cbmp.FontStyle := [fsBold]
      else
        cbmp.FontStyle := [];
      if cfgplot.FontItalic[fontnum] then
        cbmp.FontStyle := cbmp.FontStyle + [fsItalic];

      cbmp.FontName := cfgplot.FontName[fontnum];

      if WhiteBg then
        lcolor := cfgplot.Color[11];
      if lcolor = cfgplot.backgroundcolor then
        lcolor := (not lcolor) and $FFFFFF;

      ts := cbmp.TextSize(txt);

      case Xalign of
        laRight: xx := xx - ts.cx;
        laCenter: xx := xx - (ts.cx div 2);
      end;

      case Yalign of
        laBottom: yy := yy - ts.cy;
        laCenter: yy := yy - (ts.cy div 2);
      end;

      if clip then
      begin
        if yy < cfgplot.ymin then
          yy := cfgplot.ymin + marge;
        if (yy + ts.cy + marge) > cfgplot.ymax then
          yy := cfgplot.ymax - ts.cy - marge;
        if xx < cfgplot.xmin then
          xx := cfgplot.xmin + marge;
        if (xx + ts.cx + marge) > cfgplot.xmax then
          xx := cfgplot.xmax - ts.cx - marge;
      end;

      arect := Bounds(xx, yy, ts.cx, ts.cy + 2);

      if opaque then
        cbmp.FillRect(xx, yy, xx + ts.cx, yy + ts.cy + 2, ColorToBGRA(cfgplot.backgroundcolor), dmSet);

      BGRATextOut(xx, yy, orient, txt, ColorToBGRA(lcolor), cbmp);
    end
    else

    if cnv <> nil then
      with cnv do
      begin
        ATextStyle := TextStyle;
        ATextStyle.Opaque := opaque;
        TextStyle := ATextStyle;
        if opaque then
          Brush.Style := bsSolid
        else
          Brush.Style := bsClear;
        Brush.Color := cfgplot.backgroundcolor;
        Pen.Mode := pmCopy;
        Pen.Color := cfgplot.backgroundcolor;
        Font.Name := cfgplot.FontName[fontnum];
        Font.Color := lcolor;
        if Font.Color = Brush.Color then
          Font.Color := (not Font.Color) and $FFFFFF;
        Font.Size := round(cfgplot.FontSize[fontnum] * cfgchart.fontscale);

        if cfgplot.FontBold[fontnum] then
          Font.Style := [fsBold]
        else
          Font.Style := [];
        if cfgplot.FontItalic[fontnum] then
          font.style := font.style + [fsItalic];

        ts := cnv.TextExtent(txt);

        case Xalign of
          laRight: xx := xx - ts.cx;
          laCenter: xx := xx - (ts.cx div 2);
        end;

        case Yalign of
          laBottom: yy := yy - ts.cy;
          laCenter: yy := yy - (ts.cy div 2);
        end;

        if clip then
        begin
          if yy < cfgplot.ymin then
            yy := cfgplot.ymin + marge;
          if (yy + ts.cy + marge) > cfgplot.ymax then
            yy := cfgplot.ymax - ts.cy - marge;
          if xx < cfgplot.xmin then
            xx := cfgplot.xmin + marge;
          if (xx + ts.cx + marge) > cfgplot.xmax then
            xx := cfgplot.xmax - ts.cx - marge;
        end;

        arect := Bounds(xx, yy, ts.cx, ts.cy + 2);

        if cnv is TPostscriptCanvas then
        begin
          if opaque then
            Rectangle(arect);
          TextOut(xx, yy, txt);
        end
        else
        begin
          arect := Bounds(xx, yy, ts.cx, ts.cy + 2);
          textRect(arect, xx, yy, txt);
        end;

      end;

  end;

end;

procedure TSplot.PlotTextCR(xx, yy, fontnum, labelnum: integer; txt: string;
  WhiteBg: boolean; opaque: boolean = True; orient: integer = 0);
var
  ls, p: integer;
  buf: string;
  arect: TRect;
  ts: TSize;
  ATextStyle: TTextStyle;
  lcolor: TColor;
begin

  if (abs(xx - cfgchart.hw) < cfgplot.outradius) and
    (abs(yy - cfgchart.hh) < cfgplot.outradius) then
  begin

    if cfgplot.UseBMP then
    begin

      ATextStyle.Opaque := opaque;
      cbmp.FontHeight := trunc(cfgplot.LabelSize[labelnum] * cfgchart.fontscale * 96 / 72);

      if cfgplot.FontBold[fontnum] then
        cbmp.FontStyle := [fsBold]
      else
        cbmp.FontStyle := [];
      if cfgplot.FontItalic[fontnum] then
        cbmp.FontStyle := cbmp.FontStyle + [fsItalic];

      cbmp.FontName := cfgplot.FontName[fontnum];
      lcolor := cfgplot.LabelColor[labelnum];

      if WhiteBg then
        lcolor := cfgplot.Color[11];
      if lcolor = cfgplot.backgroundcolor then
        lcolor := (not lcolor) and $FFFFFF;

      ts := cbmp.TextSize('1');
      ls := ts.cy;

      repeat
        p := pos(crlf, txt);

        if p = 0 then
          buf := txt
        else
        begin
          buf := copy(txt, 1, p - 1);
          Delete(txt, 1, p + 1);
        end;

        ts := cbmp.TextSize(buf);
        arect := Bounds(xx, yy, round(1.2 * ts.cx), ts.cy + 2);

        if opaque then
          cbmp.FillRect(xx, yy, xx + round(1.2 * ts.cx), yy + ts.cy + 2, ColorToBGRA(
            cfgplot.backgroundcolor), dmSet);

        BGRATextOut(xx, yy, orient, buf, ColorToBGRA(lcolor), cbmp);
        yy := yy + ls;

      until p = 0;

    end
    else

    if cnv <> nil then
      with cnv do
      begin
        ATextStyle := TextStyle;
        ATextStyle.Opaque := opaque;
        TextStyle := ATextStyle;

        if opaque then
          Brush.Style := bsSolid
        else
          Brush.Style := bsClear;

        Brush.Color := cfgplot.backgroundcolor;
        Pen.Mode := pmCopy;
        Pen.Color := cfgplot.backgroundcolor;
        Font.Name := cfgplot.FontName[fontnum];
        Font.Color := cfgplot.LabelColor[labelnum];

        if Font.Color = Brush.Color then
          Font.Color := (not Font.Color) and $FFFFFF;

        Font.Size := round(cfgplot.LabelSize[labelnum] * cfgchart.fontscale);

        if cfgplot.FontBold[fontnum] then
          Font.Style := [fsBold]
        else
          Font.Style := [];
        if cfgplot.FontItalic[fontnum] then
          font.style := font.style + [fsItalic];

        ls := round(cnv.TextHeight('1'));

        repeat
          p := pos(crlf, txt);

          if p = 0 then
            buf := txt
          else
          begin
            buf := copy(txt, 1, p - 1);
            Delete(txt, 1, p + 1);
          end;

          ts := TextExtent(buf);
          arect := Bounds(xx, yy, ts.cx, ts.cy + 2);

          if cnv is TPostscriptCanvas then
          begin
            if opaque then
              Rectangle(arect);
            TextOut(xx, yy, buf);
          end
          else
            textRect(arect, xx, yy, buf);

          yy := yy + ls;
        until p = 0;

      end;

  end;

end;

function TSplot.ClipVector(var x1, y1, x2, y2: integer; var clip1, clip2: boolean): boolean;
var
  side, side1, side2: TSideSet;
  x, y: double;
  xR, xL, yU, yD: integer;

  procedure GetSide(x, y: integer; var side: TSideSet);
  begin
    side := [];
    if x < xL then
      side := [L]
    else if x > xR then
      side := [R];
    if y < yU then
      side := side + [U]
    else if y > yD then
      side := side + [D];
  end;

  procedure doClip;
  var
    deltaX, deltaY: double;
  begin
    deltaX := x2 - x1;
    deltaY := y2 - y1;

    if R in side then
    begin
      x := xR;
      y := y1 + deltaY * (xR - x1) / deltaX;
    end
    else if L in side then
    begin
      x := xL;
      y := y1 + deltaY * (xL - x1) / deltaX;
    end
    else if D in side then
    begin
      x := x1 + deltaX * (yD - y1) / deltaY;
      y := yD;
    end
    else if U in side then
    begin
      x := x1 + deltaX * (yU - y1) / deltaY;
      y := yU;
    end;

  end;

begin
  x := 0;
  y := 0;
  xL := -cfgchart.cliparea;
  xR := cfgchart.Width + cfgchart.cliparea;
  yU := -cfgchart.cliparea;
  yD := cfgchart.Height + cfgchart.cliparea;

  GetSide(x1, y1, side1);
  GetSide(x2, y2, side2);

  Result := (side1 * side2 = []);

  clip1 := False;
  clip2 := False;

  while ((side1 <> []) or (side2 <> [])) and Result do
  begin
    side := side1;

    if side = [] then
      side := side2;

    doclip;

    if side = side1 then
    begin
      clip1 := True;
      x1 := round(x);
      y1 := round(y);
      GetSide(x1, y1, side1);
    end
    else
    begin
      clip2 := True;
      x2 := round(x);
      y2 := round(y);
      GetSide(x2, y2, side2);
    end;

    Result := (side1 * side2 = []);

  end;

end;

procedure TSplot.labelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin

  if (Sender is TImage) and (editlabel < 0) then
  begin
    if button = mbLeft then
      if assigned(FLabelClick) then
        FLabelClick(TImage(Sender).tag);
  end;

end;

procedure TSplot.editlabelmenuPopup(Sender: TObject);
var
  pt: Tpoint;
  lb: TComponent;
begin

  lb := editlabelmenu.PopupComponent;

  if (lb is TImage) and (editlabel < 0) then
  begin
    pt.x := mouse.cursorpos.x;
    pt.y := mouse.cursorpos.y;
    selectedlabel := TImage(lb).tag;
    editlabelx := pt.x;
    editlabely := pt.y;
    editlabelmod := False;
    editlabelmenu.Items[0].Caption := ilabels[selectedlabel].Caption;
    // editlabelmenu.popup(pt.x,pt.y);
  end;

end;

procedure TSplot.labelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
  pt: Tpoint;
begin

  if editlabel > 0 then
    with Sender as TImage do
    begin
      pt := clienttoscreen(point(x, y));
      ilabels[editlabel].left := ilabels[editlabel].Left + pt.X - editlabelX;
      ilabels[editlabel].Top := ilabels[editlabel].Top + pt.Y - editlabelY;
      editlabelx := pt.x;
      editlabely := pt.y;
      editlabelmod := True;
    end;

end;

procedure TSplot.labelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin

  if editlabel > 0 then
  begin

    //  labels[editlabel].Transparent:=true;
    ilabels[editlabel].color := clNone;
    ilabels[editlabel].Cursor := crDefault;
    if editlabelmod and assigned(FEditLabelPos) then
      FEditLabelPos(editlabel, ilabels[editlabel].left, ilabels[editlabel].top,
        ilabels[editlabel].Width, ilabels[editlabel].Height, FlabelRaDec);
  end;

  editlabel := -1;

end;

procedure TSplot.labelMouseLeave(Sender: TObject);
begin

  if editlabel > 0 then
  begin
    // force the label to the cursor while editing
    ilabels[editlabel].left := ilabels[editlabel].Left + mouse.CursorPos.x - editlabelX;
    ilabels[editlabel].Top := ilabels[editlabel].Top + mouse.CursorPos.y - editlabelY;
    editlabelx := mouse.CursorPos.x;
    editlabely := mouse.CursorPos.y;
  end;

end;

procedure TSplot.Movelabel(Sender: TObject);
begin
  FlabelRaDec := False;
  mouse.CursorPos := point(editlabelx, editlabely);
  editlabel := selectedlabel;

  //labels[editlabel].Transparent:=false;
  ilabels[editlabel].Color := cfgplot.Color[0];
  ilabels[editlabel].Cursor := crSizeAll;
end;

procedure TSplot.MovelabelRaDec(Sender: TObject);
begin
  FlabelRaDec := True;
  mouse.CursorPos := point(editlabelx, editlabely);
  editlabel := selectedlabel;

  //labels[editlabel].Transparent:=false;
  ilabels[editlabel].Color := cfgplot.Color[0];
  ilabels[editlabel].Cursor := crSizeAll;
end;

procedure TSplot.EditlabelTxt(Sender: TObject);
begin
  if (selectedlabel > 0) and assigned(FEditLabelTxt) then
    FEditLabelTxt(selectedlabel, editlabelx, editlabely, 0, 0, False);
end;

procedure TSplot.DefaultLabel(Sender: TObject);
begin
  if (selectedlabel > 0) and assigned(FDefaultLabel) then
    FDefaultLabel(selectedlabel);
end;

procedure TSplot.Deletelabel(Sender: TObject);
begin
  if (selectedlabel > 0) and assigned(FDeleteLabel) then
    FDeleteLabel(selectedlabel);
end;

procedure TSplot.DeleteAlllabel(Sender: TObject);
begin
  if assigned(FDeleteAllLabel) then
    FDeleteAllLabel;
end;

procedure TSplot.PlotMWDot(x, y, r: single; col: TColor; WhiteBg: boolean);
begin

  if WhiteBg then
    col := SubColor(clWhite, col);

  if cfgplot.UseBMP then
  begin

    if not WhiteBg then
      col := Addcolor(col, cfgplot.backgroundcolor);

    if cfgplot.AntiAlias then
      cbmp.FillEllipseLinearColorAntialias(x, y, r * 2, r * 2, ColorToBGRA(
        col, 0), ColorToBGRA(col, 255))
    else
      cbmp.FillRect(round(x - r), round(y - r), round(x + r), round(y + r), ColorToBGRA(col), dmSet);

  end
  else

  if cnv <> nil then
    with cnv do
    begin
      Pen.Color := col;
      Brush.Color := col;
      Brush.Style := bsSolid;
      Ellipse(round(x - r), round(y - r), round(x + r), round(y + r));
      Pen.Mode := pmCopy;
    end;

end;

procedure TSplot.PlotCircle(x1, y1, x2, y2: single; lcolor: integer; moving: boolean);
var
  x, y, r: single;
begin

  if cfgplot.UseBMP and (not moving) then
  begin
    x := (x1 + x2) / 2;
    y := (y1 + y2) / 2;
    r := abs(x1 - x2) / 2;
    cbmp.EllipseAntialias(x, y, r, r, ColorToBGRA(lcolor), MarkWidth * cfgchart.drawpen);
  end
  else

  if cnv <> nil then
    with cnv do
    begin
      Pen.Width := MarkWidth * cfgchart.drawpen;

      if moving then
      begin
        Pen.Color := clWhite;
        Pen.Mode := pmXor;
      end
      else
      begin
        Pen.Color := lcolor;
        Pen.Mode := pmCopy;
      end;

      Brush.Style := bsClear;
      Ellipse(round(x1), round(y1), round(x2), round(y2));
      Pen.Mode := pmCopy;
      brush.Style := bsSolid;
    end;

end;

procedure TSplot.PlotCircleMask(x1, y1, r: single; whitebg: boolean);
var
  mask: TBGRABitmap;
  xx1, yy1, r1, np, i: integer;
  a, da: double;
  sa, ca: extended;
  p1, p2: array[0..30] of TPoint;
begin

  if cfgplot.UseBMP then
  begin

    if whitebg then
      mask := TBGRABitmap.Create(cfgplot.xmax, cfgplot.ymax, BGRAWhite)
    else
      mask := TBGRABitmap.Create(cfgplot.xmax, cfgplot.ymax, BGRABlack);

    Mask.EraseEllipseAntialias(x1, y1, r, r, 255);
    cbmp.PutImage(0, 0, mask, dmDrawWithTransparency);

    Mask.Free;

  end
  else

  if cnv <> nil then
    with cnv do
    begin
      xx1 := round(x1);
      yy1 := round(y1);
      r1 := round(r);
      p1[0] := Point(0, 0);
      p1[1] := Point(xx1, 0);
      p1[2] := Point(xx1, yy1 - r1);
      p2[0] := Point(cfgchart.Width, 0);
      p2[1] := Point(xx1, 0);
      p2[2] := Point(xx1, yy1 - r1);
      np := 2;
      a := pi / 2;
      da := pi / 21;

      for i := 0 to 20 do
      begin
        Inc(np);
        a := a + da;
        sincos(a, sa, ca);
        p2[np] := Point(round(xx1 - r1 * ca), round(yy1 - r1 * sa));
        p1[np] := Point(round(xx1 + r1 * ca), round(yy1 - r1 * sa));
      end;

      Inc(np);
      p1[np] := Point(xx1, yy1 + r1);
      p2[np] := Point(xx1, yy1 + r1);
      Inc(np);
      p1[np] := Point(xx1, cfgchart.Height);
      p2[np] := Point(xx1, cfgchart.Height);
      Inc(np);
      p1[np] := Point(0, cfgchart.Height);
      p2[np] := Point(cfgchart.Width, cfgchart.Height);
      Inc(np);
      p1[np] := Point(0, 0);
      p2[np] := Point(cfgchart.Width, 0);
      Inc(np);

      Pen.Width := cfgchart.drawpen;
      Pen.Mode := pmCopy;
      Pen.Color := clWhite;

      Brush.Style := bsSolid;
      Brush.Color := Pen.Color;

      Polygon(p1, np);
      Polygon(p2, np);
      Pen.Color := clBlack;

      Brush.Style := bsClear;

      Ellipse(xx1 - r1, yy1 - r1, xx1 + r1, yy1 + r1);

    end;

end;

procedure TSplot.PlotCRose(rosex, rosey, roserd, rot: single; flipx, flipy: integer;
  WhiteBg: boolean; RoseType: integer);
var
  c, s, c1, s1, c2, s2, rote: extended;
  td: single;
  i: integer;
  col: TBGRAPixel;
  ts: TSize;
begin

  if RoseType = 3 then
  begin     // simple arrow

    if cfgplot.usebmp then
    begin
      td := roserd * 0.9;
      rote := rot + pid2;

      if FlipY < 0 then
        rot := pi - rot;
      if FlipX < 0 then
        rot := -rot;

      sincos(rot, c, s);
      sincos(rot - pid4, c1, s1);
      sincos(rot + pid4, c2, s2);

      col := ColorToBGRA(cfgplot.Color[12]);

      BGRADrawLine(rosex, rosey, rosex - (roserd * c), rosey -
        (roserd * s), col, cfgchart.drawpen, cbmp);
      BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), (rosex - (roserd * c)) +
        (roserd * c1 / 8), (rosey - (roserd * s)) + (roserd * s1 / 8), col, cfgchart.drawpen, cbmp);
      BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), (rosex - (roserd * c)) +
        (roserd * c2 / 8), (rosey - (roserd * s)) + (roserd * s2 / 8), col, cfgchart.drawpen, cbmp);

      col := ColorToBGRA(cfgplot.LabelColor[7]);
      cbmp.FontName := cfgplot.FontName[1];
      cbmp.FontHeight := trunc(cfgplot.FontSize[1] * cfgchart.fontscale * 96 / 72);
      BGRATextOut((rosex - (roserd * c)) + (roserd * c2 / 8), (rosey - (roserd * s)) +
        (roserd * s2 / 8), rad2deg * rot, 'N', col, cbmp);

      if FlipY < 0 then
        rote := pi - rote;
      if FlipX < 0 then
        rote := -rote;

      sincos(rote, c, s);
      sincos(rote - pid4, c1, s1);
      sincos(rote + pid4, c2, s2);
      col := ColorToBGRA(cfgplot.Color[12]);

      BGRADrawLine(rosex, rosey, rosex - (roserd * c), rosey -
        (roserd * s), col, cfgchart.drawpen, cbmp);
      BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), (rosex - (roserd * c)) +
        (roserd * c1 / 8), (rosey - (roserd * s)) + (roserd * s1 / 8), col, cfgchart.drawpen, cbmp);
      BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), (rosex - (roserd * c)) +
        (roserd * c2 / 8), (rosey - (roserd * s)) + (roserd * s2 / 8), col, cfgchart.drawpen, cbmp);

      col := ColorToBGRA(cfgplot.LabelColor[7]);
      BGRATextOut((rosex - (roserd * c)) + (roserd * c2 / 8), (rosey - (roserd * s)) +
        (roserd * s2 / 8), rad2deg * rote, 'E', col, cbmp);

    end
    else

    if cnv <> nil then
      with cnv do
      begin
        Pen.Width := cfgchart.drawpen;
        Pen.Mode := pmCopy;
        Brush.Style := bsClear;
        Font.Name := cfgplot.FontName[1];
        Font.Color := clWhite;

        if WhiteBg then
          Font.Color := clBlack;

        Font.Size := round(cfgplot.FontSize[1] * cfgchart.fontscale);
        td := roserd * 0.9;
        rote := rot + pid2;

        if FlipY < 0 then
          rot := pi - rot;
        if FlipX < 0 then
          rot := -rot;

        sincos(rot, c, s);
        sincos(rot - pid4, c1, s1);
        sincos(rot + pid4, c2, s2);

        Pen.Color := cfgplot.Color[12];
        MoveTo(round(rosex), round(rosey));
        LineTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        MoveTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        LineTo(round((rosex - (roserd * c)) + (roserd * c1 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s1 / 8)));
        MoveTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        LineTo(round((rosex - (roserd * c)) + (roserd * c2 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s2 / 8)));
        TextOut(round((rosex - (roserd * c)) + (roserd * c2 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s2 / 8)), 'N');

        if FlipY < 0 then
          rote := pi - rote;
        if FlipX < 0 then
          rote := -rote;

        sincos(rote, c, s);
        sincos(rote - pid4, c1, s1);
        sincos(rote + pid4, c2, s2);

        MoveTo(round(rosex), round(rosey));
        LineTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        MoveTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        LineTo(round((rosex - (roserd * c)) + (roserd * c1 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s1 / 8)));
        MoveTo(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
        LineTo(round((rosex - (roserd * c)) + (roserd * c2 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s2 / 8)));
        TextOut(round((rosex - (roserd * c)) + (roserd * c2 / 8)), round(
          (rosey - (roserd * s)) + (roserd * s2 / 8)), 'E');
        Pen.Mode := pmCopy;
        brush.Style := bsSolid;
      end;

  end
  else
  begin    // compass

    if (cfgplot.nebplot > 0) and (cfgplot.usebmp) and
      (compassrose <> nil) and (compassrose.Width > 0) and
      (compassarrow <> nil) and (compassarrow.Width > 0) then
    begin

      case RoseType of

        1:
        begin
          PlotImage(rosex, rosey, 2 * roserd, 2 * roserd, rot, flipx, flipy,
            WhiteBg, True, compassrose, 2);
          td := roserd * 0.6;
          rote := rot + pid2;

          if FlipY < 0 then
            rot := pi - rot;
          if FlipX < 0 then
            rot := -rot;

          sincos(rot, c, s);
          col := ColorToBGRA(cfgplot.LabelColor[7]);
          cbmp.FontName := cfgplot.FontName[1];
          cbmp.FontHeight := trunc(cfgplot.FontSize[1] * cfgchart.fontscale * 96 / 72);
          ts := cbmp.TextSize('N');

          BGRATextOut((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c,
            (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s, rad2deg * rot, 'N', col, cbmp);

          if FlipY < 0 then
            rote := pi - rote;
          if FlipX < 0 then
            rote := -rote;

          sincos(rote, c, s);
          ts := cbmp.TextSize('E');
          BGRATextOut((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c,
            (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s, rad2deg * rote, 'E', col, cbmp);
        end;

        2: PlotImage(rosex, rosey, 2 * roserd, 2 * roserd, rot, flipx, flipy,
            WhiteBg, True, compassarrow, 2);

      end;

    end
    else

    begin

      if FlipY < 0 then
        rot := pi - rot;
      if FlipX < 0 then
        rot := -rot;
      if cfgplot.usebmp then
      begin

        case RoseType of

          1:
          begin
            td := roserd * 0.6;
            rote := rot + pid2;
            col := ColorToBGRA(cfgplot.Color[12]);
            cbmp.EllipseAntialias(rosex, rosey, roserd, roserd, col, cfgchart.drawpen);
            sincos(rot, c, s);

            if not WhiteBg then
              col := ColorToBGRA(clRed);

            BGRADrawLine(rosex + (roserd * s / 8), rosey - (roserd / 8 * c), rosex -
              (roserd * c), rosey - (roserd * s), col, cfgchart.drawpen, cbmp);
            BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), rosex -
              (roserd * s / 8), rosey + (roserd / 8 * c), col, cfgchart.drawpen, cbmp);
            BGRADrawLine(rosex - (roserd * s / 8), rosey + (roserd / 8 * c), rosex +
              (roserd * s / 8), rosey - (roserd / 8 * c), col, cfgchart.drawpen, cbmp);

            if not WhiteBg then
              col := ColorToBGRA(clBlue);

            BGRADrawLine(rosex + (roserd * s / 8), rosey - (roserd / 8 * c), rosex +
              (roserd * c), rosey + (roserd * s), col, cfgchart.drawpen, cbmp);
            BGRADrawLine(rosex + (roserd * c), rosey + (roserd * s), rosex -
              (roserd * s / 8), rosey + (roserd / 8 * c), col, cfgchart.drawpen, cbmp);
            col := ColorToBGRA(cfgplot.Color[12]);

            for i := 1 to 7 do
            begin
              sincos(rot + i * pi / 4, c, s);
              BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), rosex -
                (0.9 * roserd * c), rosey - (0.9 * roserd * s), col, cfgchart.drawpen, cbmp);
            end;

            if WhiteBg then
              col := ColorToBGRA(clBlack)
            else
              col := ColorToBGRA(clWhite);

            if FlipY < 0 then
              rot := pi - rot;
            if FlipX < 0 then
              rot := -rot;

            sincos(rot, c, s);
            cbmp.FontName := cfgplot.FontName[1];
            cbmp.FontHeight := trunc(cfgplot.FontSize[1] * cfgchart.fontscale * 96 / 72);
            ts := cbmp.TextSize('N');

            BGRATextOut((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c,
              (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s, rad2deg * rot, 'N', col, cbmp);

            if FlipY < 0 then
              rote := pi - rote;
            if FlipX < 0 then
              rote := -rote;
            sincos(rote, c, s);
            ts := cbmp.TextSize('E');
            BGRATextOut((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c,
              (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s, rad2deg * rote, 'E', col, cbmp);
          end;

          2:
          begin
            col := ColorToBGRA(cfgplot.Color[12]);
            sincos(rot, c, s);
            BGRADrawLine(rosex + (roserd * s / 8), rosey - (roserd / 8 * c), rosex -
              (roserd * c), rosey - (roserd * s), col, cfgchart.drawpen, cbmp);
            BGRADrawLine(rosex - (roserd * c), rosey - (roserd * s), rosex -
              (roserd * s / 8), rosey + (roserd / 8 * c), col, cfgchart.drawpen, cbmp);
            BGRADrawLine(rosex - (roserd * s / 8), rosey + (roserd / 8 * c), rosex +
              (roserd * s / 8), rosey - (roserd / 8 * c), col, cfgchart.drawpen, cbmp);
          end;

        end;

      end
      else

      if cnv <> nil then
        with cnv do
        begin
          td := roserd * 0.6;
          rote := rot + pid2;
          Pen.Width := cfgchart.drawpen;
          Pen.Mode := pmCopy;
          Brush.Style := bsClear;

          case RoseType of

            1:
            begin
              Pen.Color := cfgplot.Color[13];
              Ellipse(round(rosex - roserd), round(rosey - roserd), round(
                rosex + roserd), round(rosey + roserd));
              sincos(rot, c, s);

              if not WhiteBg then
                Pen.Color := clRed;

              moveto(round(rosex + (roserd * s / 8)), round(rosey - (roserd / 8 * c)));
              lineto(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
              moveto(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
              lineto(round(rosex - (roserd * s / 8)), round(rosey + (roserd / 8 * c)));
              moveto(round(rosex - (roserd * s / 8)), round(rosey + (roserd / 8 * c)));
              lineto(round(rosex + (roserd * s / 8)), round(rosey - (roserd / 8 * c)));

              if not WhiteBg then
                Pen.Color := clBlue;

              moveto(round(rosex + (roserd * s / 8)), round(rosey - (roserd / 8 * c)));
              lineto(round(rosex + (roserd * c)), round(rosey + (roserd * s)));
              moveto(round(rosex + (roserd * c)), round(rosey + (roserd * s)));
              lineto(round(rosex - (roserd * s / 8)), round(rosey + (roserd / 8 * c)));
              Pen.Color := cfgplot.Color[13];

              for i := 1 to 7 do
              begin
                sincos(rot + i * pi / 4, c, s);
                moveto(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
                lineto(round(rosex - (0.9 * roserd * c)), round(rosey - (0.9 * roserd * s)));
              end;

              Font.Name := cfgplot.FontName[1];
              Font.Color := clWhite;

              if WhiteBg then
                Font.Color := clBlack;

              Font.Size := round(cfgplot.FontSize[1] * cfgchart.fontscale);

              if FlipY < 0 then
                rot := pi - rot;
              if FlipX < 0 then
                rot := -rot;

              sincos(rot, c, s);
              ts := TextExtent('N');
              TextOut(round((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c), round(
                (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s), 'N');

              if FlipY < 0 then
                rote := pi - rote;
              if FlipX < 0 then
                rote := -rote;

              sincos(rote, c, s);
              ts := TextExtent('E');
              TextOut(round((rosex - (td * c)) - (ts.cx div 2) * s - (ts.cy div 2) * c), round(
                (rosey - (td * s)) + (ts.cx div 2) * c - (ts.cy div 2) * s), 'E');
            end;

            2:
            begin
              Pen.Color := cfgplot.Color[13];
              sincos(rot, c, s);
              moveto(round(rosex + (roserd * s / 8)), round(rosey - (roserd / 8 * c)));
              lineto(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
              moveto(round(rosex - (roserd * c)), round(rosey - (roserd * s)));
              lineto(round(rosex - (roserd * s / 8)), round(rosey + (roserd / 8 * c)));
              moveto(round(rosex - (roserd * s / 8)), round(rosey + (roserd / 8 * c)));
              lineto(round(rosex + (roserd * s / 8)), round(rosey - (roserd / 8 * c)));
            end;

          end;

          Pen.Mode := pmCopy;
          brush.Style := bsSolid;
        end;

    end;

  end;

end;

procedure TSplot.PlotPolyLine(p: array of Tpoint; lcolor: integer; moving: boolean);
begin

  if cfgplot.UseBMP and (not moving) then
    cbmp.DrawPolyLineAntialias(p, ColorToBGRA(lcolor), True)
  else

  if cnv <> nil then
    with cnv do
    begin
      Pen.Width := cfgchart.drawpen;

      if moving then
      begin
        Pen.Color := clWhite;
        Pen.Mode := pmXor;
      end
      else
      begin
        Pen.Color := lcolor;
        Pen.Mode := pmCopy;
      end;

      Polyline(p);
      Pen.Mode := pmCopy;

    end;

end;

procedure TSplot.FloodFill(X, Y: integer; FillColor: TColor);
begin

  if cfgplot.UseBMP then
    cbmp.FloodFill(x, y, ColorToBGRA(FillColor), fmSet)
  else
    cnv.FloodFill(x, y, FillColor, fsBorder);

end;

procedure TSplot.PlotDSOGxy(Ax, Ay: single;
  Ar1, Ar2, Apa, Arnuc, Ab_vt, Ab_ve, Ama, Asbr, Apixscale, sizeunit: double; Amorph: string;
  forcecolor: boolean; col: Tcolor; alpha:byte=255);
{
Plots galaxies - Arnuc comes thru as 0, Ab_vt and Ab_ve come thru as 100
}

var
  ds1, ds2, xx, yy: integer;
  ex, ey, th: double;
  n, ex1, ey1: integer;
  exf1, eyf1: single;
  elp: array [1..44] of Tpoint;
  elpf: array [1..44] of Tpointf;
  nebcolor: Tcolor;
  icol, r, g, b: byte;
  Nebbright, Nebgray: integer;
  lw: single;
begin
  if not forcecolor then
    col := cfgplot.Color[31];
  xx := round(Ax);
  yy := round(Ay);
  if Ar2 = 0 then
    Ar2 := Ar1 / 2;
  ds1 := round(max(Apixscale * Ar1 / 2, cfgchart.drawpen)) + cfgchart.drawpen;
  ds2 := round(max(Apixscale * Ar2 / 2, cfgchart.drawpen)) + cfgchart.drawpen;
  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillGxy then
  begin
    Nebbright := cfgplot.Nebbright;
    Nebgray := cfgplot.Nebgray;
  end
  else
  begin
    Nebbright := max(200, cfgplot.Nebbright); // not too faint in line mode
    Nebgray := max(50, cfgplot.Nebgray);
  end;
  // always compute an approximative but homogeneous sbr
  if sizeunit = 0 then
    sizeunit := 60;
  Ar1 := Ar1 * 3600 / sizeunit;
  Ar2 := Ar2 * 3600 / sizeunit;
  if Ar1 <= 0 then
    Ar1 := 1;
  if Ar2 <= 0 then
    Ar2 := Ar1;
  Asbr := Ama + 2.5 * log10(Ar1 * Ar2) - 0.26;
  Asbr := max(Asbr, Ama); // do not overbright small objects
  icol := maxintvalue([Nebgray, minintvalue([Nebbright,
    trunc(Nebbright - ((Asbr - 22) / 4) * (Nebbright - Nebgray))])]);
  if icol > 200 then
    lw := 2 * cfgchart.drawpen
  else if icol > 150 then
    lw := 1.5 * cfgchart.drawpen
  else
    lw := cfgchart.drawpen;
  r := col and $FF;
  g := (col shr 8) and $FF;
  b := (col shr 16) and $FF;
  Nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
  if cfgplot.UseBMP then
  begin
    th := 0;
    for n := 1 to 44 do
    begin
      ex := ds1 * cos(th);
      ey := ds2 * sin(th);
      exf1 := ex * sin(Apa) - ey * cos(Apa) + Ax;
      eyf1 := ex * cos(Apa) + ey * sin(Apa) + Ay;
      elpf[n] := Pointf(exf1, eyf1);
      th := th + 0.15;
    end;
    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillGxy then // line mode
      cbmp.DrawPolygonAntialias(elpf, ColorToBGRA(nebcolor), lw)
    else
      cbmp.DrawPolygonAntialias(elpf, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), cfgchart.drawpen, ColorToBGRA(nebcolor,alpha));
  end
  else
  begin
    cnv.Pen.Width := round(lw);
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Color := nebcolor;
    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillGxy) or (cfgchart.onprinter) then
    begin// line mode
      cnv.Brush.style := bsClear;
    end
    else
    begin
      cnv.Brush.style := bsSolid;
      cnv.Brush.Color := nebcolor;
    end;
    th := 0;
    for n := 1 to 44 do
    begin
      ex := ds1 * cos(th);
      ey := ds2 * sin(th);
      ex1 := round(ex * sin(Apa) - ey * cos(Apa)) + xx;
      ey1 := round(ex * cos(Apa) + ey * sin(Apa)) + yy;
      elp[n] := Point(ex1, ey1);
      th := th + 0.15;
    end;
    cnv.Polygon(elp);
  end;
end;

procedure TSplot.PlotDSOOcl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot open clusters
}
var
  sz: double;
  ds, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin
  // set defaults
  if not forcecolor then
    col := cfgplot.Color[24];
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  nebcolor := col;                           // Fix color
  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillOCl then // SBR color
  begin
    if Asbr <= 0 then
    begin
      if Adim <= +0 then
        Adim := 1;
      Asbr := Ama + 5 * log10(Adim) - 0.26;
    end;
    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 6) / 9) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;
  if cfgplot.usebmp then
  begin
    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillOCl then
    begin// line mode
      cbmp.PenStyle := psDash;
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(nebcolor), cfgchart.drawpen);
      cbmp.PenStyle := psSolid;
    end
    else
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), cfgchart.drawpen, ColorToBGRA(nebcolor,alpha));
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    cnv.Brush.Style := bsSolid;

    if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillOCl then // graphic mode
    begin
      cnv.Pen.Color := nebcolor;
      cnv.Brush.Color := nebcolor;
    end
    else
    begin
      ds := ds + cfgchart.drawpen;
      if cfgchart.onprinter and (ds < (10)) then
        cnv.Pen.Style := psSolid
      else
        cnv.Pen.Style := psDash;
      cnv.Brush.Style := bsClear;
    end;
{ and draw it... we're using an ellipse, in future we may adjust this for non-circular clusters
  use the symbol set from Display>Options
}
    cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;
end;


procedure TSplot.PlotDSOPNe(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot planetary nebulae - currently these are shown as circular...
  todo: change so that we can plot non-circular ones
  ---> nice but where to find the information ????

  Also, use Skiff's formula in DS to calc the SBr. This is fairly close
  to the published OIII brightness.
}
var
  sz: double;
  ds, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin
  // set defaults
  if not forcecolor then
    col := cfgplot.Color[26];
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  nebcolor := col;                           // Fix color
  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillPNe then // SBR color
  begin
    if Asbr <= 0 then
    begin
      if Adim <= +0 then
        Adim := 1;
      Asbr := Ama + 5 * log10(Adim) - 0.26;
    end;
    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 11) / 4) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;
  if cfgplot.usebmp then
  begin
    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillPNe then // line mode
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(nebcolor), cfgchart.drawpen)
    else
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), cfgchart.drawpen, ColorToBGRA(nebcolor,alpha));
    cbmp.DrawLineAntialias(xx - ds * 1.5, yy, xx + ds * 1.5, yy, ColorToBGRA(nebcolor), 1.5);
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillPNe) or (cfgchart.onprinter) then
    begin // line mode
      cnv.Brush.Style := bsClear;
    end
    else
    begin
      cnv.Brush.Style := bsSolid;
      cnv.Brush.Color := nebcolor;
    end;
    // and draw it... we're using an circle, in future we may adjust this for non-circular planetaries
    cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
    cnv.MoveTo((xx - round(ds * 1.5) - 1), yy);
    cnv.Pen.Width := 2 * cnv.Pen.Width;
    cnv.LineTo((xx + round(ds * 1.5)), yy);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;
end;

procedure TSplot.PlotDSOGCl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot globular clusters - currently these are shown as circular...
}
var
  sz: double;
  ds, ds2, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin
  // set defaults
  if not forcecolor then
    col := cfgplot.Color[25];
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  nebcolor := col;                           // Fix color
  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillGCl then // SBR color
  begin
    if Asbr <= 0 then
    begin
      if Adim <= +0 then
        Adim := 1;
      Asbr := Ama + 5 * log10(Adim) - 0.26;
    end;
    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 11) / 4) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;
  if cfgplot.usebmp then
  begin
    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillGCl then
    begin// line mode
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(nebcolor), cfgchart.drawpen);
      cbmp.DrawHorizLine(xx - ds, yy, xx + ds, ColorToBGRA(nebcolor));
      cbmp.DrawVertLine(xx, yy - ds, yy + ds, ColorToBGRA(nebcolor));
    end
    else
    begin
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), cfgchart.drawpen, ColorToBGRA(nebcolor,alpha));
      ds2 := ds div 3;
      nebcolor := Addcolor(nebcolor, $00202020);
      cbmp.FillEllipseAntialias(Ax, Ay, ds2, ds2, ColorToBGRA(nebcolor,alpha));
    end;
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillGCl) or (cfgchart.onprinter) then
    begin// line mode
      cnv.Brush.Style := bsClear;
      ds2 := round(ds * 2 / 3);
      ds := ds + cfgchart.drawpen;
      //    and draw it... we're using an circle,
      cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
      cnv.MoveTo(xx - ds, yy);
      cnv.LineTo(xx + ds, yy);
      cnv.MoveTo(xx, yy - ds);
      cnv.LineTo(xx, yy + ds);
    end
    else
    begin
      cnv.Brush.Style := bsSolid;
      cnv.Brush.Color := nebcolor;
      //    draw outer limit
      cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
      cnv.Brush.Color := Addcolor(cnv.Brush.Color, $00202020);
      cnv.Pen.Color := cnv.Brush.Color;
      ds2 := ds div 3; // a third looks more realistic
      //    draw core
      cnv.Ellipse(xx - ds2, yy - ds2, xx + ds2, yy + ds2);
    end;
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;

  end;
end;

procedure TSplot.PlotDSOBN(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot bright nebula - both emmission and reflection are plotted the same
  in the future, we'll separate these out, maybe even for Herbig-Haro and variable nebulae
}
var
  sz: double;
  ds, dsr, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
  ObjMorph: string;
  fill: boolean;
begin
  // set defaults
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  dsr := ds div 4;
  // emission of reflection nebula?
  ObjMorph := LeftStr(Amorph, 1);
  if ObjMorph = 'R' then
  begin
    if not forcecolor then
      col := cfgplot.Color[29];
    nebcolor := col;
    fill := cfgplot.DSOColorFillRN and not cfgchart.onprinter;
  end
  else
  begin
    if not forcecolor then
      col := cfgplot.Color[28];
    nebcolor := col;
    fill := cfgplot.DSOColorFillEN and not cfgchart.onprinter;
  end;
  if (cfgplot.nebplot = 1) and fill then // SBR color
  begin
    if Asbr <= 0 then
    begin
      if Adim <= +0 then
        Adim := 1;
      Asbr := Ama + 5 * log10(Adim) - 0.26;
    end;
    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 11) / 4) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := nebcolor and $FF;
    g := (nebcolor shr 8) and $FF;
    b := (nebcolor shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;
  if cfgplot.UseBMP then
  begin
    if (cfgplot.nebplot = 0) or not fill then
    begin// line mode
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ColorToBGRA(nebcolor),
        BGRAPixelTransparent);
    end
    else
    begin
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), ColorToBGRA(nebcolor,alpha));
    end;
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    if (cfgplot.nebplot = 0) or (not fill) or (cfgchart.onprinter) then
    begin// line mode
      cnv.Brush.Style := bsClear;
    end
    else
    begin
      cnv.Brush.Style := bsSolid;
      cnv.Brush.Color := nebcolor;
    end;
    //    and draw it... we're using an rectangle in the event that we don't have an outline
    cnv.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;
end;

procedure TSplot.PlotDSOClNb(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot nebula and cluster associations - e.g. M8, M42...
}
var
  sz: double;
  ds, dsr, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[29];

  xx := round(Ax);
  yy := round(Ay);

  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  dsr := ds div 4;
  nebcolor := col;                           // Fix color

  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillRN then // SBR color
  begin

    if Asbr <= 0 then
    begin

      if Adim <= +0 then
        Adim := 1;

      Asbr := Ama + 5 * log10(Adim) - 0.26;
    end;

    //    adjust colour by using Asbr and UI options

    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 6) / 9) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);

    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;

    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;

  if cfgplot.UseBMP then
  begin

    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillRN then
    begin// line mode
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ColorToBGRA(
        nebcolor), BGRAPixelTransparent);
      cbmp.DrawHorizLine(xx - ds, yy, xx + ds, ColorToBGRA(nebcolor));
      cbmp.DrawVertLine(xx, yy - ds, yy + ds, ColorToBGRA(nebcolor));
    end
    else
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), ColorToBGRA(nebcolor,alpha));

  end
  else

  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;

    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillRN) or (cfgchart.onprinter) then
    begin// line mode
      cnv.Brush.Style := bsClear;
      ds := ds + cfgchart.drawpen;
      cnv.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr);
      cnv.MoveTo(xx - ds, yy);
      cnv.Pen.Color := cfgplot.Color[24];
      cnv.LineTo(xx + ds, yy);
      cnv.MoveTo(xx, yy - ds);
      cnv.LineTo(xx, yy + ds);
    end
    else
    begin
      cnv.Brush.Style := bsSolid;
      cnv.Brush.Color := nebcolor;
      cnv.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr);
    end;

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
  Plot DSO that is actually a single star
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[24];

  xx := round(Ax);
  yy := round(Ay);
  Adim := 0.5;
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    cbmp.DrawHorizLine(xx - ds, yy, xx + ds, ColorToBGRA(col));
    cbmp.DrawVertLine(xx, yy - ds, yy + ds, ColorToBGRA(col));
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;

    // Plotted as an '+', so there's no difference between line and graphics mode
    // we use the same colour as for open clusters

    cnv.MoveTo(xx - ds, yy);
    cnv.LineTo(xx + ds, yy);
    cnv.MoveTo(xx, yy - ds);
    cnv.LineTo(xx, yy + ds);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSODStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
  Plot DSO that is actually a double star
  DSO's as stars are slit into different routines as we may decide to use
  different symbols for single, or multiple stars cataloged as DSOs.
  ToDO: Implement user-definable symbol sets.
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[24];

  xx := round(Ax);
  yy := round(Ay);

  Adim := 0.5;
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    cbmp.DrawHorizLine(xx - ds, yy, xx + ds, ColorToBGRA(col));
    cbmp.DrawVertLine(xx, yy - ds, yy + ds, ColorToBGRA(col));
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;

    // Plotted as a '+', so there's no difference between line and graphics mode
    // we use the same colour as for open clusters

    cnv.MoveTo(xx - ds, yy);
    cnv.LineTo(xx + ds, yy);
    cnv.MoveTo(xx, yy - ds);
    cnv.LineTo(xx, yy + ds);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOTStar(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
 Plot DSO that is actually a triple star
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[24];

  xx := round(Ax);
  yy := round(Ay);

  Adim := 0.5;
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    cbmp.DrawHorizLine(xx - ds, yy, xx + ds, ColorToBGRA(col));
    cbmp.DrawVertLine(xx, yy - ds, yy + ds, ColorToBGRA(col));
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;

    // Plotted as a '+', so there's no difference between line and graphics mode
    // we use the same colour as for open clusters

    cnv.MoveTo(xx - ds, yy);
    cnv.LineTo(xx + ds, yy);
    cnv.MoveTo(xx, yy - ds);
    cnv.LineTo(xx, yy + ds);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOAst(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Asterisms are chance? groupings of stars so plot as for open clusters apart from colour
}
var
  sz: double;
  ds, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[23];

  xx := round(Ax);
  yy := round(Ay);

  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  nebcolor := col;                           // Fix color

  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillAst then // SBR color
  begin

    if Asbr <= 0 then
    begin

      if Adim <= +0 then
        Adim := 1;

      Asbr := Ama + 5 * log10(Adim) - 0.26;

    end;

    if Asbr < 10 then
      Asbr := 10;  //some very bright cluster make too bright surface

    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 6) / 9) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;

  if cfgplot.usebmp then
  begin

    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillAst then
    begin// line mode
      cbmp.PenStyle := psDashDot;
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(nebcolor), cfgchart.drawpen);
      cbmp.PenStyle := psSolid;
    end
    else
      cbmp.EllipseAntialias(Ax, Ay, ds, ds, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), cfgchart.drawpen, ColorToBGRA(nebcolor,alpha));

  end
  else

  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillAst) or (cfgchart.onprinter) then
    begin// line mode
      cnv.Brush.Style := bsClear;
      cnv.Pen.Style := psDashDot;
      //{$ifdef mswindows}cnv.Pen.width:=1;{$endif}
    end
    else
    begin
      cnv.Brush.Style := bsSolid;
      cnv.Brush.Color := nebcolor;
    end;

    // and draw it... we're using an ellipse, in future we may adjust this for non-circular asterisms
    cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOHIIRegion(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor; alpha:byte);
{
  Plot HII regions. NGC has these catalogued as 'knots'. We plot them as if they
  are emission nebulae (bright nebulae)
  Catalogued as Nebula in SAC 8.2.
}
var
  sz: double;
  ds, dsr, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin
  // set defaults
  if not forcecolor then
    col := cfgplot.Color[28];
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  dsr := ds div 4;
  nebcolor := col;                           // Fix color

  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillEN then // SBR color
  begin

    if Asbr <= 0 then
    begin

      if Adim <= +0 then
        Adim := 1;

      Asbr := Ama + 5 * log10(Adim) - 0.26;

    end;
    //    adjust colour by using Asbr and UI options

    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - ((Asbr - 11) / 4) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;

  if cfgplot.UseBMP then
  begin

    if (cfgplot.nebplot = 0) or not cfgplot.DSOColorFillEN then
      // line mode
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ColorToBGRA(
        nebcolor), BGRAPixelTransparent)
    else
      cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ApplyLightnessFast(ColorToBGRA(nebcolor),35000), ColorToBGRA(nebcolor,alpha));

  end
  else

  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;

    if (cfgplot.nebplot = 0) or (not cfgplot.DSOColorFillEN) or (cfgchart.onprinter) then
      // line mode
      cnv.Brush.Style := bsClear
    else
      cnv.Brush.Style := bsSolid;

    cnv.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOGxyCl(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor);
{
  Plot galaxy cluster - in SAC they are the Abell clusters, the size is the Abell radius
  confusingly, this is not the *angular* radius of the cluster   (reference ???)
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[32];

  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    cbmp.PenStyle := psDot;
    cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(col), cfgchart.drawpen);
    cbmp.PenStyle := psSolid;
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psDot;
    {$ifdef mswindows}
    cnv.Pen.Width := 1;
{$endif}
    cnv.Pen.Color := col;
    cnv.Brush.Style := bsClear;
  { Plotted as an open dashed circle, so there's no difference between line and
    graphics mode
  }
    ds := ds + cfgchart.drawpen;
    cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSODN(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; Amorph: string; forcecolor: boolean; col: Tcolor);
{
  Plot dark nebula
}
var
  sz: double;
  ds, dsr, xx, yy: integer;
  icol, r, g, b: byte;
  nebcolor: Tcolor;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[27];

  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));
  dsr := ds div 4;
  nebcolor := col;                          // Fix color

  if (cfgplot.nebplot = 1) and cfgplot.DSOColorFillDN then // SBR color
  begin

    if Asbr <= 0 then
    begin

      if Adim <= +0 then
        Adim := 1;

      Asbr := Ama + 5 * log10(Adim) - 0.26;

    end;

    //    adjust colour by using Asbr and UI options
    icol := maxintvalue([cfgplot.Nebgray, minintvalue(
      [cfgplot.Nebbright, trunc(cfgplot.Nebbright - (0.8) *
      (cfgplot.Nebbright - cfgplot.Nebgray))])]);
    r := col and $FF;
    g := (col shr 8) and $FF;
    b := (col shr 16) and $FF;
    nebcolor := (r * icol div 255) + 256 * (g * icol div 255) + 65536 * (b * icol div 255);
    nebcolor := Addcolor(nebcolor, cfgplot.backgroundcolor);
  end;

  if cfgplot.UseBMP then
    // never fill dark nebulae
    cbmp.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr, ColorToBGRA(
      nebcolor), BGRAPixelTransparent)
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := nebcolor;
    cnv.Brush.Style := bsClear;
    cnv.RoundRect(xx - ds, yy - ds, xx + ds, yy + ds, dsr, dsr);
    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOUnknown(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
 Plot unknown object?
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[35];

  xx := round(Ax);
  yy := round(Ay);
  Adim := 0.5;
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    BGRADrawLine(Ax - ds, Ay - ds, Ax + ds, Ay + ds, ColorToBGRA(col), 1, cbmp);
    BGRADrawLine(Ax + ds, Ay - ds, Ax - ds, Ay + ds, ColorToBGRA(col), 1, cbmp);
  end
  else
  begin
    cnv.Pen.Width := cfgchart.drawpen;

    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;

    // Plotted as an 'X', so there's no difference between line and graphics mode

    cnv.MoveTo(xx - ds, yy - ds);
    cnv.LineTo(xx + ds + 1, yy + ds);
    cnv.MoveTo(xx + ds, yy - ds);
    cnv.LineTo(xx - ds, yy + ds + 1);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;
end;

procedure TSplot.PlotDSOCircle(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
 Plot a circle
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults
  if not forcecolor then
    col := cfgplot.Color[7];

  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
    cbmp.EllipseAntialias(Ax, Ay, ds, ds, ColorToBGRA(col), cfgchart.drawpen)
  else

  begin
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;
    cnv.Brush.Style := bsClear;

    // Plotted as a circle, so there's no difference between line and graphics mode

    cnv.Ellipse(xx - ds, yy - ds, xx + ds, yy + ds);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSORectangle(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
 Plot a rectangle
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults

  if not forcecolor then
    col := cfgplot.Color[7];

  xx := round(Ax);
  yy := round(Ay);

  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
    BGRARectangle(Ax - ds, Ay - ds, Ax + ds, Ay + ds, ColorToBGRA(col), cfgchart.drawpen, cbmp)
  else
  begin
    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := col;
    cnv.Brush.Style := bsClear;

    // Plotted as a rectangle, so there's no difference between line and graphics mode

    cnv.Rectangle(xx - ds, yy - ds, xx + ds, yy + ds);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

procedure TSplot.PlotDSOlozenge(Ax, Ay: single; Adim, Ama, Asbr, Apixscale: double;
  Atyp: integer; forcecolor: boolean; col: Tcolor);
{
 Plot a lozenge
}
var
  sz: double;
  ds, xx, yy: integer;
begin

  // set defaults
  if not forcecolor then
    col := cfgplot.Color[7];
  xx := round(Ax);
  yy := round(Ay);
  sz := APixScale * Adim / 2;                         // calc size
  ds := round(max(sz, cfgplot.MinDsoSize * cfgchart.drawpen));

  if cfgplot.UseBMP then
  begin
    cbmp.DrawPolygonAntialias([PointF(xx, yy - ds), PointF(Ax + ds, Ay),
      PointF(Ax, Ay + ds), PointF(Ax - ds, Ay), PointF(Ax, Ay - ds)],
      ColorToBGRA(col), cfgchart.drawpen);
  end
  else
  begin

    cnv.Pen.Mode := pmCopy;
    cnv.Pen.Style := psSolid;
    cnv.Pen.Color := cfgplot.Color[7];
    cnv.Brush.Style := bsClear;

    // Plotted as a lozenge, so there's no difference between line and graphics mode

    cnv.polygon([point(xx, yy - ds), point(xx + ds, yy),
      point(xx, yy + ds), point(xx - ds, yy), point(xx, yy - ds)]);

    // reset brush and pen back to default ready for next object
    cnv.Brush.Style := bsClear;
    cnv.Pen.Style := psSolid;
  end;

end;

/// BGRAbitmap interface
function TSplot.BGRATextOut(x, y, o: single; s: string; c: TBGRAPixel;
  abmp: TBGRABitmap; forceantialias: boolean = False): TRect;

const
  aafactor = 2;

var
  size: TSize;
  temp: TBGRABitmap;
  aacx, aacy, orient: integer;
  TopRight, BottomRight, BottomLeft: TPointF;
  cosA, sinA, tx, ty: single;
  rotBounds: TRect;
  sizeFactor: integer;

  procedure rotBoundsAdd(pt: TPointF);
  begin
    if floor(pt.X) < rotBounds.Left then
      rotBounds.Left := floor(pt.X / sizeFactor) * sizeFactor;
    if floor(pt.Y) < rotBounds.Top then
      rotBounds.Top := floor(pt.Y / sizeFactor) * sizeFactor;
    if ceil(pt.X) > rotBounds.Right then
      rotBounds.Right := ceil(pt.X / sizeFactor) * sizeFactor;
    if ceil(pt.Y) > rotBounds.Bottom then
      rotBounds.Bottom := ceil(pt.Y / sizeFactor) * sizeFactor;
  end;

begin

  orient := round(10 * o);

  if cfgplot.AntiAlias or (forceantialias) then
  begin
    size := abmp.TextSize(s);
    sizeFactor := aafactor;

    if orient <> 0 then
    begin
      cosA := cos(orient * Pi / 1800);
      sinA := sin(orient * Pi / 1800);

      TopRight := PointF(cosA * size.cx, -sinA * size.cx);
      BottomRight := PointF(cosA * size.cx + sinA * size.cy, cosA * size.cy - sinA * size.cx);
      BottomLeft := PointF(sinA * size.cy, cosA * size.cy);
      rotBounds := rect(0, 0, 0, 0);
      rotBoundsAdd(TopRight);
      rotBoundsAdd(BottomRight);
      rotBoundsAdd(BottomLeft);
      Inc(rotBounds.Right);
      Inc(rotBounds.Bottom);
      size.cx := rotBounds.Right - rotBounds.Left;
      size.cy := rotBounds.Bottom - rotBounds.Top;
    end
    else
    begin
      rotBounds.Left := 0;
      rotBounds.Top := 0;
    end;

    aacx := round(max((aafactor + 0.2) * size.cx, aafactor * (size.cx + 1)));
    aacy := aafactor * size.cy;

    temp := TBGRABitmap.Create(aacx, aacy);

    try

      //  temp.Rectangle(0,0,aacx,aacy,clred);
      temp.FontHeight := aafactor * abmp.FontHeight;
      temp.FontStyle := abmp.FontStyle;
      temp.FontName := abmp.FontName;
      temp.FontOrientation := orient;

      tx := frac(x) - rotBounds.Left;
      ty := frac(y) - rotBounds.Top;

      temp.TextOut(round(aafactor * tx), round(aafactor * ty), s, c);
      temp.ResampleFilter := rfMitchell;

      BGRAReplace(temp, temp.Resample(size.cx, size.cy, rmFineResample));

      abmp.PutImage(trunc(x - tx), trunc(y - ty), temp, dmDrawWithTransparency);

    finally
      temp.Free;
    end;

    Result.Left := rotBounds.Left;
    Result.Top := rotBounds.Top;
    Result.Right := size.cx;
    Result.Bottom := size.cy;
  end
  else
    abmp.TextOutAngle(round(x), round(y), orient, s, c, taLeftJustify);

end;

procedure TSplot.BGRADrawLine(x1, y1, x2, y2: single; c: TBGRAPixel;
  w: single; abmp: TBGRABitmap; ps: TPenStyle = psSolid);
begin

  if cfgplot.AntiAlias then
    abmp.CanvasBGRA.AntialiasingMode:=amOn
  else
    abmp.CanvasBGRA.AntialiasingMode:=amOff;

  abmp.CanvasBGRA.Pen.Style := ps;
  abmp.CanvasBGRA.Pen.Width := ceil(w);
  abmp.CanvasBGRA.Pen.Color := BGRAToColor(c);
  abmp.CanvasBGRA.MoveTo(round(x1), round(y1));
  abmp.CanvasBGRA.LineTo(round(x2), round(y2));
  abmp.CanvasBGRA.Pen.Style := psSolid;
  abmp.CanvasBGRA.Pen.Width := 1;
  abmp.Pen.Style := psSolid;

end;

procedure TSplot.BGRARectangle(x1, y1, x2, y2: single; c: TBGRAPixel;
  w: single; abmp: TBGRABitmap);
begin

  if cfgplot.AntiAlias or (w > 1) then
    abmp.RectangleAntialias(x1, y1, x2, y2, c, w)
  else
    abmp.Rectangle(round(x1), round(y1), round(x2), round(y2), c, dmSet);

end;


end.
