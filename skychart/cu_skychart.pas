unit cu_skychart;

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
 Skychart computation component
}
{$mode objfpc}{$H+}

interface

uses
  u_translation, gcatunit, UScaleDPI,
  BGRABitmap, BGRABitmapTypes, contnrs, FPCanvas,
  cu_plot, cu_catalog, cu_fits, u_constant, cu_planet, cu_database,
  u_projection, u_util,
  pu_addlabel, SysUtils, Classes, Math, Types, Buttons, Dialogs,
  Forms, StdCtrls, Controls, ExtCtrls, Graphics, FPImage, LCLType, IntfGraphics;

type
  Tint2func = procedure(i, j: integer) of object;
  Tfloat2func = procedure(n: string; x, y: double) of object;

  TDrawHorizonThread = class(TThread)
  public
    horizonpicture: TBGRABitmap;
    hbmp: TBGRABitmap;
    col2: TBGRAPixel;
    cfgsc: Tconf_skychart;
    working, lowquality: boolean;
    num, id: integer;
    procedure Execute; override;
    constructor Create(CreateSuspended: boolean);
  end;

  Tskychart = class(TComponent)
  private
    Fplot: TSplot;
    FFits: TFits;
    Fcatalog: Tcatalog;
    Fplanet: Tplanet;
    Fcdb: Tcdcdb;
    FShowDetailXY: Tint2func;
    FonTelescopeMove: Tfloat2func;
    fsat: textfile;
    constlabelindex: integer;
    bgcra, bgcde, bgfov, bgmis, bgmas, bgrot: double;
    bgvalid, HorizonDone: boolean;
    bgw, bgh, bgproj, bgflipx, bgflipy: integer;
    nebmagmin, nebmagmax: single;
    FObjectListLabels: TStringList;
    FUpdObsList: boolean;
    FUpdObsListTime: TNotifyEvent;
    FRefreshImage: TNotifyEvent;
    procedure DrawSatel(j, ipla: integer; ra, Dec, ma, diam, pixscale, rot: double;
      hidesat, showhide: boolean; ra2000, de2000: double);
    procedure InitLabels;
    procedure SetLabel(id: integer; xx, yy: single; radius, fontnum, labelnum: integer;
      txt: string; align: TLabelAlign = laLeft; orient: single = 0; priority: integer = 5;
      opt: boolean = True; lsize: single = -1);
    procedure EditLabelPos(lnum, x, y, w, h: integer; moderadec: boolean);
    procedure EditLabelTxt(lnum, x, y, w, h: integer; mode: boolean);
    procedure DefaultLabel(lnum: integer);
    procedure DeleteLabel(lnum: integer);
    procedure LabelClick(lnum: integer);
    procedure SetImage(Value: TCanvas);
    procedure DrawHorizonPicture(hbmp: TBGRABitmap);
    function DrawRAline(ra, de, dd, dra: double; drawlabel: boolean; col,linewidth,dir,lh,lt: integer; linestyle: TFPPenStyle; var labelok:boolean): boolean;
    function DrawDEline(ra, de, da,dde,ra1: double; drawlabel: boolean; col,linewidth,dir,lh,lt: integer; linestyle: TFPPenStyle; var labelok:boolean): boolean;
  public
    cfgsc: Tconf_skychart;
    horizonpicture, horizonpicturedark: TBGRABitmap;
    labels: array[1..maxlabels] of Tobjlabel;
    numlabels: integer;
    dsopos: array[1..maxlabels] of TPoint;
    numdsopos: integer;
    bgbmp: Tbitmap;
    bgsettingchange: boolean;
    function CenterRot: double;
    procedure ResetAllLabel;
    procedure AddNewLabel(ra, Dec: double);
    procedure SetLang;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property plot: TSplot read Fplot;
    property catalog: Tcatalog read Fcatalog write Fcatalog;
    property planet: Tplanet read Fplanet write Fplanet;
    property cdb: Tcdcdb read Fcdb write Fcdb;
    property Fits: TFits read FFits write FFits;
    property ObjectListLabels: TStringList read FObjectListLabels
      write FObjectListLabels;
    property UpdObsList: boolean read FUpdObsList write FUpdObsList;
    function Refresh(newtime: boolean): boolean;
    function InitCatalog(fov:double): boolean;
    function InitTime(newtime: boolean): boolean;
    function InitChart(full: boolean = True): boolean;
    function InitColor: boolean;
    function GetFieldNum(fov: double): integer;
    function InitCoordinates: boolean;
    function InitObservatory: boolean;
    function DrawCustomlabel: boolean;
    procedure DrawObsListLabel;
    function DrawStars: boolean;
    function DrawVarStars: boolean;
    function DrawDblStars: boolean;
    function DrawDeepSkyObject: boolean;
    function DrawImagesList: boolean;
    function DrawOutline: boolean;
    function DrawDSL: boolean;
    function DrawMilkyWay: boolean;
    function DrawPlanet: boolean;
    procedure DrawEarthShadow(AR, DE, SunDist, MoonDist, MoonDistTopo, flatten: double);
    function DrawAsteroidMark: boolean;
    function DrawAsteroid: boolean;
    function DrawCometMark: boolean;
    function DrawComet: boolean;
    function DrawBodies: boolean;
    procedure DrawArtSat;
    function CloseSat: integer;
    function FindArtSat(x1, y1, x2, y2: double; nextobj: boolean;
      var nom, ma, desc: string): boolean;
    function DrawOrbitPath: boolean;
    procedure DrawPrePointLine;
    procedure DrawGrid(drawlabel: boolean);
    procedure DrawAltAzEqGrid;
    procedure DrawPole(pole: integer);
    procedure DrawEqGrid(drawlabel: boolean; altstyle: boolean = False);
    procedure DrawAzGrid(drawlabel: boolean);
    procedure DrawGalGrid(drawlabel: boolean);
    procedure DrawEclGrid(drawlabel: boolean);
    procedure DrawTelescopeLimit;
    procedure DrawMeridian;
    procedure DrawScale;
    procedure DrawBorder;
    function DrawConstL: boolean;
    function DrawConstB: boolean;
    function DrawHorizon: boolean;
    function DrawEcliptic: boolean;
    function DrawGalactic: boolean;
    function DrawEquator: boolean;
    function DrawPlanisphereDate: boolean;
    function DrawPlanisphereTime: boolean;
    procedure OptimizeLabels;
    function DrawLabels: boolean;
    procedure DrawLegend;
    procedure DrawSearchMark(ra, de: double; moving: boolean);
    procedure DrawFinderMark(ra, de: double; moving: boolean; num: integer; mark: integer = 0);
    procedure DrawEyepieceMask;
    procedure DrawCircle;
    procedure DrawTarget;
    procedure DrawCompass;
    procedure DrawCRose;
    function TelescopeMove(ra, Dec: double): boolean;
    function Telescope2Move(ra, Dec: double): boolean;
    procedure GetCoord(x, y: integer; var ra, Dec, a, h, l, b, le, be: double);
    procedure MoveCenter(loffset, boffset: double);
    procedure MoveChart(ns, ew: integer; movefactor: double);
    procedure MovetoXY(X, Y: integer);
    procedure MovetoRaDec(ra, Dec: double);
    procedure Zoom(zoomfactor: double);
    procedure SetFOV(f: double);
    function PoleRot2000(ra, Dec: double): double;
    procedure FormatCatRec(rec: Gcatrec; var desc: string);
    procedure FindRiseSet(mode: integer);
    function FindatRaDec(ra, Dec, dx: double; searchcenter: boolean;
      showall: boolean = False; ftype: integer = ftAll; planetcenter: boolean = False): boolean;
    procedure GetLabPos(ra, Dec, r: double; w, h: integer; var x, y: integer);
    procedure FindList(ra, Dec, dx, dy: double; var Text, msg: string; showall, allobject, trunc, usefov: boolean; maxln:integer=1000);
    procedure FindListWin(var Text, msg: string; showall, allobject: boolean);
    property OnShowDetailXY: Tint2func read FShowDetailXY write FShowDetailXY;
    function GetChartInfo(sep: string = blank): string;
    function GetChartPos: string;
    procedure LoadHorizon;
    procedure LoadHorizonPicture(fname: string);
    property Image: TCanvas write SetImage;
    property onRefreshImage: TNotifyEvent read FRefreshImage write FRefreshImage;
    property onUpdObsListTime: TNotifyEvent read FUpdObsListTime write FUpdObsListTime;
    property onTelescopeMove: Tfloat2func read FonTelescopeMove write FonTelescopeMove;
  end;


implementation

function doSimLabel(simnb, step, simlabel: integer): boolean;
begin
  Result := False;
  case simlabel of
    -1000.. -1: Result := ((step mod abs(simlabel)) = 0); // one of ...
    0: Result := (simnb = 1);       // none if more than one point
    1: Result := (step = 0);        // first
    2: Result := (step = simnb - 1);  // last
    3: Result := True;            // every
  end;
end;

constructor Tskychart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  horizonpicture := TBGRABitmap.Create;
  horizonpicturedark := TBGRABitmap.Create;
  // set safe value
  cfgsc := Tconf_skychart.Create;
  cfgsc.quick := False;
  cfgsc.JDChart := jd2000;
  cfgsc.lastJDchart := -1E25;
  cfgsc.racentre := 0;
  cfgsc.decentre := 0;
  cfgsc.fov := 1;
  cfgsc.theta := 0;
  cfgsc.projtype := 'A';
  cfgsc.ProjPole := Equat;
  cfgsc.FlipX := 1;
  cfgsc.FlipY := 1;
  cfgsc.WindowRatio := 1;
  cfgsc.BxGlb := 1;
  cfgsc.ByGlb := 1;
  cfgsc.AxGlb := 0;
  cfgsc.AyGlb := 0;
  cfgsc.xshift := 0;
  cfgsc.yshift := 0;
  cfgsc.xmin := 0;
  cfgsc.xmax := 100;
  cfgsc.ymin := 0;
  cfgsc.ymax := 100;
  cfgsc.RefractionOffset := 0;
  cfgsc.AsteroidLstSize := 0;
  cfgsc.CometLstSize := 0;
  cfgsc.nummodlabels := 0;
  cfgsc.posmodlabels := 0;
  cfgsc.numcustomlabels := 0;
  cfgsc.poscustomlabels := 0;
  cfgsc.LeftMargin := 0;
  cfgsc.RightMargin := 0;
  cfgsc.TopMargin := 0;
  cfgsc.BottomMargin := 0;
  Fplot := TSplot.Create(AOwner);
  Fplot.OnEditLabelPos := @EditLabelPos;
  Fplot.OnEditLabelTxt := @EditLabelTxt;
  Fplot.OnDefaultLabel := @DefaultLabel;
  Fplot.OnDeleteLabel := @DeleteLabel;
  Fplot.OnDeleteAllLabel := @ResetAllLabel;
  Fplot.OnLabelClick := @LabelClick;
  bgbmp := Tbitmap.Create;
  bgsettingchange := False;
  bgvalid := False;
end;

destructor Tskychart.Destroy;
begin
  try
    Fplot.Free;
    cfgsc.Free;
    bgbmp.Free;
    horizonpicture.Free;
    horizonpicturedark.Free;
    inherited Destroy;
  except
    writetrace('error destroy ' + Name);
  end;
end;

procedure Tskychart.SetLang;
begin
  if f_addlabel <> nil then
    f_addlabel.SetLang;
  Fplot.editlabelmenu.Items[2].Caption := rsMoveLabel;
  Fplot.editlabelmenu.Items[3].Caption := rsOffsetLabel;
  Fplot.editlabelmenu.Items[4].Caption := rsEditLabel;
  Fplot.editlabelmenu.Items[5].Caption := rsDefaultLabel;
  Fplot.editlabelmenu.Items[6].Caption := rsHideLabel;
  Fplot.editlabelmenu.Items[7].Caption := rsResetAllLabe;
end;

procedure Tskychart.SetImage(Value: TCanvas);
begin
  FPlot.Image := Value;
end;

function Tskychart.Refresh(newtime: boolean): boolean;
var
  savmag: double;
  savebg: Tcolor;
  savfilter, saveautofilter, savfillmw, scopemark, savApparentPos: boolean;
  saveplaplot: integer;
  step: string;
begin
  try
  step:='Init';
  if VerboseMsg then
  begin
    if cfgsc.quick and FPlot.cfgplot.red_move then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': Simplified Refresh')
    else
      WriteTrace('SkyChart ' + cfgsc.chartname + ': Full Refresh');
  end;
  savmag := Fcatalog.cfgshr.StarMagFilter[cfgsc.FieldNum];
  savApparentPos := cfgsc.ApparentPos;
  savfilter := Fcatalog.cfgshr.StarFilter;
  saveautofilter := Fcatalog.cfgshr.AutoStarFilter;
  savfillmw := cfgsc.FillMilkyWay;
  scopemark := cfgsc.ScopeMark;
  saveplaplot := Fplot.cfgplot.plaplot;
  savebg := Fplot.cfgplot.color[0];
  newtime := newtime or (cfgsc.fov > (10 * minarc));
  try
    chdir(appdir);
    // initialize chart value
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': Init');
    cfgsc.msg := '';
    step:='Init observatory';
    InitObservatory;
    step:='Init time';
    InitTime(newtime);
    step:='Init chart';
    InitChart;
    step:='Init coordinates';
    InitCoordinates; // now include ComputePlanet
    if cfgsc.quick and FPlot.cfgplot.red_move then
    begin
      Fcatalog.cfgshr.StarFilter := True;
      //if Fplot.cfgplot.plaplot=2 then Fplot.cfgplot.plaplot := 1;
    end
    else
    begin
      step:='Init labels';
      InitLabels;
    end;
    step:='Init color';
    InitColor; // after ComputePlanet
    // draw objects
    HorizonDone := False;
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': Open catalogs');
    step:='Open catalog';
    Fcatalog.OpenCat(cfgsc);
    step:='Init catalog';
    InitCatalog(cfgsc.fov);
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': begin drawing');
    // first the extended object
    if not (cfgsc.quick and FPlot.cfgplot.red_move) then
    begin
      step:='draw images 1';
      // the images first on canvas that not support the transparency
      if cfgsc.PlotImageFirst then
      begin
        if cfgsc.ShowHorizonPicture and (not HorizonDone) then
          DrawHorizon;
        if cfgsc.ShowImageList then
          DrawImagesList;
      end;
      DrawMilkyWay; // most extended first
      // EQ grid in ALt/Az mode
      DrawAltAzEqGrid;
      // then the horizon line if transparent
      if (not cfgsc.horizonopaque) and (not HorizonDone) then
        DrawHorizon;
    end;
    // the DSO
    step:='draw dso';
    DrawDeepSkyObject;
    step:='draw lines 1';
    if not (cfgsc.quick and FPlot.cfgplot.red_move) then
    begin
      if cfgsc.showline then
      begin
        DrawDSL;
      end;
      DrawOutline;
      DrawCometMark;
      DrawComet;
    end;
    if not (cfgsc.ShowPlanet and FPlot.cfgplot.TransparentPlanet and
      (FPlot.cfgplot.plaplot = 1)) then
    begin
      // then the lines if planet opaque or not line mode
      DrawGrid(False);
      if not (cfgsc.quick and FPlot.cfgplot.red_move) then
      begin
        DrawConstL;
        DrawConstB;
        DrawEcliptic;
        DrawGalactic;
        DrawEquator;
        DrawPrePointLine;
        DrawTelescopeLimit;
      end;
    end;
    // the stars
    step:='draw stars';
    if cfgsc.showstars then
      DrawStars;
    if not (cfgsc.quick and FPlot.cfgplot.red_move) then
    begin
      if cfgsc.showstars then
        DrawDblStars;
      if cfgsc.showstars then
        DrawVarStars;
    end;
    // the planets
    step:='draw planets';
    if not (cfgsc.quick and FPlot.cfgplot.red_move) then
    begin
      DrawAsteroidMark;
      DrawAsteroid;
      DrawBodies;
      if cfgsc.SimLine then
        DrawOrbitPath;
    end;
    if cfgsc.ShowPlanetValid then
      DrawPlanet;
    step:='draw lines 2';
    if (cfgsc.ShowPlanet and FPlot.cfgplot.TransparentPlanet and
      (FPlot.cfgplot.plaplot = 1)) then
    begin
      // then the lines if planet transparent + line mode
      DrawGrid(False);
      if not (cfgsc.quick and FPlot.cfgplot.red_move) then
      begin
        DrawConstL;
        DrawConstB;
        DrawEcliptic;
        DrawGalactic;
        DrawEquator;
        DrawPrePointLine;
        DrawTelescopeLimit;
      end;
    end;
    // Finder mark
    DrawCircle;
    // Artificials satellites
    step:='draw satellites';
    if cfgsc.ShowArtSat then
      DrawArtSat;
    // BG image
    step:='draw image list';
    if (not (cfgsc.quick and FPlot.cfgplot.red_move)) and (not cfgsc.PlotImageFirst) and
      cfgsc.ShowImageList then
      DrawImagesList;

    // the labels
    step:='draw label';
    if (not (cfgsc.quick and FPlot.cfgplot.red_move)) and cfgsc.showlabelall then
      DrawLabels;

    // the horizon line if not transparent
    step:='draw horizon';
    if (not (cfgsc.quick and FPlot.cfgplot.red_move)) and (not HorizonDone) then
      DrawHorizon;

    // the coordinates grid labels
    step:='draw grid';
    if cfgsc.ShowGridNum then
      DrawGrid(True);

    // Mask the chart outside of eyepiece
    step:='draw mask';
    DrawEyepieceMask;

    // the compass and scale
    step:='draw compass';
    DrawCompass;
    DrawTarget;

    // Planisphere
    step:='draw planisphere';
    DrawPlanisphereTime;
    DrawPlanisphereDate;

    // Draw the chart border
    step:='draw border';
    DrawBorder;

    // the chart legend
    step:='draw legend';
    DrawLegend;

    // refresh telescope mark
    if scopemark then
      cfgsc.ScopeMark := True;

    Result := True;
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': end drawing');
    step:='finalize';
  finally
    Fcatalog.CloseCat;
    cfgsc.ApparentPos := savApparentPos;
    if cfgsc.quick and FPlot.cfgplot.red_move then
    begin
      Fcatalog.cfgshr.StarMagFilter[cfgsc.FieldNum] := savmag;
      Fcatalog.cfgshr.StarFilter := savfilter;
      Fcatalog.cfgshr.AutoStarFilter := saveautofilter;
      Fplot.cfgplot.plaplot := saveplaplot;
    end;
    Fplot.cfgplot.color[0] := savebg;
    cfgsc.FillMilkyWay := savfillmw;
    cfgsc.quick := False;
  end;
  step:='refresh image';
  if assigned(FRefreshImage) then
    FRefreshImage(self);
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': end Refresh');
  except
    on E: Exception do begin
      cfgsc.msg := 'Draw chart, '+step+' error: ' + E.Message;
      WriteTrace(cfgsc.msg); // better to write the error two time than risk the message is overwriten
    end;
  end;
end;

function Tskychart.InitCatalog(fov:double): boolean;
var
  i,FieldNum: integer;
  mag, magmax, f: double;
  vostar_magmax: double;

  procedure InitStarC(cat: integer; defaultmag: double);
  { determine if the star catalog is active at this scale }
  begin
    if Fcatalog.cfgcat.starcatdef[cat - BaseStar] and
      (FieldNum >= Fcatalog.cfgcat.starcatfield[cat - BaseStar, 1]) and
      (FieldNum <= Fcatalog.cfgcat.starcatfield[cat - BaseStar, 2]) then
    begin
      Fcatalog.cfgcat.starcaton[cat - BaseStar] := True;
      magmax := max(magmax, defaultmag);
      if Fcatalog.cfgshr.StarFilter then
        mag := MinValue([defaultmag, Fcatalog.cfgcat.StarMagMax])
      else
        mag := defaultmag;
      Fplot.cfgchart.min_ma := MaxValue([Fplot.cfgchart.min_ma, mag]);
    end
    else
      Fcatalog.cfgcat.starcaton[cat - BaseStar] := False;
  end;

  procedure InitVarC(cat: integer);
  { determine if the variable star catalog is active at this scale }
  begin
    if Fcatalog.cfgcat.varstarcatdef[cat - BaseVar] and
      (FieldNum >= Fcatalog.cfgcat.varstarcatfield[cat - BaseVar, 1]) and
      (FieldNum <= Fcatalog.cfgcat.varstarcatfield[cat - BaseVar, 2]) then
      Fcatalog.cfgcat.varstarcaton[cat - BaseVar] := True
    else
      Fcatalog.cfgcat.varstarcaton[cat - BaseVar] := False;
  end;

  procedure InitDblC(cat: integer);
  { determine if the double star catalog is active at this scale }
  begin
    if Fcatalog.cfgcat.dblstarcatdef[cat - BaseDbl] and
      (FieldNum >= Fcatalog.cfgcat.dblstarcatfield[cat - BaseDbl, 1]) and
      (FieldNum <= Fcatalog.cfgcat.dblstarcatfield[cat - BaseDbl, 2]) then
      Fcatalog.cfgcat.dblstarcaton[cat - BaseDbl] := True
    else
      Fcatalog.cfgcat.dblstarcaton[cat - BaseDbl] := False;
  end;

  procedure InitNebC(cat: integer);
  { determine if the nebulae catalog is active at this scale }
  begin
    if Fcatalog.cfgcat.nebcatdef[cat - BaseNeb] and
      (FieldNum >= Fcatalog.cfgcat.nebcatfield[cat - BaseNeb, 1]) and
      (FieldNum <= Fcatalog.cfgcat.nebcatfield[cat - BaseNeb, 2]) then
      Fcatalog.cfgcat.nebcaton[cat - BaseNeb] := True
    else
      Fcatalog.cfgcat.nebcaton[cat - BaseNeb] := False;
  end;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init catalogs');
  vostar_magmax := Fcatalog.GetVOstarmag;
  if fov=cfgsc.fov then
    FieldNum:=cfgsc.FieldNum
  else
    FieldNum := GetFieldNum(fov - musec);
  if Fcatalog.cfgshr.AutoStarFilter then
  begin
    f := fov - 15 * minarc;
    if (f > minarc) or cfgsc.Quick then
      Fcatalog.cfgcat.StarMagMax :=
        max(MagnitudeMin,
        round(10 * (
        Fcatalog.cfgshr.AutoStarFilterMag + 2.4 * log10((pid2*pid2) / (f*f*(1+2*cos(min(3*f,pid2)) ))))
        ) / 10
        )
    else
      Fcatalog.cfgcat.StarMagMax := 99;
  end
  else
    Fcatalog.cfgcat.StarMagMax := Fcatalog.cfgshr.StarMagFilter[FieldNum];
  if cfgsc.quick and FPlot.cfgplot.red_move then begin
    Fcatalog.cfgcat.Quick := true;
    Fcatalog.cfgcat.StarMagMax := min(16,Fcatalog.cfgcat.StarMagMax - 2);
  end
  else
    Fcatalog.cfgcat.Quick := false;
  Fcatalog.cfgcat.NebMagMax := Fcatalog.cfgshr.NebMagFilter[FieldNum];
  Fcatalog.cfgcat.NebSizeMin := Fcatalog.cfgshr.NebSizeFilter[FieldNum];

  if cfgsc.lockMagn then begin
    Fcatalog.cfgcat.StarMagMax := cfgsc.lockStarMag;
    Fcatalog.cfgcat.NebMagMax := cfgsc.lockNebMag;
    Fcatalog.cfgcat.NebSizeMin := cfgsc.lockNebSize;
  end;

  Fplot.cfgchart.min_ma := MagnitudeMin;
  magmax := MagnitudeMin;
  { activate the star catalog}
  InitStarC(dsbase, 5.5);
  InitStarC(bsc, 6.5);
  InitStarC(sky2000, 9.5);
  InitStarC(DefStar, 10);
  InitStarC(tyc, 11);
  InitStarC(tyc2, 12);
  InitStarC(dstyc, 12);
  InitStarC(tic, 12);
  InitStarC(gsc, 14.5);
  InitStarC(gscf, 14.5);
  InitStarC(gscc, 14.5);
  InitStarC(dsgsc, 14.5);
  InitStarC(microcat, 16);
  InitStarC(hn290, Fcatalog.Get290MagMax);
  InitStarC(gaia, Fcatalog.GetGaiaMagMax);
  InitStarC(usnoa, 18);
  InitStarC(usnob, 21);
  InitStarC(vostar, vostar_magmax);
  { activate the other catalog }
  InitVarC(gcvs);
  InitDblC(wds);
  for i := 1 to MaxNebCatalog do
    Fcatalog.cfgcat.nebcaton[i] := False;
  if Fcatalog.cfgcat.nebcatdef[uneb - BaseNeb] then
    InitNebC(uneb);
  if Fcatalog.cfgcat.nebcatdef[voneb - BaseNeb] then
    InitNebC(voneb);
  if cfgsc.shownebulae then
  begin
    InitNebC(sac);
    InitNebC(ngc);
    InitNebC(lbn);
    InitNebC(sh2);
    InitNebC(drk);
    InitNebC(rc3);
    InitNebC(pgc);
    InitNebC(ocl);
    InitNebC(gcm);
    InitNebC(gpn);
  end;
  Fcatalog.cfgcat.starcaton[gcstar - BaseStar] := False;
  Fcatalog.cfgcat.varstarcaton[gcvar - Basevar] := False;
  Fcatalog.cfgcat.dblstarcaton[gcdbl - Basedbl] := False;
  Fcatalog.cfgcat.nebcaton[gcneb - Baseneb] := False;
  Fcatalog.cfgcat.lincaton[gclin - Baselin] := False;
  for i := 1 to Fcatalog.cfgcat.GCatNum do
    if Fcatalog.cfgcat.GCatLst[i - 1].Actif and
      (FieldNum >= Fcatalog.cfgcat.GCatLst[i - 1].min) and
      (FieldNum <= Fcatalog.cfgcat.GCatLst[i - 1].max) then
    begin
      Fcatalog.cfgcat.GCatLst[i - 1].CatOn := True;
      case Fcatalog.cfgcat.GCatLst[i - 1].cattype of
        rtstar:
        begin
          magmax := max(magmax, Fcatalog.cfgcat.GCatLst[i - 1].magmax);
          Fcatalog.cfgcat.starcaton[gcstar - BaseStar] := True;
          if Fcatalog.cfgshr.StarFilter then
            mag := min(Fcatalog.cfgcat.GCatLst[i - 1].magmax, Fcatalog.cfgcat.StarMagMax)
          else
            mag := Fcatalog.cfgcat.GCatLst[i - 1].magmax;
          Fplot.cfgchart.min_ma := max(Fplot.cfgchart.min_ma, mag);
        end;
        rtvar: Fcatalog.cfgcat.varstarcaton[gcvar - Basevar] := True;
        rtdbl: Fcatalog.cfgcat.dblstarcaton[gcdbl - Basedbl] := True;
        rtneb: if cfgsc.shownebulae then
            Fcatalog.cfgcat.nebcaton[gcneb - Baseneb] := True;
        rtlin: Fcatalog.cfgcat.lincaton[gclin - Baselin] := True;
      end;
    end
    else
      Fcatalog.cfgcat.GCatLst[i - 1].CatOn := False;
  // Store mag limit for this chart
  Fplot.cfgchart.max_catalog_mag := magmax;
  cfgsc.StarFilter := Fcatalog.cfgshr.StarFilter;
  cfgsc.StarMagMax := Fcatalog.cfgcat.StarMagMax;
  cfgsc.NebFilter := Fcatalog.cfgshr.NebFilter;
  cfgsc.NebMagMax := Fcatalog.cfgcat.NebMagMax;
  if cfgsc.quick and FPlot.cfgplot.red_move and
    (Fplot.cfgchart.min_ma = Fcatalog.cfgcat.StarMagMax) then
    Fplot.cfgchart.min_ma := Fplot.cfgchart.min_ma + 2;
  cfgsc.ONGCimg := FFits.ImagesForCatalog('ONGC');
  Result := True;
end;

function Tskychart.InitTime(newtime: boolean): boolean;
var
  xp, yp, MJD, A, C: double;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init time');
  if newtime and cfgsc.UseSystemTime and (not cfgsc.quick) then
    SetCurrentTime(cfgsc);
  cfgsc.DT_UT := DTminusUT(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay, cfgsc);
  cfgsc.DT_UTerr := DTminusUTError(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay, cfgsc);
  cfgsc.CurJDTT := jd(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay, cfgsc.CurTime -
    cfgsc.TimeZone + cfgsc.DT_UT);  // TT
  cfgsc.CurJDUT := jd(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay, cfgsc.CurTime -
    cfgsc.TimeZone);
  // UT
  cfgsc.jd0 := jd(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay, 0);
  // thing to do when the date change
  if (not (cfgsc.TrackOn and ((cfgsc.TrackType <= TTplanet) or (cfgsc.TrackType = TTequat)))) and
    (((cfgsc.FindType < ftPla) and (abs(cfgsc.CurJDTT - cfgsc.FindJD) > (3652))) or
    // 10 year limit for precession
    ((cfgsc.FindType >= ftPla) and (abs(cfgsc.CurJDTT - cfgsc.LastJD) >
    (30 / 86400)))   // 30 sec. limit for moving objects
    ) then
  begin
    cfgsc.FindOk := False;    // last search no longuer valid
  end;
  if ((FUpdObsList) and (abs(cfgsc.CurJDTT - cfgsc.LastJD) > (1 / 1440))) then
  begin
    if assigned(FUpdObsListTime) then
      FUpdObsListTime(self);
  end;
  if cfgsc.CurJDTT <> cfgsc.LastJD then
  begin
    if not cfgsc.NewArtSat then
      cfgsc.ShowArtSat := False;  // satellite position not valid
  end;
  cfgsc.LastJD := cfgsc.CurJDTT;
  if (cfgsc.Equinoxtype = 2) then
  begin  // use equinox of the date
    cfgsc.JDChart := jd(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay,
      cfgsc.CurTime - cfgsc.TimeZone);  // UT
    cfgsc.EquinoxName := rsDate;
  end
  else
  begin
    cfgsc.JDChart := cfgsc.DefaultJDChart;
    cfgsc.EquinoxName := cfgsc.EquinoxChart;
  end;
  if (cfgsc.lastJDchart < -1E20) then
    cfgsc.lastJDchart := cfgsc.JDchart; // initial value
  // position of J2000 pole in current coordinates
  cfgsc.rap2000 := 0;
  cfgsc.dep2000 := pid2;
  precession(jd2000, cfgsc.JDChart, cfgsc.rap2000, cfgsc.dep2000);
  // Pole motion (must be done after setting the time)
  xp := cfgsc.ObsXP;
  yp := cfgsc.ObsYP;
  if (xp = 0) and (yp = 0) and (cfgsc.CurJDUT > jd2000) and (cfgsc.CurJDUT < 2458849.5) then
  begin // 2000-2020
    // compute predicted value using formula in 3 January 2013 IERS BULLETIN-A
    MJD := cfgsc.CurJDUT - 2400000.5;
    A := 2 * pi * (MJD - 56295) / 365.25;
    C := 2 * pi * (MJD - 56295) / 435;
    xp := 0.0940 - 0.0383 * cos(A) - 0.1277 * sin(A) + 0.0101 * cos(C) + 0.0530 * sin(C);
    yp := 0.3393 - 0.1066 * cos(A) + 0.0261 * sin(A) + 0.0530 * cos(C) - 0.0101 * sin(C);
  end;
  if (xp = 0) and (yp = 0) then
  begin
    cfgsc.ObsELONG := -deg2rad * cfgsc.ObsLongitude;
    cfgsc.ObsPHI := deg2rad * cfgsc.ObsLatitude;
    cfgsc.ObsDAZ := 0;
  end
  else
    sla_POLMO(-deg2rad * cfgsc.ObsLongitude, deg2rad * cfgsc.ObsLatitude,
      deg2rad * XP / 3600, deg2rad * YP / 3600, cfgsc.ObsELONG, cfgsc.ObsPHI, cfgsc.ObsDAZ);
  Result := True;
end;

function Tskychart.InitObservatory: boolean;
var
  u, p, r90, rm, dip, ht: double;
const
  ratio = 0.99664719;
  H0 = 6378140.0;
  SOLSID = 1.00273790935;  // Ratio between solar and sidereal time
  C = 173.14463331;        // Speed of light (AU per day)
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init observatory');
  cfgsc.tz.Longitude:=cfgsc.ObsLongitude;
  cfgsc.TimeZone := cfgsc.tz.SecondsOffset / 3600;
  p := deg2rad * cfgsc.ObsLatitude;
  u := arctan(ratio * tan(p));
  cfgsc.ObsRoSinPhi := ratio * sin(u) + (cfgsc.ObsAltitude / H0) * sin(p);
  cfgsc.ObsRoCosPhi := cos(u) + (cfgsc.ObsAltitude / H0) * cos(p);
  // compute refraction constant
  cfgsc.ObsRefractionCor := (cfgsc.ObsPressure / 1010) * (283 / (273 + cfgsc.ObsTemperature));
  sla_REFCO(cfgsc.ObsAltitude, 273.15 + cfgsc.ObsTemperature, cfgsc.ObsPressure,
    cfgsc.ObsRH, RefractionWavelength, deg2rad * cfgsc.ObsLatitude, cfgsc.ObsTlr,
    1E-8, cfgsc.ObsRefA, cfgsc.ObsRefb);
  // horizon dip  (Wittmann, 1997 Astron. Nachr. 318)
  if cfgsc.ShowHorizonDepression and (cfgsc.ObsAltitude > 10) then
  begin
    r90 := 0;
    Refraction(r90, True, cfgsc, 2);
    r90 := rad2deg * r90;
    rm := r90 * ((2 * exp(cfgsc.ObsAltitude / 8000)) / (1 + exp(-cfgsc.ObsAltitude / 12300)));
    dip := sqrt(cfgsc.ObsAltitude) * 0.02931;
    ht := dip + rm;
    cfgsc.ObsHorizonDepression := min(0, -deg2rad * ht);
  end
  else
  begin
    cfgsc.ShowHorizonDepression := False;
    cfgsc.ObsHorizonDepression := 0;
  end;
  // diurnal abberation
  sla_GEOC(p, cfgsc.ObsAltitude, cfgsc.ObsRAU, cfgsc.ObsZAU);
  cfgsc.Diurab := PI2 * cfgsc.ObsRAU * SOLSID / C;
  // horizon drawing
  if cfgsc.HorizonFile<>'' then LoadHorizon;
  if cfgsc.ShowHorizonPicture then LoadHorizonPicture(cfgsc.HorizonPictureFile);
  cfgsc.ShowHorizonPicture := cfgsc.ShowHorizonPicture and cfgsc.horizonpicturevalid;
  Result := True;
end;

function Tskychart.InitChart(full: boolean = True): boolean;
var
  w, h: double;
begin
  // do not add more function here as this is also called at the chart create
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init chart');
  if full then
  begin
    // we must know the projection now
    w := cfgsc.fov;
    h := cfgsc.fov / cfgsc.WindowRatio;
    w := MaxValue([w, h]);
    cfgsc.FieldNum := GetFieldNum(w - musec);
    cfgsc.projtype := (cfgsc.projname[cfgsc.fieldnum] + 'A')[1];
    // full sky button
    if (cfgsc.ProjPole = Altaz) and ((cfgsc.projtype = 'T') or
      (cfgsc.projtype = 'S') or (cfgsc.ProjEquatorCentered)) and (cfgsc.fov > pi) and
      (abs(cfgsc.hcentre) > pid4) then
      cfgsc.projtype := 'A';
  end;
  cfgsc.xmin := cfgsc.LeftMargin;
  cfgsc.ymin := cfgsc.TopMargin;
  cfgsc.xmax := Fplot.cfgchart.Width - cfgsc.RightMargin;
  cfgsc.ymax := Fplot.cfgchart.Height - cfgsc.BottomMargin;
  Fplot.cfgplot.xmin := cfgsc.xmin;
  Fplot.cfgplot.ymin := cfgsc.ymin;
  Fplot.cfgplot.xmax := cfgsc.xmax;
  Fplot.cfgplot.ymax := cfgsc.ymax;
  ScaleWindow(cfgsc);
  Result := True;
end;

function Tskychart.InitColor: boolean;
var
  i,n: integer;
  p: PBGRAPixel;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init colors');
  if Fplot.cfgplot.color[0] > Fplot.cfgplot.color[11] then
  begin // white background
    Fplot.cfgplot.AutoSkyColor := False;
    Fplot.cfgplot.autoskycolorValid := False;
    Fplot.cfgplot.StarPlot := 0;
    Fplot.cfgplot.NebPlot := 0;
    cfgsc.FillMilkyWay := False;
    cfgsc.WhiteBg := True;
  end
  else
    cfgsc.WhiteBg := False;
  if (cfgsc.fov > 10 * deg2rad) then
  begin
    if cfgsc.CurSunH > 0 then begin
      i := 1;
      n := 0;
    end
    else if cfgsc.CurSunH > -5 * deg2rad then begin
      i := 2;
      n := 30;
    end
    else if cfgsc.CurSunH > -11 * deg2rad then begin
      i := 3;
      n := 50;
    end
    else if cfgsc.CurSunH > -13 * deg2rad then begin
      i := 4;
      n := 70;
    end
    else if cfgsc.CurSunH > -15 * deg2rad then begin
      i := 5;
      n := 90;
    end
    else if cfgsc.CurSunH > -17 * deg2rad then begin
      i := 6;
      n := 110;
    end
    else begin
      i := 7;
      n := 130;
    end;
  end
  else
  if cfgsc.CurSunH > 0 then begin
    i := 5;
    n := 90;
  end
  else if cfgsc.CurSunH > -5 * deg2rad then begin
    i := 5;
    n := 90;
  end
  else if cfgsc.CurSunH > -11 * deg2rad then begin
    i := 6;
    n := 110;
  end
  else if cfgsc.CurSunH > -13 * deg2rad then begin
    i := 6;
    n := 110;
  end
  else if cfgsc.CurSunH > -15 * deg2rad then begin
    i := 7;
    n := 130;
  end
  else if cfgsc.CurSunH > -17 * deg2rad then begin
    i := 7;
    n := 130;
  end
  else begin
    i := 7;
    n := 130;
  end;
  if (i >= 5) and (cfgsc.CurMoonH > 0) then
  begin
    if (cfgsc.CurMoonIllum > 0.1) and (cfgsc.CurMoonIllum < 0.5) then begin
      i := i - 1;
      n := n - 20;
    end;
    if (cfgsc.CurMoonIllum >= 0.5) then begin
      i := i - 2;
      n := n - 50;
    end;
    if i < 5 then begin
      i := 5;
      n := 90;
    end;
  end;
  if Fplot.cfgplot.autoskycolorValid and (cfgsc.Projpole = AltAz) then
  begin
    Fplot.cfgplot.color[0] := Fplot.cfgplot.SkyColor[i];
  end
  else
    Fplot.cfgplot.color[0] := Fplot.cfgplot.bgColor;
  Fplot.cfgplot.backgroundcolor := Fplot.cfgplot.color[0];
  if not cfgsc.DarkenHorizonPicture then n:=0;
  if cfgsc.horizonpicturevalid and (n <> cfgsc.horizondarken) then
  begin
    cfgsc.horizondarken := n;
    horizonpicturedark.Assign(horizonpicture);
    if n>0 then begin
      p := horizonpicturedark.Data;
      for i := horizonpicturedark.NbPixels-1 downto 0 do
      begin
        if p^.alpha>0 then begin
          p^.red := max(0,p^.red-n);
          p^.green := max(0,p^.green-n);
          p^.blue := max(0,p^.blue-n);
        end;
        inc(p);
      end;
      horizonpicturedark.InvalidateBitmap;
    end;
  end;
  Fplot.init(Fplot.cfgchart.Width, Fplot.cfgchart.Height);
  if Fplot.cfgchart.onprinter and (Fplot.cfgplot.starplot = 0) and
    (Fplot.cfgplot.color[1] <> clBlack) then
  begin
    Fplot.cfgplot.color[0] := clBlack;
    Fplot.cfgplot.color[11] := clWhite;
  end;
  Result := True;
end;

function Tskychart.GetFieldNum(fov: double): integer;
var
  i: integer;
begin
  fov := rad2deg * fov;
  if fov > 360 then
    fov := 360;
  Result := MaxField;
  if Fcatalog <> nil then
    for i := 0 to MaxField do
      if Fcatalog.cfgshr.FieldNum[i] > fov then
      begin
        Result := i;
        break;
      end;
end;

function Tskychart.InitCoordinates: boolean;
var
  w, h, a, d, dist, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, saveaz: double;
  acc, dcc: double;
  se, ce: extended;
  s1, s2, s3: string;
  nom, ma, date, desc: string;
  TrackAltAz: boolean;
  outr: integer;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init coordinates');
  TrackAltAz := False;
  cfgsc.scopemark := False;
  cfgsc.RefractionOffset := 0;
  // clipping limit
  Fplot.cfgchart.hw := Fplot.cfgchart.Width div 2;
  Fplot.cfgchart.hh := Fplot.cfgchart.Height div 2;
  Fplot.cfgchart.cliparea := max(Fplot.cfgchart.hw, Fplot.cfgchart.hh);
  case trunc(rad2deg * cfgsc.fov) of
    0..1: outr := 100;
    2..5: outr := 20;
    else
      outr := 10;
  end;
  Fplot.cfgplot.outradius := abs(round(min(outr * cfgsc.fov, 0.98 * pi2) * cfgsc.BxGlb / 2));
  if cfgsc.projtype = 'T' then
  begin
    Fplot.cfgplot.outradius := 2 * Fplot.cfgplot.outradius;
    cfgsc.x2 := 9 * cfgsc.x2;
  end;
  if Fplot.cfgplot.outradius > maxSmallint then
    Fplot.cfgplot.outradius := maxSmallint;
  if Fplot.cfgplot.outradius < Fplot.cfgchart.hw then
    Fplot.cfgplot.outradius := Fplot.cfgchart.hw;
  if Fplot.cfgplot.outradius < Fplot.cfgchart.hh then
    Fplot.cfgplot.outradius := Fplot.cfgchart.hh;
  // nutation constant
  if cfgsc.ApparentPos then
    Fplanet.nutation(cfgsc.CurJDTT, cfgsc.nutl, cfgsc.nuto)
  else
  begin
    cfgsc.nutl := 0;
    cfgsc.nuto := 0;
  end;
  // ecliptic obliquity
  if cfgsc.ApparentPos then
    cfgsc.ecl := ecliptic(cfgsc.JdChart, cfgsc.nuto)
  else
    cfgsc.ecl := ecliptic(cfgsc.JdChart);
  // nutation matrix
  sincos(cfgsc.ecl, se, ce);
  cfgsc.NutMAT[1, 1] := 1;
  cfgsc.NutMAT[1, 2] := -ce * cfgsc.nutl;
  cfgsc.NutMAT[1, 3] := -se * cfgsc.nutl;
  cfgsc.NutMAT[2, 1] := ce * cfgsc.nutl;
  cfgsc.NutMAT[2, 2] := 1;
  cfgsc.NutMAT[2, 3] := -cfgsc.nuto;
  cfgsc.NutMAT[3, 1] := se * cfgsc.nutl;
  cfgsc.NutMAT[3, 2] := cfgsc.nuto;
  cfgsc.NutMAT[3, 3] := 1;
  // equation of the equinox
  cfgsc.eqeq := cfgsc.nutl * cos(cfgsc.ecl);
  // Sidereal time
  cfgsc.CurST := Sidtim(cfgsc.jd0, cfgsc.CurTime - cfgsc.TimeZone,
    cfgsc.ObsLongitude, cfgsc.eqeq);
  // Sun geometric longitude eq. of date for aberration
  fplanet.sunecl(cfgsc.CurJDTT, cfgsc.sunl, cfgsc.sunb);
  PrecessionEcl(jd2000, cfgsc.CurJDUT, cfgsc.sunl, cfgsc.sunb);
  // Can compute planet?
  cfgsc.ephvalid := (Fplanet.eph_method > '');
  cfgsc.ShowPlanetValid := cfgsc.ShowPlanet and cfgsc.ephvalid;
  cfgsc.ShowAsteroidValid := cfgsc.ShowAsteroid and cfgsc.ephvalid;
  cfgsc.ShowBodiesValid := Length(cfgsc.SPKBodies)>0;
  cfgsc.ShowCometValid := cfgsc.ShowComet and cfgsc.ephvalid;
  cfgsc.ShowEarthShadowValid := cfgsc.ShowEarthShadow and cfgsc.ephvalid;
  cfgsc.ShowEclipticValid := cfgsc.ShowEcliptic and cfgsc.ephvalid;
  Fplot.cfgplot.autoskycolorValid := Fplot.cfgplot.autoskycolor and cfgsc.ephvalid;
  // aberration and light deflection constant
  if cfgsc.ApparentPos then
    Fplanet.aberration(cfgsc.CurJDTT, cfgsc.abv, cfgsc.ehn, cfgsc.ab1,
      cfgsc.abe, cfgsc.abp, cfgsc.gr2e, cfgsc.abm, cfgsc.asl)
  else
  begin
    cfgsc.abe := 0;
    cfgsc.abp := 0;
    cfgsc.abm := False;
    cfgsc.asl := False;
  end;
  // Earth barycentric position in parsec for parallax
  fplanet.Barycenter(cfgsc.CurJDTT, v1, v2, v3);
  cfgsc.EarthB[1] := -v1 * au2parsec;
  cfgsc.EarthB[2] := -v2 * au2parsec;
  cfgsc.EarthB[3] := -v3 * au2parsec;
  // Planet position
  if not cfgsc.quick then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': Compute planet position');
    if not Fplanet.ComputePlanet(cfgsc) then
    begin
      if VerboseMsg then
        WriteTrace('SkyChart ' + cfgsc.chartname + ': ' + rsEphemerisPro);
      cfgsc.msg := rsEphemerisPro;
      cfgsc.ephvalid := False;
      cfgsc.ShowPlanet := False;
      cfgsc.ShowAsteroid := False;
      cfgsc.ShowComet := False;
      cfgsc.ShowEarthShadow := False;
      cfgsc.ShowEcliptic := False;
      cfgsc.ShowPlanetValid := False;
      cfgsc.ShowAsteroidValid := False;
      cfgsc.ShowCometValid := False;
      cfgsc.ShowEarthShadowValid := False;
      cfgsc.ShowEclipticValid := False;
      Fplot.cfgplot.autoskycolorValid := False;
    end;
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': end Compute planet position');
  end;
  // is the chart to be centered on an object ?
  if cfgsc.TrackOn then
  begin
    case cfgsc.TrackType of
      TTplanet:
      begin
        // planet
        cfgsc.racentre := cfgsc.PlanetLst[0, cfgsc.Trackobj, 1];
        cfgsc.decentre := cfgsc.PlanetLst[0, cfgsc.Trackobj, 2];
        cfgsc.TrackRA := cfgsc.racentre;
        cfgsc.TrackDec := cfgsc.decentre;
        cfgsc.TrackEpoch := cfgsc.JDChart;
        cfgsc.lastJDchart := cfgsc.JDchart;
        Planet.FormatPlanet(0, cfgsc.Trackobj, cfgsc, nom, ma, date, desc);
      end;
      TTcomet:
      begin
        // comet
        if cdb.GetComElem(cfgsc.TrackId, cfgsc.TrackElemEpoch, v1, v2,
          v3, v4, v5, v6, v7, v8, v9, s1, s2) then
        begin
          Fplanet.InitComet(v1, v2, v3, v4, v5, v6, v7, v8, v9, s1);
          Fplanet.Comet(cfgsc.CurJDTT, True, a, d, dist, v1, v2, v3, v4,
            v5, v6, v7, v8, v9, v10, v11, v12);
          precession(jd2000, cfgsc.JDChart, a, d);
          cfgsc.LastJDChart := cfgsc.JDChart;
          if cfgsc.PlanetParalaxe then
            Paralaxe(cfgsc.CurST, dist, a, d, a, d, v1, cfgsc);
          if cfgsc.ApparentPos then
            apparent_equatorial(a, d, cfgsc, True, False);
          cfgsc.racentre := a;
          cfgsc.decentre := d;
          cfgsc.TrackRA := cfgsc.racentre;
          cfgsc.TrackDec := cfgsc.decentre;
          cfgsc.TrackEpoch := cfgsc.JDChart;
          cfgsc.lastJDchart := cfgsc.JDchart;
        end
        else
          cfgsc.TrackOn := False;
      end;
      TTasteroid:
      begin
        // asteroid
        if cdb.GetAstElem(strtoint(cfgsc.TrackId), cfgsc.TrackElemEpoch, v1, v2, v3, v4, v5, v6, v7, v8, v9, s1, s2) then
        begin
          Fplanet.InitAsteroid(cfgsc.TrackElemEpoch, v1, v2, v3, v4, v5, v6, v7, v8, v9, s2);
          Fplanet.Asteroid(cfgsc.CurJDTT, True, a, d, dist, v1, v2, v3, v4, v5, v6, v7);
          precession(jd2000, cfgsc.JDChart, a, d);
          cfgsc.LastJDChart := cfgsc.JDChart;
          if cfgsc.PlanetParalaxe then
            Paralaxe(cfgsc.CurST, dist, a, d, a, d, v1, cfgsc);
          if cfgsc.ApparentPos then
            apparent_equatorial(a, d, cfgsc, True, False);
          cfgsc.racentre := a;
          cfgsc.decentre := d;
          cfgsc.TrackRA := cfgsc.racentre;
          cfgsc.TrackDec := cfgsc.decentre;
          cfgsc.TrackEpoch := cfgsc.JDChart;
          cfgsc.lastJDchart := cfgsc.JDchart;
        end
        else
          cfgsc.TrackOn := False;
      end;
      TTaltaz:
      begin
        // azimuth - altitude
        if cfgsc.Projpole = AltAz then
        begin
          Hz2Eq(cfgsc.acentre, cfgsc.hcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
          cfgsc.racentre := cfgsc.CurST - cfgsc.racentre;
        end;
        cfgsc.TrackOn := False;
        TrackAltAz := True;
      end;
      TTimage:
      begin
        // fits image
        cfgsc.TrackOn := False;
        if FFits.Header.valid and Fits.WCSvalid then
        begin
          if VerboseMsg then
            WriteTrace('Center to FITS image ' + ' ra:' + formatfloat(f5, rad2deg * FFits.Center_RA) +
              ' de:' + formatfloat(f5, rad2deg * FFits.Center_DE) + ' fov:' + formatfloat(
              f6, rad2deg * FFits.Img_Width));
          cfgsc.lastJDchart := cfgsc.JDChart;
          v1 := FFits.Center_RA;
          v2 := FFits.Center_DE;
          precession(jd2000, cfgsc.JDChart, v1, v2);
          if cfgsc.ApparentPos then
            apparent_equatorial(v1, v2, cfgsc, True, True);
          cfgsc.racentre := v1;
          cfgsc.decentre := v2;
          ScaleWindow(cfgsc);
        end;
      end;
      TTequat:
      begin
        // ra - dec
        cfgsc.racentre := cfgsc.TrackRA;
        cfgsc.decentre := cfgsc.TrackDec;
        Precession(cfgsc.TrackEpoch, cfgsc.JDChart, cfgsc.TrackRA, cfgsc.TrackDec);
        cfgsc.TrackEpoch := cfgsc.JDChart;
      end;
      TTbody:
      begin
        // spk body
        if Fplanet.Body(cfgsc.CurJDTT, strtoint(cfgsc.TrackId), a, d, dist, v1) then
        begin
          precession(jd2000, cfgsc.JDChart, a, d);
          cfgsc.LastJDChart := cfgsc.JDChart;
          if cfgsc.PlanetParalaxe then
            Paralaxe(cfgsc.CurST, dist, a, d, a, d, v1, cfgsc);
          if cfgsc.ApparentPos then
            apparent_equatorial(a, d, cfgsc, True, False);
          cfgsc.racentre := a;
          cfgsc.decentre := d;
          cfgsc.TrackRA := cfgsc.racentre;
          cfgsc.TrackDec := cfgsc.decentre;
          cfgsc.TrackEpoch := cfgsc.JDChart;
          cfgsc.lastJDchart := cfgsc.JDchart;
        end
        else
          cfgsc.TrackOn := False;
      end;
    end;
  end
  else
  begin
    if cfgsc.TrackName = rsTelescope + '-2' then
    begin
      cfgsc.TrackName := '';
    end;
  end;
  // find the current field number and projection (a second time if fov is adjusted to the image size)
  w := cfgsc.fov;
  h := cfgsc.fov / cfgsc.WindowRatio;
  w := MaxValue([w, h]);
  cfgsc.FieldNum := GetFieldNum(w - musec);
  cfgsc.projtype := (cfgsc.projname[cfgsc.fieldnum] + 'A')[1];
  // full sky button
  if (cfgsc.ProjPole = Altaz) and (cfgsc.fov > pi) and
    (((cfgsc.projtype = 'T') or (cfgsc.projtype = 'S') or (cfgsc.ProjEquatorCentered)) and
    (abs(cfgsc.hcentre) > pid4) or (cfgsc.hcentre > (85 * deg2rad))) then
    cfgsc.projtype := 'A';
  // Mercator diverge near the pole
  if (not cfgsc.ProjEquatorCentered) and (cfgsc.projtype = 'M') then
  begin
    case cfgsc.ProjPole of
      Equat: if abs(cfgsc.decentre) > (85 * deg2rad) then
          cfgsc.decentre := sgn(cfgsc.decentre) * 85 * deg2rad;
      Altaz: if abs(cfgsc.hcentre) > (85 * deg2rad) then
        begin
          cfgsc.hcentre := sgn(cfgsc.hcentre) * 85 * deg2rad;
          Hz2Eq(cfgsc.acentre, cfgsc.hcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
          cfgsc.racentre := cfgsc.CurST - cfgsc.racentre;
        end;
      Gal: if abs(cfgsc.bcentre) > (85 * deg2rad) then
        begin
          cfgsc.bcentre := sgn(cfgsc.bcentre) * 85 * deg2rad;
          Gal2Eq(cfgsc.lcentre, cfgsc.bcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
        end;
      Ecl: if abs(cfgsc.becentre) > (85 * deg2rad) then
        begin
          cfgsc.becentre := sgn(cfgsc.becentre) * 85 * deg2rad;
          Ecl2Eq(cfgsc.lecentre, cfgsc.becentre, cfgsc.ecl, cfgsc.racentre, cfgsc.decentre);
        end;
    end;
  end;
  // normalize the coordinates
  if (cfgsc.decentre >= (pid2 - secarc)) then
    cfgsc.decentre := pid2 - secarc;
  if (cfgsc.decentre <= (-pid2 + secarc)) then
    cfgsc.decentre := -pid2 + secarc;
  cfgsc.racentre := rmod(cfgsc.racentre + pi2, pi2);
  // apply precession if the epoch change from previous chart
  if cfgsc.lastJDchart <> cfgsc.JDchart then
    precession(cfgsc.lastJDchart, cfgsc.JDchart, cfgsc.racentre, cfgsc.decentre);
  cfgsc.lastJDchart := cfgsc.JDchart;
  // store J2000 center coordinates
  cfgsc.racentre2000 := cfgsc.racentre;
  cfgsc.decentre2000 := cfgsc.decentre;
  Precession(cfgsc.JDchart, jd2000, cfgsc.racentre2000, cfgsc.decentre2000);
  // get alt/az center
  saveaz := cfgsc.acentre;
  if not TrackAltAz then
  begin
    Eq2Hz(cfgsc.CurST - cfgsc.racentre, cfgsc.decentre, cfgsc.acentre, cfgsc.hcentre, cfgsc);
    if abs(cfgsc.hcentre - pid2) < max(10 * minarc, (4 / cfgsc.BxGlb)) then
    begin
      cfgsc.acentre := saveaz;
    end;
  end;
  // compute refraction error at the chart center
  Hz2Eq(cfgsc.acentre, cfgsc.hcentre, a, d, cfgsc);
  Eq2Hz(a, d, w, h, cfgsc);
  cfgsc.RefractionOffset := h - cfgsc.hcentre;
  // get galactic center
  Eq2Gal(cfgsc.racentre, cfgsc.decentre, cfgsc.lcentre, cfgsc.bcentre, cfgsc);
  // get ecliptic center
  Eq2Ecl(cfgsc.racentre, cfgsc.decentre, cfgsc.ecl, cfgsc.lecentre, cfgsc.becentre);
  // Rotation matrix for equator centered projection
  case cfgsc.ProjPole of
    Equat:
    begin
      acc := cfgsc.racentre;
      dcc := cfgsc.decentre;
    end;
    Altaz:
    begin
      acc := -cfgsc.acentre;
      dcc := cfgsc.hcentre;
    end;
    Gal:
    begin
      acc := cfgsc.lcentre;
      dcc := cfgsc.bcentre;
    end;
    Ecl:
    begin
      acc := cfgsc.lecentre;
      dcc := cfgsc.becentre;
    end;
    else
    begin
      acc := 0;
      dcc := 0;
    end;
  end;
  sofa_Ir(cfgsc.EqpMAT);
  sofa_Rz(acc, cfgsc.EqpMAT);
  sofa_Ry(-dcc, cfgsc.EqpMAT);
  sofa_tr(cfgsc.EqpMAT, cfgsc.EqtMAT);
  // Hammer-Aitoff center offset
  if (not cfgsc.ProjEquatorCentered) and (cfgsc.projtype = 'H') then
  begin
    case cfgsc.ProjPole of
      Equat: Proj2(cfgsc.racentre, 0.0, cfgsc.racentre, cfgsc.decentre,
          cfgsc.haicx, cfgsc.haicy, cfgsc, True, True);
      Altaz: Proj2(cfgsc.acentre, 0.0, cfgsc.acentre, cfgsc.hcentre, cfgsc.haicx,
          cfgsc.haicy, cfgsc, True, True);
      Gal: Proj2(cfgsc.lcentre, 0.0, cfgsc.lcentre, cfgsc.bcentre, cfgsc.haicx,
          cfgsc.haicy, cfgsc, True, True);
      Ecl: Proj2(cfgsc.lecentre, 0.0, cfgsc.lecentre, cfgsc.becentre,
          cfgsc.haicx, cfgsc.haicy, cfgsc, True, True);
    end;
  end;
  // is the pole in the chart
  cfgsc.NP := northpoleinmap(cfgsc);
  cfgsc.SP := southpoleinmap(cfgsc);
  // detect if the position change
  if not cfgsc.quick then
  begin
    cfgsc.moved := (cfgsc.racentre <> cfgsc.raprev) or (cfgsc.decentre <> cfgsc.deprev);
    cfgsc.raprev := cfgsc.racentre;
    cfgsc.deprev := cfgsc.decentre;
  end;
  Result := True;
end;

function Tskychart.DrawCustomLabel: boolean;
var
  ra, Dec, x1, y1: double;
  xx, yy: single;
  lid, i, j, labelnum: integer;
  lis, txt: string;
  Lalign: TLabelAlign;
  orient: single;
begin
  Result := False;
  for i := 1 to cfgsc.numcustomlabels do
  begin
    ra := cfgsc.customlabels[i].ra;
    Dec := cfgsc.customlabels[i].Dec;
    txt := cfgsc.customlabels[i].txt;
    Lalign := cfgsc.customlabels[i].align;
    orient := cfgsc.customlabels[i].orientation;
    labelnum := cfgsc.customlabels[i].labelnum;
    lis := cfgsc.customlabels[i].txt + FormatFloat(f6, ra) + FormatFloat(f6, Dec);
    lid := rshash(lis, $7FFFFFFF);
    for j := 1 to cfgsc.nummodlabels do
      if lid = cfgsc.modlabels[j].id then
      begin
        txt := cfgsc.modlabels[j].txt;
        labelnum := cfgsc.modlabels[j].labelnum;
        Lalign := cfgsc.modlabels[j].align;
        orient := cfgsc.modlabels[j].orientation;
        break;
      end;
    projection(ra, Dec, x1, y1, True, cfgsc);
    WindowXY(x1, y1, xx, yy, cfgsc);
    if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
    begin
      lis := cfgsc.customlabels[i].txt + FormatFloat(f6, ra) + FormatFloat(f6, Dec);
      lid := rshash(lis, $7FFFFFFF);
      SetLabel(lid, xx, yy, 0, 2, labelnum, txt, Lalign, orient, 0, False);
      Result := True;
    end;
  end;
end;

procedure Tskychart.DrawObsListLabel;
var
  i, lid: integer;
  x1, y1, lra, lde: double;
  xx, yy: single;
  buf, lbuf, lis: string;
begin
  if FObjectListLabels.Count > 0 then
  begin
    if cfgsc.ObslistAlLabels then
    begin
      lbuf := ';';
      for i := 0 to FObjectListLabels.Count - 1 do
      begin
        with TLabelCoord(FObjectListLabels.Objects[i]) do
        begin
          if (ra > -1000) and (Dec > -1000) then
          begin
            lra := deg2rad * ra;
            lde := deg2rad * Dec;
            Precession(jd2000, cfgsc.CurJDUT, lra, lde);
            projection(lra, lde, x1, y1, True, cfgsc);
            WindowXY(x1, y1, xx, yy, cfgsc);
            if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and
              (yy < cfgsc.Ymax) then
            begin
              buf := FObjectListLabels[i];
              lis := buf + FormatFloat(f6, ra) + FormatFloat(f6, Dec);
              lid := rshash(lis, $7FFFFFFF);
              SetLabel(lid, xx, yy, 0, 2, 9, buf, laLeft, labrotation(lra, lde, 1, cfgsc), 0, False);
              lbuf := lbuf + buf + ';';
            end;
          end;
        end;
      end;
      for i := 1 to numlabels do
        if pos(';' + labels[i].txt + ';', lbuf) > 0 then
        begin
          if labels[i].labelnum <> 9 then
            labels[i].x := -9999;
        end;
    end
    else
    begin
      lbuf := ';';
      for i := 0 to FObjectListLabels.Count - 1 do
        lbuf := lbuf + FObjectListLabels[i] + ';';
      for i := 1 to numlabels do
        if pos(';' + labels[i].txt + ';', lbuf) > 0 then
        begin
          labels[i].priority := 0;
          labels[i].labelnum := 9;
        end;
    end;
  end;
end;

function Tskychart.DrawStars: boolean;
var
  rec: GcatRec;
  x1, y1, cyear, dyear, pra, pdec, lra,ldec, timelimit: double;
  xx, yy, xxp, yyp: single;
  j, lid, saveplot, lnum, lp, rs: integer;
  First: boolean;
  firstcat: TSname;
  gk, lis, dlbl, lmag: string;
  al: TLabelAlign;
  p: coordvector;
  distfact: double;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw stars');
  fillchar(rec, sizeof(rec), 0);
  if cfgsc.YPmon = 0 then
    cyear := cfgsc.CurYear + DayofYear(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay) / 365.25
  else
    cyear := cfgsc.YPmon;
  dyear := 0;
  First := True;
  saveplot := Fplot.cfgplot.starplot;
  if (not Fplot.cfgplot.UseBMP) and cfgsc.DrawPMon and (Fplot.cfgplot.starplot = 2) then
    Fplot.cfgplot.starplot := 1;
  try
    if First and Fcatalog.cfgcat.starcaton[DefStar - BaseStar] then
    begin
      firstcat := 'Star';
      First := False;
    end;
    for j := 0 to Fcatalog.cfgcat.GCatNum - 1 do
    begin
      if Fcatalog.cfgcat.GCatLst[j].CatOn and
        (Fcatalog.cfgcat.GCatLst[j].shortname = 'star') then
      begin
        firstcat := 'Star';
        First := False;
      end;
    end;
    if First and Fcatalog.cfgcat.starcaton[bsc - BaseStar] then
    begin
      firstcat := 'BSC';
      First := False;
    end;
    timelimit := now + 10 / secday;
    if Fcatalog.OpenStar then
      while Fcatalog.readstar(rec) do
      begin
        if now > timelimit then
        begin
          cfgsc.msg := Format(rsItTakeTooLon, [rsStars, trim(rec.options.LongName)]);
          break;
        end;
        lnum := 1;
        lp := 2;
        if catalog.cfgshr.StarFilter and (rec.star.magv > catalog.cfgcat.StarMagMax) then
          continue;
        if First then
        begin
          firstcat := rec.options.ShortName;
          First := False;
        end;
        pra := rec.ra;
        pdec := rec.Dec;
        if cfgsc.PMon or cfgsc.DrawPMon then
        begin
          if rec.star.valid[vsEpoch] then
            dyear := cyear - rec.star.epoch
          else
            dyear := cyear - rec.options.Epoch;
        end;
        if cfgsc.PMon and rec.star.valid[vsPmra] and rec.star.valid[vsPmdec] then
        begin
          propermotion(rec.ra, rec.Dec, dyear, rec.star.pmra, rec.star.pmdec,
                      ((abs(dyear)>50)and rec.star.valid[vsPx] and(rec.star.px>0)and(rec.star.px<0.8) and (trim(rec.options.flabel[26]) = 'RV')),
                       rec.star.px, rec.num[1], distfact);
          catalog.AdjustStarForDistance(rec,distfact);
        end;
        lra:=rec.ra;
        ldec:=rec.Dec;
        sofa_S2C(rec.ra, rec.Dec, p);
        PrecessionV(rec.options.EquinoxJD, cfgsc.JDChart, p);
        if cfgsc.ApparentPos then
          apparent_equatorialV(p, cfgsc, True, True);
        sofa_c2s(p, rec.ra, rec.Dec);
        rec.ra := rmod(rec.ra + pi2, pi2);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc);
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
        begin
          if cfgsc.DrawPMon and rec.star.valid[vsPmra] and rec.star.valid[vsPmdec] then
          begin
            propermotion(pra, pdec, cfgsc.DrawPMyear, rec.star.pmra, rec.star.pmdec,
              (rec.star.valid[vsPx] and(rec.star.px>0)and(rec.star.px<0.8)and (trim(rec.options.flabel[26]) = 'RV')), rec.star.px, rec.num[1], distfact);
            precession(rec.options.EquinoxJD, cfgsc.JDChart, pra, pdec);
            if cfgsc.ApparentPos then
              apparent_equatorial(pra, pdec, cfgsc, True, True);
            projection(pra, pdec, x1, y1, True, cfgsc);
            WindowXY(x1, y1, xxp, yyp, cfgsc);
            Fplot.PlotLine(xx, yy, xxp, yyp, Fplot.cfgplot.Color[15], 1);
          end;

          rs := Fplot.PlotStar(xx, yy, rec.star.magv, rec.star.b_v);
          if ((cfgsc.DrawAllStarLabel or (rec.options.ShortName = firstcat)) and
            (rec.star.magv < cfgsc.StarmagMax - cfgsc.LabelMagDiff[1])) then
          begin
            lis := rec.star.id + FormatFloat(f6, lra) + FormatFloat(f6, ldec);
            lid := rshash(lis, $7FFFFFFF);
            if (rec.options.ShortName = firstcat) then
              al := laBottomLeft
            else
              al := laBottomRight;
            if cfgsc.DistLabel and rec.star.valid[vsPx] and (rec.star.px > 0)and(rec.star.px<0.8) then
            begin
              str(parsec2ly / rec.star.px: 5: 0, dlbl);
              dlbl := ' ' + rsLy + ':' + trim(dlbl);
            end
            else
              dlbl := '';
            if cfgsc.MagLabel then begin
              if cfgsc.MagNoDecimal then
                lmag := FormatFloat(f0,rec.star.magv*100)
              else
                lmag := formatfloat(f2, rec.star.magv);
              SetLabel(lid, xx, yy, rs, 2, lnum, lmag + dlbl, al, labrotation(rec.ra, rec.Dec, lnum, cfgsc), 4, True);
            end
            else if ((cfgsc.NameLabel) and rec.vstr[3] and
              (trim(copy(rec.options.flabel[18], 1, 8)) = trim(copy(rsCommonName, 1, 8)))) then
              SetLabel(lid, xx, yy, rs, 2, lnum, rec.str[3] + dlbl, al,
                labrotation(rec.ra, rec.Dec, lnum, cfgsc), lp, True)
            else if rec.star.valid[vsGreekSymbol] then
            begin
              gk := GreekSymbolUtf8(rec.star.greeksymbol);
          {$ifdef mswindows}
              dlbl := StringReplace(dlbl, rsLy, '', []);
              SetLabel(lid, xx, yy, rs, 7, 1, gk + dlbl, al, labrotation(
                rec.ra, rec.Dec, lnum, cfgsc), lp, True);
          {$else}
              SetLabel(lid, xx, yy, rs, 2, lnum, gk + dlbl, al, labrotation(
                rec.ra, rec.Dec, lnum, cfgsc), lp, True);
          {$endif}
            end
            else
            begin
              if lp > 0 then
                lp := 4;
              gk:=rec.star.greeksymbol;
              if gk=''  then gk:=rec.star.id;
              SetLabel(lid, xx, yy, rs, 2, lnum, gk + dlbl, al, labrotation(
                rec.ra, rec.Dec, lnum, cfgsc), lp, True);
            end;
          end;
        end;
      end;
    Result := True;
  finally
    Fcatalog.CloseStar;
    Fplot.cfgplot.starplot := saveplot;
  end;
end;

function Tskychart.DrawVarStars: boolean;
var
  rec: GcatRec;
  x1, y1, timelimit: double;
  xx, yy: single;
  lid, lnum, lp, rs: integer;
  lis,lmag: string;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw variable stars');
  fillchar(rec, sizeof(rec), 0);
  try
    timelimit := now + 10 / secday;
    if Fcatalog.OpenVarStar then
      while Fcatalog.readvarstar(rec) do
      begin
        if now > timelimit then
        begin
          cfgsc.msg := Format(rsItTakeTooLon, [rsVariableStar2, trim(rec.options.LongName)]);
          break;
        end;
        lnum := 2;
        lp := 2;
        if (rec.variable.magmax > catalog.cfgcat.StarMagMax) then
          continue;
        lis := rec.variable.id + FormatFloat(f6, rec.ra) + FormatFloat(f6, rec.Dec);
        lid := rshash(lis, $7FFFFFFF);
        precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
        if cfgsc.ApparentPos then
          apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, True);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc);
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
        begin
          rs := Fplot.PlotVarStar(xx, yy, rec.variable.magmax, rec.variable.magmin);
          if (rec.variable.magmax < cfgsc.StarmagMax - cfgsc.LabelMagDiff[2]) then
          begin
            if cfgsc.MagLabel then begin
              if cfgsc.MagNoDecimal then
                lmag := formatfloat(f0, rec.variable.magmax*100) + '-' + formatfloat(f0, rec.variable.magmin*100)
              else
                lmag := formatfloat(f2, rec.variable.magmax) + '-' + formatfloat(f2, rec.variable.magmin);

              SetLabel(lid, xx, yy, rs, 2, lnum, lmag, laTopLeft, labrotation(rec.ra, rec.Dec, lnum, cfgsc), 4)
            end
            else
              SetLabel(lid, xx, yy, rs, 2, lnum, rec.variable.id, laTopLeft, labrotation(
                rec.ra, rec.Dec, lnum, cfgsc), lp);
          end;
        end;
      end;
    Result := True;
  finally
    Fcatalog.CloseVarStar;
  end;
end;

function Tskychart.DrawDblStars: boolean;
var
  rec: GcatRec;
  x1, y1, x2, y2, rot, timelimit,bv: double;
  xx, yy: single;
  lid, lnum, lp, rs: integer;
  sp: char;
  lis, buf, lmag: string;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw double stars');
  fillchar(rec, sizeof(rec), 0);
  try
    timelimit := now + 10 / secday;
    if Fcatalog.OpenDblStar then
      while Fcatalog.readdblstar(rec) do
      begin
        if now > timelimit then
        begin
          cfgsc.msg := Format(rsItTakeTooLon, [rsDoubleStar, trim(rec.options.LongName)]);
          break;
        end;
        lnum := 3;
        lp := 2;
        if (rec.double.mag1 > catalog.cfgcat.StarMagMax) then
          continue;
        lis := rec.double.id + FormatFloat(f6, rec.ra) + FormatFloat(f6, rec.Dec);
        lid := rshash(lis, $7FFFFFFF);
        precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
        if cfgsc.ApparentPos then
          apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, True);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc);
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
        begin
          projection(rec.ra, rec.Dec + 0.001, x2, y2, False, cfgsc);
          rot := RotationAngle(x1, y1, x2, y2, cfgsc);
          if (not rec.double.valid[vdPA]) or (rec.double.pa = -999) then
            rec.double.pa := 0
          else
            rec.double.pa := rec.double.pa - rad2deg * PoleRot2000(rec.ra, rec.Dec);
          rec.double.pa := rec.double.pa * cfgsc.FlipX;
          if cfgsc.FlipY < 0 then
            rec.double.pa := 180 - rec.double.pa;
          rec.double.pa := Deg2Rad * rec.double.pa + rot;
          if rec.double.sp1>'' then begin
            sp:=rec.double.sp1[1];
            // not a real b-v, just a value to match the star color range
            case sp of
              'O','B' : bv:=-0.5;
                  'A' : bv:=-0.2;
                  'F' : bv:=0;
                  'G' : bv:=0.3;
                  'K' : bv:=0.6;
              'M','R','N','S' : bv:=1.5;
               else bv:=0;
            end;
          end
          else bv:=0;
          rs := Fplot.PlotDblStar(xx, yy, abs(rec.double.sep * secarc * cfgsc.BxGlb),
            rec.double.mag1, rec.double.sep, rec.double.pa, bv);
          if (rec.double.mag1 < cfgsc.StarmagMax - cfgsc.LabelMagDiff[3]) then
          begin
            if cfgsc.MagLabel then begin
              if cfgsc.MagNoDecimal then
                lmag := FormatFloat(f0,rec.double.mag1*100)
              else
                lmag := formatfloat(f2, rec.double.mag1);
              SetLabel(lid, xx, yy, rs, 2, lnum, lmag, laTopRight, labrotation(rec.ra, rec.Dec, lnum, cfgsc), 4)
            end
            else
            begin
              buf := rec.double.id;
              if trim(rec.double.compname) > '' then
                buf := trim(buf) + blank + trim(rec.double.compname);
              SetLabel(lid, xx, yy, rs, 2, lnum, buf, laTopRight, labrotation(
                rec.ra, rec.Dec, lnum, cfgsc), lp);
            end;
          end;
        end;
      end;
    Result := True;
  finally
    Fcatalog.CloseDblStar;
  end;
end;

function Tskychart.PoleRot2000(ra, Dec: double): double;
var
  x1, y1: double;
begin
  if cfgsc.JDChart = jd2000 then
    Result := 0
  else
  begin
    Result := 0;
    if Proj2(cfgsc.rap2000, cfgsc.dep2000, ra, Dec, x1, y1, cfgsc, False) then
    begin
      if (abs(x1) < 200) and (abs(x1) < 200) then
        Result := arctan2(x1, y1);
    end;
  end;
end;

function Tskychart.DrawDeepSkyObject: boolean;
var
  rec: GcatRec;
  x1, y1, x2, y2, rot, ra, de, lra,lde, radius, timelimit: double;
  x, y, xx, yy, sz, lsize: single;
  lid, save_nebplot, lp, lnum: integer;
  imgfile, CurrentCat, ImgCat, lis: string;
  bmp: TBGRAbitmap;
  save_col: Starcolarray;
  al: TLabelAlign;
  imageok: boolean;

  procedure Drawing;
  begin
    if rec.neb.nebtype <> 1 then
    begin
      if rec.options.UseColor = 1 then
      begin
        if cfgsc.WhiteBg then
          rec.neb.color := FPlot.cfgplot.Color[11];
        Fplot.PlotDeepSkyObject(xx, yy, rec.neb.dim1, rec.neb.mag,
          rec.neb.sbr, abs(cfgsc.BxGlb) * deg2rad / rec.neb.nebunit, rec.neb.nebtype,
          rec.neb.morph, cfgsc.WhiteBg, True, rec.neb.color,cfgsc.SurfaceAlpha);
      end
      else
        Fplot.PlotDeepSkyObject(xx, yy, rec.neb.dim1, rec.neb.mag,
          rec.neb.sbr, abs(cfgsc.BxGlb) * deg2rad / rec.neb.nebunit, rec.neb.nebtype,
          rec.neb.morph, cfgsc.WhiteBg, False,clWhite,cfgsc.SurfaceAlpha);
    end
    else
    begin
      ;    //   galaxies are the only rotatable objects, so rotate them and then plot...
      projection(rec.ra, rec.Dec + 0.001, x2, y2, False, cfgsc);
      rot := RotationAngle(x1, y1, x2, y2, cfgsc);
      if (not rec.neb.valid[vnPA]) or (rec.neb.pa = -999) then
        rec.neb.pa := 90
      else
        rec.neb.pa := rec.neb.pa - rad2deg * PoleRot2000(rec.ra, rec.Dec);
      rec.neb.pa := rec.neb.pa * cfgsc.FlipX;
      if cfgsc.FlipY < 0 then
        rec.neb.pa := 180 - rec.neb.pa;
      rec.neb.pa := Deg2Rad * rec.neb.pa + rot;
      if rec.options.UseColor = 1 then
      begin
        if cfgsc.WhiteBg then
          rec.neb.color := FPlot.cfgplot.Color[11];
        Fplot.PlotDSOGxy(xx, yy, rec.neb.dim1, rec.neb.dim2, rec.neb.pa, 0,
          100, 100, rec.neb.mag, rec.neb.sbr, abs(cfgsc.BxGlb) * deg2rad / rec.neb.nebunit,
          rec.neb.nebunit, rec.neb.morph, True, rec.neb.color,cfgsc.SurfaceAlpha);
      end
      else
        Fplot.PlotDSOGxy(xx, yy, rec.neb.dim1, rec.neb.dim2, rec.neb.pa, 0,
          100, 100, rec.neb.mag, rec.neb.sbr, abs(cfgsc.BxGlb) * deg2rad / rec.neb.nebunit,
          rec.neb.nebunit, rec.neb.morph, False, rec.neb.color,cfgsc.SurfaceAlpha);
    end;
  end;

  procedure Drawing_Gray;
  begin
    save_nebplot := Fplot.cfgplot.nebplot;
    save_col := Fplot.cfgplot.color;
    Fplot.cfgplot.nebplot := 0;
    Fplot.cfgplot.color := DfGray;
    Drawing;
    Fplot.cfgplot.nebplot := save_nebplot;
    Fplot.cfgplot.color := save_col;
  end;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw deepsky objects');
  CurrentCat := '';
  nebmagmax := 0;
  nebmagmin := 99;
  imageok := False;
  fillchar(rec, sizeof(rec), 0);
  bmp := TBGRAbitmap.Create;
  try
    timelimit := now + 10 / secday;
    if Fcatalog.OpenNeb then
      while Fcatalog.readneb(rec) do
      begin
        if now > timelimit then
        begin
          cfgsc.msg := Format(rsItTakeTooLon, [rsNebula, trim(rec.options.LongName)]);
          break;
        end;
        lnum := 4;
        if not rec.neb.valid[vnNebunit] then
          rec.neb.nebunit := rec.options.Units;
        if not rec.neb.valid[vnNebtype] then
          rec.neb.nebtype := rec.options.ObjType;
        if catalog.cfgshr.NebFilter then
        begin
          if (not (catalog.cfgshr.NoFilterMessier and rec.neb.messierobject)) and
            (not (catalog.cfgshr.NoFilterMagBright and ((rec.neb.nebtype=5)or(rec.neb.nebtype=6)))) and
            rec.neb.valid[vnMag] and (rec.neb.mag > catalog.cfgcat.NebMagMax) then
            continue;
          if (not (catalog.cfgshr.NoFilterMessier and rec.neb.messierobject)) and
            rec.neb.valid[vnDim1] and (rec.neb.dim1 * 60 / rec.neb.nebunit <
            catalog.cfgcat.NebSizeMin) then
            continue;
        end;
        lra:=rec.ra;
        lde:=rec.Dec;
        precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
        if cfgsc.ApparentPos then
          apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, True);
        radius := (deg2rad / rec.neb.nebunit) * (rec.neb.dim1 / 2);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc, False, radius);
        WindowXY(x1, y1, xx, yy, cfgsc);
        sz := abs(cfgsc.BxGlb) * radius;
        if Fcatalog.cfgcat.SampSelectIdent then
        begin
          Fcatalog.cfgcat.SampSelectX := round(xx);
          Fcatalog.cfgcat.SampSelectY := round(yy);
        end;
        if ((xx + sz) > cfgsc.Xmin) and ((xx - sz) < cfgsc.Xmax) and
          ((yy + sz) > cfgsc.Ymin) and ((yy - sz) < cfgsc.Ymax) then
        begin
          if numdsopos < maxlabels then
          begin
            Inc(numdsopos);
            dsopos[numdsopos] := Point(round(xx), round(yy));
          end;
          ImgCat := rec.options.ShortName;
          if (ImgCat = 'ONGC')and(not cfgsc.ONGCimg) then
             ImgCat := 'SAC';
          if (not cfgsc.Quick) and cfgsc.ShowImages and (ImgCat <> CurrentCat) then
          begin
            CurrentCat := ImgCat;
            imageok := FFits.ImagesForCatalog(CurrentCat);
          end;
          if (not cfgsc.Quick) and cfgsc.ShowImages and imageok then
          begin
            if FFits.GetFileName(ImgCat, rec.neb.id, imgfile) then
            begin
              if (ExtractFileExt(imgfile) <> '.nil') then
              begin
                if (sz > 6) then
                begin
                  FFits.FileName := imgfile;
                  if FFits.Header.valid then
                  begin
                    if ((FFits.Img_Width * cfgsc.BxGlb / FFits.Header.naxis1) < 100) then
                    begin
                      ra := FFits.Center_RA;
                      de := FFits.Center_DE;
                      precession(jd2000, cfgsc.JDChart, ra, de);
                      if cfgsc.ApparentPos then
                        apparent_equatorial(ra, de, cfgsc, True, True);
                      projection(ra, de, x1, y1, True, cfgsc, False, radius);
                      WindowXY(x1, y1, x, y, cfgsc);
                      FFits.min_sigma := cfgsc.NEBmin_sigma;
                      FFits.max_sigma := cfgsc.NEBmax_sigma;
                      FFits.GetBGRABitmap(bmp);
                      // keep this method instead of GetProjBitmap for performance
                      projection(ra, de + 0.001, x2, y2, False, cfgsc, False, radius);
                      rot := FFits.Rotation - arctan2((x2 - x1), (y2 - y1));
                      Fplot.plotimage(
                        x, y, abs(FFits.Img_Width * cfgsc.BxGlb), abs(FFits.Img_Height * cfgsc.ByGlb), rot,
                        cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, True, bmp, 0);
                      if (Fplot.cfgplot.nebplot = 0) then
                        Drawing;
                    end
                    else if (Fplot.cfgplot.nebplot = 0) then
                      Drawing
                    else
                      Drawing_Gray;
                  end
                  else if (Fplot.cfgplot.nebplot = 0) then
                    Drawing
                  else
                    Drawing_Gray;
                end
                else if (Fplot.cfgplot.nebplot = 0) then
                  Drawing
                else
                  Drawing_Gray;
              end;
            end
            else if (Fplot.cfgplot.nebplot = 0) then
              Drawing
            else
              Drawing_Gray;
          end
          else
          if cfgsc.shownebulae or Fcatalog.cfgcat.nebcatdef[uneb - BaseNeb] then
          begin
            Drawing;
          end;
          // label
          if rec.neb.messierobject or
            (min(40, rec.neb.mag) < cfgsc.NebmagMax - cfgsc.LabelMagDiff[4]) then
          begin
            al := laRight;
            lsize := rec.neb.mag;
            if rec.neb.messierobject then
              lp := 2
            else if (min(40, rec.neb.mag) < cfgsc.NebmagMax -
              cfgsc.LabelMagDiff[4] * 2) then
              lp := 3
            else
              lp := 4;
            nebmagmax := max(nebmagmax, rec.neb.mag);
            nebmagmin := min(nebmagmin, rec.neb.mag);
            lis := rec.neb.id + FormatFloat(f6, lra) + FormatFloat(f6, lde);
            lid := rshash(lis, $7FFFFFFF);
            SetLabel(lid, xx, yy, round(sz), 2, lnum, rec.neb.id, al,
              labrotation(rec.ra, rec.Dec, lnum, cfgsc), lp, True, lsize);
          end;
        end;
      end;
    Result := True;
  finally
    Fcatalog.CloseNeb;
    bmp.Free;
  end;
end;

function Tskychart.DrawImagesList: boolean;
type
  trdist = record
    r: double;
    n: integer;
  end;
var
  filename, objname: string;
  ra, de, Width, Height, dw, dh, lra, lde: double;
  cosr, sinr: extended;
  x1, y1, x2, y2, xx1, yy1, xx2, yy2, rot, ra2000, de2000: double;
  xx, yy: single;
  i, j, n: integer;
  rdist: array of trdist;
  crdist: trdist;
  maxreached, rdsorted: boolean;

  procedure drawfitslabel;
  var
    ii: integer;
    xx1, yy1: double;
    xla, yla: single;
  begin
    if cfgsc.ShowImageLabel and (fits.fitslist.Count > 0) then
    begin
      for ii := 0 to fits.fitslist.Count - 1 do
      begin
        if fits.fitslistactive[ii] then
        begin
          projection(fits.fitslistlabel[ii].lra, fits.fitslistlabel[ii].lde,
            xx1, yy1, True, cfgsc);
          WindowXY(xx1, yy1, xla, yla, cfgsc);
          SetLabel(fits.fitslistlabel[ii].lid, xla, yla, 0, 2, 7, ExtractFileName(
            fits.fitslist[ii]), laCenter, rad2deg * fits.fitslistlabel[ii].rot, 5, False);
        end;
      end;
    end;
  end;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': DrawImagesList');
  if bgvalid and (not bgsettingchange) and (bgcra = cfgsc.racentre) and
    (bgcde = cfgsc.decentre) and (bgfov = cfgsc.fov) and (bgmis = cfgsc.BGmin_sigma) and
    (bgmas = cfgsc.BGmax_sigma) and (bgw = cfgsc.xmax) and (bgh = cfgsc.ymax) and
    (bgproj = cfgsc.ProjPole) and (bgrot = cfgsc.theta) and (bgflipx = cfgsc.FlipX) and
    (bgflipy = cfgsc.FlipY) then
  begin
    //use cache bgbmp
    Fplot.PlotBGImage(bgbmp, cfgsc.WhiteBg, cfgsc.BGalpha);
    drawfitslabel;
  end
  else
  begin
    bgcra := cfgsc.racentre;
    bgcde := cfgsc.decentre;
    bgfov := cfgsc.fov;
    bgrot := cfgsc.theta;
    bgflipx := cfgsc.FlipX;
    bgflipy := cfgsc.FlipY;
    bgmis := cfgsc.BGmin_sigma;
    bgmas := cfgsc.BGmax_sigma;
    bgw := cfgsc.xmax;
    bgh := cfgsc.ymax;
    bgproj := cfgsc.ProjPole;
    bgvalid := False;
    bgsettingchange := False;
    // if the list is not manually edited
    if (not fits.fitslistmodified) or (fits.fitslistra <> cfgsc.racentre) or
      (fits.fitslistdec <> cfgsc.decentre) then
    begin
      cfgsc.MaxArchiveImg := min(cfgsc.MaxArchiveImg, maxfitslist);
      fits.fitslist.Clear;
      setlength(fits.fitslistactive, 10);
      setlength(fits.fitslistcenterdist, 10);
      setlength(fits.fitslistlabel, 10);
      fits.fitslistmodified := False;
      fits.fitslistra := cfgsc.racentre;
      fits.fitslistdec := cfgsc.decentre;
      n := 0;
      maxreached := False;
      Result := False;
      try
        ra2000 := cfgsc.racentre;
        de2000 := cfgsc.decentre;
        if cfgsc.ApparentPos then
          mean_equatorial(ra2000, de2000, cfgsc, True, True);
        precession(cfgsc.JDChart, jd2000, ra2000, de2000);
        if northpoleinmap(cfgsc) or southpoleinmap(cfgsc) then
        begin
          x1 := 0;
          x2 := pi2;
        end
        else
        begin
          x1 := NormRA(ra2000 - cfgsc.fov / cos(de2000) - deg2rad);
          x2 := NormRA(ra2000 + cfgsc.fov / cos(de2000) + deg2rad);
        end;
        y1 := MaxValue([-pid2, de2000 - cfgsc.fov / cfgsc.WindowRatio - deg2rad]);
        y2 := MinValue([pid2, de2000 + cfgsc.fov / cfgsc.WindowRatio + deg2rad]);
        // search each files in every directories using the values in database
        for i := 1 to MaxArchiveDir do
          if cfgsc.ArchiveDirActive[i] then
          begin
            if FFits.OpenDB(cfgsc.ArchiveDir[i], x1, x2, y1, y2) then
              while FFits.GetDB(filename, objname, ra, de, Width, Height, rot) do
              begin
                sincos(rot, sinr, cosr);
                precession(jd2000, cfgsc.JDChart, ra, de);
                if cfgsc.ApparentPos then
                  apparent_equatorial(ra, de, cfgsc, True, True);
                projection(ra, de, xx1, yy1, True, cfgsc);
                WindowXY(xx1, yy1, xx, yy, cfgsc);
                dw := abs((Width * cosr + Height * sinr) * abs(cfgsc.BxGlb) / 2);
                dh := abs((Height * cosr + Width * sinr) * abs(cfgsc.ByGlb) / 2);
                if ((xx + dw) > cfgsc.Xmin) and ((xx - dw) < cfgsc.Xmax) and
                  ((yy + dh) > cfgsc.Ymin) and ((yy - dh) < cfgsc.Ymax) and
                  (abs(max(Width, Height) * cfgsc.BxGlb) > 10) then
                begin
                  // this file is visible on the current chart
                  fits.fitslist.Add(filename);
                  if n < cfgsc.MaxArchiveImg then
                    fits.fitslistactive[n] := True
                  else
                  begin
                    fits.fitslistactive[n] := False;
                    maxreached := True;
                  end;
                  fits.fitslistcenterdist[n] :=
                    AngularDistance(cfgsc.racentre, cfgsc.decentre, ra, de);
                  projection(ra, de + 0.001, xx2, yy2, False, cfgsc);
                  fits.fitslistlabel[n].rot := rot + RotationAngle(xx1, yy1, xx2, yy2, cfgsc);
                  XYWindow(round(xx), round(yy + dh), xx2, yy2, cfgsc);
                  InvProj(xx2, yy2, lra, lde, cfgsc);
                  fits.fitslistlabel[n].lra := lra;
                  fits.fitslistlabel[n].lde := lde;
                  fits.fitslistlabel[n].lid :=
                    rshash(filename + FormatFloat(f6, lra) + FormatFloat(f6, lde), $7FFFFFFF);
                  Inc(n);
                  if n >= Length(fits.fitslistactive) then
                  begin
                    SetLength(fits.fitslistactive, Length(fits.fitslistactive) + 10);
                    SetLength(fits.fitslistcenterdist, Length(fits.fitslistcenterdist) + 10);
                    SetLength(fits.fitslistlabel, Length(fits.fitslistlabel) + 10);
                  end;
                end;
              end;
          end;
      finally
      end;
      if cfgsc.ShowBackgroundImage then
      begin
        if FFits.OpenDB('other', x1, x2, y1, y2) then
          while FFits.GetDB(filename, objname, ra, de, Width, Height, rot) do
            if objname = 'BKG' then
            begin
              // add the last downloaded image even if not archived
              sincos(rot, sinr, cosr);
              precession(jd2000, cfgsc.JDChart, ra, de);
              if cfgsc.ApparentPos then
                apparent_equatorial(ra, de, cfgsc, True, True);
              projection(ra, de, xx1, yy1, True, cfgsc);
              WindowXY(xx1, yy1, xx, yy, cfgsc);
              dw := abs((Width * cosr + Height * sinr) * abs(cfgsc.BxGlb) / 2);
              dh := abs((Height * cosr + Width * sinr) * abs(cfgsc.ByGlb) / 2);
              if ((xx + dw) > cfgsc.Xmin) and ((xx - dw) < cfgsc.Xmax) and
                ((yy + dh) > cfgsc.Ymin) and ((yy - dh) < cfgsc.Ymax) and
                (abs(max(Width, Height) * cfgsc.BxGlb) > 10) then
              begin
                fits.fitslist.Add(filename);
                fits.fitslistactive[n] := True;
                fits.fitslistcenterdist[n] := 0;
                projection(ra, de + 0.001, xx2, yy2, False, cfgsc);
                fits.fitslistlabel[n].rot := rot + RotationAngle(xx1, yy1, xx2, yy2, cfgsc);
                XYWindow(round(xx), round(yy + dh), xx2, yy2, cfgsc);
                InvProj(xx2, yy2, lra, lde, cfgsc);
                fits.fitslistlabel[n].lra := lra;
                fits.fitslistlabel[n].lde := lde;
                fits.fitslistlabel[n].lid :=
                  rshash(filename + FormatFloat(f6, lra) + FormatFloat(f6, lde), $7FFFFFFF);
                Inc(n);
                if n >= Length(fits.fitslistactive) then
                begin
                  SetLength(fits.fitslistactive, Length(fits.fitslistactive) + 10);
                  SetLength(fits.fitslistcenterdist, Length(fits.fitslistcenterdist) + 10);
                  SetLength(fits.fitslistlabel, Length(fits.fitslistlabel) + 10);
                end;
              end;
            end;
      end;
      // if too much files, keep the ones near the center
      if maxreached and (fits.fitslist.Count > 0) then
      begin
        SetLength(rdist, fits.fitslist.Count);
        for j := 0 to fits.fitslist.Count - 1 do
        begin
          rdist[j].n := j;
          rdist[j].r := fits.fitslistcenterdist[j];
        end;
        // sort by distance to center
        repeat
          rdsorted := True;
          for j := 1 to fits.fitslist.Count - 1 do
          begin
            if rdist[j - 1].r > rdist[j].r then
            begin
              crdist := rdist[j - 1];
              rdist[j - 1] := rdist[j];
              rdist[j] := crdist;
              rdsorted := False;
            end;
          end;
        until rdsorted;
        // keep files near the center
        for j := 0 to fits.fitslist.Count - 1 do
        begin
          if j < cfgsc.MaxArchiveImg then
            fits.fitslistactive[rdist[j].n] := True
          else
            fits.fitslistactive[rdist[j].n] := False;
        end;
      end;
    end;
    if fits.fitslist.Count > 0 then
    begin
      FFits.min_sigma := cfgsc.BGmin_sigma;
      FFits.max_sigma := cfgsc.BGmax_sigma;
      FFits.itt := cfgsc.BGitt;
      FFits.GetProjList(bgbmp, cfgsc);
      Fplot.PlotBGImage(bgbmp, cfgsc.WhiteBg, cfgsc.BGalpha);
      drawfitslabel;
      bgvalid := True;
    end;
  end;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': DrawImagesList end');
end;

function Tskychart.DrawOutline: boolean;
var
  rec: GcatRec;
  x1, y1: double;
  xx, yy: single;
  op, lw, col, fs: integer;
  lid, lnum, lp, rs: integer;
  lis: string;
  sbmp:TBGRABitmap;
  sbmpUsed: boolean;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw outlines');
  if Fcatalog.OpenLin then
  begin
    sbmp := TBGRABitmap.Create;
    sbmp.SetSize(fplot.cfgchart.Width, fplot.cfgchart.Height);
    sbmp.FillTransparent;
    sbmpUsed:=false;
    fillchar(rec, sizeof(rec), 0);
    lnum := 7;
    lp := 2;
    rs:=0;
    try
      while Fcatalog.readlin(rec) do
      begin
        precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
        if cfgsc.ApparentPos then
          apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, False);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc, False);
        WindowXY(x1, y1, xx, yy, cfgsc);
        op := rec.outlines.lineoperation;
        if (op=0)and(rec.outlines.id<>'') then begin
          lis := rec.outlines.id + FormatFloat(f6, rec.ra) + FormatFloat(f6, rec.Dec);
          lid := rshash(lis, $7FFFFFFF);
          SetLabel(lid, xx, yy, rs, 2, lnum, rec.outlines.id, laTopLeft, labrotation(rec.ra, rec.Dec, lnum, cfgsc), lp);
        end;
        if rec.outlines.valid[vlLinewidth] then
          lw := rec.outlines.linewidth
        else
          lw := rec.options.Size;
        if rec.outlines.valid[vlLinetype] then
          fs := rec.outlines.linetype
        else
          fs := rec.options.LogSize;
        if cfgsc.WhiteBg then
          col := FPlot.cfgplot.Color[11]
        else
        begin
          if rec.outlines.valid[vlLinecolor] then
            col := rec.outlines.linecolor
          else
            col := rec.options.Units;
        end;
        sbmpUsed := FPlot.PlotOutline(xx, yy, op, lw, fs, rec.options.ObjType, cfgsc.x2, col, sbmp, cfgsc.SurfaceAlpha) or sbmpUsed;
      end;
      if sbmpUsed then begin
        if cfgsc.SurfaceBlure then
           BGRAReplace(sbmp,sbmp.FilterBlurRadial(5*min(1,10*deg2rad/cfgsc.fov),rbFast));
        Fplot.cbmp.PutImage(0, 0, sbmp, dmLinearBlend);
      end;
      sbmp.Free;
      Result := True;
    finally
      Fcatalog.CloseLin;
    end;
  end;
end;

function Tskychart.DrawDSL: boolean;
var
  rec: GcatRec;
  x1, y1: double;
  xx, yy: single;
  op, lw, col, fs: integer;
  sbmp:TBGRABitmap;
  sbmpUsed: boolean;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw nebula outlines');
  if Fcatalog.OpenDSL(cfgsc.DSLsurface, cfgsc.DSLforcecolor, cfgsc.DSLcolor) then
  begin
    sbmp := TBGRABitmap.Create;
    sbmp.SetSize(fplot.cfgchart.Width, fplot.cfgchart.Height);
    sbmp.FillTransparent;
    sbmpUsed:=false;
    fillchar(rec, sizeof(rec), 0);
    try
      while Fcatalog.ReadDSL(rec) do
      begin
        precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
        if cfgsc.ApparentPos then
          apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, False);
        projection(rec.ra, rec.Dec, x1, y1, True, cfgsc, False);
        WindowXY(x1, y1, xx, yy, cfgsc);
        op := rec.outlines.lineoperation;
        if rec.outlines.valid[vlLinewidth] then
          lw := rec.outlines.linewidth
        else
          lw := rec.options.Size;
        if rec.outlines.valid[vlLinetype] then
          fs := rec.outlines.linetype
        else
          fs := rec.options.LogSize;
        if cfgsc.WhiteBg then
          col := FPlot.cfgplot.Color[11]
        else
        begin
          if rec.outlines.valid[vlLinecolor] then
            col := rec.outlines.linecolor
          else
            col := rec.options.Units;
        end;
        sbmpUsed := FPlot.PlotOutline(xx, yy, op, lw, fs, rec.options.ObjType, cfgsc.x2, col, sbmp, cfgsc.SurfaceAlpha) or sbmpUsed;
      end;
      if sbmpUsed then begin
        if cfgsc.SurfaceBlure then
           BGRAReplace(sbmp,sbmp.FilterBlurRadial(5*min(1,10*deg2rad/cfgsc.fov),rbFast));
        Fplot.cbmp.PutImage(0, 0, sbmp, dmLinearBlend);
      end;
      sbmp.Free;
      Result := True;
    finally
      Fcatalog.CloseDSL;
    end;
  end;
end;

function Tskychart.DrawMilkyWay: boolean;
var
  rec: GcatRec;
  x1, y1: double;
  xx, yy: single;
  op, lw, col, fs, i: integer;
  First: boolean;
  pxradius, ra, de: double;
  xmi, xma, ymi, yma: single;
  mwcol: TColor;
begin
  Result := False;
  if not cfgsc.ShowMilkyWay then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw milky way');
  if Fcatalog.cfgshr.MilkywaydotNum = 0 then
    cfgsc.LinemodeMilkyway := True;
  if cfgsc.LinemodeMilkyway then
  begin
    if cfgsc.fov < (deg2rad * 2) then
      exit;
    fillchar(rec, sizeof(rec), 0);
    First := True;
    lw := 1;
    fs := 1;
    if cfgsc.WhiteBg then
      col := FPlot.cfgplot.Color[11]
    else
    begin
      col := addcolor(FPlot.cfgplot.Color[22], FPlot.cfgplot.Color[0]);
    end;
    if col = FPlot.cfgplot.bgcolor then
      cfgsc.FillMilkyWay := False;
    try
      if Fcatalog.OpenMilkyway(cfgsc.FillMilkyWay) then
        while Fcatalog.readMilkyway(rec) do
        begin
          if First then
          begin
            // all the milkyway line use the same property
            if rec.outlines.valid[vlLinewidth] then
              lw := rec.outlines.linewidth
            else
              lw := rec.options.Size;
            if rec.outlines.valid[vlLinetype] then
              fs := rec.outlines.linetype
            else
              fs := rec.options.LogSize;
            if fs=2 then fs:=3; // no spline for milkyway
            First := False;
          end;
          precession(rec.options.EquinoxJD, cfgsc.JDChart, rec.ra, rec.Dec);
          if cfgsc.ApparentPos then
            apparent_equatorial(rec.ra, rec.Dec, cfgsc, True, False);
          projection(rec.ra, rec.Dec, x1, y1, True, cfgsc, True);
          WindowXY(x1, y1, xx, yy, cfgsc);
          op := rec.outlines.lineoperation;
          FPlot.PlotOutline(xx, yy, op, lw, fs, rec.options.ObjType, cfgsc.x2, col);
        end;
      Result := True;
    finally
      Fcatalog.CloseMilkyway;
    end;
  end
  else
  begin
    pxradius := round(max(abs(cfgsc.BxGlb) * deg2rad * Fcatalog.cfgshr.Milkywaydotradius,
      Fplot.cfgchart.drawpen)) + Fplot.cfgchart.drawpen;
    xmi := cfgsc.Xmin - pxradius;
    xma := cfgsc.Xmax + pxradius;
    ymi := cfgsc.Ymin - pxradius;
    yma := cfgsc.Ymax + pxradius;
    for i := 0 to Fcatalog.cfgshr.MilkywaydotNum - 1 do
    begin
      ra := Fcatalog.cfgshr.Milkywaydot[i].ra;
      de := Fcatalog.cfgshr.Milkywaydot[i].de;
      precession(jd2000, cfgsc.JDChart, ra, de);
      projection(ra, de, x1, y1, True, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (xx > xmi) and (xx < xma) and (yy > ymi) and (yy < yma) then
      begin
        col := round(Fcatalog.cfgshr.Milkywaydot[i].val);
        mwcol := (col) + 256 * (col) + 65536 * (col);
        FPlot.PlotMWDot(xx, yy, pxradius, mwcol, cfgsc.WhiteBg);
      end;
    end;
  end;
end;

function Tskychart.DrawPlanet: boolean;
var
  x1, y1, xx1, yy1, xx2, yy2, pixscale, ra, Dec, jdt, diam, magn, phase, fov, pa,
  rot, r1, r2, be, dist, distc,lecl1,becl1,lecl2,becl2: double;
  ppa, poleincl, sunincl, w1, w2, w3, a, h, dh, h1, h2, flatten, moonflatten, saverefraction: double;
  xx, yy, lori: single;
  lopt,lblup: boolean;
  lalign: TLabelAlign;
  i, j, jj, n, ipla, sunsize, lid: integer;
  draworder: array[1..11] of integer;
  ltxt, lis, buf: string;
  ft: textfile;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw planets');
  fov := rad2deg * cfgsc.fov;
  moonflatten:=1;
  pixscale := abs(cfgsc.BxGlb) * deg2rad / 3600;
  for j := 0 to cfgsc.SimNb - 1 do
  begin
    draworder[1] := 1;
    for n := 2 to 11 do
    begin
      if cfgsc.Planetlst[j, n, 6] < cfgsc.Planetlst[j, draworder[n - 1], 6] then
        draworder[n] := n
      else
      begin
        i := n;
        repeat
          i := i - 1;
          draworder[i + 1] := draworder[i];
        until (i = 1) or (cfgsc.Planetlst[j, n, 6] <= cfgsc.Planetlst[j, draworder[i - 1], 6]);
        draworder[i] := n;
      end;
    end;
    if (Fplot.cfgplot.plaplot = 2) and cfgsc.PlanetParalaxe and (cfgsc.CurYear > 1000) then
    begin
      buf := jddate2(cfgsc.Planetlst[j, 10, 3]);
      buf := buf + ' 1.0 ' + formatfloat(f5, cfgsc.ObsLatitude) + blank + formatfloat(
        f5, -cfgsc.ObsLongitude);
      AssignFile(ft, slash(Tempdir) + 'origin.txt');
      rewrite(ft);
      writeln(ft, buf);
      CloseFile(ft);
      if VerboseMsg then
        WriteTrace('Created ' + slash(Tempdir) + 'origin.txt');
    end
    else
    begin
      if FileExists(slash(Tempdir) + 'origin.txt') then
      begin
        DeleteFile(slash(Tempdir) + 'origin.txt');
        if VerboseMsg then
          WriteTrace('Deleted ' + slash(Tempdir) + 'origin.txt');
      end;
    end;
    for n := 1 to 11 do
    begin
      ipla := draworder[n];
      if ((j>0) or ((cfgsc.SimNb>1) and cfgsc.SimMark and cfgsc.SimObject[ipla])) and (not cfgsc.SimObject[ipla]) then
        continue;
      if ipla = 3 then
        continue;
      if (ipla = 9) and (not cfgsc.ShowPluto) then
        continue;
      ra := cfgsc.Planetlst[j, ipla, 1];
      Dec := cfgsc.Planetlst[j, ipla, 2];
      jdt := cfgsc.Planetlst[j, ipla, 3];
      diam := cfgsc.Planetlst[j, ipla, 4];
      magn := cfgsc.Planetlst[j, ipla, 5];
      phase := cfgsc.Planetlst[j, ipla, 7];
      Eq2Hz(cfgsc.CurST - ra, Dec, a, h, cfgsc, 0);
      if (cfgsc.ProjPole = Altaz) and (h < pid4) then
      begin
        dh := abs(deg2rad * diam / 3600);
        h1 := h + dh / 2;
        Refraction(h1, True, cfgsc, refmethod);
        h2 := h - dh / 2;
        Refraction(h2, True, cfgsc, refmethod);
        flatten := abs(h1 - h2) / dh;
        if (flatten > 0.99) then
          flatten := 1;
        if (flatten < 0.7) then
          flatten := 0.7;
      end
      else
        flatten := 1;
      distc := rad2deg * AngularDistance(ra, Dec, cfgsc.racentre, cfgsc.decentre);
      projection(ra, Dec, x1, y1, (h < (-deg2rad)), cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if ((xx > -5 * cfgsc.Xmax) and (xx < 6 * cfgsc.Xmax) and (yy > -5 * cfgsc.Ymax) and
        (yy < 6 * cfgsc.Ymax)) or (distc < 2) then
      begin
        saverefraction := cfgsc.ObsRefractionCor;
        try
          cfgsc.ObsRefractionCor := 0;        // rotation without refraction
          projection(ra, Dec, xx1, yy1, False, cfgsc);
          projection(ra, Dec + 0.001, xx2, yy2, False, cfgsc);
          rot := RotationAngle(xx1, yy1, xx2, yy2, cfgsc);
        finally
          cfgsc.ObsRefractionCor := saverefraction;
        end;
        if (ipla <> 3) and (ipla <= 10) then
          Fplanet.PlanetOrientation(jdt, ipla, ppa, poleincl, sunincl, w1, w2, w3);
        if (doSimLabel(cfgsc.SimNb, j, cfgsc.SimLabel)) and (ipla <= 11) then
        begin
          if (cfgsc.SimNb = 1) or (not cfgsc.SimObject[ipla]) then
          begin
            ltxt := pla[ipla];
            lori := labrotation(ra, Dec, 5, cfgsc);
            lopt := True;
            lalign := laLeft;
          end
          else
          begin
            if cfgsc.SimNameLabel then
              ltxt := pla[ipla] + blank
            else
              ltxt := '';
            if cfgsc.SimDateLabel then
              ltxt := ltxt + jddatetime(jdt + (cfgsc.TimeZone - cfgsc.DT_UT) /
                24, cfgsc.SimDateYear, cfgsc.SimDateMonth, cfgsc.SimDateDay, cfgsc.SimDateHour,
                cfgsc.SimDateMinute, cfgsc.SimDateSecond) + blank;
            if cfgsc.SimMagLabel then
              if ipla = 11 then
                ltxt := ltxt + formatfloat(f1, Fplanet.MoonMag(phase))
              else
                ltxt := ltxt + formatfloat(f1, magn);
            if j < cfgsc.SimNb - 1 then
            begin  // for the last label we keep the orientation of the previous one
              if j=0 then begin
                // try to detect the side of retrograde loop, work only for the first side of the loop
                Eq2Ecl(cfgsc.Planetlst[0, ipla, 1],cfgsc.Planetlst[0, ipla, 2],cfgsc.ecl,lecl1,becl1);
                Eq2Ecl(cfgsc.Planetlst[cfgsc.SimNb-1, ipla, 1],cfgsc.Planetlst[cfgsc.SimNb-1, ipla, 2],cfgsc.ecl,lecl2,becl2);
                lblup:=((becl1>=becl2) and (cfgsc.Planetlst[1, ipla, 1]>cfgsc.Planetlst[0, ipla, 1])) or ((becl1<becl2) and (cfgsc.Planetlst[1, ipla, 1]<cfgsc.Planetlst[0, ipla, 1]))
              end;
              jj := j + 1;
              projection(cfgsc.Planetlst[jj, ipla, 1], cfgsc.Planetlst[jj, ipla, 2], xx2, yy2, True, cfgsc);
              if lblup
              then
                lori := rmod(rad2deg * RotationAngle(x1, y1, xx2, yy2, cfgsc) + 360, 360)
              else
                lori := rmod(rad2deg * RotationAngle(xx2, yy2, x1, y1, cfgsc) + 360, 360);
            end;
            if (lori < 90) or (lori > 270) then
            begin
              lalign := laLeft;
            end
            else
            begin
              lalign := laRight;
              lori := lori - 180;
            end;
            lopt := False;
          end;
          lis := pla[ipla] + FormatFloat(f3, cfgsc.Planetlst[j, ipla, 8]) + FormatFloat(f3, cfgsc.Planetlst[j, ipla, 9]);
          lid := rshash(lis, $7FFFFFFF);
          SetLabel(lid, xx, yy, round(pixscale * diam / 2), 2, 5, ltxt, lalign, lori, 1, lopt);
        end;
        if (cfgsc.SimNb=1)or (not (cfgsc.SimLine and cfgsc.SimMark and cfgsc.SimObject[ipla])) then case ipla of
          4:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 29, 6] < 90) then
              for i := 1 to 2 do
                DrawSatel(j, i + 28, cfgsc.Planetlst[j, i + 28, 1], cfgsc.Planetlst[j, i + 28, 2],
                  cfgsc.Planetlst[j, i + 28, 5], cfgsc.Planetlst[j, i + 28, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 28, 6] > 1.0, True, cfgsc.Planetlst[j, i + 28, 8], cfgsc.Planetlst[j, i + 28, 9]);
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, 0, 0, 0, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 29, 6] < 90) then
              for i := 1 to 2 do
                DrawSatel(j, i + 28, cfgsc.Planetlst[j, i + 28, 1], cfgsc.Planetlst[j, i + 28, 2],
                  cfgsc.Planetlst[j, i + 28, 5], cfgsc.Planetlst[j, i + 28, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 28, 6] > 1.0, False, cfgsc.Planetlst[j, i + 28, 8], cfgsc.Planetlst[j, i + 28, 9]);
          end;
          5:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 12, 6] < 90) then
            begin
              for i := 1 to 4 do
                DrawSatel(j, i + 11, cfgsc.Planetlst[j, i + 11, 1], cfgsc.Planetlst[j, i + 11, 2],
                  cfgsc.Planetlst[j, i + 11, 5], cfgsc.Planetlst[j, i + 11, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 11, 6] > 1.0, True, cfgsc.Planetlst[j, i + 11, 8], cfgsc.Planetlst[j, i + 11, 9]);
              if cfgsc.SmallSatActive then begin
                for i := 1 to 4 do
                  DrawSatel(j, i + 36, cfgsc.Planetlst[j, i + 36, 1], cfgsc.Planetlst[j, i + 36, 2],
                    cfgsc.Planetlst[j, i + 36, 5], cfgsc.Planetlst[j, i + 36, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 36, 6] > 1.0, True, cfgsc.Planetlst[j, i + 36, 8], cfgsc.Planetlst[j, i + 36, 9]);
                if cfgsc.CalcephActive or cfgsc.SpiceActive then begin
                for i := 1 to 8 do
                  DrawSatel(j, i + 69, cfgsc.Planetlst[j, i + 69, 1], cfgsc.Planetlst[j, i + 69, 2],
                    cfgsc.Planetlst[j, i + 69, 5], cfgsc.Planetlst[j, i + 69, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 69, 6] > 1.0, True, cfgsc.Planetlst[j, i + 69, 8], cfgsc.Planetlst[j, i + 69, 9]);
                end;
              end;
            end;
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w2,
              Fplanet.JupGRS(cfgsc.GRSlongitude, cfgsc.GRSdrift, cfgsc.GRSjd, cfgsc.CurJDTT), 0, 0, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 12, 6] < 90) then
            begin
              for i := 1 to 4 do
                DrawSatel(j, i + 11, cfgsc.Planetlst[j, i + 11, 1], cfgsc.Planetlst[j, i + 11, 2],
                  cfgsc.Planetlst[j, i + 11, 5], cfgsc.Planetlst[j, i + 11, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 11, 6] > 1.0, False, cfgsc.Planetlst[j, i + 11, 8], cfgsc.Planetlst[j, i + 11, 9]);
              if cfgsc.SmallSatActive then begin
                for i := 1 to 4 do
                  DrawSatel(j, i + 36, cfgsc.Planetlst[j, i + 36, 1], cfgsc.Planetlst[j, i + 36, 2],
                    cfgsc.Planetlst[j, i + 36, 5], cfgsc.Planetlst[j, i + 36, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 36, 6] > 1.0, False, cfgsc.Planetlst[j, i + 36, 8], cfgsc.Planetlst[j, i + 36, 9]);
                if cfgsc.CalcephActive or cfgsc.SpiceActive then begin
                for i := 1 to 8 do
                  DrawSatel(j, i + 69, cfgsc.Planetlst[j, i + 69, 1], cfgsc.Planetlst[j, i + 69, 2],
                    cfgsc.Planetlst[j, i + 69, 5], cfgsc.Planetlst[j, i + 69, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 69, 6] > 1.0, False, cfgsc.Planetlst[j, i + 69, 8], cfgsc.Planetlst[j, i + 69, 9]);
                end;
              end;
            end;
          end;
          6:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 16, 6] < 90) then
            begin
              for i := 1 to 8 do
                DrawSatel(j, i + 15, cfgsc.Planetlst[j, i + 15, 1], cfgsc.Planetlst[j, i + 15, 2],
                  cfgsc.Planetlst[j, i + 15, 5], cfgsc.Planetlst[j, i + 15, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 15, 6] > 1.0, True, cfgsc.Planetlst[j, i + 15, 8], cfgsc.Planetlst[j, i + 15, 9]);
              DrawSatel(j, 33, cfgsc.Planetlst[j, 33, 1], cfgsc.Planetlst[j, 33, 2],
                cfgsc.Planetlst[j, 33, 5], cfgsc.Planetlst[j, 33, 4], pixscale, rot,
                cfgsc.Planetlst[j, 33, 6] > 1.0, True, cfgsc.Planetlst[j, 33, 8], cfgsc.Planetlst[j, 33, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 10 do
                  DrawSatel(j, i + 40, cfgsc.Planetlst[j, i + 40, 1], cfgsc.Planetlst[j, i + 40, 2],
                    cfgsc.Planetlst[j, i + 40, 5], cfgsc.Planetlst[j, i + 40, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 40, 6] > 1.0, True, cfgsc.Planetlst[j, i + 40, 8], cfgsc.Planetlst[j, i + 40, 9]);
            end;
            r1 := cfgsc.Planetlst[j, 31, 2];
            r2 := cfgsc.Planetlst[j, 31, 3];
            be := cfgsc.Planetlst[j, 31, 4];
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, r1, r2, be, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 16, 6] < 90) then
            begin
              for i := 1 to 8 do
                DrawSatel(j, i + 15, cfgsc.Planetlst[j, i + 15, 1], cfgsc.Planetlst[j, i + 15, 2],
                  cfgsc.Planetlst[j, i + 15, 5], cfgsc.Planetlst[j, i + 15, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 15, 6] > 1.0, False, cfgsc.Planetlst[j, i + 15, 8], cfgsc.Planetlst[j, i + 15, 9]);
              DrawSatel(j, 33, cfgsc.Planetlst[j, 33, 1], cfgsc.Planetlst[j, 33, 2],
                cfgsc.Planetlst[j, 33, 5], cfgsc.Planetlst[j, 33, 4], pixscale, rot,
                cfgsc.Planetlst[j, 33, 6] > 1.0, False, cfgsc.Planetlst[j, 33, 8], cfgsc.Planetlst[j, 33, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 10 do
                  DrawSatel(j, i + 40, cfgsc.Planetlst[j, i + 40, 1], cfgsc.Planetlst[j, i + 40, 2],
                    cfgsc.Planetlst[j, i + 40, 5], cfgsc.Planetlst[j, i + 40, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 40, 6] > 1.0, False, cfgsc.Planetlst[j, i + 40, 8], cfgsc.Planetlst[j, i + 40, 9]);
            end;
          end;
          7:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 24, 6] < 90) then
            begin
              for i := 1 to 5 do
                DrawSatel(j, i + 23, cfgsc.Planetlst[j, i + 23, 1], cfgsc.Planetlst[j, i + 23, 2],
                  cfgsc.Planetlst[j, i + 23, 5], cfgsc.Planetlst[j, i + 23, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 23, 6] > 1.0, True, cfgsc.Planetlst[j, i + 23, 8], cfgsc.Planetlst[j, i + 23, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 13 do
                  DrawSatel(j, i + 50, cfgsc.Planetlst[j, i + 50, 1], cfgsc.Planetlst[j, i + 50, 2],
                    cfgsc.Planetlst[j, i + 50, 5], cfgsc.Planetlst[j, i + 50, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 50, 6] > 1.0, True, cfgsc.Planetlst[j, i + 50, 8], cfgsc.Planetlst[j, i + 50, 9]);
            end;
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, 0, 0, 0, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 24, 6] < 90) then
            begin
              for i := 1 to 5 do
                DrawSatel(j, i + 23, cfgsc.Planetlst[j, i + 23, 1], cfgsc.Planetlst[j, i + 23, 2],
                  cfgsc.Planetlst[j, i + 23, 5], cfgsc.Planetlst[j, i + 23, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 23, 6] > 1.0, False, cfgsc.Planetlst[j, i + 23, 8], cfgsc.Planetlst[j, i + 23, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 13 do
                  DrawSatel(j, i + 50, cfgsc.Planetlst[j, i + 50, 1], cfgsc.Planetlst[j, i + 50, 2],
                    cfgsc.Planetlst[j, i + 50, 5], cfgsc.Planetlst[j, i + 50, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 50, 6] > 1.0, False, cfgsc.Planetlst[j, i + 50, 8], cfgsc.Planetlst[j, i + 50, 9]);
            end;
          end;
          8:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 34, 6] < 90) then
            begin
              for i := 1 to 2 do
                DrawSatel(j, i + 33, cfgsc.Planetlst[j, i + 33, 1], cfgsc.Planetlst[j, i + 33, 2],
                  cfgsc.Planetlst[j, i + 33, 5], cfgsc.Planetlst[j, i + 33, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 33, 6] > 1.0, True, cfgsc.Planetlst[j, i + 33, 8], cfgsc.Planetlst[j, i + 33, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 6 do
                  DrawSatel(j, i + 63, cfgsc.Planetlst[j, i + 63, 1], cfgsc.Planetlst[j, i + 63, 2],
                    cfgsc.Planetlst[j, i + 63, 5], cfgsc.Planetlst[j, i + 63, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 63, 6] > 1.0, True, cfgsc.Planetlst[j, i + 63, 8], cfgsc.Planetlst[j, i + 63, 9]);
            end;
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, 0, 0, 0, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 34, 6] < 90) then
            begin
              for i := 1 to 2 do
                DrawSatel(j, i + 33, cfgsc.Planetlst[j, i + 33, 1], cfgsc.Planetlst[j, i + 33, 2],
                  cfgsc.Planetlst[j, i + 33, 5], cfgsc.Planetlst[j, i + 33, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 33, 6] > 1.0, False, cfgsc.Planetlst[j, i + 33, 8], cfgsc.Planetlst[j, i + 33, 9]);
              if cfgsc.SmallSatActive then
                for i := 1 to 6 do
                  DrawSatel(j, i + 63, cfgsc.Planetlst[j, i + 63, 1], cfgsc.Planetlst[j, i + 63, 2],
                    cfgsc.Planetlst[j, i + 63, 5], cfgsc.Planetlst[j, i + 63, 4], pixscale, rot,
                    cfgsc.Planetlst[j, i + 63, 6] > 1.0, False, cfgsc.Planetlst[j, i + 63, 8], cfgsc.Planetlst[j, i + 63, 9]);
            end;
          end;
          9:
          begin
            if (fov <= 5) and (cfgsc.Planetlst[j, 36, 6] < 90) then
              for i := 1 to 1 do
                DrawSatel(j, i + 35, cfgsc.Planetlst[j, i + 35, 1], cfgsc.Planetlst[j, i + 35, 2],
                  cfgsc.Planetlst[j, i + 35, 5], cfgsc.Planetlst[j, i + 35, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 35, 6] > 1.0, True, cfgsc.Planetlst[j, i + 35, 8], cfgsc.Planetlst[j, i + 35, 9]);
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, 0, 0, 0, False);
            if (fov <= 5) and (cfgsc.Planetlst[j, 34, 6] < 90) then
              for i := 1 to 1 do
                DrawSatel(j, i + 35, cfgsc.Planetlst[j, i + 35, 1], cfgsc.Planetlst[j, i + 35, 2],
                  cfgsc.Planetlst[j, i + 35, 5], cfgsc.Planetlst[j, i + 35, 4], pixscale, rot,
                  cfgsc.Planetlst[j, i + 35, 6] > 1.0, False, cfgsc.Planetlst[j, i + 35, 8], cfgsc.Planetlst[j, i + 35, 9]);
          end;
          10:
          begin
            if cfgsc.SunOnline or use_xplanet then
              sunsize := cfgsc.sunurlsize
            else
              sunsize := 0;
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, -w1, 0,
              0, 0, False, sunsize, cfgsc.sunurlmargin);
          end;
          11:
          begin
            moonflatten:=flatten;
            magn := -10;  // better to alway show a bright dot for the Moon
            dist := cfgsc.Planetlst[j, ipla, 6];
            fplanet.MoonOrientation(jdt, ra, Dec, dist, pa, poleincl, sunincl, w1);
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, pa, rot, poleincl, sunincl, -w1, 0, 0, 0, False);
          end;
          else
          begin
            Fplot.PlotPlanet(xx, yy, cfgsc.FlipX, cfgsc.FlipY, ipla,
              jdt, pixscale, diam, flatten, magn, phase, ppa, rot, poleincl, sunincl, w1, 0, 0, 0, False);
          end;
        end;
      end;
    end;

    if cfgsc.ShowEarthShadowValid and   // draw earth shadow
      ((j = 0) or                       //  at first simulation point
      ((j = (cfgsc.SimNb - 1)) and cfgsc.SimObject[11])) // and at the last point if simulating the Moon
      then
        DrawEarthShadow(cfgsc.Planetlst[j, 32, 1], cfgsc.Planetlst[j, 32, 2],
        cfgsc.Planetlst[j, 32, 3], cfgsc.Planetlst[j, 32, 4], cfgsc.Planetlst[j, 32, 5], moonflatten);

  end;
  Result := True;
end;

procedure Tskychart.DrawEarthShadow(AR, DE, SunDist, MoonDist, MoonDistTopo, flatten: double);
var
  x, y, cone, umbra, penumbra, pixscale: double;
  xx, yy: single;
begin
  projection(ar, de, x, y, True, cfgsc);
  windowxy(x, y, xx, yy, cfgsc);
  // earth diam = 12.906 incl atmophere ; sun diam = 1392 (*1000 km)
  cone := SunDist * 12.906 / (1392 - 12.906);
  umbra := 12906 * (cone - MoonDist) / cone;
  umbra := 1.01 * arctan2(umbra, MoonDistTopo);
  penumbra := umbra + 1.07 * deg2rad;  // + 2x sun diameter
  pixscale := abs(cfgsc.BxGlb);
  Fplot.PlotEarthShadow(xx, yy, umbra, penumbra, pixscale, flatten, cfgsc.EarthShadowForceLine);
end;

procedure Tskychart.DrawSatel(j, ipla: integer; ra, Dec, ma, diam, pixscale, rot: double;
  hidesat, showhide: boolean; ra2000, de2000: double);
var
  x1, y1: double;
  xx, yy: single;
  lid: integer;
  lis: string;
begin
  projection(ra, Dec, x1, y1, True, cfgsc);
  WindowXY(x1, y1, xx, yy, cfgsc);
  Fplot.PlotSatel(xx, yy, ipla, cfgsc.JDChart, pixscale, ma, diam, rot, hidesat,
    showhide, False, cfgsc.FlipX, cfgsc.FlipY);

  if not (hidesat xor showhide) and (j = 0) then
  begin
    lis := pla[ipla] + FormatFloat(f3, ra2000) + FormatFloat(f3, de2000);
    lid := rshash(lis, $7FFFFFFF);
    SetLabel(lid, xx, yy, round(pixscale * diam / 2), 2, 5, pla[ipla], laLeft,
      labrotation(ra, Dec, 5, cfgsc), 2, True);
  end;
end;

function Tskychart.DrawAsteroidMark: boolean;
var
  i: integer;
  ra, de, mag, x1, y1: double;
  xx, yy, r, lori: single;
  lalign: TLabelAlign;
  lid: integer;
  lopt: boolean;
  ltxt, lis: string;
begin
  Result := False;
  if cfgsc.ShowAsteroidValid then
  begin
    r := 5;
    if Fplot.cfgplot.UseBMP then r := DoScaleX(5);
    for i := 0 to cfgsc.AsteroidMark.Count - 1 do
    begin
      if FPlanet.FindAsteroidName(cfgsc.AsteroidMark[i], ra, de, mag, cfgsc, False) then
      begin
        precession(jd2000, cfgsc.jdchart, ra, de);
        if cfgsc.ApparentPos then
        begin
          apparent_equatorial(ra, de, cfgsc, True, False);
        end;
        projection(ra, de, x1, y1, True, cfgsc);
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and
          (yy < cfgsc.Ymax) then
        begin
          Fplot.PlotCircle(xx - r, yy - r, xx + r, yy + r, Fplot.cfgplot.Color[20], False);
          if mag >= (cfgsc.StarMagMax + cfgsc.AstMagDiff - cfgsc.LabelMagDiff[10]) then
          begin
            lis := cfgsc.AsteroidMark[i] + FormatFloat(f3, ra) + FormatFloat(f3, de);
            lid := rshash(lis, $7FFFFFFF);
            ltxt := cfgsc.AsteroidMark[i];
            lori := labrotation(ra, de, 10, cfgsc);
            lopt := True;
            lalign := laLeft;
            SetLabel(lid, xx, yy, round(r), 2, 10, ltxt, lalign, lori, 4, lopt);
          end;
          Result := True;
        end;
      end;
    end;
  end;
end;

function Tskychart.DrawAsteroid: boolean;
var
  x1, y1, x2, y2, ra, Dec, magn: double;
  xx, yy, lori: single;
  lopt: boolean;
  lalign: TLabelAlign;
  i, j, jj, lid: integer;
  ltxt, lis: string;
begin
  if cfgsc.ShowAsteroidValid then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw asteroids');
    try
      Fplanet.ComputeAsteroid(cfgsc);
      for j := 0 to cfgsc.SimNb - 1 do
      begin
        if ((j>0)or ((cfgsc.SimNb>1) and cfgsc.SimMark)) and (not cfgsc.SimObject[12]) then
          break;
        for i := 1 to cfgsc.AsteroidNb do
        begin
         if (cfgsc.AsteroidLst[j, i, 5]>0) then begin
          ra := cfgsc.AsteroidLst[j, i, 1];
          Dec := cfgsc.AsteroidLst[j, i, 2];
          magn := cfgsc.AsteroidLst[j, i, 3];
          projection(ra, Dec, x1, y1, True, cfgsc);
          WindowXY(x1, y1, xx, yy, cfgsc);
          if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
          begin
            if magn > (cfgsc.StarMagMax + cfgsc.AstMagDiff) then
              continue;
            if (cfgsc.SimNb=1)or (not (cfgsc.SimLine and cfgsc.SimMark)) then begin
              Fplot.PlotAsteroid(xx, yy, cfgsc.AstSymbol, magn);
            end;
            if ((doSimLabel(cfgsc.SimNb, j, cfgsc.SimLabel)) and
              (magn < cfgsc.StarMagMax + cfgsc.AstMagDiff - cfgsc.LabelMagDiff[10])) then
            begin
              lis := cfgsc.AsteroidName[j, i, 1] + FormatFloat(f3, cfgsc.AsteroidLst[j, i, 6]) + FormatFloat(f3, cfgsc.AsteroidLst[j, i, 7]);
              lid := rshash(lis, $7FFFFFFF);
              if (cfgsc.SimNb = 1) or (not cfgsc.SimObject[12]) then
              begin
                ltxt := cfgsc.AsteroidName[j, i, 2];
                lori := labrotation(ra, Dec, 10, cfgsc);
                lopt := True;
                lalign := laLeft;
              end
              else
              begin
                if cfgsc.SimNameLabel then
                  ltxt := cfgsc.AsteroidName[j, i, 2] + blank
                else
                  ltxt := '';
                if cfgsc.SimDateLabel then
                  ltxt := ltxt + jddatetime(cfgsc.AsteroidLst[j, i, 4] +
                    (cfgsc.TimeZone - cfgsc.DT_UT) / 24, cfgsc.SimDateYear, cfgsc.SimDateMonth,
                    cfgsc.SimDateDay, cfgsc.SimDateHour, cfgsc.SimDateMinute, cfgsc.SimDateSecond) + blank;
                if cfgsc.SimMagLabel then
                  ltxt := ltxt + formatfloat(f1, magn);
                if j < cfgsc.SimNb - 1 then
                  jj := j + 1
                else
                  jj := j - 1;
                projection(cfgsc.AsteroidLst[jj, i, 1], cfgsc.AsteroidLst[jj, i, 2],
                  x2, y2, True, cfgsc);
                lori := rmod(rad2deg * RotationAngle(x2, y2, x1, y1, cfgsc) + 360, 360);
                if (lori < 90) or (lori > 270) then
                begin
                  lalign := laLeft;
                end
                else
                begin
                  lalign := laRight;
                  lori := lori - 180;
                end;
                lopt := False;
              end;
              SetLabel(lid, xx, yy, 0, 2, 10, ltxt, lalign, lori, 4, lopt);
            end;
          end;
         end;
        end;
      end;
      Result := True;
    finally
    end;
  end
  else
  begin
    cfgsc.AsteroidNb := 0;
    Result := False;
  end;
end;

function Tskychart.DrawBodies: boolean;
var
  x1, y1, x2, y2, ra, Dec: double;
  xx, yy, lori: single;
  lopt: boolean;
  lalign: TLabelAlign;
  i, j, jj, lid: integer;
  ltxt, lis: string;
begin
  if cfgsc.ShowBodiesValid then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw spk bodies');
    try
      Fplanet.ComputeBodies(cfgsc);
      for j := 0 to cfgsc.SimNb - 1 do
      begin
        if ((j>0)or ((cfgsc.SimNb>1) and cfgsc.SimMark)) and (not cfgsc.SimObject[14]) then
          break;
        for i := 1 to cfgsc.BodiesNb do
        begin
         if (cfgsc.BodiesLst[j, i, 5]>0) then begin
          ra := cfgsc.BodiesLst[j, i, 1];
          Dec := cfgsc.BodiesLst[j, i, 2];
          projection(ra, Dec, x1, y1, True, cfgsc);
          WindowXY(x1, y1, xx, yy, cfgsc);
          if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
          begin
            if (cfgsc.SimNb=1)or (not (cfgsc.SimLine and cfgsc.SimMark)) then begin
              Fplot.PlotAsteroid(xx, yy, cfgsc.AstSymbol, 8);
            end;
            if doSimLabel(cfgsc.SimNb, j, cfgsc.SimLabel) then
            begin
              lis := cfgsc.BodiesName[j, i, 1] + FormatFloat(f3, cfgsc.BodiesLst[j, i, 6]) + FormatFloat(f3, cfgsc.BodiesLst[j, i, 7]);
              lid := rshash(lis, $7FFFFFFF);
              if (cfgsc.SimNb = 1) or (not cfgsc.SimObject[14]) then
              begin
                ltxt := cfgsc.BodiesName[j, i, 2];
                lori := labrotation(ra, Dec, 10, cfgsc);
                lopt := True;
                lalign := laLeft;
              end
              else
              begin
                if cfgsc.SimNameLabel then
                  ltxt := cfgsc.BodiesName[j, i, 2] + blank
                else
                  ltxt := '';
                if cfgsc.SimDateLabel then
                  ltxt := ltxt + jddatetime(cfgsc.BodiesLst[j, i, 4] +
                    (cfgsc.TimeZone - cfgsc.DT_UT) / 24, cfgsc.SimDateYear, cfgsc.SimDateMonth,
                    cfgsc.SimDateDay, cfgsc.SimDateHour, cfgsc.SimDateMinute, cfgsc.SimDateSecond) + blank;
                if j < cfgsc.SimNb - 1 then
                  jj := j + 1
                else
                  jj := j - 1;
                projection(cfgsc.BodiesLst[jj, i, 1], cfgsc.BodiesLst[jj, i, 2],
                  x2, y2, True, cfgsc);
                lori := rmod(rad2deg * RotationAngle(x2, y2, x1, y1, cfgsc) + 360, 360);
                if (lori < 90) or (lori > 270) then
                begin
                  lalign := laLeft;
                end
                else
                begin
                  lalign := laRight;
                  lori := lori - 180;
                end;
                lopt := False;
              end;
              SetLabel(lid, xx, yy, 0, 2, 10, ltxt, lalign, lori, 4, lopt);
            end;
          end;
         end;
        end;
      end;
      Result := True;
    finally
    end;
  end
  else
  begin
    cfgsc.BodiesNb := 0;
    Result := False;
  end;
end;

function Tskychart.DrawCometMark: boolean;
var
  i: integer;
  ra, de, mag, x1, y1: double;
  xx, yy, r, lori: single;
  lalign: TLabelAlign;
  lid: integer;
  lopt: boolean;
  ltxt, lis: string;
begin
  Result := False;
  if cfgsc.ShowCometValid then
  begin
    r := 5;
    if Fplot.cfgplot.UseBMP then r := DoScaleX(5);
    for i := 0 to cfgsc.CometMark.Count - 1 do
    begin
      if FPlanet.FindCometName(cfgsc.CometMark[i], ra, de, mag, cfgsc, False) then
      begin
        precession(jd2000, cfgsc.jdchart, ra, de);
        if cfgsc.ApparentPos then
        begin
          apparent_equatorial(ra, de, cfgsc, True, False);
        end;
        projection(ra, de, x1, y1, True, cfgsc);
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and
          (yy < cfgsc.Ymax) then
        begin
          Fplot.PlotCircle(xx - r, yy - r, xx + r, yy + r, Fplot.cfgplot.Color[21], False);
          if mag >= (cfgsc.StarMagMax + cfgsc.ComMagDiff - cfgsc.LabelMagDiff[11]) then
          begin
            lis := cfgsc.CometMark[i] + FormatFloat(f3, ra) + FormatFloat(f3, de);
            lid := rshash(lis, $7FFFFFFF);
            ltxt := cfgsc.CometMark[i];
            lori := labrotation(ra, de, 11, cfgsc);
            lopt := True;
            lalign := laLeft;
            SetLabel(lid, xx, yy, round(r), 2, 11, ltxt, lalign, lori, 4, lopt);
          end;
          Result := True;
        end;
      end;
    end;
  end;
end;

function Tskychart.DrawComet: boolean;
var
  x1, y1, x2, y2: double;
  xx, yy, cxx, cyy, lori: single;
  lopt: boolean;
  lalign: TLabelAlign;
  i, j, jj, lid, sz: integer;
  ltxt, lis: string;
begin
  if cfgsc.ShowCometValid then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw comets');
    try
      Fplanet.ComputeComet(cfgsc);
      for j := 0 to cfgsc.SimNb - 1 do
      begin
        if ((j>0) or ((cfgsc.SimNb>1) and cfgsc.SimMark)) and (not cfgsc.SimObject[13]) then
          break;
        for i := 1 to cfgsc.CometNb do
        begin
         if (cfgsc.CometLst[j, i, 8]>0) then begin
          projection(cfgsc.CometLst[j, i, 1], cfgsc.CometLst[j, i, 2], x1, y1, True, cfgsc);
          WindowXY(x1, y1, xx, yy, cfgsc);
          if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
          begin
            if cfgsc.CometLst[j, i, 3] > (cfgsc.StarMagMax + cfgsc.ComMagDiff) then
              continue;
            if ((doSimLabel(cfgsc.SimNb, j, cfgsc.SimLabel)) and
              ((cfgsc.SimNb > 1) or (cfgsc.CometLst[j, i, 3] < cfgsc.StarMagMax + cfgsc.ComMagDiff -
              cfgsc.LabelMagDiff[11]))) then
            begin
              lis := cfgsc.CometName[j, i, 1] + FormatFloat(f3, cfgsc.CometLst[j, i, 9]) + FormatFloat(f3, cfgsc.CometLst[j, i, 10]);
              lid := rshash(lis, $7FFFFFFF);
              sz := round(abs(cfgsc.BxGlb) * deg2rad / 60 * cfgsc.CometLst[j, i, 4] / 2);

              if (cfgsc.SimNb = 1) or (not cfgsc.SimObject[13]) then
              begin
                ltxt := cfgsc.CometName[j, i, 2];
                lori := labrotation(cfgsc.CometLst[j, i, 1], cfgsc.CometLst[j, i, 2], 11, cfgsc);
                lopt := True;
                lalign := laLeft;
              end
              else
              begin
                if cfgsc.SimNameLabel then
                  ltxt := cfgsc.CometName[j, i, 2] + blank
                else
                  ltxt := '';
                if cfgsc.SimDateLabel then
                  ltxt := ltxt + jddatetime(cfgsc.CometLst[j, i, 7] +
                    (cfgsc.TimeZone - cfgsc.DT_UT) / 24, cfgsc.SimDateYear, cfgsc.SimDateMonth,
                    cfgsc.SimDateDay, cfgsc.SimDateHour, cfgsc.SimDateMinute, cfgsc.SimDateSecond) + blank;
                if cfgsc.SimMagLabel then
                  ltxt := ltxt + formatfloat(f1, cfgsc.CometLst[j, i, 3]);
                if j < cfgsc.SimNb - 1 then
                  jj := j + 1
                else
                  jj := j - 1;
                projection(cfgsc.CometLst[jj, i, 1], cfgsc.CometLst[jj, i, 2], x2, y2, True, cfgsc);
                lori := rmod(rad2deg * RotationAngle(x2, y2, x1, y1, cfgsc) + 360, 360);
                if (lori < 90) or (lori > 270) then
                begin
                  lalign := laLeft;
                end
                else
                begin
                  lalign := laRight;
                  lori := lori - 180;
                end;
                lopt := False;
              end;
              SetLabel(lid, xx, yy, sz, 2, 11, ltxt, lalign, lori, 4, lopt);
            end;
            if projection(cfgsc.CometLst[j, i, 5], cfgsc.CometLst[j, i, 6], x1, y1, True, cfgsc) then
              WindowXY(x1, y1, cxx, cyy, cfgsc)
            else
            begin
              cxx := xx;
              cyy := yy;
            end;
            if (cfgsc.SimNb=1)or (not (cfgsc.SimLine and cfgsc.SimMark)) then begin
              Fplot.PlotComet(xx, yy, cxx, cyy, cfgsc.Comsymbol,
                 cfgsc.CometLst[j, i, 3], cfgsc.CometLst[j, i, 4], abs(cfgsc.BxGlb) * deg2rad / 60);
            end;
          end;
         end;
        end;
      end;
      Result := True;
    finally
    end;
  end
  else
  begin
    cfgsc.CometNb := 0;
    Result := False;
  end;
end;

procedure Tskychart.DrawArtSat;
var
  ar, de, ma: double;
  x1, y1: double;
  xx, yy, xp, yp: single;
  line, showlabel: boolean;
  nom, buf, mm, dat, last, lis: string;
  i, lid: integer;
  f: textfile;
const
  mois: array[1..12] of string =
    ('Jan ', 'Feb ', 'Mar ', 'Apr ', 'May ', 'June', 'July', 'Aug ', 'Sept', 'Oct ', 'Nov ', 'Dec ');
begin
  if cfgsc.ShowArtSat and Fileexists(slash(SatDir) + 'satdetail.out') then
  begin
    CloseSat;
    cfgsc.NewArtSat := False;
    Filemode := 0;
    try
      Assignfile(f, slash(SatDir) + 'satdetail.out');
      reset(f);
      Readln(f, buf);
      Readln(f, buf);
      last := '';
      xp := 0;
      yp := 0;
      repeat
        Readln(f, buf);
        if copy(buf, 1, 3) = '***' then
        begin
          mm := copy(buf, 11, 4);
          for i := 1 to 12 do
            if mm = mois[i] then
              mm := IntToStr(i);
          dat := copy(buf, 6, 4) + '-' + padzeros(mm, 2) + '-' + padzeros(copy(buf, 16, 2), 2);
          Readln(f, buf);
          Readln(f, buf);
          continue;
        end;
        if trim(buf) = '' then
          continue;
        ar := (StrToInt(copy(buf, 51, 2)) + StrToInt(copy(buf, 53, 2)) / 60) * 15 * deg2rad;
        de := strtofloat(trim(copy(buf, 55, 5))) * deg2rad;
        ma := strtofloat(trim(copy(buf, 26, 4)));
        if ma > 17.9 then
          ma := (ma - 20 + 6);
        nom := trim(copy(buf, 66, 99));
        if nom = '' then
        begin
          nom := last;
          line := True;
          showlabel := False;
        end
        else
        begin
          last := nom;
          line := False;
          showlabel := True;
        end;
        nom := nom + ' ' + dat + ' ' + padzeros(copy(buf, 1, 2), 2) + ':' + padzeros(
          copy(buf, 4, 2), 2) + ':' + padzeros(copy(buf, 7, 2), 2);
        projection(ar, de, x1, y1, True, cfgsc);
        windowxy(x1, y1, xx, yy, cfgsc);
        if (xx > -2 * cfgsc.xmax) and (yy > -2 * cfgsc.ymax) and (xx < 3 * cfgsc.xmax) and
          (yy < 3 * cfgsc.ymax) then
        begin
          if line then
          begin
            Fplot.PlotLine(xp, yp, xx, yy, clGray, 1);
          end;
          Fplot.PlotStar(xx, yy, ma, 0);
          if showlabel then
          begin
            lis := nom + FormatFloat(f6, ar) + FormatFloat(f6, de);
            lid := rshash(lis, $7FFFFFFF);
            SetLabel(lid, xx, yy, 0, 2, 1, nom, laLeft, 0, 4);
          end;
        end;
        xp := xx;
        yp := yy;
      until EOF(f);
    finally
      Closefile(f);
    end;
  end;
end;

function Tskychart.CloseSat: integer;
begin
  {$I-}
  Closefile(fsat);
  Result := ioresult;
  {$I+}
end;

function Tskychart.FindArtSat(x1, y1, x2, y2: double; nextobj: boolean;
  var nom, ma, desc: string): boolean;
var
  tar, tde, ra, de, m: double;
  sar, sde: string;
  buf, mm, last, heure, dist: string;
  i: integer;
  First: boolean;
const
  mois: array[1..12] of string =
    ('Jan ', 'Feb ', 'Mar ', 'Apr ', 'May ', 'June', 'July', 'Aug ', 'Sept', 'Oct ', 'Nov ', 'Dec ');
begin
  First := False;
  last := '';
  heure := '';
  dist := '';
  if not nextobj then
  begin
    if not Fileexists(slash(SatDir) + 'satdetail.out') then
    begin
      Result := False;
      exit;
    end;
    CloseSat;
    Assignfile(fsat, slash(SatDir) + 'satdetail.out');
    reset(fsat);
    Readln(fsat, buf);
    Readln(fsat, buf);
    First := True;
    if EOF(fsat) then
    begin
      Result := False;
      exit;
    end;
  end;
  Result := False;
  desc := '';
  tar := 1;
  tde := 1;
  repeat
    First := False;
    Readln(fsat, buf);
    if EOF(fsat) then
      break;
    if copy(buf, 1, 3) = '***' then
    begin
      mm := copy(buf, 11, 4);
      for i := 1 to 12 do
        if mm = mois[i] then
          mm := IntToStr(i);
      Readln(fsat, buf);
      Readln(fsat, buf);
      continue;
    end;
    if trim(buf) = '' then
      continue;
    if trim(copy(buf, 66, 99)) <> '' then
      last := copy(buf, 66, 14);
    tar := (StrToInt(copy(buf, 51, 2)) + StrToInt(copy(buf, 53, 2)) / 60) * 15 * deg2rad;
    tde := strtofloat(trim(copy(buf, 55, 5))) * deg2rad;
    tar := NormRA(tar);
    if (tar < x1) or (tar > x2) then
      continue;
    if (tde < y1) or (tde > y2) then
      continue;
    heure := padzeros(copy(buf, 1, 2), 2) + 'h' + padzeros(copy(buf, 4, 2), 2) +
      'm' + padzeros(copy(buf, 7, 2), 2) + 's';
    ma := copy(buf, 26, 4);
    m := strtofloat(trim(ma));
    if m > 17.9 then
    begin
      m := (m - 20 + 6);
      str(m: 4: 1, ma);
      ma := '(' + ma + ')';
    end;
    dist := copy(buf, 46, 4);
    Result := True;
  until Result;
  if Result then
  begin
    nom := trim(last) + ' ' + heure;
    ra := rmod(tar * rad2deg / 15 + 24, 24);
    de := tde * rad2deg;
    sar := ARpToStr(ra);
    sde := DEpToStr(de);
    Desc := sar + tab + sde + tab + 'Sat' + tab + nom + tab +
      'm:' + ma + tab + 'dist:' + dist + 'km ';
    cfgsc.FindOK := True;
    cfgsc.FindSize := 0;
    cfgsc.FindRA := tar;
    cfgsc.FindDec := tde;
    cfgsc.FindPM := False;
    cfgsc.FindType := ftlin;
    cfgsc.FindName := nom;
    cfgsc.FindId := nom;
    cfgsc.FindDesc := Desc;
    cfgsc.FindDesc2 := '';
    cfgsc.FindNote := '';
    cfgsc.TrackRA := cfgsc.FindRA;
    cfgsc.TrackDec := cfgsc.FindDec;
    cfgsc.TrackEpoch := cfgsc.JDChart;
    if ServerCoordSystem=csJ2000 then begin
        ra := tar;
        de := tde;
        Precession(cfgsc.JDChart,jd2000,ra,de);
        cfgsc.FindDesc2000 := ARpToStr(rmod(24+rad2deg * ra / 15,24)) + tab + DEpToStr(rad2deg * de);
    end
    else
        cfgsc.FindDesc2000 := '';
  end;
end;

function Tskychart.DrawOrbitPath: boolean;
var
  i, j, color: integer;
  x1, y1: double;
  xx, yy, xp, yp, dx, dy: single;
begin
  if cfgsc.SimNb > 1 then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw orbit path');
    case trunc(rad2deg * cfgsc.fov) of
      0..1:
      begin
        dx := 100 * cfgsc.xmax;
        dy := 100 * cfgsc.ymax;
      end;
      2..5:
      begin
        dx := 20 * cfgsc.xmax;
        dy := 20 * cfgsc.ymax;
      end;
      6..9:
      begin
        dx := 10 * cfgsc.xmax;
        dy := 10 * cfgsc.ymax;
      end;
      10..29:
      begin
        dx := 5 * cfgsc.xmax;
        dy := 5 * cfgsc.ymax;
      end;
      30..89:
      begin
        dx := 3 * cfgsc.xmax;
        dy := 3 * cfgsc.ymax;
      end;
      else
      begin
        dx := 2 * cfgsc.xmax;
        dy := 2 * cfgsc.ymax;
      end;
    end;
    dx := Min(dx, maxSmallint);
    dy := Min(dy, maxSmallint);
    Color := Fplot.cfgplot.Color[14];
    xp := 0;
    yp := 0;
    if cfgsc.ShowPlanetValid then
      for i := 1 to 11 do
        if (i <> 3) and (cfgsc.SimObject[i]) then
          for j := 0 to cfgsc.SimNb - 1 do
          begin
            projection(cfgsc.Planetlst[j, i, 1], cfgsc.Planetlst[j, i, 2], x1, y1, True, cfgsc);
            windowxy(x1, y1, xx, yy, cfgsc);
            if (j <> 0) and ((xx > -dx) and (yy > -dy) and (xx < dx) and (yy < dy)) and
              ((xp > -dx) and (yp > -dy) and (xp < dx) and (yp < dy)) then
            begin
              Fplot.PlotLine(xp, yp, xx, yy, color, 1);
              if cfgsc.SimMark then
                Fplot.PlotSimMark(xx, yy, color);
            end;
            if cfgsc.SimMark and (j = 0) then
              Fplot.PlotSimMark(xx, yy, color);
            xp := xx;
            yp := yy;
          end;
    xp := 0;
    yp := 0;
    if cfgsc.SimObject[13] then
      for i := 1 to cfgsc.CometNb do
        for j := 0 to cfgsc.SimNb - 1 do
         if cfgsc.CometLst[j, i, 8]>0 then begin
          projection(cfgsc.CometLst[j, i, 1], cfgsc.CometLst[j, i, 2], x1, y1, True, cfgsc);
          windowxy(x1, y1, xx, yy, cfgsc);
          if (j <> 0) and ((xx > -dx) and (yy > -dy) and (xx < dx) and (yy < dy)) and
            ((xp > -dx) and (yp > -dy) and (xp < dx) and (yp < dy)) then
          begin
            Fplot.PlotLine(xp, yp, xx, yy, color, 1);
            if cfgsc.SimMark then
              Fplot.PlotSimMark(xx, yy, color);
          end;
          if cfgsc.SimMark and (j = 0) then
            Fplot.PlotSimMark(xx, yy, color);
          xp := xx;
          yp := yy;
        end;
    xp := 0;
    yp := 0;
    if cfgsc.SimObject[12] then
      for i := 1 to cfgsc.AsteroidNb do
        for j := 0 to cfgsc.SimNb - 1 do
         if cfgsc.AsteroidLst[j, i, 5]>0 then begin
          projection(cfgsc.AsteroidLst[j, i, 1], cfgsc.AsteroidLst[j, i, 2], x1, y1, True, cfgsc);
          windowxy(x1, y1, xx, yy, cfgsc);
          if (j <> 0) and ((xx > -dx) and (yy > -dy) and (xx < dx) and (yy < dy)) and
            ((xp > -dx) and (yp > -dy) and (xp < dx) and (yp < dy)) then
          begin
            Fplot.PlotLine(xp, yp, xx, yy, color, 1);
            if cfgsc.SimMark then
              Fplot.PlotSimMark(xx, yy, color);
          end;
          if cfgsc.SimMark and (j = 0) then
            Fplot.PlotSimMark(xx, yy, color);
          xp := xx;
          yp := yy;
        end;
    xp := 0;
    yp := 0;
    if cfgsc.SimObject[14] then
      for i := 1 to cfgsc.BodiesNb do
        for j := 0 to cfgsc.SimNb - 1 do
         if cfgsc.BodiesLst[j, i, 5]>0 then begin
          projection(cfgsc.BodiesLst[j, i, 1], cfgsc.BodiesLst[j, i, 2], x1, y1, True, cfgsc);
          windowxy(x1, y1, xx, yy, cfgsc);
          if (j <> 0) and ((xx > -dx) and (yy > -dy) and (xx < dx) and (yy < dy)) and
            ((xp > -dx) and (yp > -dy) and (xp < dx) and (yp < dy)) then
          begin
            Fplot.PlotLine(xp, yp, xx, yy, color, 1);
            if cfgsc.SimMark then
              Fplot.PlotSimMark(xx, yy, color);
          end;
          if cfgsc.SimMark and (j = 0) then
            Fplot.PlotSimMark(xx, yy, color);
          xp := xx;
          yp := yy;
        end;
    Result := True;
  end
  else
    Result := False;
end;

procedure Tskychart.DrawPrePointLine;
var
  i, n, s, color,lid: integer;
  lis:string;
  ra, de, x1, y1, x2, y2, ltime, dx, dt, lrot: double;
  xx, yy, xp, yp: single;
begin
  if cfgsc.DrawPrePoint then begin
    color:=clAqua;
    ltime:=cfgsc.PrePointTime;
    n:=cfgsc.PrePointLength;
    ra:=cfgsc.PrePointRA;
    de:=cfgsc.PrePointDEC;
    dt:=1/60;
    dx:=deg2rad*15*dt;
    s:=round(min(n,max(1,(30*Fplot.cfgchart.drawpen/(dx*cfgsc.BxGlb)))));
    projection(ra, de, x1, y1, True, cfgsc);
    windowxy(x1, y1, xp, yp, cfgsc);
    projection(ra, de + 0.001, x2, y2, True, cfgsc);
    lrot := rmod(360+ 90 + rad2deg * RotationAngle(x1, y1, x2, y2, cfgsc),360);
    if (lrot>90)and(lrot<270) then lrot:=rmod(lrot+180,360);
    lis := 'PrePointLine' + FormatFloat(f6, ra) + FormatFloat(f6, de);
    lid := rshash(lis, $7FFFFFFF);
    SetLabel(lid, xp, yp, 5, 2, 1, ARmtoStr(ltime), laTopLeft, lrot, 1, false);
    for i:=1 to n do begin
      ra:=ra-dx;
      ltime:=ltime-dt;
      if ltime<0 then ltime:=ltime+24;
      projection(ra, de, x1, y1, True, cfgsc);
      lis := 'PrePointLine' + FormatFloat(f6, ra) + FormatFloat(f6, de);
      lid := rshash(lis, $7FFFFFFF);
      windowxy(x1, y1, xx, yy, cfgsc);
      Fplot.PlotLine(xp, yp, xx, yy, color, 1);
      if (i mod s) = 0 then begin
        Fplot.PlotSimMark(xx, yy, color);
        SetLabel(lid, xx, yy, 5, 2, 1, ARmtoStr(ltime), laTopLeft, lrot, 1, false);
      end;
      xp:=xx;
      yp:=yy;
    end;
    if (cfgsc.PrePointMarkRA<99)and(cfgsc.PrePointMarkDEC<99) then begin
      projection(cfgsc.PrePointMarkRA, cfgsc.PrePointMarkDEC, x1, y1, True, cfgsc);
      windowxy(x1, y1, xx, yy, cfgsc);
      Fplot.PlotSimMark(xx, yy, clRed);
    end;
  end;
end;

procedure Tskychart.GetCoord(x, y: integer; var ra, Dec, a, h, l, b, le, be: double);
begin
  getadxy(x, y, ra, Dec, cfgsc);
  Eq2Hz(cfgsc.CurST - ra, Dec, a, h, cfgsc);
  if Fcatalog.cfgshr.AzNorth then
    a := rmod(a + pi, pi2);
  Eq2Gal(ra, Dec, l, b, cfgsc);
  Eq2Ecl(ra, Dec, cfgsc.ecl, le, be);
  ra := rmod(ra + pi2, pi2);
  a := rmod(a + pi2, pi2);
  l := rmod(l + pi2, pi2);
  le := rmod(le + pi2, pi2);
end;

procedure Tskychart.MoveCenter(loffset, boffset: double);
begin
  case cfgsc.Projpole of
    Altaz:
    begin
      cfgsc.acentre := rmod(cfgsc.acentre + loffset + pi2, pi2);
      cfgsc.hcentre := cfgsc.hcentre + boffset;
      if cfgsc.hcentre >= pid2 then
        cfgsc.hcentre := pid2 - secarc;
      if cfgsc.hcentre <= -pid2 then
        cfgsc.hcentre := -pid2 + secarc;
      Hz2Eq(cfgsc.acentre, cfgsc.hcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
      cfgsc.racentre := cfgsc.CurST - cfgsc.racentre;
    end;
    Equat:
    begin
      cfgsc.racentre := cfgsc.racentre + loffset;
      cfgsc.decentre := cfgsc.decentre + boffset;
    end;
    Gal:
    begin
      cfgsc.lcentre := rmod(cfgsc.lcentre + loffset + pi2, pi2);
      cfgsc.bcentre := cfgsc.bcentre + boffset;
      if cfgsc.bcentre >= pid2 then
        cfgsc.bcentre := pid2 - secarc;
      if cfgsc.bcentre <= -pid2 then
        cfgsc.bcentre := -pid2 + secarc;
      Gal2Eq(cfgsc.lcentre, cfgsc.bcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
    end;
    Ecl:
    begin
      cfgsc.lecentre := rmod(cfgsc.lecentre + loffset + pi2, pi2);
      cfgsc.becentre := cfgsc.becentre + boffset;
      if cfgsc.becentre >= pid2 then
        cfgsc.becentre := pid2 - secarc;
      if cfgsc.becentre <= -pid2 then
        cfgsc.becentre := -pid2 + secarc;
      Ecl2Eq(cfgsc.lecentre, cfgsc.becentre, cfgsc.ecl, cfgsc.racentre, cfgsc.decentre);
    end;
  end;
  cfgsc.racentre := rmod(cfgsc.racentre + pi2, pi2);
  if cfgsc.decentre >= pid2 then
    cfgsc.decentre := pid2 - secarc;
  if cfgsc.decentre <= -pid2 then
    cfgsc.decentre := -pid2 + secarc;
end;

procedure Tskychart.MoveChart(ns, ew: integer; movefactor: double);
begin
  cfgsc.TrackOn := False;
  if cfgsc.Projpole = AltAz then
  begin
    cfgsc.acentre := rmod(cfgsc.acentre - ew * cfgsc.fov / movefactor / cos(
      cfgsc.hcentre) + pi2, pi2);
    cfgsc.hcentre := cfgsc.hcentre + ns * cfgsc.fov / movefactor / cfgsc.windowratio;
    if cfgsc.hcentre >= pid2 then
      cfgsc.hcentre := pi - cfgsc.hcentre;
    if cfgsc.hcentre <= -pid2 then
      cfgsc.hcentre := -pi - cfgsc.hcentre;
    Hz2Eq(cfgsc.acentre, cfgsc.hcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
    cfgsc.racentre := cfgsc.CurST - cfgsc.racentre;
  end
  else if cfgsc.Projpole = Gal then
  begin
    cfgsc.lcentre := rmod(cfgsc.lcentre + ew * cfgsc.fov / movefactor / cos(
      cfgsc.bcentre) + pi2, pi2);
    cfgsc.bcentre := cfgsc.bcentre + ns * cfgsc.fov / movefactor / cfgsc.windowratio;
    if cfgsc.bcentre >= pid2 then
      cfgsc.bcentre := pi - cfgsc.bcentre;
    if cfgsc.bcentre <= -pid2 then
      cfgsc.bcentre := -pi - cfgsc.bcentre;
    Gal2Eq(cfgsc.lcentre, cfgsc.bcentre, cfgsc.racentre, cfgsc.decentre, cfgsc);
  end
  else if cfgsc.Projpole = Ecl then
  begin
    cfgsc.lecentre := rmod(cfgsc.lecentre + ew * cfgsc.fov / movefactor / cos(
      cfgsc.becentre) + pi2, pi2);
    cfgsc.becentre := cfgsc.becentre + ns * cfgsc.fov / movefactor / cfgsc.windowratio;
    if cfgsc.becentre >= pid2 then
      cfgsc.becentre := pi - cfgsc.becentre;
    if cfgsc.becentre <= -pid2 then
      cfgsc.becentre := -pi - cfgsc.becentre;
    Ecl2Eq(cfgsc.lecentre, cfgsc.becentre, cfgsc.ecl, cfgsc.racentre, cfgsc.decentre);
  end
  else
  begin // Equ
    cfgsc.racentre := rmod(cfgsc.racentre + ew * cfgsc.fov / movefactor / cos(
      cfgsc.decentre) + pi2, pi2);
    cfgsc.decentre := cfgsc.decentre + ns * cfgsc.fov / movefactor / cfgsc.windowratio;
    if cfgsc.decentre > pid2 then
      cfgsc.decentre := pi - cfgsc.decentre;
  end;
end;

procedure Tskychart.MovetoXY(X, Y: integer);
begin
  GetADxy(X, Y, cfgsc.racentre, cfgsc.decentre, cfgsc);
  cfgsc.racentre := rmod(cfgsc.racentre + pi2, pi2);
end;

procedure Tskychart.MovetoRaDec(ra, Dec: double);
begin
  cfgsc.racentre := rmod(ra + pi2, pi2);
  cfgsc.decentre := Dec;
end;

procedure Tskychart.Zoom(zoomfactor: double);
begin
  SetFOV(cfgsc.fov / zoomfactor);
end;

procedure Tskychart.SetFOV(f: double);
begin
  cfgsc.fov := f;
  if cfgsc.fov < FovMin then
    cfgsc.fov := FovMin;
  if cfgsc.fov > FovMax then
    cfgsc.fov := FovMax;
end;

procedure Tskychart.FormatCatRec(rec: Gcatrec; var desc: string);
var
  txt, buf, c: string;
  i: integer;
  f: byte;
const
  b = ' ';
  b5 = '     ';
  b6 = '      ';
  dp = ':';
  cm = ',';
begin
  cfgsc.FindRA := rec.ra;
  cfgsc.FindDec := rec.Dec;
  cfgsc.FindPM := cfgsc.PMon and (rec.options.rectype = rtStar) and
    rec.star.valid[vsPmra] and rec.star.valid[vsPmdec];
  cfgsc.FindSize := 0;
  cfgsc.FindPX := 0;
  cfgsc.FindType := rec.options.rectype;
  cfgsc.FindCat := rec.options.ShortName;
  cfgsc.FindCatname := rec.options.LongName;
  // description must start with coordinates, type, name and magnitude to ensure this values can be found by external scripts
  // coordinates
  desc := ARpToStr(rmod(rad2deg * rec.ra / 15 + 24, 24)) + tab + DEpToStr(rad2deg * rec.Dec) + tab;
  if ServerCoordSystem=csJ2000 then begin
     cfgsc.FindDesc2000 := ARpToStr(rmod(rad2deg * cfgsc.FindRA2000 / 15 + 24, 24)) + tab + DEpToStr(rad2deg * cfgsc.FindDec2000);
  end
  else
      cfgsc.FindDesc2000 := '';
  case rec.options.rectype of
    rtStar:
    begin   // stars
      // type and name
      if rec.star.valid[vsId] then
        txt := rec.star.id
      else
        txt := '';
      if trim(txt) = '' then
        Fcatalog.GetAltName(rec, txt);
      cfgsc.FindId := txt;
      c := copy(txt, 1, 1);
      if (rec.options.ShortName <> 'Star') and (c >= '0') and (c <= '9') then
        txt := rec.options.ShortName + b + txt;
      if ((cfgsc.NameLabel) and rec.vstr[3] and
        (trim(copy(rec.options.flabel[18], 1, 8)) = trim(copy(rsCommonName, 1, 8)))) then
        cfgsc.FindName := trim(rec.str[3])
      else
        cfgsc.FindName := txt;
      Desc := Desc + '  *' + tab + txt + tab;
      // magnitude
      if rec.star.magv < 90 then
        str(rec.star.magv: 6: 3, txt)
      else
        txt := b6;
      Desc := Desc + trim(rec.options.flabel[lOffset + vsMagv]) + dp + txt + tab;
      // b-v
      if rec.star.valid[vsB_v] then
      begin
        if (rec.star.b_v < 90) then
          txt := formatfloat('0.0##', rec.star.b_v)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vsB_v]) + dp + txt + tab;
      end;
      // magnitude B
      if rec.star.valid[vsMagb] then
      begin
        if (rec.star.magb < 90) then
          str(rec.star.magb: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vsMagb]) + dp + txt + tab;
      end;
      // magnitude R
      if rec.star.valid[vsMagr] then
      begin
        if (rec.star.magr < 90) then
          str(rec.star.magr: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vsMagr]) + dp + txt + tab;
      end;
      // other magnitudes
      for i := 1 to 10 do
        if rec.vnum[i] and (uppercase(trim(copy(rec.options.flabel[lOffsetNum + i],1,1)))='M') then
        begin
          Desc := Desc + trim(rec.options.flabel[lOffsetNum + i]) + dp + formatfloat('0.0####', rec.num[i]) + tab;
        end;
      // spectral class
      if rec.star.valid[vsSp] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vsSp]) + dp + rec.star.sp + tab;
      // proper motion
      if rec.star.valid[vsPmra] then
      begin
        str(rad2deg * 3600 * 1000 * rec.star.pmra: 6: 3, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vsPmra]) + dp + txt + b + '[mas/y]' + tab;
      end;
      if rec.star.valid[vsPmdec] then
      begin
        str(rad2deg * 3600 * 1000 * rec.star.pmdec: 6: 3, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vsPmdec]) + dp + txt + b + '[mas/y]' + tab;
      end;
      if rec.star.valid[vsEpoch] then
      begin
        str(rec.star.epoch: 8: 2, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vsEpoch]) + dp + txt + tab;
      end;
      // parallax
      if rec.star.valid[vsPx] then
      begin
        if (rec.star.px>0)and(rec.star.px<0.8) then cfgsc.FindPX := rec.star.px;
        str(rec.star.px * 1000: 6: 3, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vsPx]) + dp + txt + b + '[mas]' + tab;
        if (rec.star.px>0)and(rec.star.px<0.8) then
        begin
          str(parsec2ly / rec.star.px: 5: 1, txt);
          Desc := Desc + 'Dist:' + txt + b + '[ly]' + tab;
        end;
      end;
      // alternate names
      for i := 1 to 10 do
      begin
        if rec.vstr[i] and rec.options.altname[i] and (trim(rec.str[i]) > '') then
          Desc := Desc + trim(rec.options.flabel[lOffsetStr + i]) + dp + rec.str[i] + tab;
      end;
      // comments
      if rec.star.valid[vsComment] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vsComment]) +
          dp + b + rec.star.comment + tab;
    end;
    rtVar:
    begin   // variables stars
      if rec.variable.valid[vvId] then
        txt := rec.variable.id
      else
        txt := '';
      if trim(txt) = '' then
        Fcatalog.GetAltName(rec, txt);
      cfgsc.FindId := txt;
      cfgsc.FindName := txt;
      txt := rec.options.ShortName + b + txt;
      Desc := Desc + ' V*' + tab + txt + tab;
      if rec.variable.valid[vvMagmax] then
      begin
        if (rec.variable.magmax < 90) then
          str(rec.variable.magmax: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vvMagmax]) + dp + txt + tab;
      end;
      if rec.variable.valid[vvMagmin] then
      begin
        if (rec.variable.magmin < 90) then
          str(rec.variable.magmin: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vvMagmin]) + dp + txt + tab;
      end;
      if rec.variable.valid[vvVartype] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vvVartype]) + dp + rec.variable.vartype + tab;
      if rec.variable.valid[vvMagcode] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vvMagcode]) + dp + rec.variable.magcode + tab;
      if rec.variable.valid[vvPeriod] then
      begin
        str(rec.variable.period: 16: 10, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vvPeriod]) + dp + txt + tab;
      end;
      if rec.variable.valid[vvMaxepoch] then
      begin
        str(rec.variable.Maxepoch: 16: 10, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vvMaxepoch]) + dp + txt + tab;
      end;
      if rec.variable.valid[vvRisetime] then
      begin
        str(rec.variable.risetime: 5: 2, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vvRisetime]) + dp + txt + tab;
      end;
      for i := 1 to 10 do
      begin
        if rec.vstr[i] and rec.options.altname[i] then
          Desc := Desc + trim(rec.options.flabel[lOffsetStr + i]) + dp + rec.str[i] + tab;
      end;
      if rec.variable.valid[vvSp] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vvSp]) + dp + rec.variable.sp + tab;
      if rec.variable.valid[vvComment] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vvComment]) + dp + rec.variable.comment + tab;
    end;
    rtDbl:
    begin   // doubles stars
      if rec.double.valid[vdId] then
        txt := rec.double.id
      else
        txt := '';
      if trim(txt) = '' then
        Fcatalog.GetAltName(rec, txt);
      cfgsc.FindId := txt;
      cfgsc.FindName := txt;
      txt := rec.options.ShortName + b + txt;
      Desc := Desc + ' D*' + tab + txt + tab;
      if rec.double.valid[vdMag1] then
      begin
        if (rec.double.mag1 < 90) then
          str(rec.double.mag1: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vdMag1]) + dp + txt + tab;
      end;
      if rec.double.valid[vdMag2] then
      begin
        if (rec.double.mag2 < 90) then
          str(rec.double.mag2: 6: 3, txt)
        else
          txt := b6;
        Desc := Desc + trim(rec.options.flabel[lOffset + vdMag2]) + dp + txt + tab;
      end;
      if rec.double.valid[vdCompname] then
      begin
        Desc := Desc + rec.double.compname + tab;
        cfgsc.FindName := cfgsc.FindName + blank + trim(rec.double.compname);
      end;
      if rec.double.valid[vdSep] then
      begin
        if (rec.double.sep > 0) then
          str(rec.double.sep: 5: 1, txt)
        else
          txt := b5;
        Desc := Desc + trim(rec.options.flabel[lOffset + vdSep]) + dp + txt + tab;
      end;
      if rec.double.valid[vdPa] then
      begin
        if (rec.double.pa > 0) then
          str(round(rec.double.pa - rad2deg * PoleRot2000(rec.ra, rec.Dec)): 3, txt)
        else
          txt := '   ';
        Desc := Desc + trim(rec.options.flabel[lOffset + vdPa]) + dp + txt + tab;
      end;
      if rec.double.valid[vdEpoch] then
      begin
        str(rec.double.epoch: 4: 2, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vdEpoch]) + dp + txt + tab;
      end;
      for i := 1 to 10 do
      begin
        if rec.vstr[i] and rec.options.altname[i] then
          Desc := Desc + trim(rec.options.flabel[lOffsetStr + i]) + dp + rec.str[i] + tab;
      end;
      if rec.double.valid[vdSp1] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vdSp1]) + dp + ' 1 ' + rec.double.sp1 + tab;
      if rec.double.valid[vdSp2] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vdSp2]) + dp + ' 2 ' + rec.double.sp2 + tab;
      if rec.double.valid[vdComment] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vdComment]) + dp + rec.double.comment + tab;
    end;
    rtNeb:
    begin   // nebulae
      if rec.neb.valid[vnId] then
        txt := rec.neb.id
      else
        txt := '';
      if trim(txt) = '' then
        Fcatalog.GetAltName(rec, txt);
      cfgsc.FindId := txt;
      cfgsc.FindName := txt;
      if rec.neb.valid[vnNebtype] then
        i := rec.neb.nebtype
      else
        i := rec.options.ObjType;
      // 100+ipla = planet ; 112=ast ; 113=com; 114=var; 115=star
      if i <= 18 then
        Desc := Desc + nebtype[i + 2]
      else
      begin
        case i of
          101..111: Desc := Desc + ' DSP';
          112: Desc := Desc + ' DSAs';
          113: Desc := Desc + ' DSCm';
          114: Desc := Desc + ' DSV*';
          115: Desc := Desc + ' DS*';
          else
            Desc := Desc + ' ?';
        end;
      end;
      Desc := Desc + tab + txt + tab;
      if rec.neb.valid[vnMag] and (rec.options.flabel[5] <> 'DrkMagFilter') then
      begin
        if (rec.neb.mag < 90) then
          str(rec.neb.mag: 5: 2, txt)
        else
          txt := b5;
      end
      else
        txt := b5;
      Desc := Desc + trim(rec.options.flabel[lOffset + vnMag]) + dp + txt + tab;
      for i := 1 to 10 do
      begin
        if rec.vstr[i] and rec.options.altname[i] and (trim(rec.str[i]) > '') then
          Desc := Desc + trim(rec.options.flabel[lOffsetStr + i]) + dp + rec.str[i] + tab;
      end;
      if rec.neb.valid[vnSbr] then
      begin
        if (rec.neb.sbr < 90) then
          str(rec.neb.sbr: 5: 2, txt)
        else
          txt := b5;
        Desc := Desc + trim(rec.options.flabel[lOffset + vnSbr]) + dp + txt + tab;
      end;
      if rec.options.LogSize = 0 then
      begin
        if rec.neb.valid[vnDim1] then
          cfgsc.FindSize := rec.neb.dim1
        else
          cfgsc.FindSize := rec.options.Size;
        str(cfgsc.FindSize: 5: 1, txt);
        buf := trim(rec.options.flabel[lOffset + vnDim1]);
        if buf = '' then
          buf := 'Dim';
        if buf = 'No size' then
        begin
          Desc := Desc + buf + dp;
          cfgsc.FindSize := 0;
        end
        else
        begin
          Desc := Desc + buf + dp + txt;
          if rec.neb.valid[vnDim2] and (rec.neb.dim2 > 0) then
            str(rec.neb.dim2: 5: 1, txt);
          Desc := Desc + ' x' + txt + b;
          if rec.neb.valid[vnNebunit] then
            i := rec.neb.nebunit
          else
            i := rec.options.Units;
          if i = 0 then
            i := 1;
          cfgsc.FindSize := deg2rad * cfgsc.FindSize / i;
          case i of
            1: Desc := Desc + ldeg;
            60: Desc := Desc + lmin;
            3600: Desc := Desc + lsec;
          end;
        end;
        Desc := Desc + tab;
      end
      else
      begin
        if rec.neb.valid[vnDim1] then
          str(rec.neb.dim1: 5: 1, txt)
        else
          txt := b5;
        Desc := Desc + 'Flux:' + txt + tab;
      end;
      if rec.neb.valid[vnPa] then
      begin
        if (rec.neb.pa > 0) then
          str(rec.neb.pa - rad2deg * PoleRot2000(rec.ra, rec.Dec): 3: 0, txt)
        else
          txt := '   ';
        Desc := Desc + trim(rec.options.flabel[lOffset + vnPa]) + dp + txt + tab;
      end;
      if rec.neb.valid[vnRv] then
      begin
        str(rec.neb.rv: 6: 0, txt);
        Desc := Desc + trim(rec.options.flabel[lOffset + vnRv]) + dp + txt + tab;
      end;
      if rec.neb.valid[vnMorph] then
        Desc := Desc + trim(rec.options.flabel[lOffset + vnMorph]) + dp + rec.neb.morph + tab;
      if rec.neb.valid[vnComment] and (trim(rec.neb.comment) > '') then
        Desc := Desc + trim(rec.options.flabel[lOffset + vnComment]) + dp + rec.neb.comment + tab;
    end;
  end;   // case  rec.options.rectype
  if trim(rec.options.ShortName) = 'd2k' then
  begin
    // ds2000 specific fileds
    Desc := Desc + 'desc:' + tab;
    for i := 1 to 10 do
    begin
      if rec.vstr[i] then
        Desc := Desc + rec.str[i];
    end;
    Desc := Desc + tab;
  end
  else
  begin
    // other string values without alternate names
    for i := 1 to 10 do
    begin
      if rec.vstr[i] and (not rec.options.altname[i]) and (trim(rec.str[i]) > '') then
        Desc := Desc + trim(rec.options.flabel[lOffsetStr + i]) + dp + rec.str[i] + tab;
    end;
  end;
  // other numeric values without star magnitudes
  for i := 1 to 10 do
    if rec.vnum[i] and ((rec.options.rectype<>rtStar)or(uppercase(trim(copy(rec.options.flabel[lOffsetNum + i],1,1)))<>'M')) then
    begin
      buf := trim(rec.options.flabel[lOffsetNum + i]);
      txt := formatfloat('0.0####', rec.num[i]);
      if ((cfgsc.FindCat = 'Star')or(cfgsc.FindCat = 'Gaia')) and (uppercase(buf) = 'RV') then
        txt := txt + b + '[km/s]';
      if (cfgsc.FindCat = 'Star') and (uppercase(buf) = 'GFLAG') then begin
        buf:='Gaia cross-match';
        f:=trunc(rec.num[i]);
        txt:=inttostr(f);
        if f>0 then begin
          txt:=txt+dp;
          if (f and 64)<>0 then txt:=txt+'no match, all astrometry from Hipparcos'+cm;
          if (f and 32)<>0 then txt:=txt+'no proper motion HIP 1991.25 position'+cm;
          if (f and 16)<>0 then txt:=txt+'rejected match for V error > 2'+cm;
          if (f and 8)<>0 then txt:=txt+'rejected match for position error > 5"'+cm;
          if (f and 4)<>0 then txt:=txt+'proper motion from Hipparcos'+cm;
          if (f and 2)<>0 then txt:=txt+'parallax from Hipparcos'+cm;
          if (f and 1)<>0 then txt:=txt+'radial velocity from XHIP'+cm;
          if copy(txt,Length(txt),1)=cm then txt:=copy(txt,1,Length(txt)-1);
        end
        else txt:=txt+dp+'OK, all astrometry from Gaia';
      end;
      Desc := Desc + buf + dp + txt + tab;
    end;
  cfgsc.FindName := wordspace(cfgsc.FindName);
  cfgsc.FindDesc := Desc;
  cfgsc.FindDesc2 := '';
  cfgsc.FindNote := '';
end;

procedure Tskychart.FindRiseSet(mode: integer);
var
  txt, thr, tht, ths, tazr, tazs: string;
  cjd0, ra, Dec, h, hr, ht, hs, azr, azs, j1, j2, j3, rar, der, rat, det, ras, des: double;
  hrl,hsl,al,lha: double;
  i, ii, y, m, d: integer;
begin
  lha:=-9999;
  if (cfgsc.Equinoxtype = 2) then
  begin
    // mode= 0 star, 1..11 planet
    if (mode > 0) and (cfgsc.FindSimjd <> 0) then
    begin
      Djd(cfgsc.FindSimjd + (cfgsc.TimeZone - cfgsc.DT_UT) / 24, y, m, d, h);
      cjd0 := jd(y, m, d, 0);
    end
    else
    begin
      cjd0 := cfgsc.jd0;
    end;
    // rise/set time
    if (mode > 0) and (mode <= 31) then
    begin // planet
      planet.PlanetRiseSet(mode, cjd0, catalog.cfgshr.AzNorth, thr, tht,
        ths, tazr, tazs, j1, j2, j3, rar, der, rat, det, ras, des, i, cfgsc);
    end
    else
    begin // fixed object
      ra := cfgsc.FindRA;
      Dec := cfgsc.FindDec;
      rar:=ra;
      der:=dec;
      ras:=ra;
      des:=dec;
      RiseSet(cjd0, ra, Dec, hr, ht, hs, azr, azs, i, cfgsc);
      thr := artostr3(rmod(hr + 24, 24));
      tht := artostr3(rmod(ht + 24, 24));
      ths := artostr3(rmod(hs + 24, 24));
      if catalog.cfgshr.AzNorth then
        Azr := rmod(Azr + pi, pi2);
      if catalog.cfgshr.AzNorth then
        Azs := rmod(Azs + pi, pi2);
      tazr := LONmToStr(rad2deg * Azr);
      tazs := LONmToStr(rad2deg * Azs);
      lha:=rmod(cfgsc.CurST-ra+pi2,pi2);
      if lha>pi then lha:=lha-pi2;
    end;
    if cfgsc.HorizonRise and (cfgsc.HorizonMax > musec) then begin
      if ObjRise(rar,der,cfgsc,hrl,al,ii) then begin
         thr := artostr3(rmod(hrl + 24, 24));
         tazr:=LONmToStr(rad2deg * al);
         i:=ii;
      end;
      if ObjSet(ras,des,cfgsc,hsl,al,ii) then begin
         ths := artostr3(rmod(hsl + 24, 24));
         tazs:=LONmToStr(rad2deg * al);
         i:=ii;
      end;
    end;

    txt := '';
    if trim(thr) = '' then
      thr := 'N/A';
    if trim(tht) = '' then
      tht := 'N/A';
    if trim(ths) = '' then
      ths := 'N/A';
    case i of
      0:
      begin
        txt := txt + rsRise + ':' +  thr + blank + rsAz + ':' + tazr + blank + blank;
        txt := txt + rsCulmination + ':' + blank + tht + blank + blank;
        txt := txt + rsSet + ':' + blank + ths + blank + rsAz + ':' + tazs + blank;
      end;
      1:
      begin
        txt := txt + rsCircumpolar + blank + blank + blank;
        txt := txt + rsCulmination +':' + blank + tht + blank;
      end;
      else
      begin
        txt := txt + rsInvisibleAtT + blank;
      end;
    end;
    if lha>-99 then txt:=txt + blank + rsLHA + ':'+ blank + armtostr(rad2deg * lha / 15);
    cfgsc.FindDesc2 := txt;
  end
  else
  begin
    cfgsc.FindDesc2 := ' ';
  end;
end;

function Tskychart.FindatRaDec(ra, Dec, dx: double; searchcenter: boolean;
  showall: boolean = False; ftype: integer = ftAll; planetcenter: boolean = False): boolean;
var
  x1, x2, y1, y2: double;
  rec: Gcatrec;
  desc, n, m, d: string;
  saveStarFilter, saveNebFilter: boolean;
begin
  x1 := NormRA(ra - dx / cos(Dec));
  x2 := NormRA(ra + dx / cos(Dec));
  if x2 < x1 then
    x2 := x2 + pi2;
  y1 := max(-pid2, Dec - dx);
  y2 := min(pid2, Dec + dx);
  desc := '';
  cfgsc.FindSimjd := 0;
  cfgsc.FindDesc2 := '';
  cfgsc.FindDesc2000 := '';
  cfgsc.FindDesc := '';
  Fcatalog.OpenCat(cfgsc);
  InitCatalog(cfgsc.fov);
  saveNebFilter := Fcatalog.cfgshr.NebFilter;
  saveStarFilter := Fcatalog.cfgshr.StarFilter;
  if showall then
  begin
    Fcatalog.cfgshr.NebFilter := False;
    Fcatalog.cfgshr.StarFilter := False;
  end;
  Result := False;
  // search catalog object
  try
    if (ftype = ftAll) or (ftype < ftCat) then
      Result := fcatalog.Findobj(x1, y1, x2, y2, searchcenter, cfgsc, rec, ftype);
  finally
    Fcatalog.CloseCat;
    if showall then
    begin
      Fcatalog.cfgshr.NebFilter := saveNebFilter;
      Fcatalog.cfgshr.StarFilter := saveStarFilter;
    end;
  end;
  if Result then
  begin
    FormatCatRec(rec, desc);
    FindRiseSet(0);
    cfgsc.TrackType := TTequat;
    cfgsc.TrackName := cfgsc.FindName;
    cfgsc.TrackRA := rec.ra;
    cfgsc.TrackDec := rec.Dec;
    cfgsc.TrackEpoch := cfgsc.JDChart;
  end
  else
  begin
    cfgsc.FindRA2000 := 0;
    cfgsc.FindDec2000 := 0;
    cfgsc.FindCat := '';
    cfgsc.FindCatname := '';
    // search solar system object
    if cfgsc.ShowPlanetValid and ((ftype = ftAll) or (ftype = ftPla)) then
      Result := fplanet.findplanet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, true, planetcenter);
    if Result then
    begin
      if cfgsc.SimNb > 1 then
        cfgsc.FindName := cfgsc.FindName + blank + d;
      // add date to the name if simulation for more than one date
      FindRiseSet(cfgsc.FindIpla);
    end
    else
    begin
      if cfgsc.ShowBodiesValid and ((ftype = ftAll) or (ftype = ftBody)) then
        Result := fplanet.FindBody(x1, y1, x2, y2, False, cfgsc, n, m, d, desc);
      if Result then
      begin
        if cfgsc.SimNb > 1 then
          cfgsc.FindName := cfgsc.FindName + blank + d;
        FindRiseSet(0);
      end
      else
      begin
      if cfgsc.ShowAsteroidValid and ((ftype = ftAll) or (ftype = ftAst)) then
        Result := fplanet.findasteroid(x1, y1, x2, y2, False, cfgsc, n, m, d, desc);
      if Result then
      begin
        if cfgsc.SimNb > 1 then
          cfgsc.FindName := cfgsc.FindName + blank + d;
        FindRiseSet(0);
      end
      else
      begin
        if cfgsc.ShowCometValid and ((ftype = ftAll) or (ftype = ftCom)) then
          Result := fplanet.findcomet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc);
        if Result then
        begin
          if cfgsc.SimNb > 1 then
            cfgsc.FindName := cfgsc.FindName + blank + d;
          FindRiseSet(0);
        end
        else
        begin
          // search artificial satellite
          if cfgsc.ShowArtSat and (ftype = ftAll) then
          begin
            Result := FindArtSat(x1, y1, x2, y2, False, n, m, desc);
            CloseSat;
          end;
        end;
      end;
      end;
    end;
  end;
end;

procedure Tskychart.FindList(ra, Dec, dx, dy: double; var Text, msg: string; showall, allobject, trunc, usefov: boolean; maxln:integer=1000);
var
  x1, x2, y1, y2, xx1, yy1: double;
  rec: Gcatrec;
  desc, n, m, d: string;
  saveStarFilter, saveNebFilter, ok: boolean;
  i: integer;
  xx, yy: single;

  procedure FindatPosCat(cat: integer);
  begin
    ok := fcatalog.FindatPos(cat, x1, y1, x2, y2, False, trunc, True, cfgsc, rec);
    while ok do
    begin
      if i > maxln then
        break;
      FormatCatRec(rec, desc);
      Text := Text + cfgsc.FindCat + tab + desc + crlf;
      Inc(i);
      ok := fcatalog.FindatPos(cat, x1, y1, x2, y2, True, trunc, True, cfgsc, rec);
    end;
    fcatalog.CloseCat;
  end;

  procedure FindatPosPlanet;
  begin
    ok := fplanet.findplanet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, trunc);
    while ok do
    begin
      if i > maxln then
        break;
      Text := Text + fplanet.eph_method + tab + desc + crlf;
      Inc(i);
      ok := fplanet.findplanet(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, trunc);
    end;
  end;

  procedure FindatPosAsteroid;
  begin
    ok := fplanet.findasteroid(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, trunc);
    while ok do
    begin
      if i > maxln then
        break;
      Text := Text + 'MPC' + tab + desc + crlf;
      Inc(i);
      ok := fplanet.findasteroid(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, trunc);
    end;
  end;

  procedure FindatPosComet;
  begin
    ok := fplanet.findcomet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, trunc);
    while ok do
    begin
      if i > maxln then
        break;
      Text := Text + 'MPC' + tab + desc + crlf;
      Inc(i);
      ok := fplanet.findcomet(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, trunc);
    end;
  end;

  procedure FindatPosBodies;
  begin
    ok := fplanet.FindBody(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, trunc);
    while ok do
    begin
      if i > maxln then
        break;
      Text := Text + 'SPK' + tab + desc + crlf;
      Inc(i);
      ok := fplanet.FindBody(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, trunc);
    end;
  end;

  /////////////
begin
  if ((abs(Dec) + abs(dx)) > pid2) or ((abs(Dec) + abs(dy)) > pid2) then
  begin
    x1 := 0;
    x2 := pi2;
  end
  else
  begin
    x1 := NormRA(ra - dx / cos(Dec));
    x2 := NormRA(ra + dx / cos(Dec));
    if x2 < x1 then
      x2 := x2 + pi2;
  end;
  y1 := max(-pid2, Dec - dy);
  y2 := min(pid2, Dec + dy);
  Text := '';
  Fcatalog.OpenCat(cfgsc);
  if usefov then
    InitCatalog(dx)
  else
    InitCatalog(cfgsc.fov);
  saveNebFilter := Fcatalog.cfgshr.NebFilter;
  saveStarFilter := Fcatalog.cfgshr.StarFilter;
  if showall then
  begin
    Fcatalog.cfgshr.NebFilter := False;
    Fcatalog.cfgshr.StarFilter := False;
  end;
  // search catalog object
  try
    i := 0;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosPlanet;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosComet;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosAsteroid;
    if (allobject or Fcatalog.cfgshr.ListPla)and cfgsc.ShowBodiesValid then
      FindatPosBodies;
    if allobject or Fcatalog.cfgshr.ListNeb then
    begin
      FindAtPosCat(gcneb);
      if Fcatalog.cfgcat.nebcaton[uneb - BaseNeb] then
        FindAtPosCat(uneb);
      if Fcatalog.cfgcat.nebcaton[voneb - BaseNeb] then
        FindAtPosCat(voneb);
      if Fcatalog.cfgcat.nebcaton[sac - BaseNeb] then
        FindAtPosCat(sac);
      if Fcatalog.cfgcat.nebcaton[ngc - BaseNeb] then
        FindAtPosCat(ngc);
      if Fcatalog.cfgcat.nebcaton[lbn - BaseNeb] then
        FindAtPosCat(lbn);
      if Fcatalog.cfgcat.nebcaton[sh2 - BaseNeb] then
        FindAtPosCat(sh2);
      if Fcatalog.cfgcat.nebcaton[drk - BaseNeb] then
        FindAtPosCat(drk);
      if Fcatalog.cfgcat.nebcaton[rc3 - BaseNeb] then
        FindAtPosCat(rc3);
      if Fcatalog.cfgcat.nebcaton[pgc - BaseNeb] then
        FindAtPosCat(pgc);
      if Fcatalog.cfgcat.nebcaton[ocl - BaseNeb] then
        FindAtPosCat(ocl);
      if Fcatalog.cfgcat.nebcaton[gcm - BaseNeb] then
        FindAtPosCat(gcm);
      if Fcatalog.cfgcat.nebcaton[gpn - BaseNeb] then
        FindAtPosCat(gpn);
    end;
    if allobject or Fcatalog.cfgshr.ListVar then
    begin
      FindAtPosCat(gcvar);
      if Fcatalog.cfgcat.varstarcaton[gcvs - BaseVar] then
        FindAtPosCat(gcvs);
    end;
    if allobject or Fcatalog.cfgshr.ListDbl then
    begin
      FindAtPosCat(gcdbl);
      if Fcatalog.cfgcat.dblstarcaton[wds - BaseDbl] then
        FindAtPosCat(wds);
    end;
    if allobject or Fcatalog.cfgshr.ListStar then
    begin
      FindAtPosCat(gcstar);
      if Fcatalog.cfgcat.starcaton[vostar - BaseStar] then
        FindAtPosCat(vostar);
      if Fcatalog.cfgcat.starcaton[DefStar - BaseStar] then
        FindAtPosCat(DefStar);
      if Fcatalog.cfgcat.starcaton[bsc - BaseStar] then
        FindAtPosCat(bsc);
      if Fcatalog.cfgcat.starcaton[dsbase - BaseStar] then
        FindAtPosCat(dsbase);
      if Fcatalog.cfgcat.starcaton[sky2000 - BaseStar] then
        FindAtPosCat(sky2000);
      if Fcatalog.cfgcat.starcaton[tyc - BaseStar] then
        FindAtPosCat(tyc);
      if Fcatalog.cfgcat.starcaton[tyc2 - BaseStar] then
        FindAtPosCat(tyc2);
      if Fcatalog.cfgcat.starcaton[tic - BaseStar] then
        FindAtPosCat(tic);
      if Fcatalog.cfgcat.starcaton[dstyc - BaseStar] then
        FindAtPosCat(dstyc);
      if Fcatalog.cfgcat.starcaton[gsc - BaseStar] then
        FindAtPosCat(gsc);
      if Fcatalog.cfgcat.starcaton[gscf - BaseStar] then
        FindAtPosCat(gscf);
      if Fcatalog.cfgcat.starcaton[gscc - BaseStar] then
        FindAtPosCat(gscc);
      if Fcatalog.cfgcat.starcaton[dsgsc - BaseStar] then
        FindAtPosCat(dsgsc);
      if Fcatalog.cfgcat.starcaton[usnoa - BaseStar] then
        FindAtPosCat(usnoa);
      if Fcatalog.cfgcat.starcaton[usnob - BaseStar] then
        FindAtPosCat(usnob);
      if Fcatalog.cfgcat.starcaton[hn290 - BaseStar] then
        FindAtPosCat(hn290);
      if Fcatalog.cfgcat.starcaton[gaia - BaseStar] then
        FindAtPosCat(gaia);
      if Fcatalog.cfgcat.starcaton[microcat - BaseStar] then
        FindAtPosCat(microcat);
    end;
    if i > maxln then
      msg := Format(rsMoreThanObje, [IntToStr(maxln)])
    else
      msg := Format(rsThereAreObjec, [IntToStr(i)]);
  finally
    Fcatalog.CloseCat;
    if showall then
    begin
      Fcatalog.cfgshr.NebFilter := saveNebFilter;
      Fcatalog.cfgshr.StarFilter := saveStarFilter;
    end;
  end;
end;

procedure Tskychart.FindListWin(var Text, msg: string; showall, allobject: boolean);
var
  x1, x2, y1, y2, xx1, yy1: double;
  ra, Dec, dx, dy: double;
  rec: Gcatrec;
  desc, n, m, d: string;
  saveStarFilter, saveNebFilter, ok: boolean;
  i: integer;
  xx, yy: single;
const
  maxln: integer = 10000;

  procedure FindatPosCat(cat: integer);
  begin
    ok := fcatalog.FindInWin(cat, False, cfgsc, rec);
    while ok do
    begin
      if i > maxln then
        break;
      projection(rec.ra, rec.Dec, xx1, yy1, True, cfgsc);
      windowxy(xx1, yy1, xx, yy, cfgsc);
      if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
      begin
        FormatCatRec(rec, desc);
        Text := Text + cfgsc.FindCat + tab + desc + crlf;
        Inc(i);
      end;
      ok := fcatalog.FindInWin(cat, True, cfgsc, rec);
    end;
    fcatalog.CloseCat;
  end;

  procedure FindatPosPlanet;
  var eph: string;
  begin
    ok := fplanet.findplanet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, false);
    while ok do
    begin
      if i > maxln then
        break;
      projection(cfgsc.findra, cfgsc.finddec, xx1, yy1, True, cfgsc);
      windowxy(xx1, yy1, xx, yy, cfgsc);
      if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
      begin
        if cfgsc.FindIpla <= 11 then
           eph := fplanet.eph_method
        else begin
           if cfgsc.SpiceActive or cfgsc.CalcephActive then
              eph := 'SPICE'
           else
              eph := '';
        end;
        Text := Text + eph + tab + desc + crlf;
        Inc(i);
      end;
      ok := fplanet.findplanet(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, false);
    end;
  end;

  procedure FindatPosAsteroid;
  begin
    ok := fplanet.findasteroid(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, false);
    while ok do
    begin
      if i > maxln then
        break;
      projection(cfgsc.findra, cfgsc.finddec, xx1, yy1, True, cfgsc);
      windowxy(xx1, yy1, xx, yy, cfgsc);
      if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
      begin
        Text := Text + 'MPC' + tab + desc + crlf;
        Inc(i);
      end;
      ok := fplanet.findasteroid(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, false);
    end;
  end;

  procedure FindatPosComet;
  begin
    ok := fplanet.findcomet(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, false);
    while ok do
    begin
      if i > maxln then
        break;
      projection(cfgsc.findra, cfgsc.finddec, xx1, yy1, True, cfgsc);
      windowxy(xx1, yy1, xx, yy, cfgsc);
      if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
      begin
        Text := Text + 'MPC' + tab + desc + crlf;
        Inc(i);
      end;
      ok := fplanet.findcomet(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, false);
    end;
  end;

  procedure FindatPosBodies;
  begin
    ok := fplanet.FindBody(x1, y1, x2, y2, False, cfgsc, n, m, d, desc, false);
    while ok do
    begin
      if i > maxln then
        break;
      projection(cfgsc.findra, cfgsc.finddec, xx1, yy1, True, cfgsc);
      windowxy(xx1, yy1, xx, yy, cfgsc);
      if (xx > cfgsc.Xmin) and (xx < cfgsc.Xmax) and (yy > cfgsc.Ymin) and (yy < cfgsc.Ymax) then
      begin
        Text := Text + 'SPK' + tab + desc + crlf;
        Inc(i);
      end;
      ok := fplanet.FindBody(x1, y1, x2, y2, True, cfgsc, n, m, d, desc, false);
    end;
  end;


  /////////////
begin
  if cfgsc.windowratio = 0 then
     cfgsc.windowratio := 1;
  ra :=  cfgsc.racentre;
  Dec:=  cfgsc.decentre;
  dx :=  cfgsc.fov / 2;
  dy :=  cfgsc.fov / 2 / cfgsc.windowratio;
  if ((abs(Dec) + abs(dx)) > pid2) or ((abs(Dec) + abs(dy)) > pid2) then
  begin
    x1 := 0;
    x2 := pi2;
  end
  else
  begin
    x1 := NormRA(ra - dx / cos(Dec));
    x2 := NormRA(ra + dx / cos(Dec));
    if x2 < x1 then
      x2 := x2 + pi2;
  end;
  y1 := max(-pid2, Dec - dy);
  y2 := min(pid2, Dec + dy);
  Text := '';
  Fcatalog.OpenCat(cfgsc);
  InitCatalog(cfgsc.fov);
  saveNebFilter := Fcatalog.cfgshr.NebFilter;
  saveStarFilter := Fcatalog.cfgshr.StarFilter;
  if showall then
  begin
    Fcatalog.cfgshr.NebFilter := False;
    Fcatalog.cfgshr.StarFilter := False;
  end;
  // search catalog object
  try
    i := 0;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosPlanet;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosComet;
    if allobject or Fcatalog.cfgshr.ListPla then
      FindatPosAsteroid;
    if (allobject or Fcatalog.cfgshr.ListPla)and cfgsc.ShowBodiesValid then
      FindatPosBodies;
    if allobject or Fcatalog.cfgshr.ListNeb then
    begin
      FindAtPosCat(gcneb);
      if Fcatalog.cfgcat.nebcaton[uneb - BaseNeb] then
        FindAtPosCat(uneb);
      if Fcatalog.cfgcat.nebcaton[voneb - BaseNeb] then
        FindAtPosCat(voneb);
      if Fcatalog.cfgcat.nebcaton[sac - BaseNeb] then
        FindAtPosCat(sac);
      if Fcatalog.cfgcat.nebcaton[ngc - BaseNeb] then
        FindAtPosCat(ngc);
      if Fcatalog.cfgcat.nebcaton[lbn - BaseNeb] then
        FindAtPosCat(lbn);
      if Fcatalog.cfgcat.nebcaton[sh2 - BaseNeb] then
        FindAtPosCat(sh2);
      if Fcatalog.cfgcat.nebcaton[drk - BaseNeb] then
        FindAtPosCat(drk);
      if Fcatalog.cfgcat.nebcaton[rc3 - BaseNeb] then
        FindAtPosCat(rc3);
      if Fcatalog.cfgcat.nebcaton[pgc - BaseNeb] then
        FindAtPosCat(pgc);
      if Fcatalog.cfgcat.nebcaton[ocl - BaseNeb] then
        FindAtPosCat(ocl);
      if Fcatalog.cfgcat.nebcaton[gcm - BaseNeb] then
        FindAtPosCat(gcm);
      if Fcatalog.cfgcat.nebcaton[gpn - BaseNeb] then
        FindAtPosCat(gpn);
    end;
    if allobject or Fcatalog.cfgshr.ListVar then
    begin
      FindAtPosCat(gcvar);
      if Fcatalog.cfgcat.varstarcaton[gcvs - BaseVar] then
        FindAtPosCat(gcvs);
    end;
    if allobject or Fcatalog.cfgshr.ListDbl then
    begin
      FindAtPosCat(gcdbl);
      if Fcatalog.cfgcat.dblstarcaton[wds - BaseDbl] then
        FindAtPosCat(wds);
    end;
    if allobject or Fcatalog.cfgshr.ListStar then
    begin
      FindAtPosCat(gcstar);
      if Fcatalog.cfgcat.starcaton[vostar - BaseStar] then
        FindAtPosCat(vostar);
      if Fcatalog.cfgcat.starcaton[DefStar - BaseStar] then
        FindAtPosCat(DefStar);
      if Fcatalog.cfgcat.starcaton[bsc - BaseStar] then
        FindAtPosCat(bsc);
      if Fcatalog.cfgcat.starcaton[dsbase - BaseStar] then
        FindAtPosCat(dsbase);
      if Fcatalog.cfgcat.starcaton[sky2000 - BaseStar] then
        FindAtPosCat(sky2000);
      if Fcatalog.cfgcat.starcaton[tyc - BaseStar] then
        FindAtPosCat(tyc);
      if Fcatalog.cfgcat.starcaton[tyc2 - BaseStar] then
        FindAtPosCat(tyc2);
      if Fcatalog.cfgcat.starcaton[tic - BaseStar] then
        FindAtPosCat(tic);
      if Fcatalog.cfgcat.starcaton[dstyc - BaseStar] then
        FindAtPosCat(dstyc);
      if Fcatalog.cfgcat.starcaton[gsc - BaseStar] then
        FindAtPosCat(gsc);
      if Fcatalog.cfgcat.starcaton[gscf - BaseStar] then
        FindAtPosCat(gscf);
      if Fcatalog.cfgcat.starcaton[gscc - BaseStar] then
        FindAtPosCat(gscc);
      if Fcatalog.cfgcat.starcaton[dsgsc - BaseStar] then
        FindAtPosCat(dsgsc);
      if Fcatalog.cfgcat.starcaton[usnoa - BaseStar] then
        FindAtPosCat(usnoa);
      if Fcatalog.cfgcat.starcaton[usnob - BaseStar] then
        FindAtPosCat(usnob);
      if Fcatalog.cfgcat.starcaton[hn290 - BaseStar] then
        FindAtPosCat(hn290);
      if Fcatalog.cfgcat.starcaton[gaia - BaseStar] then
        FindAtPosCat(gaia);
      if Fcatalog.cfgcat.starcaton[microcat - BaseStar] then
        FindAtPosCat(microcat);
    end;
    if i > maxln then
      msg := Format(rsMoreThanObje, [IntToStr(maxln)])
    else
      msg := Format(rsThereAreObjec, [IntToStr(i)]);
  finally
    Fcatalog.CloseCat;
    if showall then
    begin
      Fcatalog.cfgshr.NebFilter := saveNebFilter;
      Fcatalog.cfgshr.StarFilter := saveStarFilter;
    end;
  end;
end;

procedure Tskychart.DrawGrid(drawlabel: boolean);
begin
  if (cfgsc.ShowOnlyMeridian) or
    ((deg2rad * Fcatalog.cfgshr.DegreeGridSpacing[cfgsc.FieldNum]) <= (cfgsc.fov / 2)) then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw grid');
    if cfgsc.ShowGrid then
    begin
      case cfgsc.ProjPole of
        Equat: DrawEqGrid(drawlabel);
        AltAz:
        begin
          DrawAzGrid(drawlabel);
          if ((not Fplot.cfgplot.UseBMP) or (not cfgsc.horizonopaque)) and
            cfgsc.ShowEqGrid and (not drawlabel) then
            DrawEqGrid(drawlabel, True);
        end;
        Gal:
        begin
          DrawGalGrid(drawlabel);
          if cfgsc.ShowEqGrid and (not drawlabel) then
            DrawEqGrid(drawlabel, True);
        end;
        Ecl:
        begin
          DrawEclGrid(drawlabel);
          if cfgsc.ShowEqGrid and (not drawlabel) then
            DrawEqGrid(drawlabel, True);
        end;
      end;
      if cfgsc.ShowAlwaysMeridian and (cfgsc.ProjPole <> Altaz) then
      begin
        DrawMeridian;
      end;
    end
    else if cfgsc.ShowEqGrid and (((not Fplot.cfgplot.UseBMP) or (not cfgsc.horizonopaque)) or
      (cfgsc.ProjPole <> AltAz)) then
    begin
      DrawEqGrid(drawlabel, True);
    end;
  end;
end;

procedure Tskychart.DrawAltAzEqGrid;
begin
  if ((deg2rad * Fcatalog.cfgshr.DegreeGridSpacing[cfgsc.FieldNum]) <= (cfgsc.fov / 2)) then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw alt/az EQ grid');
    if Fplot.cfgplot.UseBMP and cfgsc.horizonopaque and (cfgsc.ProjPole = AltAz) and
      cfgsc.ShowEqGrid then
      DrawEqGrid(False, True);
  end;
end;

procedure Tskychart.DrawPole(pole: integer);
var
  a, d, x1, y1: double;
  xx, yy: single;
begin
  {mark north pole}
  a := 0;
  d := pid2;
  case pole of
    Equat: projection(a, d, x1, y1, cfgsc.horizonopaque, cfgsc);
    Altaz: proj2(a, d, cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
    Gal: proj2(a, d, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
    Ecl: proj2(a, d, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
  end;
  WindowXY(x1, y1, xx, yy, cfgsc);
  if (abs(xx) < 10000) and (abs(yy) < 10000) then
  begin
    Fplot.Plotline(xx - 5 * Fplot.cfgchart.drawsize, yy, xx + 5 * Fplot.cfgchart.drawsize,
      yy, Fplot.cfgplot.Color[13], cfgsc.LineWidthGrid, cfgsc.StyleGrid);
    Fplot.Plotline(xx, yy - 5 * Fplot.cfgchart.drawsize, xx, yy + 5 * Fplot.cfgchart.drawsize,
      Fplot.cfgplot.Color[13], cfgsc.LineWidthGrid, cfgsc.StyleGrid);
  end;
  {mark south pole}
  a := 0;
  d := -pid2;
  case pole of
    Equat: projection(a, d, x1, y1, cfgsc.horizonopaque, cfgsc);
    Altaz: proj2(a, d, cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
    Gal: proj2(a, d, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
    Ecl: proj2(a, d, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
  end;
  WindowXY(x1, y1, xx, yy, cfgsc);
  if (abs(xx) < 10000) and (abs(yy) < 10000) then
  begin
    Fplot.Plotline(xx - 5 * Fplot.cfgchart.drawsize, yy, xx + 5 * Fplot.cfgchart.drawsize,
      yy, Fplot.cfgplot.Color[13], cfgsc.LineWidthGrid, cfgsc.StyleGrid);
    Fplot.Plotline(xx, yy - 5 * Fplot.cfgchart.drawsize, xx, yy + 5 * Fplot.cfgchart.drawsize,
      Fplot.cfgplot.Color[13], cfgsc.LineWidthGrid, cfgsc.StyleGrid);
  end;
end;

procedure Tskychart.DrawScale;
var
  fv, u: double;
  i, n, s, x, y, xp: integer;
  l1, l2: string;
const
  sticksize = 10;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw scale line');
  DrawPole(cfgsc.ProjPole);
  fv := rad2deg * cfgsc.fov / 3;
  if trunc(fv) > 20 then
  begin
    l1 := '5' + ldeg;
    n := trunc(fv / 5);
    l2 := IntToStr(n * 5) + ldeg;
    s := 5;
    u := deg2rad;
  end
  else if trunc(fv) > 5 then
  begin
    l1 := '1' + ldeg;
    n := trunc(fv);
    l2 := IntToStr(n) + ldeg;
    s := 1;
    u := deg2rad;
  end
  else if trunc(fv) > 0 then
  begin
    l1 := '30' + lmin;
    n := trunc(fv) * 2;
    l2 := IntToStr(n * 30) + lmin;
    s := 30;
    u := deg2rad / 60;
  end
  else if trunc(6 * fv / 2) > 0 then
  begin
    l1 := '10' + lmin;
    n := trunc(6 * fv);
    l2 := IntToStr(n * 10) + lmin;
    s := 10;
    u := deg2rad / 60;
  end
  else if trunc(30 * fv / 2) > 0 then
  begin
    l1 := '2' + lmin;
    n := trunc(30 * fv);
    l2 := IntToStr(n * 2) + lmin;
    s := 2;
    u := deg2rad / 60;
  end
  else if trunc(60 * fv / 2) > 0 then
  begin
    l1 := '1' + lmin;
    n := trunc(60 * fv);
    l2 := IntToStr(n) + lmin;
    s := 1;
    u := deg2rad / 60;
  end
  else if trunc(360 * fv / 2) > 0 then
  begin
    l1 := '10' + lsec;
    n := trunc(360 * fv);
    l2 := IntToStr(n * 10) + lsec;
    s := 10;
    u := deg2rad / 3600;
  end
  else if trunc(1800 * fv / 2) > 0 then
  begin
    l1 := '2' + lsec;
    n := trunc(1800 * fv);
    l2 := IntToStr(n * 2) + lsec;
    s := 2;
    u := deg2rad / 3600;
  end
  else if trunc(7200 * fv / 2) > 0 then
  begin
    l1 := '1' + lsec;
    n := trunc(3600 * fv);
    l2 := IntToStr(n) + lsec;
    s := 1;
    u := deg2rad / 3600;
  end
  else
  begin
    l1 := '0.5' + lsec;
    n := trunc(7200 * fv);
    l2 := IntToStr(n) + lsec;
    s := 1;
    u := deg2rad / 7200;
  end;
  if n < 1 then
    n := 1;
  xp := cfgsc.xmin + 10 + Fcatalog.cfgshr.CRoseSz * fplot.cfgchart.drawsize + sticksize;
  y := cfgsc.ymax - sticksize;
  FPlot.PlotLine(xp, y, xp, y - sticksize, Fplot.cfgplot.Color[12], 1);
  FPlot.PlotText(xp, y - sticksize, 1, Fplot.cfgplot.LabelColor[7], laCenter,
    laBottom, '0', cfgsc.WhiteBg);
  for i := 1 to n do
  begin
    x := xp + round(s * u * cfgsc.bxglb);
    FPlot.PlotLine(xp, y, x, y, Fplot.cfgplot.Color[12], 1);
    FPlot.PlotLine(x, y, x, y - sticksize, Fplot.cfgplot.Color[12], 1);
    if i = 1 then
      FPlot.PlotText(x, y - sticksize, 1, Fplot.cfgplot.LabelColor[7], laCenter,
        laBottom, l1, cfgsc.WhiteBg);
    xp := x;
  end;
  if n > 1 then
    FPlot.PlotText(xp, y - sticksize, 1, Fplot.cfgplot.LabelColor[7], laCenter,
      laBottom, l2, cfgsc.WhiteBg);
end;

procedure Tskychart.DrawBorder;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw chart border');
  Fplot.PlotBorder(cfgsc.LeftMargin, cfgsc.RightMargin, cfgsc.TopMargin,
    cfgsc.BottomMargin, cfgsc.HeaderHeight, cfgsc.FooterHeight, cfgsc.WhiteBg);
end;

function Tskychart.CenterRot: double;
var
  x1, y1, x2, y2: double;
  a, d, ar, de: double;
begin
  case cfgsc.ProjPole of
    Equat:
    begin
      projection(cfgsc.racentre, cfgsc.decentre, x1, y1, False, cfgsc);
      projection(cfgsc.racentre, cfgsc.decentre + 0.001, x2, y2, False, cfgsc);
      Result := -arctan2((x2 - x1), (y2 - y1));
    end;
    Altaz:
    begin
      projection(cfgsc.racentre, cfgsc.decentre, x1, y1, False, cfgsc);
      Eq2Hz(cfgsc.CurST - cfgsc.racentre, cfgsc.decentre, a, d, cfgsc);
      Hz2Eq(a, d + 0.001, ar, de, cfgsc);
      projection(cfgsc.CurST - ar, de, x2, y2, False, cfgsc);
      Result := -arctan2((x2 - x1), (y2 - y1));
    end;
    Gal:
    begin
      projection(cfgsc.racentre, cfgsc.decentre, x1, y1, False, cfgsc);
      Eq2Gal(cfgsc.racentre, cfgsc.decentre, a, d, cfgsc);
      gal2eq(a, d + 0.001, ar, de, cfgsc);
      projection(ar, de, x2, y2, False, cfgsc);
      Result := -arctan2((x2 - x1), (y2 - y1));
    end;
    Ecl:
    begin
      projection(cfgsc.racentre, cfgsc.decentre, x1, y1, False, cfgsc);
      Eq2Ecl(cfgsc.racentre, cfgsc.decentre, cfgsc.ecl, a, d);
      Ecl2eq(a, d + 0.001, cfgsc.ecl, ar, de);
      projection(ar, de, x2, y2, False, cfgsc);
      Result := -arctan2((x2 - x1), (y2 - y1));
    end;
    else
      Result := 0;
  end;
end;

function Tskychart.DrawRAline(ra, de, dd, dra: double; drawlabel: boolean; col,linewidth,dir,lh,lt: integer; linestyle: TFPPenStyle; var labelok:boolean): boolean;
var
  n, lx, ly: integer;
  x1, y1: double;
  xx, yy, xxp, yyp: single;
  plotok: boolean;
begin
  projection(ra, de, x1, y1, False, cfgsc);
  WindowXY(x1, y1, xxp, yyp, cfgsc);
  n := 0;
  plotok := False;
  repeat
    Inc(n);
    de := de + dd / 3;
    projection(ra, de, x1, y1, cfgsc.ProjPole=Altaz, cfgsc);
    WindowXY(x1, y1, xx, yy, cfgsc);
    if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
      if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
      begin
        if (not drawlabel) then
          Fplot.Plotline(xxp, yyp, xx, yy, col, linewidth, linestyle);
        if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
          plotok := True;
      end;
    if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
      (((dir = 1) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
      ((dir = 2) and ((abs(yy - cfgsc.Ymin) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
      ((dir = 3) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
      ((dir = 4) and ((abs(xx - cfgsc.Xmax) < lt) and (yy > 0) and (yy < cfgsc.Ymax)))) then
    begin
      if dir <= 2 then
      begin
        lx := round(xx);
        if yy < (cfgsc.Ymax div 2) then
          ly := (lh div 2)
        else
          ly := cfgsc.Ymax - (lh div 2);
      end
      else
      begin
        ly := round(yy);
        if xx < (cfgsc.Xmax div 2) then
          lx := (lh div 2)
        else
          lx := cfgsc.Xmax - (lh div 2);
      end;
      if dra <= 15 * minarc then
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
          artostr3(rmod(ra + pi2, pi2) * rad2deg / 15), cfgsc.WhiteBg, True, True, 5)
      else
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
          armtostr(rmod(ra + pi2, pi2) * rad2deg / 15), cfgsc.WhiteBg, True, True, 5);
      labelok := True;
    end;
    xxp := xx;
    yyp := yy;
  until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
    (yy > 2 * cfgsc.Ymax) or (de > (pid2 - 2 * dd / 3)) or (de < (-pid2 - 2 * dd / 3));
  Result := (n > 1);
end;

function Tskychart.DrawDEline(ra, de, da,dde,ra1: double; drawlabel: boolean; col,linewidth,dir,lh,lt: integer; linestyle: TFPPenStyle; var labelok:boolean): boolean;
var
  n, w, lx, ly: integer;
  x1, y1: double;
  xx, yy, xxp, yyp: single;
  plotok: boolean;
begin
  if de = 0 then
    w := WideLine+linewidth
  else
    w := linewidth;
  projection(ra, de, x1, y1, False, cfgsc);
  WindowXY(x1, y1, xxp, yyp, cfgsc);
  n := 0;
  plotok := False;
  repeat
    Inc(n);
    ra := ra + da / 3;
    projection(ra, de, x1, y1, cfgsc.ProjPole=Altaz, cfgsc);
    WindowXY(x1, y1, xx, yy, cfgsc);
    if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
      if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
      begin
        if (not drawlabel) then
          Fplot.Plotline(xxp, yyp, xx, yy, col, w, linestyle);
        if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
          plotok := True;
      end;
    if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
      (((dir = 1) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
      ((dir = 2) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
      ((dir = 3) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
      ((dir = 4) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax)))) then
    begin
      if dir > 2 then
      begin
        lx := round(xx);
        if yy < (cfgsc.Ymax div 2) then
          ly := (lh div 2)
        else
          ly := cfgsc.Ymax - (lh div 2);
      end
      else
      begin
        ly := round(yy);
        if xx < (cfgsc.Xmax div 2) then
          lx := (lh div 2)
        else
          lx := cfgsc.Xmax - (lh div 2);
      end;
      if dde <= 5 * minarc then
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
          detostr(de * rad2deg), cfgsc.WhiteBg, True, True, 5)
      else
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
          demtostr(de * rad2deg), cfgsc.WhiteBg, True, True, 5);
      labelok := True;
    end;
    xxp := xx;
    yyp := yy;
  until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
    (yy > 2 * cfgsc.Ymax) or (ra > ra1 + pi) or (ra < ra1 - pi);
  Result := (n > 1);
end;

procedure Tskychart.DrawEqGrid(drawlabel: boolean; altstyle: boolean = False);
var
  ra1, de1, ac, dc, dra, dde, lda1, lda2, rot: double;
  col, n, lh, lt, dir: integer;
  ok, labelok: boolean;
  linestyle: TFPPenStyle;
  linewidth: integer;
begin
  if altstyle then
  begin
    col := Fplot.cfgplot.Color[13];
    linestyle := cfgsc.StyleEqGrid;
    linewidth := cfgsc.LineWidthEqGrid;
  end
  else
  begin
    col := Fplot.cfgplot.Color[12];
    linestyle := cfgsc.StyleGrid;
    linewidth := cfgsc.LineWidthGrid;
  end;
  DrawPole(Equat);
  if not cfgsc.ShowOnlyMeridian then
  begin
    n := cfgsc.FieldNum;
    dde := Fcatalog.cfgshr.DegreeGridSpacing[n];
    lda1 := Fcatalog.cfgshr.HourGridSpacing[n] * 15 * cos(cfgsc.decentre);
    lda2 := lda1;
    while (lda1 < dde) and (n < MaxField) do
    begin
      lda2 := lda1;
      n := n + 1;
      lda1 := Fcatalog.cfgshr.HourGridSpacing[n] * 15 * cos(cfgsc.decentre);
    end;
    lda1 := abs(dde - lda1);
    lda2 := abs(dde - lda2);
    if lda2 < lda1 then
      n := min(n - 1, MaxField);
    dra := Fcatalog.cfgshr.HourGridSpacing[n];
    if dde > 1000 then
      dde := dde - 1000;
    ra1 := deg2rad * trunc(rad2deg * cfgsc.racentre / 15 / dra) * dra * 15;
    de1 := deg2rad * trunc(rad2deg * cfgsc.decentre / dde) * dde;
    dra := deg2rad * dra * 15;
    dde := deg2rad * dde;
    ac := ra1;
    dc := de1;
    lh := 2 * fplot.GetTextSize(1, '1', 7).cy;
    lt := round(abs(1.2 * cfgsc.BxGlb * dde / 3));
    dir := 1;
    rot := rmod(720 + rad2deg * CenterRot, 360);
    case round(rot) of
      0..45: if cfgsc.decentre > 0 then
          dir := 1
        else
          dir := 2;
      46..135: if cfgsc.decentre > 0 then
          dir := 4
        else
          dir := 3;
      136..225: if cfgsc.decentre > 0 then
          dir := 2
        else
          dir := 1;
      226..315: if cfgsc.decentre > 0 then
          dir := 3
        else
          dir := 4;
      316..360: if cfgsc.decentre > 0 then
          dir := 1
        else
          dir := 2;
    end;
    //RA, east of chart center
    repeat
      labelok := False;
      if cfgsc.decentre > 0 then
      begin
        ok := DrawRAline(ac, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
        ok := DrawRAline(ac, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      end
      else
      begin
        ok := DrawRAline(ac, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
        ok := DrawRAline(ac, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      end;
      ac := ac + dra;
    until (not ok) or (ac > ra1 + pi + musec);
    ac := ra1;
    dc := de1;
    //RA, west of chart center
    repeat
      labelok := False;
      if cfgsc.decentre > 0 then
      begin
        ok := DrawRAline(ac, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
        ok := DrawRAline(ac, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      end
      else
      begin
        ok := DrawRAline(ac, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
        ok := DrawRAline(ac, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      end;
      ac := ac - dra;
    until (not ok) or (ac < ra1 - pi - musec);
    ac := ra1;
    dc := de1;
    lt := round(abs(1.2 * cfgsc.BxGlb * dra / 3));
    //DEC, north of chart center
    repeat
      labelok := False;
      ok := DrawDEline(ac, dc, dra,dde,ra1,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
      ok := DrawDEline(ac, dc, -dra,dde,ra1,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      dc := dc + dde;
    until (not ok) or (dc > pid2);
    ac := ra1;
    dc := de1;
    //DEC, south of chart center
    repeat
      labelok := False;
      ok := DrawDEline(ac, dc, dra,dde,ra1,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
      ok := DrawDEline(ac, dc, -dra,dde,ra1,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok) or ok;
      dc := dc - dde;
    until (not ok) or (dc < -pid2);
  end;
end;

procedure Tskychart.DrawTelescopeLimit;
var n,col,linewidth,dir,lh,lt: integer;
  ac,dc,ah,dra,dde: double;
  drawlabel, labelok: boolean;
  linestyle: TFPPenStyle;
begin
  // drawing step
  n := cfgsc.FieldNum;
  dde := deg2rad * Fcatalog.cfgshr.DegreeGridSpacing[n];
  dra := dde;
  // chart center
  ac := cfgsc.racentre;
  dc := cfgsc.decentre;
  // no label
  drawlabel:=False; dir:=1; lh:=1; lt:=1;
  labelok := False;
  // same color and width as the meridian line
  col := Fplot.cfgplot.Color[15];
  linestyle := cfgsc.StyleGrid;
  linewidth := cfgsc.LineWidthGrid+WideLine;
  // max dec
  if cfgsc.TelLimitDecMaxActive then begin
    DrawDEline(ac, cfgsc.TelLimitDecMax*deg2rad, dra,dde,ac,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
    DrawDEline(ac, cfgsc.TelLimitDecMax*deg2rad, -dra,dde,ac,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
  end;
  // min dec
  if cfgsc.TelLimitDecMinActive then begin
    DrawDEline(ac, cfgsc.TelLimitDecMin*deg2rad, dra,dde,ac,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
    DrawDEline(ac, cfgsc.TelLimitDecMin*deg2rad, -dra,dde,ac,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
  end;
  // east hour angle
  if cfgsc.TelLimitHaEActive then begin
    ah:=rmod(cfgsc.CurST+cfgsc.TelLimitHaE*15*deg2rad+pi2,pi2);
    DrawRAline(ah, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
    DrawRAline(ah, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
  end;
  // west hour angle
  if cfgsc.TelLimitHaWActive then begin
    ah:=rmod(cfgsc.CurST-cfgsc.TelLimitHaW*15*deg2rad+pi2,pi2);
    DrawRAline(ah, dc, -dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
    DrawRAline(ah, dc, dde,dra,drawlabel,col,linewidth,dir,lh,lt,linestyle,labelok);
  end;
end;

procedure Tskychart.DrawAzGrid(drawlabel: boolean);
var
  a1, h1, ac, hc, dda, ddh, lda1, lda2, rot: double;
  col, n, lh, lt, dir: integer;
  ok, labelok: boolean;

  // draw meridian lines
  function DrawAline(a, h, dd: double): boolean;
  var
    x1, y1, al: double;
    n, w, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    if (abs(a) < musec) or (abs(a - pi2) < musec) or (abs(a - pi) < musec) then
    begin
      w := cfgsc.LineWidthGrid+WideLine;
      col := Fplot.cfgplot.Color[15];
    end
    else
    begin
      if cfgsc.ShowOnlyMeridian then
      begin
        Result := True;
        exit;
      end
      else
      begin
        w := cfgsc.LineWidthGrid;
        col := Fplot.cfgplot.Color[12];
      end;
    end;
    if h > (pid2 - 2 * dd / 3) then
      h := pid2 - 2 * dd / 3;
    if h > (pid2 + 2 * dd / 3) then
      h := pid2 + 2 * dd / 3;
    if h < (-pid2 - 2 * dd / 3) then
      h := -pid2 - 2 * dd / 3;
    if h < (-pid2 + 2 * dd / 3) then
      h := -pid2 + 2 * dd / 3;
    proj2(-a, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      h := h + dd / 3;
      if cfgsc.horizonopaque and (h < -musec) then
        break;
      proj2(-a, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and (((abs(h) < minarc) or (abs(yy - cfgsc.Ymax) < lt)) and (xx > 0) and
        (xx < cfgsc.Xmax))) or ((dir = 2) and (((abs(h) < minarc) or (abs(yy - cfgsc.Ymin) < lt)) and
        (xx > 0) and (xx < cfgsc.Xmax))) or ((dir = 3) and
        (((abs(h) < minarc) or (abs(xx - cfgsc.Xmin) < lt)) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 4) and (((abs(h) < minarc) or (abs(xx - cfgsc.Xmax) < lt)) and (yy > 0) and
        (yy < cfgsc.Ymax)))) then
      begin
        if (abs(h) < minarc) then
        begin
          lx := round(xx);
          ly := round(yy);
        end
        else
        begin
          if dir <= 2 then
          begin
            lx := round(xx);
            if yy < (cfgsc.Ymax div 2) then
              ly := (lh div 2)
            else
              ly := cfgsc.Ymax - (lh div 2);
          end
          else
          begin
            ly := round(yy);
            if xx < (cfgsc.Xmax div 2) then
              lx := (lh div 2)
            else
              lx := cfgsc.Xmax - (lh div 2);
          end;
        end;
        if Fcatalog.cfgshr.AzNorth then
          al := rmod(rad2deg * a + 540, 360)
        else
          al := rmod(rad2deg * a + 360, 360);
        if (al < 359.9999) or (cfgsc.fov < pid4) then
        begin
          if dda <= 15 * minarc then
            Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
              lontostr(al), cfgsc.WhiteBg, False, True, 5)
          else
            Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
              lonmtostr(al), cfgsc.WhiteBg, False, True, 5);
        end;
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (h > (pid2 - 2 * dd / 3)) or (h < (-pid2 - 2 * dd / 3));
    Result := (n > 1);
  end;

  // draw altitude lines
  function DrawHline(a, h, da: double): boolean;
  var
    x1, y1: double;
    n, w, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    if h = 0 then
      w := cfgsc.LineWidthGrid+WideLine
    else
      w := cfgsc.LineWidthGrid;
    proj2(-a, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      a := a + da / 3;
      proj2(-a, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 2) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 3) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 4) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax)))) then
      begin
        if dir > 2 then
        begin
          lx := round(xx);
          if yy < (cfgsc.Ymax div 2) then
            ly := (lh div 2)
          else
            ly := cfgsc.Ymax - (lh div 2);
        end
        else
        begin
          ly := round(yy);
          if xx < (cfgsc.Xmax div 2) then
            lx := (lh div 2)
          else
            lx := cfgsc.Xmax - (lh div 2);
        end;
        if ddh <= 5 * minarc then
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            detostr(h * rad2deg), cfgsc.WhiteBg, False, True, 5)
        else
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            demtostr(h * rad2deg), cfgsc.WhiteBg, False, True, 5);
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (a > a1 + pi) or (a < a1 - pi);
    Result := (n > 1);
  end;

  //  Tskychart.DrawAzGrid
begin
  DrawPole(Altaz);
  col := Fplot.cfgplot.Color[12];
  n := cfgsc.FieldNum;
  ddh := Fcatalog.cfgshr.DegreeGridSpacing[n];
  lda1 := ddh * cos(cfgsc.hcentre);
  lda2 := lda1;
  while (lda1 < ddh) and (n < MaxField) do
  begin
    lda2 := lda1;
    n := n + 1;
    lda1 := Fcatalog.cfgshr.DegreeGridSpacing[n] * cos(cfgsc.hcentre);
  end;
  lda1 := abs(ddh - lda1);
  lda2 := abs(ddh - lda2);
  if lda2 < lda1 then
    n := min(n - 1, MaxField);
  dda := Fcatalog.cfgshr.DegreeGridSpacing[n];
  a1 := deg2rad * round(rad2deg * cfgsc.acentre / dda) * dda;
  h1 := deg2rad * round(rad2deg * cfgsc.hcentre / ddh) * ddh;
  dda := deg2rad * dda;
  ddh := deg2rad * ddh;
  ac := a1;
  hc := h1;
  lh := 2 * fplot.GetTextSize(1, '1', 7).cy;
  lt := round(abs(1.2 * cfgsc.BxGlb * ddh / 3));
  dir := 1;
  rot := rmod(720 + rad2deg * CenterRot, 360);
  case round(rot) of
    0..45: if cfgsc.hcentre > 0 then
        dir := 1
      else
        dir := 2;
    46..135: if cfgsc.hcentre > 0 then
        dir := 4
      else
        dir := 3;
    136..225: if cfgsc.hcentre > 0 then
        dir := 2
      else
        dir := 1;
    226..315: if cfgsc.hcentre > 0 then
        dir := 3
      else
        dir := 4;
    316..360: if cfgsc.hcentre > 0 then
        dir := 1
      else
        dir := 2;
  end;
  repeat
    labelok := False;
    ok := DrawAline(ac, hc, -ddh);
    ok := DrawAline(ac, hc, ddh) or ok;
    ac := ac + dda;
  until (not ok) or (ac > a1 + pi);
  ac := a1;
  hc := h1;
  repeat
    labelok := False;
    ok := DrawAline(ac, hc, -ddh);
    ok := DrawAline(ac, hc, ddh) or ok;
    ac := ac - dda;
  until (not ok) or (ac < a1 - pi);
  if not cfgsc.ShowOnlyMeridian then
  begin
    ac := a1;
    hc := h1;
    col := Fplot.cfgplot.Color[12];
    lt := round(abs(1.2 * cfgsc.BxGlb * dda / 3));
    repeat
      if cfgsc.horizonopaque and (hc < -musec) then
        break;
      labelok := False;
      ok := DrawHline(ac, hc, dda);
      ok := DrawHline(ac, hc, -dda) or ok;
      hc := hc + ddh;
    until (not ok) or (hc > pid2);
    ac := a1;
    hc := h1;
    repeat
      if cfgsc.horizonopaque and (hc < -musec) then
        break;
      labelok := False;
      ok := DrawHline(ac, hc, dda);
      ok := DrawHline(ac, hc, -dda) or ok;
      hc := hc - ddh;
    until (not ok) or (hc < -pid2);
  end;
end;

procedure Tskychart.DrawMeridian;
var
  ra, de: double;
  col, n, i, w: integer;
  x1, y1: double;
  xx, yy, xxp, yyp: single;
begin
  col := Fplot.cfgplot.Color[15];
  w := cfgsc.LineWidthGrid+WideLine;
  // meridian
  for i := 0 to 1 do
  begin
    xxp := 999999;
    yyp := 999999;
    for n := 0 to 90 do
    begin
      Hz2Eq(i * pi, deg2rad * n, ra, de, cfgsc);
      ra := cfgsc.CurST - ra;
      projection(ra, de, x1, y1, False, cfgsc);
      if (x1 < 200) and (y1 < 200) then
      begin
        WindowXY(x1, y1, xx, yy, cfgsc);
        if (xxp < 999999) and ((intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2) and
          ((xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax)) then
        begin
          Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
        end;
        xxp := xx;
        yyp := yy;
      end;
    end;
  end;
  // horizon
  xxp := 999999;
  for n := 0 to 360 do
  begin
    Hz2Eq(deg2rad * n, 0, ra, de, cfgsc);
    ra := cfgsc.CurST - ra;
    projection(ra, de, x1, y1, False, cfgsc);
    if (x1 < 200) and (y1 < 200) then
    begin
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (xxp < 999999) and ((intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2) and
        ((xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax)) then
      begin
        Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
      end;
      xxp := xx;
      yyp := yy;
    end;
  end;
end;


constructor TDrawHorizonThread.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
  working := True;
end;

procedure TDrawHorizonThread.Execute;
var
  hsx, hsy, x, y, xx2, yy2: single;
  hlimit, az, h, de, hh, x2, y2: double;
  i, j, startline, endline: integer;
  col1: TBGRAPixel;
  p, p2: PBGRAPixel;
  ok: boolean;
  p2line, p2col: boolean;
  mi: byte;
begin
  ok := False;
  hsx := (horizonpicture.Width - 1) / 360;
  hsy := horizonpicture.Height / 2;
  hlimit := deg2rad * hsy / hsx;
  i := hbmp.Height div num;
  startline := id * i;
  if id = (num - 1) then
    endline := hbmp.Height - 1
  else
    endline := (id + 1) * i - 1;
  p2line := False;
  p2 := nil;
  for i := startline to endline do
  begin
    p := hbmp.ScanLine[i];
    if lowquality and (i < endline) then
    begin
      if p2line then
      begin
        p2line := False;
        continue;
      end;
      p2line := True;
      p2 := hbmp.ScanLine[i + 1];
    end;
    p2col := False;
    for j := 0 to hbmp.Width - 1 do
    begin
      if Terminated then
        exit;
      if p2line then
      begin
        if p2col then
        begin
          p2col := False;
          continue;
        end;
        p2col := True;
      end;
      x := -1;
      y := -1;
      h := 1;
      GetAHxy(j, i, az, h, cfgsc);
      if abs(h) <= hlimit then
      begin
        if cfgsc.fov > pi then
        begin
          Hz2Eq(az, h, hh, de, cfgsc);
          projection(cfgsc.CurST - hh, de, x2, y2, False, cfgsc);
          WindowXY(x2, y2, xx2, yy2, cfgsc);
          ok := (round(xx2) = j) and (round(yy2) = i);
        end
        else
          ok := True;
        if ok then
        begin
          az := rmod(pid2 + pi4 + az - cfgsc.HorizonPictureRotate * deg2rad, pi2);
          x := hsx * az * rad2deg;
          h := min( max(-pid2, (h - cfgsc.HorizonPictureElevation * deg2rad)), pid2);
          y := hsy - hsx * h * rad2deg;
        end;
      end;
      if (x >= 0) and (x <= horizonpicture.Width) and (y >= 0) and (y <= horizonpicture.Height) then
      begin
        col1 := horizonpicture.GetPixel(x, y, rfBestQuality);
        if cfgsc.WhiteBg then
        begin
          mi := MaxIntValue([col1.red, col1.blue, col1.green]);
          col1.red := mi;
          col1.green := mi;
          col1.blue := mi;
        end;
      end
      else if h > 0 then
        col1 := BGRAPixelTransparent
      else
        col1 := col2;
      p[j] := col1;
      if p2col then
      begin
        p2[j] := col1;
        if j < (hbmp.Width - 1) then
        begin
          p[j + 1] := col1;
          p2[j + 1] := col1;
        end;
      end;
    end;
  end;
  working := False;
end;

procedure Tskychart.DrawHorizonPicture(hbmp: TBGRABitmap);
var
  i, n, timeout: integer;
  working, timingout: boolean;
  timelimit: TDateTime;
  thread: array[0..7] of TDrawHorizonThread;
begin
  n := min(8, MaxThreadCount);
  timeout := round(max(10, hbmp.Width * hbmp.Height / n / 50000));
  thread[0] := nil;
  for i := 0 to n - 1 do
  begin
    thread[i] := TDrawHorizonThread.Create(True);
    thread[i].horizonpicture := horizonpicturedark;
    thread[i].hbmp := hbmp;
    thread[i].col2 := ColorToBGRA(FPlot.cfgplot.Color[19]);
    thread[i].cfgsc := cfgsc;
    thread[i].lowquality := cfgsc.HorizonPictureLowQuality or
      ((pi2 / horizonpicturedark.Width) > (2 * cfgsc.fov / hbmp.Width));
    thread[i].num := n;
    thread[i].id := i;
    thread[i].Start;
  end;
  timelimit := now + timeout / secday;
  repeat
    sleep(100);
    working := False;
    for i := 0 to n - 1 do
      working := working or thread[i].working;
    timingout := (now > timelimit);
  until (not working) or timingout;
  if timingout then
  begin
    for i := 0 to n - 1 do
      thread[i].Terminate;
    sleep(10);
  end;
end;

function Tskychart.DrawHorizon: boolean;
const
  hdiv = 10;
var
  az, h, hstep, azp, hpstep, x1, y1, hlimit, daz, fillfov, hh, de: double;
  ps: array[0..1, 0..2 * hdiv + 1] of single;
  psf: array of TPointF;
  i, j, n: integer;
  xx, yy: int64;
  x, y, xh, yh, xp, yp, xph, yph, x0h, y0h, fillx1, filly1, fillx2, filly2: single;
  First, fill, ok, hlplot: boolean;
  hbmp: TBGRABitmap;
  col: TColor;
  col1, col2: TBGRAPixel;
  xx2, yy2, poslimit: single;
  x2, y2: double;

  function CheckBelowHorizon(x, y: integer): boolean;
  begin
    GetAHxy(x, y, az, h, cfgsc);
    if h > 0 then
      Result := False
    else
    begin
      // check for reversability, otherwise we are out of the world.
      Hz2Eq(az, h, hh, de, cfgsc);
      projection(cfgsc.CurST - hh, de, x2, y2, False, cfgsc);
      WindowXY(x2, y2, xx2, yy2, cfgsc);
      Result := ((h < hlimit) and (round(xx2) = x) and (round(yy2) = y));
    end;
  end;

begin
  HorizonDone := True;
  // Only with Alt/Az display
  if cfgsc.ProjPole = Altaz then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw horizon');
    fillx1 := 0;
    filly1 := 0;
    hlplot := False;
    hlimit := abs(3 / cfgsc.BxGlb); // 3 pixels
    if (cfgsc.hcentre < -hlimit) then
    begin
      fillx1 := (cfgsc.xmax - cfgsc.xmin) div 2;
      filly1 := (cfgsc.ymax - cfgsc.ymin) div 2;
    end;
    proj2(-cfgsc.acentre, -hlimit, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
    WindowXY(x1, y1, fillx2, filly2, cfgsc);
    ///// Draw to bgra bitmap
    if Fplot.cfgplot.UseBMP then
    begin
      hbmp := TBGRABitmap.Create;
      hbmp.SetSize(fplot.cfgchart.Width, fplot.cfgchart.Height);
      if cfgsc.ShowHorizonPicture then
      begin         // use horizon image bitmap

        DrawHorizonPicture(hbmp);

        // Horizon line
        if cfgsc.ShowHorizon0 then
        begin
          col2 := ColorToBGRA(Fplot.cfgplot.Color[12]);
          First := True;
          xph := 0;
          yph := 0;
          x0h := 0;
          y0h := 0;
          for i := 1 to 360 do
          begin
            az := deg2rad * rmod(360 + i - 1 - 180, 360);
            proj2(-az, 0, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
            WindowXY(x1, y1, xh, yh, cfgsc);
            if First then
            begin
              First := False;
              x0h := xh;
              y0h := yh;
            end
            else
            begin
              if (xh > -5 * cfgsc.Xmax) and (xh < 5 * cfgsc.Xmax) and (yh > -5 * cfgsc.Ymax) and
                (yh < 5 * cfgsc.Ymax) and ((cfgsc.fov < 0.1) or (abs(xh - xph) < (cfgsc.xmax / 2)) and
                (abs(yh - yph) < (cfgsc.ymax / 2))) then
              begin
                Fplot.BGRADrawLine(xph, yph, xh, yh, col2, cfgsc.LineWidthGrid+WideLine, hbmp);
                hlplot := True;
              end;
            end;
            xph := xh;
            yph := yh;
          end;
          xph := x0h;
          yph := y0h;
          if (xh > -cfgsc.Xmax) and (xh < 2 * cfgsc.Xmax) and (yh > -cfgsc.Ymax) and
            (yh < 2 * cfgsc.Ymax) and (abs(xh - xph) < (cfgsc.xmax / 2)) and (abs(yh - yph) < (cfgsc.ymax / 2)) then
            Fplot.BGRADrawLine(xh, yh, xph, yph, col2, cfgsc.LineWidthGrid+WideLine, hbmp);
        end;
        hbmp.InvalidateBitmap;
        // Render bitmap
        Fplot.cbmp.PutImage(0, 0, hbmp, dmDrawWithTransparency);
      end
      else
      begin                                      // use line definition
        fill := cfgsc.FillHorizon;// and (cfgsc.fov>(0.5*deg2rad));
        case cfgsc.projtype of
          'C': fillfov := 357 * deg2rad;
          'H': fillfov := 230 * deg2rad;
          'M': fillfov := 357 * deg2rad;
          else
            fillfov := 360 * deg2rad;
        end;
        hbmp.FillTransparent;
        col := FPlot.cfgplot.Color[19];
        if col = FPlot.cfgplot.bgcolor then
        begin
          fill := False;
          col := col xor clWhite;
        end;
        col1 := ColorToBGRA(col);
        if cfgsc.horizonopaque then
          col1.alpha := 255
        else
          col1.alpha := 176;
        col2 := ColorToBGRA(Fplot.cfgplot.Color[12]);
        daz := abs(0.5 / cfgsc.BxGlb); // 0.5 pixel polygon overlap to avoid banding
        if cfgsc.ShowHorizon and (cfgsc.HorizonMax > 0) then
        begin
          // Use horizon file data
          azp := 0;
          hpstep := 0;
          for i := 1 to 361 do
          begin
            h := cfgsc.horizonlist[i];
            az := deg2rad * rmod(360 + i - 1 - 180, 360);
            hstep := h / hdiv;
            if i = 1 then
            begin
              hpstep := hstep;
              azp := az;
              continue;
            end
            else
            begin
              if fill and ((abs(hpstep - hstep)) > (0.35 / hdiv)) then
                hpstep := hstep;
              ok := True;
              for j := 0 to hdiv do
              begin
                proj2(-azp, j * hpstep, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
                WindowXY(x1, y1, ps[0, j], ps[1, j], cfgsc);
                proj2(-az - daz, (hdiv - j) * hstep, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
                WindowXY(x1, y1, ps[0, j + hdiv + 1], ps[1, j + hdiv + 1], cfgsc);
                if (cfgsc.fov > 0.1) and
                  ((abs(ps[0, j] - Fplot.cfgchart.hw) > 20 * Fplot.cfgchart.hw) or
                  ((abs(ps[1, j] - Fplot.cfgchart.hh) > 20 * Fplot.cfgchart.hh) and
                  (abs(cfgsc.hcentre) < 0.05)) or (abs(ps[0, j + hdiv + 1] - Fplot.cfgchart.hw) > 20 *
                  Fplot.cfgchart.hw) or ((abs(ps[1, j + hdiv + 1] - Fplot.cfgchart.hh) >
                  20 * Fplot.cfgchart.hh) and (abs(cfgsc.hcentre) < 0.05))) then
                begin
                  ok := False;
                  break;
                end;
              end;
              if (cfgsc.fov > 0.1) and ((abs(ps[0, hdiv] - ps[0, hdiv + 1]) > (cfgsc.xmax / 2)) or
                (abs(ps[1, hdiv] - ps[1, hdiv + 1]) > (cfgsc.ymax / 2))) then
                ok := False;
              if ok then
              begin
                if fill then
                begin
                  SetLength(psf, 2 * hdiv + 2);
                  for j := 0 to 2 * hdiv + 1 do
                  begin
                    psf[j].x := ps[0, j];
                    psf[j].y := ps[1, j];
                  end;
                  // draw filled polygon
                  hbmp.FillPoly(psf, col1, dmset);
                end
                else
                begin
                  // draw line
                  Fplot.BGRADrawLine(ps[0, hdiv], ps[1, hdiv], ps[0, hdiv + 1],
                    ps[1, hdiv + 1], col1, 1, hbmp);
                end;
              end;
            end;
            azp := az;
            hpstep := hstep;
          end;
        end;
        // Horizon line
        if (cfgsc.fov > 5 * minarc) then
          poslimit := 5
        else
          poslimit := 30;
        if cfgsc.ShowHorizon0 then
        begin
          First := True;
          xph := 0;
          yph := 0;
          x0h := 0;
          y0h := 0;
          for i := 1 to 360 do
          begin
            az := deg2rad * rmod(360 + i - 1 - 180, 360);
            proj2(-az, 0, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
            WindowXY(x1, y1, xh, yh, cfgsc);
            if First then
            begin
              First := False;
              x0h := xh;
              y0h := yh;
            end
            else
            begin
              if (xh > -poslimit * cfgsc.Xmax) and (xh < poslimit * cfgsc.Xmax) and
                (yh > -poslimit * cfgsc.Ymax) and (yh < poslimit * cfgsc.Ymax) and
                ((cfgsc.fov < 0.1) or (abs(xh - xph) < (cfgsc.xmax / 2)) and (abs(yh - yph) < (cfgsc.ymax / 2))) then
              begin
                Fplot.BGRADrawLine(xph, yph, xh, yh, col2, cfgsc.LineWidthGrid+WideLine, hbmp);
                hlplot := True;
              end;
            end;
            xph := xh;
            yph := yh;
          end;
          xph := x0h;
          yph := y0h;
          if (xh > -cfgsc.Xmax) and (xh < 2 * cfgsc.Xmax) and (yh > -cfgsc.Ymax) and
            (yh < 2 * cfgsc.Ymax) and (abs(xh - xph) < (cfgsc.xmax / 2)) and (abs(yh - yph) < (cfgsc.ymax / 2)) then
            Fplot.BGRADrawLine(xh, yh, xph, yph, col2, cfgsc.LineWidthGrid+WideLine, hbmp);
        end;
        // Fill below horizon
        if hlplot and fill and (not Fplot.cfgchart.onprinter) and (cfgsc.fov < fillfov) then
        begin
          if (fillx1 > 0) or (filly1 > 0) then
            hbmp.FloodFill(round(fillx1), round(filly1), col1, fmSet);
          if (fillx2 > -cfgsc.Xmax) and (fillx2 < 2 * cfgsc.Xmax) and
            (filly2 > -cfgsc.Ymax) and (filly2 < 2 * cfgsc.Ymax) then
            hbmp.FloodFill(round(fillx2), round(filly2), col1, fmSet);
          if CheckBelowHorizon(cfgsc.Xmin + 1, cfgsc.Ymin + 1) and
            (hbmp.GetPixel(integer(cfgsc.Xmin + 1), integer(cfgsc.Ymin + 1)) <> col1) then
            hbmp.FloodFill(cfgsc.Xmin + 1, cfgsc.Ymin + 1, col1, fmSet);
          if CheckBelowHorizon(cfgsc.Xmin + 1, cfgsc.Ymax - 1) and
            (hbmp.GetPixel(integer(cfgsc.Xmin + 1), integer(cfgsc.Ymax - 1)) <> col1) then
            hbmp.FloodFill(cfgsc.Xmin + 1, cfgsc.Ymax - 1, col1, fmSet);
          if CheckBelowHorizon(cfgsc.Xmax - 1, cfgsc.Ymin + 1) and
            (hbmp.GetPixel(integer(cfgsc.Xmax - 1), integer(cfgsc.Ymin + 1)) <> col1) then
            hbmp.FloodFill(cfgsc.Xmax - 1, cfgsc.Ymin + 1, col1, fmSet);
          if CheckBelowHorizon(cfgsc.Xmax - 1, cfgsc.Ymax - 1) and
            (hbmp.GetPixel(integer(cfgsc.Xmax - 1), integer(cfgsc.Ymax - 1)) <> col1) then
            hbmp.FloodFill(cfgsc.Xmax - 1, cfgsc.Ymax - 1, col1, fmSet);
        end;
        // Render bitmap
        Fplot.cbmp.PutImage(0, 0, hbmp, dmDrawWithTransparency);
      end;
      hbmp.Free;
      ///// Draw to canvas
    end
    else
    begin
      if cfgsc.ShowHorizon and (cfgsc.HorizonMax > 0) then
      begin
        // Use horizon file data
        azp := 0;
        hpstep := 0;
        for i := 1 to 361 do
        begin
          h := cfgsc.horizonlist[i];
          az := deg2rad * rmod(360 + i - 1 - 180, 360);
          hstep := h / hdiv;
          if i = 1 then
          begin
            hpstep := hstep;
            azp := az;
            continue;
          end
          else
          begin
            if cfgsc.FillHorizon and ((abs(hpstep - hstep)) > (0.35 / hdiv)) then
              hpstep := hstep;
            for j := 0 to hdiv do
            begin
              proj2(-azp, j * hpstep, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
              WindowXY(x1, y1, ps[0, j], ps[1, j], cfgsc);
              proj2(-az, (hdiv - j) * hstep, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
              WindowXY(x1, y1, ps[0, j + hdiv + 1], ps[1, j + hdiv + 1], cfgsc);
            end;
            ok := True;
            if (abs(ps[0, hdiv] - ps[0, hdiv + 1]) > cfgsc.xmax) or
              (abs(ps[1, hdiv] - ps[1, hdiv + 1]) > cfgsc.ymax) then
              ok := False;
            if ok then
            begin
              if cfgsc.FillHorizon then
              begin
                Fplot.PlotOutline(ps[0, 0], ps[1, 0], 0, 1, 2, 1, 99 * cfgsc.x2,
                  Fplot.cfgplot.Color[19]);
                for j := 1 to 2 * hdiv do
                begin
                  Fplot.PlotOutline(ps[0, j], ps[1, j], 2, 1, 2, 1, 99 * cfgsc.x2,
                    Fplot.cfgplot.Color[19]);
                end;
                // draw filled polygon
                Fplot.PlotOutline(ps[0, 2 * hdiv + 1], ps[1, 2 * hdiv + 1], 1, 1, 2, 1,
                  99 * cfgsc.x2, Fplot.cfgplot.Color[19]);
              end
              else
              begin
                // draw line
                Fplot.Plotline(ps[0, hdiv], ps[1, hdiv], ps[0, hdiv + 1],
                  ps[1, hdiv + 1], Fplot.cfgplot.Color[19], 1);
              end;
              if cfgsc.ShowHorizon0 then
                Fplot.Plotline(ps[0, 0], ps[1, 0], ps[0, 2 * hdiv + 1], ps[1, 2 * hdiv + 1], Fplot.cfgplot.Color[12], 2);
            end;
          end;
          azp := az;
          hpstep := hstep;
        end;
        // Fill below horizon
        if cfgsc.horizonopaque and cfgsc.FillHorizon and (not Fplot.cfgchart.onprinter) then
        begin
          if (fillx1 > 0) or (filly1 > 0) then
            fplot.FloodFill(round(fillx1), round(filly1), Fplot.cfgplot.Color[19]);
          if (fillx2 > -cfgsc.Xmax) and (fillx2 < 2 * cfgsc.Xmax) and (filly2 > -cfgsc.Ymax) and
            (filly2 < 2 * cfgsc.Ymax) then
            fplot.FloodFill(round(fillx2), round(filly2), Fplot.cfgplot.Color[19]);
          GetAHxy(cfgsc.Xmin + 1, cfgsc.Ymin + 1, az, h, cfgsc);
          if h < 0 then
            fplot.FloodFill(cfgsc.Xmin + 1, cfgsc.Ymin + 1, Fplot.cfgplot.Color[19]);
          GetAHxy(cfgsc.Xmin + 1, cfgsc.Ymax - 1, az, h, cfgsc);
          if h < 0 then
            fplot.FloodFill(cfgsc.Xmin + 1, cfgsc.Ymax - 1, Fplot.cfgplot.Color[19]);
          GetAHxy(cfgsc.Xmax - 1, cfgsc.Ymin + 1, az, h, cfgsc);
          if h < 0 then
            fplot.FloodFill(cfgsc.Xmax - 1, cfgsc.Ymin + 1, Fplot.cfgplot.Color[19]);
          GetAHxy(cfgsc.Xmax - 1, cfgsc.Ymax - 1, az, h, cfgsc);
          if h < 0 then
            fplot.FloodFill(cfgsc.Xmax - 1, cfgsc.Ymax - 1, Fplot.cfgplot.Color[19]);
        end;
      end
      else if cfgsc.ShowHorizonPicture then
      begin         // use horizon image bitmap
        hbmp := TBGRABitmap.Create;
        hbmp.SetSize(fplot.cfgchart.Width, fplot.cfgchart.Height);
        DrawHorizonPicture(hbmp);
        fplot.cnv.CopyMode := cmSrcCopy;
        fplot.cnv.Draw(0, 0, hbmp.Bitmap);
        hbmp.Free;
      end
      else
      begin
        // Horizon line
        if cfgsc.ShowHorizon0 then
        begin
          First := True;
          xph := 0;
          yph := 0;
          x0h := 0;
          y0h := 0;
          for i := 1 to 360 do
          begin
            az := deg2rad * rmod(360 + i - 1 - 180, 360);
            proj2(-az, 0, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
            WindowXY(x1, y1, xh, yh, cfgsc);
            if First then
            begin
              First := False;
              x0h := xh;
              y0h := yh;
            end
            else
            begin
              if (xh > -cfgsc.Xmax) and (xh < 2 * cfgsc.Xmax) and (yh > -cfgsc.Ymax) and
                (yh < 2 * cfgsc.Ymax) and (abs(xh - xph) < (cfgsc.xmax / 2)) and (abs(yh - yph) < (cfgsc.ymax / 2)) then
              begin
                Fplot.Plotline(xph, yph, xh, yh, Fplot.cfgplot.Color[12], 2);
              end;
            end;
            xph := xh;
            yph := yh;
          end;
          xph := x0h;
          yph := y0h;
          if (xh > -cfgsc.Xmax) and (xh < 2 * cfgsc.Xmax) and (yh > -cfgsc.Ymax) and
            (yh < 2 * cfgsc.Ymax) and (abs(xh - xph) < (cfgsc.xmax / 2)) and (abs(yh - yph) < (cfgsc.ymax / 2)) then
            Fplot.Plotline(xh, yh, xph, yph, Fplot.cfgplot.Color[12], 2);
        end;
      end;
    end;
    ////// End of horizon drawing
    if cfgsc.ShowHorizonDepression then
    begin
      // Horizon depression line
      First := True;
      xp := 0;
      yp := 0;
      h := cfgsc.ObsHorizonDepression;
      Refraction(h, True, cfgsc, refmethod);
      // draw the line at the right altitude relative to the refracted stars
      if h < 0 then
        for i := 1 to 360 do
        begin
          az := deg2rad * rmod(360 + i - 1 - 180, 360);
          proj2(-az, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
          WindowXY(x1, y1, x, y, cfgsc);
          if First then
          begin
            First := False;
          end
          else
          begin
            if (x > -cfgsc.Xmax) and (x < 2 * cfgsc.Xmax) and (y > -cfgsc.Ymax) and
              (y < 2 * cfgsc.Ymax) and (abs(x - xp) < cfgsc.xmax) and (abs(y - yp) < cfgsc.ymax) then
            begin
              Fplot.Plotline(xp, yp, x, y, Fplot.cfgplot.Color[15], 2);
            end;
          end;
          xp := x;
          yp := y;
        end;
    end;
    // cardinal point label
    if (cfgsc.ShowLabel[7]) then
    begin
      az := 0;
      h := 0;
      for i := 1 to 8 do
      begin
        proj2(-deg2rad * az, h, -cfgsc.acentre, cfgsc.hcentre, x1, y1, cfgsc);
        WindowXY(x1, y1, x, y, cfgsc);
        xx := round(x);
        yy := round(y);
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and
          (yy < 2 * cfgsc.Ymax) then
          case round(az) of
            0: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'S', cfgsc.WhiteBg);
            45: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'SW', cfgsc.WhiteBg);
            90: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'W', cfgsc.WhiteBg);
            135: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'NW', cfgsc.WhiteBg);
            180: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'N', cfgsc.WhiteBg);
            225: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'NE', cfgsc.WhiteBg);
            270: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'E', cfgsc.WhiteBg);
            315: FPlot.PlotText(xx, yy, 1, Fplot.cfgplot.LabelColor[7],
                laCenter, laBottom, 'SE', cfgsc.WhiteBg);
          end;
        az := az + 45;
      end;
    end;
  end;
  Result := True;
end;

procedure Tskychart.DrawGalGrid(drawlabel: boolean);
var
  a1, h1, ac, hc, dda, ddh, lda1, lda2, rot: double;
  col, n, lh, lt, dir: integer;
  ok, labelok: boolean;

  function DrawAline(a, h, dd: double): boolean;
  var
    x1, y1: double;
    n, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    proj2(a, h, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      h := h + dd / 3;
      proj2(a, h, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, cfgsc.LineWidthGrid, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 2) and ((abs(yy - cfgsc.Ymin) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 3) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 4) and ((abs(xx - cfgsc.Xmax) < lt) and (yy > 0) and (yy < cfgsc.Ymax)))) then
      begin
        if dir <= 2 then
        begin
          lx := round(xx);
          if yy < (cfgsc.Ymax div 2) then
            ly := (lh div 2)
          else
            ly := cfgsc.Ymax - (lh div 2);
        end
        else
        begin
          ly := round(yy);
          if xx < (cfgsc.Xmax div 2) then
            lx := (lh div 2)
          else
            lx := cfgsc.Xmax - (lh div 2);
        end;
        if dda <= 15 * minarc then
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
            lontostr(rmod(a + pi2, pi2) * rad2deg), cfgsc.WhiteBg, True, True, 5)
        else
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
            lonmtostr(rmod(a + pi2, pi2) * rad2deg), cfgsc.WhiteBg, True, True, 5);
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (h > (pid2 - 2 * dd / 3)) or (h < (-pid2 - 2 * dd / 3));
    Result := (n > 1);
  end;

  function DrawHline(a, h, da: double): boolean;
  var
    x1, y1: double;
    n, w, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    w := cfgsc.LineWidthGrid;
    proj2(a, h, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      a := a + da / 3;
      proj2(a, h, cfgsc.lcentre, cfgsc.bcentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 2) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 3) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 4) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax)))) then
      begin
        if dir > 2 then
        begin
          lx := round(xx);
          if yy < (cfgsc.Ymax div 2) then
            ly := (lh div 2)
          else
            ly := cfgsc.Ymax - (lh div 2);
        end
        else
        begin
          ly := round(yy);
          if xx < (cfgsc.Xmax div 2) then
            lx := (lh div 2)
          else
            lx := cfgsc.Xmax - (lh div 2);
        end;
        if ddh <= 5 * minarc then
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            detostr(h * rad2deg), cfgsc.WhiteBg, True, True, 5)
        else
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            demtostr(h * rad2deg), cfgsc.WhiteBg, True, True, 5);
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (a > a1 + pi) or (a < a1 - pi);
    Result := (n > 1);
  end;

  // Tskychart.DrawGalGrid
begin
  DrawPole(Gal);
  col := Fplot.cfgplot.Color[12];
  n := cfgsc.FieldNum;
  ddh := Fcatalog.cfgshr.DegreeGridSpacing[n];
  lda1 := ddh * cos(cfgsc.bcentre);
  lda2 := lda1;
  while (lda1 < ddh) and (n < MaxField) do
  begin
    lda2 := lda1;
    n := n + 1;
    lda1 := Fcatalog.cfgshr.DegreeGridSpacing[n] * cos(cfgsc.bcentre);
  end;
  lda1 := abs(ddh - lda1);
  lda2 := abs(ddh - lda2);
  if lda2 < lda1 then
    n := min(n - 1, MaxField);
  dda := Fcatalog.cfgshr.DegreeGridSpacing[n];
  a1 := deg2rad * trunc(rad2deg * cfgsc.lcentre / dda) * dda;
  h1 := deg2rad * trunc(rad2deg * cfgsc.bcentre / ddh) * ddh;
  dda := deg2rad * dda;
  ddh := deg2rad * ddh;
  ac := a1;
  hc := h1;
  lh := 2 * fplot.GetTextSize(1, '1', 7).cy;
  lt := round(abs(1.2 * cfgsc.BxGlb * ddh / 3));
  dir := 1;
  rot := rmod(720 + rad2deg * CenterRot, 360);
  case round(rot) of
    0..45: if cfgsc.bcentre > 0 then
        dir := 1
      else
        dir := 2;
    46..135: if cfgsc.bcentre > 0 then
        dir := 4
      else
        dir := 3;
    136..225: if cfgsc.bcentre > 0 then
        dir := 2
      else
        dir := 1;
    226..315: if cfgsc.bcentre > 0 then
        dir := 3
      else
        dir := 4;
    316..360: if cfgsc.bcentre > 0 then
        dir := 1
      else
        dir := 2;
  end;
  repeat
    labelok := False;
    if cfgsc.bcentre > 0 then
    begin
      ok := DrawAline(ac, hc, -ddh);
      ok := DrawAline(ac, hc, ddh) or ok;
    end
    else
    begin
      ok := DrawAline(ac, hc, ddh);
      ok := DrawAline(ac, hc, -ddh) or ok;
    end;
    ac := ac + dda;
  until (not ok) or (ac > a1 + pi);
  ac := a1;
  hc := h1;
  repeat
    labelok := False;
    if cfgsc.bcentre > 0 then
    begin
      ok := DrawAline(ac, hc, -ddh);
      ok := DrawAline(ac, hc, ddh) or ok;
    end
    else
    begin
      ok := DrawAline(ac, hc, ddh);
      ok := DrawAline(ac, hc, -ddh) or ok;
    end;
    ac := ac - dda;
  until (not ok) or (ac < a1 - pi);
  ac := a1;
  hc := h1;
  col := Fplot.cfgplot.Color[12];
  lt := round(abs(1.2 * cfgsc.BxGlb * dda / 3));
  repeat
    labelok := False;
    ok := DrawHline(ac, hc, -dda);
    ok := DrawHline(ac, hc, dda) or ok;
    hc := hc + ddh;
  until (not ok) or (hc > pid2);
  ac := a1;
  hc := h1;
  repeat
    labelok := False;
    ok := DrawHline(ac, hc, -dda);
    ok := DrawHline(ac, hc, dda) or ok;
    hc := hc - ddh;
  until (not ok) or (hc < -pid2);
end;

procedure Tskychart.DrawEclGrid(drawlabel: boolean);
var
  a1, h1, ac, hc, dda, ddh, lda1, lda2, rot: double;
  col, n, lh, lt, dir: integer;
  ok, labelok: boolean;

  function DrawAline(a, h, dd: double): boolean;
  var
    x1, y1: double;
    n, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    proj2(a, h, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      h := h + dd / 3;
      proj2(a, h, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, cfgsc.LineWidthGrid, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 2) and ((abs(yy - cfgsc.Ymin) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 3) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 4) and ((abs(xx - cfgsc.Xmax) < lt) and (yy > 0) and (yy < cfgsc.Ymax)))) then
      begin
        if dir <= 2 then
        begin
          lx := round(xx);
          if yy < (cfgsc.Ymax div 2) then
            ly := (lh div 2)
          else
            ly := cfgsc.Ymax - (lh div 2);
        end
        else
        begin
          ly := round(yy);
          if xx < (cfgsc.Xmax div 2) then
            lx := (lh div 2)
          else
            lx := cfgsc.Xmax - (lh div 2);
        end;
        if dda <= 15 * minarc then
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
            lontostr(rmod(a + pi2, pi2) * rad2deg), cfgsc.WhiteBg, True, True, 5)
        else
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laCenter, laTop,
            lonmtostr(rmod(a + pi2, pi2) * rad2deg), cfgsc.WhiteBg, True, True, 5);
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (h > (pid2 - 2 * dd / 3)) or (h < (-pid2 - 2 * dd / 3));
    Result := (n > 1);
  end;

  function DrawHline(a, h, da: double): boolean;
  var
    x1, y1: double;
    n, w, lx, ly: integer;
    xx, yy, xxp, yyp: single;
    plotok: boolean;
  begin
    w := cfgsc.LineWidthGrid;
    proj2(a, h, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
    WindowXY(x1, y1, xxp, yyp, cfgsc);
    n := 0;
    plotok := False;
    repeat
      Inc(n);
      a := a + da / 3;
      proj2(a, h, cfgsc.lecentre, cfgsc.becentre, x1, y1, cfgsc);
      WindowXY(x1, y1, xx, yy, cfgsc);
      if (intpower(xxp - xx, 2) + intpower(yyp - yy, 2)) < cfgsc.x2 then
        if (xx > -cfgsc.Xmax) and (xx < 2 * cfgsc.Xmax) and (yy > -cfgsc.Ymax) and (yy < 2 * cfgsc.Ymax) then
        begin
          if (not drawlabel) then
            Fplot.Plotline(xxp, yyp, xx, yy, col, w, cfgsc.StyleGrid);
          if (xx > 0) and (xx < cfgsc.Xmax) and (yy > 0) and (yy < cfgsc.Ymax) then
            plotok := True;
        end;
      if drawlabel and (cfgsc.ShowGridNum) and (plotok) and (not labelok) and
        (((dir = 1) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 2) and ((abs(xx - cfgsc.Xmin) < lt) and (yy > 0) and (yy < cfgsc.Ymax))) or
        ((dir = 3) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax))) or
        ((dir = 4) and ((abs(yy - cfgsc.Ymax) < lt) and (xx > 0) and (xx < cfgsc.Xmax)))) then
      begin
        if dir > 2 then
        begin
          lx := round(xx);
          if yy < (cfgsc.Ymax div 2) then
            ly := (lh div 2)
          else
            ly := cfgsc.Ymax - (lh div 2);
        end
        else
        begin
          ly := round(yy);
          if xx < (cfgsc.Xmax div 2) then
            lx := (lh div 2)
          else
            lx := cfgsc.Xmax - (lh div 2);
        end;
        if ddh <= 5 * minarc then
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            detostr(h * rad2deg), cfgsc.WhiteBg, True, True, 5)
        else
          Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laBottom,
            demtostr(h * rad2deg), cfgsc.WhiteBg, True, True, 5);
        labelok := True;
      end;
      xxp := xx;
      yyp := yy;
    until (xx < -cfgsc.Xmax) or (xx > 2 * cfgsc.Xmax) or (yy < -cfgsc.Ymax) or
      (yy > 2 * cfgsc.Ymax) or (a > a1 + pi) or (a < a1 - pi);
    Result := (n > 1);
  end;

  // Tskychart.DrawEclGrid
begin
  DrawPole(Ecl);
  col := Fplot.cfgplot.Color[12];
  n := cfgsc.FieldNum;
  ddh := Fcatalog.cfgshr.DegreeGridSpacing[n];
  lda1 := ddh * cos(cfgsc.becentre);
  lda2 := lda1;
  while (lda1 < ddh) and (n < MaxField) do
  begin
    lda2 := lda1;
    n := n + 1;
    lda1 := Fcatalog.cfgshr.DegreeGridSpacing[n] * cos(cfgsc.becentre);
  end;
  lda1 := abs(ddh - lda1);
  lda2 := abs(ddh - lda2);
  if lda2 < lda1 then
    n := min(n - 1, MaxField);
  dda := Fcatalog.cfgshr.DegreeGridSpacing[n];
  a1 := deg2rad * trunc(rad2deg * cfgsc.lecentre / dda) * dda;
  h1 := deg2rad * trunc(rad2deg * cfgsc.becentre / ddh) * ddh;
  dda := deg2rad * dda;
  ddh := deg2rad * ddh;
  ac := a1;
  hc := h1;
  lh := 2 * fplot.GetTextSize(1, '1', 7).cy;
  lt := round(abs(1.2 * cfgsc.BxGlb * ddh / 3));
  dir := 1;
  rot := rmod(720 + rad2deg * CenterRot, 360);
  case round(rot) of
    0..45: if cfgsc.becentre > 0 then
        dir := 1
      else
        dir := 2;
    46..135: if cfgsc.becentre > 0 then
        dir := 4
      else
        dir := 3;
    136..225: if cfgsc.becentre > 0 then
        dir := 2
      else
        dir := 1;
    226..315: if cfgsc.becentre > 0 then
        dir := 3
      else
        dir := 4;
    316..360: if cfgsc.becentre > 0 then
        dir := 1
      else
        dir := 2;
  end;
  repeat
    labelok := False;
    if cfgsc.becentre > 0 then
    begin
      ok := DrawAline(ac, hc, -ddh);
      ok := DrawAline(ac, hc, ddh) or ok;
    end
    else
    begin
      ok := DrawAline(ac, hc, ddh);
      ok := DrawAline(ac, hc, -ddh) or ok;
    end;
    ac := ac + dda;
  until (not ok) or (ac > a1 + pi);
  ac := a1;
  hc := h1;
  repeat
    labelok := False;
    if cfgsc.becentre > 0 then
    begin
      ok := DrawAline(ac, hc, -ddh);
      ok := DrawAline(ac, hc, ddh) or ok;
    end
    else
    begin
      ok := DrawAline(ac, hc, ddh);
      ok := DrawAline(ac, hc, -ddh) or ok;
    end;
    ac := ac - dda;
  until (not ok) or (ac < a1 - pi);
  ac := a1;
  hc := h1;
  col := Fplot.cfgplot.Color[12];
  lt := round(abs(1.2 * cfgsc.BxGlb * dda / 3));
  repeat
    labelok := False;
    ok := DrawHline(ac, hc, -dda);
    ok := DrawHline(ac, hc, dda) or ok;
    hc := hc + ddh;
  until (not ok) or (hc > pid2);
  ac := a1;
  hc := h1;
  repeat
    labelok := False;
    ok := DrawHline(ac, hc, -dda);
    ok := DrawHline(ac, hc, dda) or ok;
    hc := hc - ddh;
  until (not ok) or (hc < -pid2);
end;

procedure Tskychart.GetLabPos(ra, Dec, r: double; w, h: integer; var x, y: integer);
var
  x1, y1: double;
  xxx, yyy: single;
  rr, xx, yy, o, hh: integer;
begin
  // no precession, the label position is already for the rigth equinox
  projection(ra, Dec, x1, y1, false, cfgsc);
  WindowXY(x1, y1, xxx, yyy, cfgsc);
  rr := round(r * cfgsc.BxGlb);
  xx := RoundInt(xxx);
  yy := RoundInt(yyy);
  x := xx;
  y := yy;
  if (xx >= cfgsc.Xmin) and (xx <= cfgsc.Xmax) and (yy >= cfgsc.Ymin) and (yy <= cfgsc.Ymax) then
  begin
    o := 1;
    hh := (h div 2);
    if (o = 1) and ((xx + w) > cfgsc.Xmax) then
      o := 0;
    if (o = 0) and ((xx - w) < cfgsc.Xmin) then
      o := 1;
    if hh > (cfgsc.Ymax - yy) then
      hh := h;
    if (yy - hh) < (cfgsc.Ymin + 1) then
      hh := yy + cfgsc.Ymin + 1;
    case o of
      0:
      begin                    // to the left
        x := xx - rr - labspacing - w;
        y := y - hh;
      end;
      1:
      begin                    // to the right
        x := xx + rr + labspacing;
        y := y - hh;
      end;
    end;
  end;
end;

function Tskychart.DrawConstL: boolean;
var
  xx1, yy1, xx2, yy2, ra1, de1, ra2, de2: double;
  cyear, dyear, r1, r2, d: double;
  i, color: integer;
  pmok: boolean;
  x1, y1, x2, y2: single;
  distfact: double;
begin
  Result := False;
  if not cfgsc.ShowConstl then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw constellation figures');
  color := Fplot.cfgplot.Color[16];
  dyear := 0;
  if cfgsc.PMon then
  begin
    cyear := cfgsc.CurYear + DayofYear(cfgsc.CurYear, cfgsc.CurMonth, cfgsc.CurDay) / 365.25;
    dyear := cyear - Fcatalog.cfgshr.ConstLepoch;
  end;
  for i := 0 to Fcatalog.cfgshr.ConstLnum - 1 do
  begin
    ra1 := Fcatalog.cfgshr.ConstL[i].ra1;
    de1 := Fcatalog.cfgshr.ConstL[i].de1;
    ra2 := Fcatalog.cfgshr.ConstL[i].ra2;
    de2 := Fcatalog.cfgshr.ConstL[i].de2;
    pmok := Fcatalog.cfgshr.ConstL[i].pm;
    if pmok and cfgsc.PMon then
    begin
      propermotion(ra1, de1, dyear, Fcatalog.cfgshr.ConstL[i].pmra1,
        Fcatalog.cfgshr.ConstL[i].pmde1, Fcatalog.cfgshr.ConstL[i].pxrv1,
        Fcatalog.cfgshr.ConstL[i].px1, Fcatalog.cfgshr.ConstL[i].rv1,distfact);
      propermotion(ra2, de2, dyear, Fcatalog.cfgshr.ConstL[i].pmra2,
        Fcatalog.cfgshr.ConstL[i].pmde2, Fcatalog.cfgshr.ConstL[i].pxrv2,
        Fcatalog.cfgshr.ConstL[i].px2, Fcatalog.cfgshr.ConstL[i].rv2,distfact);
    end;
    precession(jd2000, cfgsc.JDChart, ra1, de1);
    if cfgsc.ApparentPos then
      apparent_equatorial(ra1, de1, cfgsc, True, False);
    projection(ra1, de1, xx1, yy1, True, cfgsc);
    precession(jd2000, cfgsc.JDChart, ra2, de2);
    if cfgsc.ApparentPos then
      apparent_equatorial(ra2, de2, cfgsc, True, False);
    projection(ra2, de2, xx2, yy2, True, cfgsc);
    r1 := rad2deg * abs(xx1 - xx2);
    r2 := rad2deg * abs(yy1 - yy2);
    d := sqrt(r1 * r1 + r2 * r2);
    if (xx1 < 199) and (xx2 < 199) and (d < 50) then
    begin
      WindowXY(xx1, yy1, x1, y1, cfgsc);
      WindowXY(xx2, yy2, x2, y2, cfgsc);
      if (intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2 then
        FPlot.PlotLine(x1, y1, x2, y2, color, cfgsc.LineWidthConstL, cfgsc.StyleConstL);
    end;
  end;
  Result := True;
end;

function Tskychart.DrawConstB: boolean;
var
  dm, xx, yy, ra, de: double;
  i, color: integer;
  x1, y1, x2, y2: single;
begin
  Result := False;
  if not cfgsc.ShowConstB then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw constellation boundaries');
  dm := max(cfgsc.fov, 0.1);
  color := Fplot.cfgplot.Color[17];
  x1 := 0;
  y1 := 0;
  for i := 0 to Fcatalog.cfgshr.ConstBnum - 1 do
  begin
    ra := Fcatalog.cfgshr.ConstB[i].ra;
    de := Fcatalog.cfgshr.ConstB[i].de;
    if Fcatalog.cfgshr.ConstB[i].newconst then
      x1 := maxint;
    precession(jd2000, cfgsc.JDChart, ra, de);
    if cfgsc.ApparentPos then
      apparent_equatorial(ra, de, cfgsc, True, False);
    projection(ra, de, xx, yy, True, cfgsc);
    if (xx < 199) then
    begin
      WindowXY(xx, yy, x2, y2, cfgsc);
      if (x1 < maxint) and (abs(xx) < dm) and (abs(yy) < dm) and
        ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
        FPlot.PlotLine(x1, y1, x2, y2, color, cfgsc.LineWidthConstB, cfgsc.StyleConstB);
      x1 := x2;
      y1 := y2;
    end
    else
      x1 := maxint;
  end;
  Result := True;
end;

function Tskychart.DrawEcliptic: boolean;
var
  l, b, e, ar, de, xx, yy: double;
  i, color, mult: integer;
  x1, y1, x2, y2: single;
  First: boolean;
begin
  Result := False;
  if not cfgsc.ShowEclipticValid then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw ecliptic line');
  e := cfgsc.ecl;
  b := 0;
  First := True;
  color := Fplot.cfgplot.Color[14];
  x1 := 0;
  y1 := 0;
  if (cfgsc.fov * rad2deg) > 180 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 90 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 30 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 10 then
    mult := 3
  else if (cfgsc.fov * rad2deg) > 5 then
    mult := 2
  else
    mult := 1;
  for i := 0 to (360 div mult) do
  begin
    l := deg2rad * i * mult;
    ecl2eq(l, b, e, ar, de);
    if cfgsc.ApparentPos then
      apparent_equatorial(ar, de, cfgsc, False, False);
    projection(ar, de, xx, yy, True, cfgsc);
    WindowXY(xx, yy, x2, y2, cfgsc);
    if First then
      First := False
    else
    begin
      if ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
        FPlot.PlotLine(x1, y1, x2, y2, color, cfgsc.LineWidthEcliptic, cfgsc.StyleEcliptic);
    end;
    x1 := x2;
    y1 := y2;
  end;
  Result := True;
end;

function Tskychart.DrawGalactic: boolean;
var
  l, b, ar, de, xx, yy: double;
  i, color, mult: integer;
  x1, y1, x2, y2: single;
  First: boolean;
begin
  Result := False;
  if not cfgsc.ShowGalactic then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw galactic line');
  b := 0;
  First := True;
  color := Fplot.cfgplot.Color[15];
  x1 := 0;
  y1 := 0;
  if (cfgsc.fov * rad2deg) > 180 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 90 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 30 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 10 then
    mult := 3
  else if (cfgsc.fov * rad2deg) > 5 then
    mult := 2
  else
    mult := 1;
  for i := 0 to (360 div mult) do
  begin
    l := deg2rad * i * mult;
    gal2eq(l, b, ar, de, cfgsc);
    if cfgsc.ApparentPos then
      apparent_equatorial(ar, de, cfgsc, False, False);
    projection(ar, de, xx, yy, True, cfgsc);
    WindowXY(xx, yy, x2, y2, cfgsc);
    if First then
    begin
      First := False;
    end
    else
    begin
      if ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
        FPlot.PlotLine(x1, y1, x2, y2, color, cfgsc.LineWidthGalEq, cfgsc.StyleGalEq);
    end;
    x1 := x2;
    y1 := y2;
  end;
  Result := True;
end;

function Tskychart.DrawEquator: boolean;
var
  l, b, ar, de, xx, yy: double;
  i, color, mult: integer;
  x1, y1, x2, y2: single;
  First: boolean;
begin
  Result := False;
  if not cfgsc.ShowEquator then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw equator line');
  b := 0;
  First := True;
  color := Fplot.cfgplot.Color[15];
  x1 := 0;
  y1 := 0;
  if (cfgsc.fov * rad2deg) > 180 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 90 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 30 then
    mult := 5
  else if (cfgsc.fov * rad2deg) > 10 then
    mult := 3
  else if (cfgsc.fov * rad2deg) > 5 then
    mult := 2
  else
    mult := 1;
  for i := 0 to (360 div mult) do
  begin
    ar := deg2rad * i * mult;
    de := 0;
    if cfgsc.ApparentPos then
      apparent_equatorial(ar, de, cfgsc, False, False);
    projection(ar, de, xx, yy, True, cfgsc);
    WindowXY(xx, yy, x2, y2, cfgsc);
    if First then
    begin
      First := False;
    end
    else
    begin
      if ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
        FPlot.PlotLine(x1, y1, x2, y2, color, cfgsc.LineWidthEqGrid, cfgsc.StyleEqGrid);
    end;
    x1 := x2;
    y1 := y2;
  end;
  Result := True;
end;

{ TODO : Check FPC bug on ARM }
{$IFDEF CPUARM}
{$OPTIMIZATION NOREGVAR}
{$ENDIF}
function Tskychart.DrawPlanisphereDate: boolean;
var
  ar, de, de1, de11, de2, de3, b, b1, b11, b2, b3, xxm, yym, xx2, yy2, xx4, yy4, xx6, yy6: double;
  et, eq, dd, th: double;
  m, md, i, h, color, lx, ly, rot: integer;
  xm, ym, x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6: single;
  First: boolean;
  mask: TBGRABitmap;
  cbg, ctr: TBGRAPixel;
  pt: array[0..365] of TPointF;
  txt: string;

const
  day2deg = 360 / 365;
  hrefr = 34 / 60;
begin
  Result := False;
  if not cfgsc.PlanisphereDate then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw planisphere date');
  th := Fplot.cfgplot.FontSize[1] * Fplot.cfgchart.fontscale * 96 / 72;
  th := 1.2 * rad2deg * th / cfgsc.BxGlb;
  if cfgsc.ObsLatitude > 0 then
  begin
    b := cfgsc.ObsLatitude - 90 - hrefr;
    b1 := b - th / 8;
    b11 := b - th / 4;
    b2 := b - th;
    b3 := b2 - th;
  end
  else
  begin
    b := cfgsc.ObsLatitude + 90 + hrefr;
    b1 := b + th / 8;
    b11 := b + th / 4;
    b2 := b + th;
    b3 := b2 + th;
  end;

  { TODO : Compute the following values to allow to make planisphere for other centuries. }
  eq := 79.5; // mean equinox day number (March 20 12h)
  et := 440;  // equation of time on the equinox day (7m20s)
  dd := eq + et / 240;  // day number corresponding to RA=0

  // mask , use same polygone as date
  for i := 0 to 365 do
  begin
    ar := deg2rad * day2deg * (i - dd);
    ar := rmod(ar + pi2, pi2);
    de := deg2rad * b;
    projection(ar, de, xx2, yy2, True, cfgsc);
    WindowXY(xx2, yy2, x2, y2, cfgsc);
    pt[i].x := x2;
    pt[i].y := y2;
  end;
  cbg := ColorToBGRA(fplot.cfgplot.bgcolor);
  ctr := ColorToBGRA(clBlack);
  mask := TBGRABitmap.Create(fplot.cfgchart.Width, fplot.cfgchart.Height, cbg);
  Mask.FillPoly(pt, ctr, dmSet);
  Fplot.PlotImage(Mask.Width / 2, Mask.Height / 2, Mask.Width, Mask.Height, 0,
    1, 1, False, True, mask, 2);
  Mask.Free;
  color := Fplot.cfgplot.Color[15];
  // date scale
  First := True;
  x1 := 0;
  y1 := 0;
  x3 := 0;
  y3 := 0;
  m := 1;
  md := 1;
  for i := 0 to 365 do
  begin
    ar := deg2rad * day2deg * (i - dd);
    ar := rmod(ar + pi2, pi2);
    de := deg2rad * b;
    de1 := deg2rad * b1;
    de11 := deg2rad * b11;
    de2 := deg2rad * b2;
    projection(ar, de, xx2, yy2, True, cfgsc);
    WindowXY(xx2, yy2, x2, y2, cfgsc);
    projection(ar, de2, xx4, yy4, True, cfgsc);
    WindowXY(xx4, yy4, x4, y4, cfgsc);
    if (md mod 5) = 0 then
      projection(ar, de11, xxm, yym, True, cfgsc)
    else
      projection(ar, de1, xxm, yym, True, cfgsc);
    WindowXY(xxm, yym, xm, ym, cfgsc);
    if First then
      First := False
    else
    begin
      if ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
      begin
        FPlot.PlotLine(x1, y1, x2, y2, color, 1);
        FPlot.PlotLine(x2, y2, xm, ym, color, 1);
        FPlot.PlotLine(x3, y3, x4, y4, color, 1);
      end;
      if i = MonthStart[m] then
      begin
        FPlot.PlotLine(x2, y2, x4, y4, color, 1);
        md := 1;
      end;
      if i = (MonthStart[m] + 20) then
      begin
        txt := MonthName[m];
        lx := round(x2);
        ly := round(y2);
        rot := round(rad2deg * RotationAngle(xx4, yy4, xx2, yy2, cfgsc)) + 5;
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laTop,
          txt, cfgsc.WhiteBg, False, False, 0, rot);
        Inc(m);
      end;
    end;
    Inc(md);
    x1 := x2;
    y1 := y2;
    x3 := x4;
    y3 := y4;
  end;
  // RA scale
  First := True;
  h := 0;
  x3 := 0;
  y3 := 0;
  x5 := 0;
  y5 := 0;
  for i := 0 to 360 do
  begin
    ar := deg2rad * i;
    de2 := deg2rad * b2;
    de3 := deg2rad * b3;
    projection(ar, de2, xx4, yy4, True, cfgsc);
    WindowXY(xx4, yy4, x4, y4, cfgsc);
    projection(ar, de3, xx6, yy6, True, cfgsc);
    WindowXY(xx6, yy6, x6, y6, cfgsc);
    if First then
      First := False
    else
    begin
      if ((intpower(x4 - x3, 2) + intpower(y4 - y3, 2)) < cfgsc.x2) then
      begin
        FPlot.PlotLine(x5, y5, x6, y6, color, 1);
      end;
      if (i mod 15) = 0 then
      begin
        FPlot.PlotLine(x4, y4, x6, y6, color, 1);
        h := i div 15;
      end;
      if (i mod 15) = 5 then
      begin
        txt := IntToStr(h) + 'h';
        lx := round(x4);
        ly := round(y4);
        rot := round(rad2deg * RotationAngle(xx6, yy6, xx4, yy4, cfgsc));
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft,
          laTop, txt, cfgsc.WhiteBg, False, False, 0, rot);
      end;
    end;
    x3 := x4;
    y3 := y4;
    x5 := x6;
    y5 := y6;
  end;
  Result := True;
end;

function Tskychart.DrawPlanisphereTime: boolean;
var
  ar, de, de1, de11, de2, b, b1, b11, b2, xxm, yym, xx2, yy2, xx4, yy4, th, st: double;
  i, h, color, lx, ly, rot: integer;
  xm, ym, x1, y1, x2, y2, x4, y4: single;
  First: boolean;
  mask: TBGRABitmap;
  cbg, ctr: TBGRAPixel;
  pt: array[0..288] of TPointF;
  txt: string;

const
  hrefr = 34 / 60;
begin
  Result := False;
  if not cfgsc.PlanisphereTime then
    exit;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw planisphere time');
  th := Fplot.cfgplot.FontSize[1] * Fplot.cfgchart.fontscale * 96 / 72;
  th := 1.2 * rad2deg * th / cfgsc.BxGlb;
  if cfgsc.ObsLatitude > 0 then
  begin
    b := cfgsc.ObsLatitude - 90 - hrefr;
    b1 := b + th / 8;
    b11 := b + th / 4;
    b2 := b + th;
  end
  else
  begin
    b := cfgsc.ObsLatitude + 90 + hrefr;
    b1 := b - th / 8;
    b11 := b - th / 4;
    b2 := b - th;
  end;
  st := cfgsc.CurST;
  // mask
  for i := 0 to 288 do
  begin
    ar := st - pi + deg2rad * i * 360 / 288;
    ar := rmod(ar + pi2, pi2);
    de := deg2rad * b;
    projection(ar, de, xx2, yy2, True, cfgsc);
    WindowXY(xx2, yy2, x2, y2, cfgsc);
    pt[i].x := x2;
    pt[i].y := y2;
  end;
  cbg := ColorToBGRA(fplot.cfgplot.bgcolor);
  ctr := ColorToBGRA(clBlack);
  mask := TBGRABitmap.Create(fplot.cfgchart.Width, fplot.cfgchart.Height, cbg);
  Mask.FillPoly(pt, ctr, dmSet);
  Fplot.PlotImage(Mask.Width / 2, Mask.Height / 2, Mask.Width, Mask.Height, 0,
    1, 1, False, True, mask, 2);
  Mask.Free;
  color := Fplot.cfgplot.Color[15];
  // Time scale
  First := True;
  x1 := 0;
  y1 := 0;
  for i := 0 to 288 do
  begin //  1/288 = 5 minutes
    ar := st - pi + deg2rad * i * 360 / 288;
    ar := rmod(ar + pi2, pi2);
    de := deg2rad * b;
    de1 := deg2rad * b1;
    de11 := deg2rad * b11;
    de2 := deg2rad * b2;
    projection(ar, de, xx2, yy2, True, cfgsc);
    WindowXY(xx2, yy2, x2, y2, cfgsc);
    projection(ar, de2, xx4, yy4, True, cfgsc);
    WindowXY(xx4, yy4, x4, y4, cfgsc);
    if (i mod 3) = 0 then
      projection(ar, de11, xxm, yym, True, cfgsc)
    else
      projection(ar, de1, xxm, yym, True, cfgsc);
    WindowXY(xxm, yym, xm, ym, cfgsc);
    if First then
      First := False
    else
    begin
      if ((intpower(x2 - x1, 2) + intpower(y2 - y1, 2)) < cfgsc.x2) then
      begin
        FPlot.PlotLine(x1, y1, x2, y2, color, 1);
        FPlot.PlotLine(x2, y2, xm, ym, color, 1);
      end;
      if (i mod 12) = 0 then
      begin
        FPlot.PlotLine(x2, y2, x4, y4, color, 1);
        h := 24 - (i div 12);
        txt := IntToStr(h) + 'h';
        lx := round(x2);
        ly := round(y2);
        rot := round(rad2deg * RotationAngle(xx4, yy4, xx2, yy2, cfgsc)) + 5;
        Fplot.PlotText(lx, ly, 1, Fplot.cfgplot.LabelColor[7], laLeft, laTop,
          txt, cfgsc.WhiteBg, False, False, 0, rot);
      end;
    end;
    x1 := x2;
    y1 := y2;
  end;
  Result := True;
end;

{$IFDEF CPUARM}
{$OPTIMIZATION DEFAULT}
{$ENDIF}

procedure Tskychart.InitLabels;
var
  i, lid: integer;
  xx, yy: single;
  ra, de, x1, y1: double;
  lis: string;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Init labels');
  numlabels := 0;
  numdsopos := 0;
  for i := 0 to Fcatalog.cfgshr.ConstelNum - 1 do
  begin
    ra := Fcatalog.cfgshr.ConstelPos[i].ra;
    de := Fcatalog.cfgshr.ConstelPos[i].de;
    precession(jd2000, cfgsc.JDChart, ra, de);
    projection(ra, de, x1, y1, True, cfgsc);
    WindowXY(x1, y1, xx, yy, cfgsc);
    lis := Fcatalog.cfgshr.ConstelName[i, 2] + FormatFloat(f6, ra) + FormatFloat(f6, de);
    lid := rshash(lis, $7FFFFFFF);
    if cfgsc.ConstFullLabel then
      SetLabel(lid, xx, yy, 0, 2, 6, Fcatalog.cfgshr.ConstelName[i, 2], laCenter,
        labrotation(ra, de, 6, cfgsc), 0, False)
    else
      SetLabel(lid, xx, yy, 0, 2, 6, Fcatalog.cfgshr.ConstelName[i, 1], laCenter,
        labrotation(ra, de, 6, cfgsc), 0, False);
  end;
  constlabelindex := numlabels;
end;

procedure Tskychart.SetLabel(id: integer; xx, yy: single; radius, fontnum, labelnum: integer;
  txt: string; align: TLabelAlign = laLeft; orient: single = 0; priority: integer = 5;
  opt: boolean = True; lsize: single = -1);
begin
{ Label priority is used during placement optimization.
  0 : Constellation
  1 : Planets
  2 : Main stars, variable and double stars, Messier objects
  3 : Other DSO
  4 : Fainter DSO, fainter stars , asteroid, comets, art. sat.
  5 : Other
}
  if (cfgsc.ShowLabel[labelnum]) and (numlabels < maxlabels) and (trim(txt) <> '') and
    (xx >= cfgsc.xmin) and (xx <= cfgsc.xmax) and (yy >= cfgsc.ymin) and (yy <= cfgsc.ymax) then
  begin
    Inc(numlabels);
    try
      labels[numlabels].id := id;
      labels[numlabels].priority := priority;
      labels[numlabels].lsize := lsize;
      labels[numlabels].x := xx;
      labels[numlabels].y := yy;
      labels[numlabels].r := radius;
      labels[numlabels].optimizable := opt;
      labels[numlabels].optimized := False;
      labels[numlabels].orientation := orient;
      labels[numlabels].align := align;
      labels[numlabels].labelnum := labelnum;
      labels[numlabels].fontnum := fontnum;
      labels[numlabels].txt := trim(wordspace(txt));
      labels[numlabels].px := -1000;
      labels[numlabels].py := -1000;
    except
      Dec(numlabels);
    end;
  end;
end;

procedure Tskychart.EditLabelPos(lnum, x, y, w, h: integer; moderadec: boolean);
var
  i, j, id: integer;
  labelnum, fontnum: byte;
  Lalign: TLabelAlign;
  orient: single;
  sina, cosa: extended;
  txt: string;
  ra, Dec: double;
begin
  i := -1;
  txt := labels[lnum].txt;
  labelnum := labels[lnum].labelnum;
  fontnum := labels[lnum].fontnum;
  Lalign := labels[lnum].align;
  orient := labels[lnum].orientation;
  id := labels[lnum].id;
  for j := 1 to cfgsc.nummodlabels do
    if id = cfgsc.modlabels[j].id then
    begin
      i := j;
      txt := cfgsc.modlabels[j].txt;
      labelnum := cfgsc.modlabels[j].labelnum;
      fontnum := cfgsc.modlabels[j].fontnum;
      Lalign := cfgsc.modlabels[j].align;
      orient := cfgsc.modlabels[j].orientation;
      break;
    end;
  if i < 0 then
  begin
    if cfgsc.nummodlabels < maxmodlabels then
      Inc(cfgsc.nummodlabels);
    if cfgsc.posmodlabels < maxmodlabels then
      Inc(cfgsc.posmodlabels)
    else
      cfgsc.posmodlabels := 1;
    i := cfgsc.posmodlabels;
  end;
  cfgsc.modlabels[i].useradec := moderadec;
  if orient <> 0 then
  begin
    sincos(deg2rad * orient, sina, cosa);
    if cosa < 0 then
      x := x + w;
    y := y + round(sina * h);
  end;
  if moderadec then
  begin
    GetADxy(x, y, ra, Dec, cfgsc);
    cfgsc.modlabels[i].ra := ra;
    cfgsc.modlabels[i].Dec := Dec;
  end
  else
  begin
    cfgsc.modlabels[i].dx := x - round(labels[lnum].x);
    cfgsc.modlabels[i].dy := y - round(labels[lnum].y);
  end;
  cfgsc.modlabels[i].txt := txt;
  cfgsc.modlabels[i].align := Lalign;
  cfgsc.modlabels[i].orientation := orient;
  cfgsc.modlabels[i].labelnum := labelnum;
  cfgsc.modlabels[i].fontnum := fontnum;
  cfgsc.modlabels[i].id := id;
  cfgsc.modlabels[i].hiden := False;
  Refresh(False);
end;

procedure Tskychart.EditLabelTxt(lnum, x, y, w, h: integer; mode: boolean);
var
  i, j, id: integer;
  labelnum, fontnum: byte;
  Lalign: TLabelAlign;
  orient: single;
  txt: string;
  f1: TForm;
  e1, e2: Tedit;
  l1: Tlabel;
  b1, b2: TButton;
begin
  i := -1;
  txt := labels[lnum].txt;
  labelnum := labels[lnum].labelnum;
  fontnum := labels[lnum].fontnum;
  Lalign := labels[lnum].align;
  orient := labels[lnum].orientation;
  id := labels[lnum].id;
  for j := 1 to cfgsc.nummodlabels do
    if id = cfgsc.modlabels[j].id then
    begin
      i := j;
      txt := cfgsc.modlabels[j].txt;
      labelnum := cfgsc.modlabels[j].labelnum;
      fontnum := cfgsc.modlabels[j].fontnum;
      Lalign := cfgsc.modlabels[j].align;
      orient := cfgsc.modlabels[j].orientation;
      break;
    end;
  f1 := TForm.Create(self);
  e1 := Tedit.Create(f1);
  e2 := Tedit.Create(f1);
  l1 := TLabel.Create(f1);
  b1 := TButton.Create(f1);
  b2 := TButton.Create(f1);
  try
    e1.Parent := f1;
    l1.Parent := f1;
    e2.Parent := f1;
    b1.Parent := f1;
    b2.Parent := f1;
    e1.Font.Name := fplot.cfgplot.FontName[fontnum];
    e1.Top := 8;
    e1.Left := 8;
    e1.Width := 150;
    l1.Top := e1.Top + e1.Height + 8;
    l1.Left := 8;
    l1.Caption := rsRotation;
    e2.Top := l1.top;
    e2.Left := l1.Width + 8;
    e2.Width := 50;
    b1.Width := 65;
    b2.Width := 65;
    b1.Top := e2.Top + e2.Height + 8;
    b2.Top := b1.Top;
    b1.Left := 8;
    b2.Left := b1.Left + b2.Width + 8;
    b1.Caption := rsOK;
    b2.Caption := rsCancel;
    b1.ModalResult := mrOk;
    b1.Default := True;
    b2.ModalResult := mrCancel;
    b2.Cancel := True;
    f1.ClientWidth := e1.Width + 16;
    f1.ClientHeight := b1.top + b1.Height + 8;
    e1.Text := txt;
    e2.Text := FormatFloat('0.0', orient);
    f1.BorderStyle := bsDialog;
    f1.Caption := rsEditLabel;
    ScaleDPI(f1);
    formpos(f1, x, y);
    if f1.ShowModal = mrOk then
    begin
      txt := e1.Text;
      if i < 0 then
      begin
        if cfgsc.nummodlabels < maxmodlabels then
          Inc(cfgsc.nummodlabels);
        if cfgsc.posmodlabels < maxmodlabels then
          Inc(cfgsc.posmodlabels)
        else
          cfgsc.posmodlabels := 1;
        i := cfgsc.posmodlabels;
        cfgsc.modlabels[i].useradec := False;
        cfgsc.modlabels[i].dx := 0;
        cfgsc.modlabels[i].dy := 0;
      end;
      cfgsc.modlabels[i].txt := txt;
      cfgsc.modlabels[i].align := Lalign;
      cfgsc.modlabels[i].orientation := StrToFloatDef(e2.Text, orient);
      cfgsc.modlabels[i].labelnum := labelnum;
      cfgsc.modlabels[i].fontnum := fontnum;
      cfgsc.modlabels[i].id := id;
      cfgsc.modlabels[i].hiden := False;
      if VerboseMsg then
        WriteTrace('EditLabelTxt');
      Refresh(False);
    end;
  finally
    e1.Free;
    b1.Free;
    b2.Free;
    f1.Free;
  end;
end;

procedure Tskychart.AddNewLabel(ra, Dec: double);
var
  i, lid: integer;
  x1, y1: double;
  x, y: single;
  fontnum: byte;
  txt, lis: string;
begin
  projection(ra, Dec, x1, y1, True, cfgsc);
  ra := NormRA(ra);
  WindowXY(x1, y1, x, y, cfgsc);
  fontnum := 2;
  if f_addlabel = nil then
    f_addlabel := Tf_addlabel.Create(application);
  formpos(f_addlabel, mouse.cursorpos.x, mouse.cursorpos.y);
  f_addlabel.ActiveControl := f_addlabel.Edit1;
  if f_addlabel.ShowModal = mrOk then
  begin
    txt := f_addlabel.txt;
    if cfgsc.numcustomlabels < maxmodlabels then
      Inc(cfgsc.numcustomlabels);
    if cfgsc.poscustomlabels < maxmodlabels then
      Inc(cfgsc.poscustomlabels)
    else
      cfgsc.poscustomlabels := 1;
    i := cfgsc.poscustomlabels;
    cfgsc.customlabels[i].ra := ra;
    cfgsc.customlabels[i].Dec := Dec;
    cfgsc.customlabels[i].labelnum := f_addlabel.labelnum;
    cfgsc.customlabels[i].txt := txt;
    cfgsc.customlabels[i].align := f_addlabel.Lalign;
    cfgsc.customlabels[i].orientation := labrotation(ra, Dec, f_addlabel.labelnum, cfgsc);
    lis := txt + FormatFloat(f6, ra) + FormatFloat(f6, Dec);
    lid := rshash(lis, $7FFFFFFF);
    SetLabel(lid, x, y, 0, fontnum, cfgsc.customlabels[i].labelnum, txt,
      cfgsc.customlabels[i].align, cfgsc.customlabels[i].orientation);
    DrawLabels;
    if VerboseMsg then
      WriteTrace('AddNewLabel');
    Refresh(False);
  end;
end;

procedure Tskychart.DeleteLabel(lnum: integer);
var
  i, j, id: integer;
  labelnum, fontnum: byte;
  Lalign: TLabelAlign;
  orient: single;
  txt: string;
begin
  i := -1;
  txt := labels[lnum].txt;
  labelnum := labels[lnum].labelnum;
  fontnum := labels[lnum].fontnum;
  Lalign := labels[lnum].align;
  orient := labels[lnum].orientation;
  id := labels[lnum].id;
  for j := 1 to cfgsc.nummodlabels do
    if id = cfgsc.modlabels[j].id then
    begin
      i := j;
      txt := cfgsc.modlabels[j].txt;
      labelnum := cfgsc.modlabels[j].labelnum;
      fontnum := cfgsc.modlabels[j].fontnum;
      Lalign := cfgsc.modlabels[j].align;
      orient := cfgsc.modlabels[j].orientation;
      break;
    end;
  if i < 0 then
  begin
    if cfgsc.nummodlabels < maxmodlabels then
      Inc(cfgsc.nummodlabels);
    if cfgsc.posmodlabels < maxmodlabels then
      Inc(cfgsc.posmodlabels)
    else
      cfgsc.posmodlabels := 1;
    i := cfgsc.posmodlabels;
  end;
  cfgsc.modlabels[i].useradec := False;
  cfgsc.modlabels[i].dx := 0;
  cfgsc.modlabels[i].dy := 0;
  cfgsc.modlabels[i].txt := txt;
  cfgsc.modlabels[i].align := Lalign;
  cfgsc.modlabels[i].orientation := orient;
  cfgsc.modlabels[i].labelnum := labelnum;
  cfgsc.modlabels[i].fontnum := fontnum;
  cfgsc.modlabels[i].id := id;
  cfgsc.modlabels[i].hiden := True;
  DrawLabels;
  Refresh(False);
end;

procedure Tskychart.ResetAllLabel;
begin
  cfgsc.nummodlabels := 0;
  cfgsc.posmodlabels := 0;
  cfgsc.poscustomlabels := 0;
  cfgsc.numcustomlabels := 0;
  Refresh(False);
end;

procedure Tskychart.DefaultLabel(lnum: integer);
var
  i, j, id: integer;
begin
  i := -1;
  id := labels[lnum].id;
  for j := 1 to cfgsc.nummodlabels do
    if id = cfgsc.modlabels[j].id then
    begin
      i := j;
      break;
    end;
  if i < 0 then
    exit;
  for j := i + 1 to cfgsc.nummodlabels do
    cfgsc.modlabels[j - 1] := cfgsc.modlabels[j];
  Dec(cfgsc.nummodlabels);
  cfgsc.posmodlabels := cfgsc.nummodlabels;
  DrawLabels;
  Refresh(False);
end;

procedure Tskychart.LabelClick(lnum: integer);
var
  x, y: integer;
begin
  x := round(labels[lnum].x);
  y := round(labels[lnum].y);
  if assigned(FShowDetailXY) then
    FShowDetailXY(x, y);
end;

procedure Tskychart.OptimizeLabels;
var
  labbox: array [0..maxlabels, 1..8] of TRect;
  obmp: TBitmap;
  ts: TSize;
  pass, i, j, k, l, lsp, maxtl: integer;
  x, y, r, dist, lsize: single;
  collision: boolean;
  safedistance: single;
const
  al: array[1..4] of TLabelAlign = (laTopLeft, laBottomLeft, laTopRight, laBottomRight);

  procedure SortLabels;
  var
    i, j, p: integer;
    tmplabel: array[1..maxlabels] of Tobjlabel;
  begin
    if numlabels < 2 then
      exit;
    // Need a stable sort here.
    // As the priority use a limited range of values we can use a trivial insertion.
    j := 1;
    for p := 0 to 5 do
      for i := 1 to numlabels do
        if labels[i].priority = p then
        begin
          tmplabel[j] := labels[i];
          Inc(j);
        end;
    for i := 1 to numlabels do
      labels[i] := tmplabel[i];
  end;

  function rectangleintersect(r1, r2: TRect): boolean;
  begin
    // find more performant solution ?
    Result := ((((r1.Left >= r2.Left) and (r1.Left <= r2.Right)) or
      ((r1.Right >= r2.Left) and (r1.Right <= r2.Right))) and
      (((r1.Top >= r2.Top) and (r1.Top <= r2.Bottom)) or
      ((r1.Bottom >= r2.Top) and (r1.Bottom <= r2.Bottom)))) or
      ((((r2.Left >= r1.Left) and (r2.Left <= r1.Right)) or
      ((r2.Right >= r1.Left) and (r2.Right <= r1.Right))) and
      (((r2.Top >= r1.Top) and (r2.Top <= r1.Bottom)) or
      ((r2.Bottom >= r1.Top) and (r2.Bottom <= r1.Bottom))));
  end;

  function pointinrectangle(p: Tpoint; r: trect): boolean;
  begin
    Result := ((p.X >= r.Left) and (p.X <= r.Right)) and ((p.Y >= r.Top) and (p.Y <= r.Bottom));
  end;

begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Optimize labels');
  obmp := TBitmap.Create;
  lsp := labspacing * Fplot.cfgchart.drawsize;
  maxtl := 0;
  // give high priority to moved or custom labels
  for j := 1 to cfgsc.nummodlabels do
    for i := 1 to numlabels do
      if labels[i].id = cfgsc.modlabels[j].id then
      begin
        labels[i].priority := 0;
        labels[i].optimizable := False;
        break;
      end;
  // sort labels by priority
  SortLabels;
  // compute text box
  labbox[1, 1].Top := 0;
  for i := 1 to numlabels do
  begin
    if (labels[i].lsize > 0) and ((nebmagmax - nebmagmin) >= 2) then
    begin
      if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) / 4)) then
        lsize := 0.8
      else if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) * 2 / 4)) then
        lsize := 0.9
      else if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) * 3 / 4)) then
        lsize := 1
      else
        lsize := 1.1;
    end
    else
      lsize := 1;
    ts := Fplot.GetTextSize(labels[i].fontnum, labels[i].txt, labels[i].labelnum, lsize);
    maxtl := max(maxtl, ts.cx);
    if labels[i].optimizable then
    begin
      labels[i].align := al[1];  // reset default position
      labels[i].r := labels[i].r / 1.414; // label always in corner
    end;
    r := labels[i].r;
    if r = 0 then
      r := lsp;
    x := labels[i].x;
    y := labels[i].y;
    // TopLeft
    labbox[i, 1].Top := round(y - ts.cy - r) - 1;
    labbox[i, 1].Bottom := round(y + r) + 1;
    labbox[i, 1].Left := round(x + r) - 1;
    labbox[i, 1].Right := round(x + ts.cx + r) + 1;
    // BottomLeft
    labbox[i, 2].Top := round(y - r) - 1;
    labbox[i, 2].Bottom := round(y + ts.cy + r) + 1;
    labbox[i, 2].Left := round(x + r) - 1;
    labbox[i, 2].Right := round(x + ts.cx + r) + 1;
    // TopRight
    labbox[i, 3].Top := round(y - ts.cy - r) - 1;
    labbox[i, 3].Bottom := round(y + r) + 1;
    labbox[i, 3].Left := round(x - ts.cx - r) - 1;
    labbox[i, 3].Right := round(x - r) + 1;
    // BottomRight
    labbox[i, 4].Top := round(y - r) - 1;
    labbox[i, 4].Bottom := round(y + ts.cy + r) + 1;
    labbox[i, 4].Left := round(x - ts.cx - r) - 1;
    labbox[i, 4].Right := round(x - r) + 1;
  end;
  obmp.Free;
  safedistance := max(2 * maxtl, 200.0 * Fplot.cfgchart.drawpen);
  // label position and exclusion
  // pass 1 for high priority (>2) labels only
  for pass := 1 to 2 do
    for i := 1 to numlabels do
    begin
      if not labels[i].optimizable then
        continue; // not for planet simulation
      if (pass = 1) and (labels[i].priority > 2) then
        continue;
      if labels[i].optimized then
        continue;
      for j := 1 to 4 do
      begin
        collision := False;
        for k := 1 to numlabels do
        begin
          if k = i then
            continue;
          if (pass = 1) and (labels[k].priority > 2) then
            continue;
          if labels[i].priority < labels[k].priority then
            continue;
          if (pass > 1) and (not labels[k].optimized) then
            continue;
          dist := sqrt(sqr(labels[i].x - labels[k].x) + sqr(labels[i].y - labels[k].y));
          if dist < safedistance then
          begin
            for l := 1 to 4 do
            begin
              if labels[k].align = al[l] then
              begin
                // conflict with other label
                collision := rectangleintersect(labbox[i, j], labbox[k, l]);
                if collision then
                  break;
              end;
            end;
          end;
          if collision then
            break;
        end;
        if (not collision) and (labels[i].priority > 2) then
          for k := 1 to numdsopos do
          begin
            // conflict with DSO
            collision := pointinrectangle(dsopos[k], labbox[i, j]);
            if collision then
              break;
          end;
        if not collision then
        begin
          labels[i].align := al[j];
          labels[i].optimized := True;
          break;
        end;
      end;
      if collision and (pass = 2) then
      begin
        labels[i].x := -1000;
      end;
    end;
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': Labels optimized');
end;

function Tskychart.DrawLabels: boolean;
var
  i, j: integer;
  x, y, r, x0, y0, orient, lsize: single;
  x1, y1: double;
  labelnum, fontnum: byte;
  txt: string;
  skiplabel: boolean;
  al, av: TLabelAlign;
  ts: TSize;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw labels');
  Fplot.InitLabel;
  DrawObsListLabel;
  DrawCustomlabel;
  if cfgsc.OptimizeLabels then
    OptimizeLabels;
  nebmagmin := max(4, nebmagmin);
  for i := 1 to numlabels do
  begin
    if labels[i].x < -900 then
      continue; // label removed by optimization
    skiplabel := False;
    x := labels[i].x;
    y := labels[i].y;
    x0 := x;
    y0 := y;
    r := labels[i].r;
    al := labels[i].align;
    av := laCenter;
    if al = laNone then
      al := laLeft;
    if al = laTopLeft then
    begin
      al := laLeft;
      av := laTop;
    end;
    if al = laBottomLeft then
    begin
      al := laLeft;
      av := laBottom;
    end;
    if al = laTopRight then
    begin
      al := laRight;
      av := laTop;
    end;
    if al = laBottomRight then
    begin
      al := laRight;
      av := laBottom;
    end;
    if al = laTop then
    begin
      al := laCenter;
      av := laTop;
    end;
    if al = laBottom then
    begin
      al := laCenter;
      av := laBottom;
    end;
    txt := labels[i].txt;
    labelnum := labels[i].labelnum;
    fontnum := labels[i].fontnum;
    orient := labels[i].orientation;
    for j := 1 to cfgsc.nummodlabels do
      if labels[i].id = cfgsc.modlabels[j].id then
      begin
        skiplabel := cfgsc.modlabels[j].hiden;
        orient := cfgsc.modlabels[j].orientation;
        if i > constlabelindex then
          txt := cfgsc.modlabels[j].txt;
        if cfgsc.modlabels[j].useradec then
        begin
          projection(cfgsc.modlabels[j].ra, cfgsc.modlabels[j].Dec, x1, y1, False, cfgsc);
          WindowXY(x1, y1, x, y, cfgsc);
          r := -1;
        end
        else
        begin
          x := x + cfgsc.modlabels[j].dx * Fplot.cfgchart.drawsize;
          y := y + cfgsc.modlabels[j].dy * Fplot.cfgchart.drawsize;
        end;
        if (cfgsc.modlabels[j].dx <> 0) or (cfgsc.modlabels[j].dy <> 0) then
          r := -1;
        break;
      end;
    if not skiplabel then
    begin
      if cfgsc.OptimizeLabels and (labels[i].lsize > 0) and ((nebmagmax - nebmagmin) >= 2) then
      begin
        if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) / 4)) then
          lsize := 0.8
        else if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) * 2 / 4)) then
          lsize := 0.9
        else if labels[i].lsize > (nebmagmax - ((nebmagmax - nebmagmin) * 3 / 4)) then
          lsize := 1
        else
          lsize := 1.1;
      end
      else
        lsize := 1;
      Fplot.PlotLabel(i, labelnum, fontnum, x, y, r, orient, al, av, cfgsc.WhiteBg,
        (not cfgsc.Editlabels), txt, labels[i].px, labels[i].py, lsize);
      if cfgsc.MovedLabelLine and (i > constlabelindex) and
        (sqrt((x - x0) * (x - x0) + (y - y0) * (y - y0)) > 30) then
      begin
        if Fplot.cfgplot.UseBMP then
          ts := Fplot.cbmp.TextSize(txt)
        else
          ts := Fplot.cnv.TextExtent(txt);
        Fplot.PlotLine(x0, y0, x + ts.cx / 2, y + ts.cy / 2, Fplot.cfgplot.color[15], 1, psdot);
      end;
    end;
  end;
  Result := True;
end;

procedure Tskychart.DrawLegend;
var
  lbmp: TBGRABitmap;
  saveubmp: boolean;
  savecbmp: TBGRABitmap;
  savefontscale: single;
  savefontsize: integer;
  col: TBGRAPixel;
  txtl, txt, buf: string;
  drawgray: boolean;
  w, h, h0, fontnum, labelnum, p, lsp, ls, ws, i, xx, yy, sz, tr: integer;
  mag, dma: double;
  ts: TSize;
  lcol: Tcolor;
begin
  if cfgsc.FooterHeight > 0 then
  begin
    fontnum := 3;
    labelnum := 8;
    if cfgsc.WhiteBg then
      lcol := clBlack
    else
      lcol := Fplot.cfgplot.backgroundcolor xor $FFFFFF;
    savefontsize := Fplot.cfgplot.FontSize[fontnum];
    try
      // chart info
      txt := GetChartInfo(', ');
      ts := Fplot.GetTextSize(6, txt);
      xx := Fplot.cfgchart.Width div 2;
      yy := Fplot.cfgchart.Height - cfgsc.BottomMargin + round(ts.cy * 1.2);
      Fplot.PlotText(xx, yy, 6, Fplot.cfgplot.LabelColor[8], laCenter, laBottom, txt,
        cfgsc.WhiteBg);
      // legend
      if (ts.cy) < (cfgsc.FooterHeight / 3.6) then
        h0 := yy + round(ts.cy / 2)
      else
        h0 := yy;
      Fplot.PlotLine(cfgsc.LeftMargin, h0, Fplot.cfgchart.Width - cfgsc.RightMargin, h0, lcol, 1);
      h0 := h0 + round(ts.cy);
      Fplot.cfgplot.FontSize[fontnum] := Fplot.cfgplot.FontSize[fontnum] - 2;
      sz := 8 * Fplot.cfgchart.drawsize;
      ls := 2 * sz;
      ws := round((Fplot.cfgchart.Width - cfgsc.LeftMargin - cfgsc.RightMargin) / (7 * 1.5 + 16 * 2));
      ts := Fplot.GetTextSize(fontnum, '1');
      ws := min(round(1.5 * ts.cy), ws);
      sz := min(sz, ws);
      yy := h0;
      xx := cfgsc.LeftMargin + round((Fplot.cfgchart.Width - cfgsc.LeftMargin - cfgsc.RightMargin - ws *
        (7 * 1.5 + 16 * 2)) / 2);
      drawgray := False;
      dma := max(1, fplot.cfgchart.min_ma / 6);
      mag := -dma;
      // Stars magnitude
      for i := 0 to 6 do
      begin
        mag := mag + dma;
        xx := round(xx + 1.5 * ws);
        Fplot.PlotStar(xx, yy, mag, 0);
        Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
          laCenter, laCenter, IntToStr(round(mag)), cfgsc.WhiteBg, False);
      end;
      // Ast
      xx := round(xx + 2 * ws);
      mag := 5 * dma;
      Fplot.PlotAsteroid(xx, yy, cfgsc.AstSymbol, mag);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum], laCenter,
        laCenter, rsAbrevAsteroid, cfgsc.WhiteBg, False);
      // Com
      xx := round(xx + 2 * ws);
      mag := 4 * dma;
      Fplot.PlotComet(xx, yy, xx + sz, yy + sz, cfgsc.ComSymbol, mag, 1.5 * sz, 1);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevComet, cfgsc.WhiteBg, False);
      // Var
      xx := round(xx + 2 * ws);
      mag := 4 * dma;
      Fplot.PlotStar(xx, yy, mag, 0);
      Fplot.PlotVarStar(xx, yy, 0, mag);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevVariable, cfgsc.WhiteBg, False);
      // Dbl
      xx := round(xx + 2 * ws);
      mag := 4 * dma;
      Fplot.PlotDblStar(xx, yy, 0.8 * sz, mag, 0, -45, 0);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevDouble, cfgsc.WhiteBg, False);
      // Drk
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 13, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevDark, cfgsc.WhiteBg, False);
      // Gcl
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 12, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevGalaxyCluster, cfgsc.WhiteBg, False);
      // GX
      xx := round(xx + 2 * ws);
      Fplot.PlotDSOGxy(xx, yy, sz, sz div 3, 45, 0, 100, 100, 0, 0, 1, 3600, '', drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevGalaxy, cfgsc.WhiteBg, False);
      // OC
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 2, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevOpenCluster, cfgsc.WhiteBg, False);
      // GB
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 3, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevGlobularCluster, cfgsc.WhiteBg, False);
      // PL
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 4, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevPlanetaryNebula, cfgsc.WhiteBg, False);
      // NB
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 5, '', cfgsc.WhiteBg, drawgray, clGray,cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevNebula, cfgsc.WhiteBg, False);
      // C+N
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 6, '', cfgsc.WhiteBg, drawgray, clGray, cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, rsAbrevClusterNebula, cfgsc.WhiteBg, False);
      // *
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 7, '', cfgsc.WhiteBg, drawgray, clGray, cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, nebtype[9], cfgsc.WhiteBg, False);
      // ?
      xx := round(xx + 2 * ws);
      Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 0, '', cfgsc.WhiteBg, drawgray, clGray, cfgsc.SurfaceAlpha);
      Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
        laCenter, laCenter, nebtype[2], cfgsc.WhiteBg, False);
    finally
      Fplot.cfgplot.FontSize[fontnum] := savefontsize;
    end;
  end
  else
  begin
    fontnum := 3;
    labelnum := 8;
    // Save setting
    savecbmp := Fplot.cbmp;
    saveubmp := Fplot.cfgplot.UseBMP;
    savefontscale := Fplot.cfgchart.fontscale;
    savefontsize := Fplot.cfgplot.FontSize[fontnum];
    lbmp := TBGRABitmap.Create;
    txtl := GetChartInfo(crlf);
    txt := txtl;
    // get box size
    lbmp.FontHeight := trunc(Fplot.cfgplot.LabelSize[labelnum] * Fplot.cfgchart.drawsize * 96 / 72);
    if Fplot.cfgplot.FontBold[fontnum] then
      lbmp.FontStyle := [fsBold]
    else
      lbmp.FontStyle := [];
    if Fplot.cfgplot.FontItalic[fontnum] then
      lbmp.FontStyle := lbmp.FontStyle + [fsItalic];
    lbmp.FontName := Fplot.cfgplot.FontName[fontnum];
    ts := lbmp.TextSize('1');
    ls := ts.cy;
    w := 0;
    h := ls;
    if cfgsc.showlabel[8] then
    begin
      repeat
        p := pos(crlf, txt);
        if p = 0 then
          buf := txt
        else
        begin
          buf := copy(txt, 1, p - 1);
          Delete(txt, 1, p + 1);
        end;
        ts := lbmp.TextSize(buf);
        w := max(w, round(1.1 * ts.cx));
        h := h + ls;
      until p = 0;
    end;
    h0 := h;
    if cfgsc.showlegend then
    begin
      ts := lbmp.TextSize(rsAbrevAsteroid + rsAbrevComet + rsAbrevVariable +
        rsAbrevDouble + rsAbrevDark + rsAbrevGalaxyCluster + rsAbrevGalaxy);
      w := max(w, round(1.3 * ts.cx));
      h := h + 6 * ls;
      tr := 255;
    end
    else
      tr := 220;
    if w > 0 then
    begin
      try
        // set size
        lbmp.SetSize(w, h);
        // fill background
        if cfgsc.WhiteBg then
        begin
          col := ColorToBGRA(clWhite, 255);
          lbmp.Fill(col);
          lbmp.Rectangle(0, 0, w, h, clBlack);
        end
        else
        begin
          col := ColorToBGRA($202020, tr);
          lbmp.Fill(col);
        end;
        // replace drawing bitmap
        Fplot.cbmp := lbmp;
        Fplot.cfgplot.UseBMP := True;
        Fplot.cfgchart.fontscale := Fplot.cfgchart.drawsize;
        // chart information
        if cfgsc.showlabel[8] then
        begin
          Fplot.PlotTextCR(5, 5, fontnum, labelnum, txtl, cfgsc.WhiteBg, False);
        end;
        if cfgsc.showlegend then
        begin
          Fplot.cfgplot.FontSize[fontnum] := Fplot.cfgplot.LabelSize[labelnum];
          drawgray := False;//cfgsc.ShowImages;
          // line 1
          // Stars magnitude
          dma := max(1, fplot.cfgchart.min_ma / 6);
          mag := -dma;
          lsp := w div 7;
          yy := h0;
          xx := -(lsp div 2);
          for i := 0 to 6 do
          begin
            mag := mag + dma;
            xx := round(xx + lsp);
            Fplot.PlotStar(xx, yy, mag, 0);
            Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
              laCenter, laCenter, IntToStr(round(mag)), cfgsc.WhiteBg, False);
          end;
          // line 2
          h0 := h0 + 2 * ls;
          sz := max(10 * Fplot.cfgchart.drawsize, round(ls * 0.6));
          yy := h0;
          xx := -(lsp div 2);
          // Ast
          xx := round(xx + lsp);
          mag := 5 * dma;
          Fplot.PlotAsteroid(xx, yy, cfgsc.AstSymbol, mag);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum], laCenter,
            laCenter, rsAbrevAsteroid, cfgsc.WhiteBg, False);
          // Com
          xx := round(xx + lsp);
          mag := 4 * dma;
          Fplot.PlotComet(xx, yy, xx + sz, yy + sz, cfgsc.ComSymbol, mag, 1.5 * sz, 1);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevComet, cfgsc.WhiteBg, False);
          // Var
          xx := round(xx + lsp);
          mag := 4 * dma;
          Fplot.PlotStar(xx, yy, mag, 0);
          Fplot.PlotVarStar(xx, yy, 0, mag);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevVariable, cfgsc.WhiteBg, False);
          // Dbl
          xx := round(xx + lsp);
          mag := 4 * dma;
          Fplot.PlotDblStar(xx, yy, 0.8 * sz, mag, 0, -45, 0);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevDouble, cfgsc.WhiteBg, False);
          // Drk
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 13, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevDark, cfgsc.WhiteBg, False);
          // Gcl
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 12, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevGalaxyCluster, cfgsc.WhiteBg, False);
          // GX
          xx := round(xx + lsp);
          Fplot.PlotDSOGxy(xx, yy, sz, sz div 3, 45, 0, 100, 100, 0, 0, 1, 3600, '', drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevGalaxy, cfgsc.WhiteBg, False);
          // line 3
          h0 := h0 + 2 * ls;
          yy := h0;
          xx := -(lsp div 2);
          // OC
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 1, 1, 2, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevOpenCluster, cfgsc.WhiteBg, False);
          // GB
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 3, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevGlobularCluster, cfgsc.WhiteBg, False);
          // PL
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 4, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevPlanetaryNebula, cfgsc.WhiteBg, False);
          // NB
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 5, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevNebula, cfgsc.WhiteBg, False);
          // C+N
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 6, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, rsAbrevClusterNebula, cfgsc.WhiteBg, False);
          // *
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 7, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, nebtype[9], cfgsc.WhiteBg, False);
          // ?
          xx := round(xx + lsp);
          Fplot.PlotDeepSkyObject(xx, yy, sz, 0, 0, 1, 0, '', cfgsc.WhiteBg, drawgray, clGray);
          Fplot.PlotText(xx, yy + ls, fontnum, Fplot.cfgplot.LabelColor[labelnum],
            laCenter, laCenter, nebtype[2], cfgsc.WhiteBg, False);
        end;
      finally
        // restore setting
        Fplot.cbmp := savecbmp;
        Fplot.cfgplot.UseBMP := saveubmp;
        Fplot.cfgchart.fontscale := savefontscale;
        Fplot.cfgplot.FontSize[fontnum] := savefontsize;
      end;
      // draw legend
      if saveubmp then
      begin
        Fplot.cbmp.PutImage(cfgsc.xshift, cfgsc.yshift, lbmp, dmDrawWithTransparency);
      end
      else
      begin
        Fplot.cnv.CopyMode := cmSrcCopy;
        Fplot.cnv.Draw(cfgsc.xshift, cfgsc.yshift, lbmp.Bitmap);
      end;
    end;
    lbmp.Free;
  end;
end;

procedure Tskychart.DrawSearchMark(ra, de: double; moving: boolean);
var
  x1, y1: double;
  xa, ya, sz: single;
  saveusebmp: boolean;
begin
  saveusebmp := Fplot.cfgplot.UseBMP;
  sz := 6;
  projection(ra, de, x1, y1, False, cfgsc);
  WindowXY(x1, y1, xa, ya, cfgsc);
  xa := round(xa);
  ya := round(ya);
  try
    Fplot.cfgplot.UseBMP := False;  // always to screen canvas
    Fplot.PlotCircle(xa - sz, ya - sz, xa + sz, ya + sz, Fplot.cfgplot.Color[11], moving);
    Fplot.PlotCircle(xa - sz - 1, ya - sz - 1, xa + sz + 1, ya + sz + 1, Fplot.cfgplot.Color[0], moving);
  finally
    Fplot.cfgplot.UseBMP := saveusebmp;
  end;
end;

procedure Tskychart.DrawEyepieceMask;
var
  r, x, y, o: single;
  x1, y1, x2, y2, rot, pa: double;
  spa, cpa: extended;
  i, lbl: integer;
begin
  if cfgsc.EyepieceMask then
  begin
    lbl := -1;
    r := 0;
    for i := 1 to cfgsc.ncircle do
    begin
      if cfgsc.circleok[i] then
      begin
        if cfgsc.circle[i, 1] > r then
        begin
          r := cfgsc.circle[i, 1];
          lbl := i;
        end;
      end;
    end;
    if lbl > 0 then
    begin
      r := deg2rad * cfgsc.circle[lbl, 1] / 120;
      if (r > (cfgsc.fov / 6)) and (r < (cfgsc.fov / 2)) then
      begin
        projection(cfgsc.racentre, cfgsc.decentre, x1, y1, False, cfgsc);
        projection(cfgsc.racentre, cfgsc.decentre + 0.001, x2, y2, False, cfgsc);
        rot := RotationAngle(x1, y1, x2, y2, cfgsc);
        pa := deg2rad * cfgsc.circle[lbl, 2] * cfgsc.FlipX;
        if cfgsc.FlipY < 0 then
          pa := pi - pa;
        sincos(pa + rot, spa, cpa);
        o := abs(cfgsc.circle[lbl, 3] * deg2rad / 60);
        x2 := x1 - cfgsc.flipx * o * spa;
        y2 := y1 + cfgsc.flipy * o * cpa;
        WindowXY(x2, y2, x, y, cfgsc);
        Fplot.PlotCircleMask(x, y, abs(cfgsc.BxGlb * r), cfgsc.WhiteBg);
      end;
    end;
  end;
end;

procedure Tskychart.DrawFinderMark(ra, de: double; moving: boolean;
  num: integer; mark: integer = 0);
var
  x1, y1, x2, y2, r, xc1,xc2,yc1,yc2: double;
  i, lid, sz: integer;
  xa, ya, xb, yb, xla, yla: single;
  pa, xx1, xx2, yy1, yy2, rot, o: single;
  spa, cpa: extended;
  p: array [0..4] of Tpoint;
  col: TColor;
  lbl, lis: string;
begin
  if mark > 0 then
  begin
    col := Fplot.cfgplot.Color[18];
    projection(ra, de, x1, y1, False, cfgsc);
    WindowXY(x1, y1, xx1, yy1, cfgsc);
    if mark = 1 then
    begin
      // telescope2 mark
      xa := xx1 - 10;
      xb := xx1 + 10;
      ya := yy1 - 10;
      yb := yy1 + 10;
      Fplot.PlotCircle(xa, ya, xb, yb, col, moving);
    end
    else
    begin
      xa := xx1 - 20;
      xb := xx1 + 20;
      ya := yy1 - 20;
      yb := yy1 + 20;
      Fplot.PlotCircle(xa, ya, xb, yb, col, moving);
      xa := xx1 - 50;
      xb := xx1 + 50;
      ya := yy1 - 50;
      yb := yy1 + 50;
      Fplot.PlotCircle(xa, ya, xb, yb, col, moving);
    end;
  end
  else
  begin
    projection(ra, de, x1, y1, False, cfgsc);
    projection(ra, de + 0.001, x2, y2, False, cfgsc);
    rot := RotationAngle(x1, y1, x2, y2, cfgsc);
    // crosshair
    if cfgsc.ShowCrosshair and (num < 0) and (not moving) then
    begin
      // vertical line
      xc1 := cfgsc.xmin + (cfgsc.xmax-cfgsc.xmin) / 2;
      xc2 := xc1;
      yc1 := cfgsc.ymin;
      yc2 := cfgsc.ymax;
      Fplot.PlotLine(xc1, yc1, xc2, yc2, Fplot.cfgplot.Color[18], 1);
      // horizontal line
      xc1 := cfgsc.xmin;
      xc2 := cfgsc.xmax;
      yc1 := cfgsc.ymin + (cfgsc.ymax-cfgsc.ymin) / 2;
      yc2 := yc1;
      Fplot.PlotLine(xc1, yc1, xc2, yc2, Fplot.cfgplot.Color[18], 1);
    end;
    // circle
    for i := 1 to cfgsc.ncircle do
      if cfgsc.circleok[i] then
      begin
        if cfgsc.circle[i, 4] = 0 then
        begin
          col := Fplot.cfgplot.Color[18];
          lbl := cfgsc.circlelbl[i];
        end
        else
        begin
          col := AddColor($ffffff, -Fplot.cfgplot.Color[18]);
          lbl := cfgsc.circlelbl[i] + blank + formatfloat(f1, cfgsc.circle[i, 2]);
        end;
        pa := deg2rad * cfgsc.circle[i, 2] * cfgsc.FlipX;
        if cfgsc.FlipY < 0 then
          pa := pi - pa;
        sincos(pa + rot, spa, cpa);
        o := abs(cfgsc.circle[i, 3] * deg2rad / 60);
        x2 := x1 - cfgsc.flipx * o * spa;
        y2 := y1 + cfgsc.flipy * o * cpa;
        r := deg2rad * cfgsc.circle[i, 1] / 120;
        WindowXY(x2 - r, y2 - r, xa, ya, cfgsc);
        WindowXY(x2 + r, y2 + r, xb, yb, cfgsc);
        Fplot.PlotCircle(xa, ya, xb, yb, col, moving);
        if cfgsc.CircleLabel or cfgsc.marknumlabel then
        begin
          if not cfgsc.CircleLabel then
            lbl := '';
          if cfgsc.marknumlabel and (num > 0) then
            lbl := trim(lbl + ' ' + IntToStr(num));
          if trim(lbl) > '' then
          begin
            sz := trunc(abs(cfgsc.BxGlb * r));
            xla := abs(xa + xb) / 2;
            yla := abs(ya + yb) / 2;
            lis := cfgsc.circlelbl[i] + FormatFloat(f6, ra) + FormatFloat(f6, de);
            lid := rshash(lis, $7FFFFFFF);
            if sz >= 20 then
              SetLabel(lid, xla, yla, sz, 2, 7, lbl, laBottom, 0, 0, False);
          end;
        end;
      end;
    // rectangle
    for i := 1 to cfgsc.nrectangle do
      if cfgsc.rectangleok[i] and (deg2rad * cfgsc.rectangle[i, 2] / 60 < 2 * cfgsc.fov) then
      begin
        if cfgsc.rectangle[i, 5] = 0 then
        begin
          col := Fplot.cfgplot.Color[18];
          lbl := cfgsc.rectanglelbl[i];
        end
        else
        begin
          col := $ffffff xor Fplot.cfgplot.Color[0];
          lbl := cfgsc.rectanglelbl[i] + blank + formatfloat(f1, cfgsc.rectangle[i, 3]);
        end;
        pa := deg2rad * cfgsc.rectangle[i, 3] * cfgsc.FlipX;
        if cfgsc.FlipY < 0 then
          pa := pi - pa;
        sincos(pa + rot, spa, cpa);
        o := abs(cfgsc.rectangle[i, 4] * deg2rad / 60);
        x2 := x1 - cfgsc.flipx * o * spa;
        y2 := y1 + cfgsc.flipy * o * cpa;
        xx1 := deg2rad * cfgsc.flipx * (cfgsc.rectangle[i, 1] / 120 * cpa -
          cfgsc.rectangle[i, 2] / 120 * spa);
        yy1 := deg2rad * cfgsc.flipy * (cfgsc.rectangle[i, 1] / 120 * spa +
          cfgsc.rectangle[i, 2] / 120 * cpa);
        xx2 := deg2rad * cfgsc.flipx * (cfgsc.rectangle[i, 1] / 120 * cpa +
          cfgsc.rectangle[i, 2] / 120 * spa);
        yy2 := deg2rad * cfgsc.flipy * (-cfgsc.rectangle[i, 1] / 120 * spa +
          cfgsc.rectangle[i, 2] / 120 * cpa);
        WindowXY(x2 - xx1, y2 - yy1, xa, ya, cfgsc);
        p[0] := Point(round(xa), round(ya));
        WindowXY(x2 + xx2, y2 - yy2, xa, ya, cfgsc);
        p[1] := Point(round(xa), round(ya));
        WindowXY(x2 + xx1, y2 + yy1, xa, ya, cfgsc);
        p[2] := Point(round(xa), round(ya));
        WindowXY(x2 - xx2, y2 + yy2, xa, ya, cfgsc);
        p[3] := Point(round(xa), round(ya));
        p[4] := p[0];
        Fplot.PlotPolyline(p, col, moving);
        if cfgsc.RectangleLabel or cfgsc.marknumlabel then
        begin
          if not cfgsc.RectangleLabel then
            lbl := '';
          if cfgsc.marknumlabel and (num > 0) then
            lbl := trim(lbl + ' ' + IntToStr(num));
          if trim(lbl) > '' then
          begin
            xla := abs(p[0].X + p[1].X) / 2;
            yla := abs(p[0].Y + p[1].Y) / 2;
            sz := Max(abs(p[0].X - p[1].X), abs(p[0].Y - p[1].Y));
            lis := cfgsc.rectanglelbl[i] + FormatFloat(f6, ra) + FormatFloat(f6, de);
            lid := rshash(lis, $7FFFFFFF);
            if sz >= 20 then
              SetLabel(lid, xla, yla, 0, 2, 7, lbl, laBottom, rad2deg * (pa + rot), 0, False);
          end;
        end;
      end;
  end;
end;

procedure Tskychart.DrawCircle;
var
  i: integer;
begin
  //center mark
  if cfgsc.ShowCircle then
  begin
    if VerboseMsg then
      WriteTrace('SkyChart ' + cfgsc.chartname + ': draw circle');
    DrawFinderMark(cfgsc.racentre, cfgsc.decentre, False, -1);
  end;
  //listed mark
  for i := 1 to cfgsc.NumCircle do
    DrawFinderMark(cfgsc.CircleLst[i, 1], cfgsc.CircleLst[i, 2], False, i);
end;

procedure Tskychart.DrawTarget;
var
  r, d, phi, rot, x, y, xx, yy: double;
  xc, yc, xi, yi: single;
  a, b: single;
  txt: string;
begin
  if cfgsc.TargetOn then
  begin
    d := AngularDistance(cfgsc.racentre, cfgsc.decentre, cfgsc.TargetRA, cfgsc.TargetDec);
    txt := cfgsc.TargetName + ' ' + DEmToStr(rad2deg * d);
    r := cfgsc.fov / 5;
    if (d > r) and (not ObjectInMap(cfgsc.TargetRA, cfgsc.TargetDec, cfgsc)) then
    begin
      x := 0;
      y := 0;
      projection(cfgsc.racentre, cfgsc.decentre + 0.001, xx, yy, False, cfgsc);
      rot := -arctan2((xx - x), (yy - y));
      phi := cfgsc.FlipX * (rot + PositionAngle(cfgsc.racentre, cfgsc.decentre,
        cfgsc.TargetRA, cfgsc.TargetDec));
      if cfgsc.FlipY < 0 then
        phi := pi - phi;
      phi := rmod(pi4 + phi, pi2);
      WindowXY(0, 0, xc, yc, cfgsc);
      a := tan(phi);
      if a = 0 then
        a := MaxSingle
      else
        a := 1 / a;
      b := yc - (a * xc);
      // intercect x=0
      if phi < pi then
      begin
        xi := 0;
        yi := b;
        if (yi > 0) and (yi < cfgsc.ymax) then
        begin
          Fplot.PlotLine(xi, yi, xi + 5, yi - 3, clRed, 2);
          Fplot.PlotLine(xi, yi, xi + 5, yi + 3, clRed, 2);
          Fplot.PlotText(round(xi + 7), round(yi), 1, clRed, laLeft, laCenter, txt, False);
        end;
      end;
      // intercect x=xmax
      if phi > pi then
      begin
        xi := cfgsc.xmax;
        yi := a * xi + b;
        if (yi > 0) and (yi < cfgsc.ymax) then
        begin
          Fplot.PlotLine(xi, yi, xi - 5, yi - 3, clRed, 2);
          Fplot.PlotLine(xi, yi, xi - 5, yi + 3, clRed, 2);
          Fplot.PlotText(round(xi - 7), round(yi), 1, clRed, laRight, laCenter, txt, False);
        end;
      end;
      // intercect y=0
      if (phi < pid2) or (phi > (3 * pid2)) then
      begin
        yi := 0;
        xi := -b / a;
        if (xi > 0) and (xi < cfgsc.xmax) then
        begin
          Fplot.PlotLine(xi, yi, xi - 3, yi + 5, clRed, 2);
          Fplot.PlotLine(xi, yi, xi + 3, yi + 5, clRed, 2);
          Fplot.PlotText(round(xi), round(yi + 7), 1, clRed, laCenter, laTop, txt, False);
        end;
      end;
      // intercect y=ymax
      if (phi > pid2) and (phi < (3 * pid2)) then
      begin
        yi := cfgsc.ymax;
        xi := (yi - b) / a;
        if (xi > 0) and (xi < cfgsc.xmax) then
        begin
          Fplot.PlotLine(xi, yi, xi - 3, yi - 5, clRed, 2);
          Fplot.PlotLine(xi, yi, xi + 3, yi - 5, clRed, 2);
          Fplot.PlotText(round(xi), round(yi - 7), 1, clRed, laCenter, laBottom, txt, False);
        end;
      end;
    end;
  end;
end;

//  compass rose
procedure Tskychart.DrawCompass;
var
  compassok, scaleok: boolean;
begin
  compassok := False;
  scaleok := False;
  if (cfgsc.ShowGrid or cfgsc.ShowEqGrid) and
    ((deg2rad * Fcatalog.cfgshr.DegreeGridSpacing[cfgsc.FieldNum]) > (cfgsc.fov / 2)) then
  begin
    compassok := True;
    scaleok := True;
  end;
  if Fcatalog.cfgshr.ShowCRose then
    compassok := True;
  if ((not cfgsc.ShowGrid) or cfgsc.ShowOnlyMeridian) and (not cfgsc.ShowEqGrid) and
    Fcatalog.cfgshr.ShowCRose then
  begin
    compassok := True;
    scaleok := True;
  end;
  if compassok then
    DrawCRose;
  if scaleok then
    DrawScale;
end;

procedure Tskychart.DrawCRose;
var
  rosex, rosey, roserd: integer;
  tx, ty: single;
  ar, de, a, h, l, b, x1, y1, x2, y2, rot, rar, rde: double;
begin
  if VerboseMsg then
    WriteTrace('SkyChart ' + cfgsc.chartname + ': draw compass');
  roserd := round(Fcatalog.cfgshr.CRoseSz * fplot.cfgchart.drawsize / 2);
  rosex := cfgsc.xmin + 10 + roserd;
  rosey := cfgsc.ymax - 10 - roserd;
  GetADxy(rosex, rosey, rar, rde, cfgsc);
  projection(rar, rde, x1, y1, False, cfgsc);
  WindowXY(x1, y1, tx, ty, cfgsc);
  if (round(tx) <> rosex) or (round(ty) <> rosey) then
    exit; // reversibilty test, the rose is outside of valid coordinates
  projection(rar, rde + 0.001, x2, y2, False, cfgsc);
  rot := -arctan2((x2 - x1), (y2 - y1));
  if Fcatalog.cfgshr.SimplePointer then
  begin
    Fplot.PlotCRose(rosex, rosey, roserd, rot, cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, 3);
  end
  else
  begin
    Fplot.PlotCRose(rosex, rosey, roserd, rot, cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, 1);
    if cfgsc.ProjPole = Altaz then
    begin
      Eq2Hz(cfgsc.CurST - rar, rde, a, h, cfgsc);
      Hz2Eq(a, h + 0.001, ar, de, cfgsc);
      projection(cfgsc.CurST - ar, de, x2, y2, False, cfgsc);
      rot := -arctan2((x2 - x1), (y2 - y1));
      Fplot.PlotCRose(rosex, rosey, roserd, rot, cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, 2);
    end;
    if cfgsc.ProjPole = Ecl then
    begin
      Eq2Ecl(rar, rde, cfgsc.ecl, l, b);
      Ecl2eq(l, b + 0.001, cfgsc.ecl, ar, de);
      projection(ar, de, x2, y2, False, cfgsc);
      rot := -arctan2((x2 - x1), (y2 - y1));
      Fplot.PlotCRose(rosex, rosey, roserd, rot, cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, 2);
    end;
    if cfgsc.ProjPole = Gal then
    begin
      Eq2Gal(rar, rde, l, b, cfgsc);
      gal2eq(l, b + 0.001, ar, de, cfgsc);
      projection(ar, de, x2, y2, False, cfgsc);
      rot := -arctan2((x2 - x1), (y2 - y1));
      Fplot.PlotCRose(rosex, rosey, roserd, rot, cfgsc.FlipX, cfgsc.FlipY, cfgsc.WhiteBg, 2);
    end;
  end;
end;

function Tskychart.TelescopeMove(ra, Dec: double): boolean;
var
  dist: double;
begin
  Result := False;
  cfgsc.moved := False;
  if (abs(ra-cfgsc.ScopeRa)>secarc) or (abs(Dec-cfgsc.ScopeDec)>secarc) then
  begin
    if assigned(FonTelescopeMove) then
      FonTelescopeMove(cfgsc.chartname, ra, Dec);
    if cfgsc.scopemark then
      DrawFinderMark(cfgsc.ScopeRa, cfgsc.ScopeDec, True, -1);
    DrawFinderMark(ra, Dec, True, -1);
    cfgsc.ScopeRa := ra;
    cfgsc.ScopeDec := Dec;
    cfgsc.scopemark := True;
    dist := angulardistance(cfgsc.racentre, cfgsc.decentre, ra, Dec);
    if (dist > cfgsc.fov / 10) and (cfgsc.TrackOn) then
    begin
      if not cfgsc.scopelock then
      begin
        Result := True;
        cfgsc.scopelock := True;
        if cfgsc.TrackOn and (cfgsc.TrackName = rsTelescope) then
        begin
          cfgsc.TrackType := TTequat;
          cfgsc.TrackRA := ra;
          cfgsc.TrackDec := Dec;
          cfgsc.TrackEpoch := cfgsc.JDChart;
        end;
        MovetoRaDec(cfgsc.ScopeRa, cfgsc.ScopeDec);
        if VerboseMsg then
          WriteTrace('TelescopeMove');
        Refresh(True);
        cfgsc.scopelock := False;
      end;
    end;
  end;
end;

function Tskychart.Telescope2Move(ra, Dec: double): boolean;
var
  dist: double;
begin
  // external telescope driven by the MOVESCOPE command
  Result := False;
  cfgsc.moved := False;
  if (ra <> cfgsc.Scope2Ra) or (Dec <> cfgsc.Scope2Dec) then
  begin
    if cfgsc.scope2mark then
      DrawFinderMark(cfgsc.Scope2Ra, cfgsc.Scope2Dec, True, -1, MarkType);
    DrawFinderMark(ra, Dec, True, -1, MarkType);
    cfgsc.Scope2Ra := ra;
    cfgsc.Scope2Dec := Dec;
    cfgsc.scope2mark := True;
    dist := angulardistance(cfgsc.racentre, cfgsc.decentre, ra, Dec);
    if not cfgsc.scopelock then
    begin
      Result := True;
      cfgsc.scopelock := True;
      if cfgsc.TrackOn and (cfgsc.TrackName = rsTelescope + '-2') then
      begin
        cfgsc.TrackType := TTequat;
        cfgsc.TrackRA := ra;
        cfgsc.TrackDec := Dec;
        cfgsc.TrackEpoch := cfgsc.JDChart;
      end;
      if (dist > cfgsc.fov / 10) and (cfgsc.TrackOn) then
        MovetoRaDec(cfgsc.Scope2Ra, cfgsc.Scope2Dec);
      if VerboseMsg then
        WriteTrace('Telescope2Move');
      Refresh(True);
      cfgsc.scopelock := False;
    end;
  end;
end;

function Tskychart.GetChartInfo(sep: string = blank): string;
var
  pr, cep, dat: string;
begin
  if cfgsc.CoordExpertMode then
  begin
    ;
    if cfgsc.ApparentPos then
      cep := rsApparent
    else
      cep := rsMean;
    cep := cep + blank + trim(cfgsc.EquinoxName);
  end
  else
    case cfgsc.CoordType of
      0: cep := rsApparent;
      1: cep := rsMeanOfTheDat;
      2: cep := rsMeanJ2000;
      3: cep := rsAstrometricJ;
      else
        cep := '';
    end;
  dat := Date2Str(cfgsc.CurYear, cfgsc.curmonth, cfgsc.curday) + sep + ArToStr3(cfgsc.Curtime);
  dat := dat + ' (' + TzGMT2UTC(cfgsc.tz.ZoneName) + ')';
  if cfgsc.projtype = 'A' then
    pr := ' ARC'
  else
    pr := ' ' + cfgsc.projname[cfgsc.fieldnum];
  case cfgsc.projpole of
    Equat: Result := rsEquatorialCo3 + pr + sep + cep + sep + dat;
    AltAz: Result := rsAltAZCoord2 + pr + sep + cep + sep + trim(cfgsc.ObsName) + sep + dat;
    Gal: Result := rsGalacticCoor2 + pr + sep + dat;
    Ecl: Result := rsEclipticCoor3 + pr + sep + cep + sep + dat + sep +
        rsInclination2 + detostr(cfgsc.ecl * rad2deg);
    else
      Result := '';
  end;
  Result := Result + sep + rsMag + formatfloat(f1, plot.cfgchart.min_ma);
  if catalog.cfgshr.NebFilter then
  begin
    if catalog.cfgcat.NebMagMax < 90 then
      Result := Result + '/' + formatfloat(f1, catalog.cfgcat.NebMagMax);
    if catalog.cfgcat.NebSizeMin > 0 then
      Result := Result + ',' + formatfloat(f1, catalog.cfgcat.NebSizeMin) + lmin;
  end;
  Result := Result + sep + rsFOV2 + detostr(cfgsc.fov * rad2deg);
end;

function Tskychart.GetChartPos: string;
begin
  Result := 'C:' + armtostr(cfgsc.racentre * rad2deg / 15) + blank + demtostr(cfgsc.decentre * rad2deg);
  Result := Result + ' L:' + demtostr(cfgsc.fov * rad2deg);
end;

procedure Tskychart.LoadHorizonPicture(fname: string);
begin
  try
    if cfgsc.horizonpicturevalid and (fname = cfgsc.horizonpicturename) then
      exit;
    cfgsc.horizonpicturevalid := False;
    cfgsc.horizondarken := -1;
    cfgsc.horizonpicturename := '';
    if fname = '' then
      exit;
    if ExtractFilePath(fname) = '' then
      fname := slash(Appdir) + fname;
    if FileExists(fname) then
    begin
      horizonpicture.LoadFromFile(fname);
      if uppercase(ExtractFileExt(fname)) = '.BMP' then
        horizonpicture.ReplaceColor(ColorToBGRA(clFuchsia), BGRAPixelTransparent);
      cfgsc.horizonpicturevalid := True;
      cfgsc.horizonpicturename := fname;
    end
    else
    begin
      horizonpicture.SetSize(1, 1);
      cfgsc.horizonpicturevalid := False;
      cfgsc.horizonpicturename := '';
    end;
  except
    cfgsc.horizonpicturevalid := False;
    cfgsc.horizonpicturename := '';
  end;
end;

procedure Tskychart.LoadHorizon;
var
  de, d0, d1, d2: single;
  i, i1, i2: integer;
  f: textfile;
  fname,buf: string;
begin
  try
  fname:=cfgsc.HorizonFile;
  if (fname = cfgsc.horizonlistname) then
    exit;
  cfgsc.HorizonMax := musec;  // require in cfgsc for horizon clipping in u_projection
  cfgsc.HorizonMin := pid2;
  for i := 1 to 360 do
    cfgsc.horizonlist[i] := 0;
  if fileexists(fname) then
  begin
    i1 := 0;
    i2 := 0;
    d1 := 0;
    d0 := 0;
    try
      Filemode := 0;
      assignfile(f, fname);
      reset(f);
      // get first point
      repeat
        readln(f, buf)
      until EOF(f) or ((trim(buf) <> '') and (buf[1] <> '#'));
      if (trim(buf) = '') or (buf[1] = '#') then
        exit;
      i1 := round(StrToFloat(trim(words(buf, blank, 1, 1))));
      d1 := strtofloat(trim(words(buf, blank, 2, 1)));
      if d1 > 90 then
        d1 := 90;
      if d1 < 0 then
        d1 := 0;
      if i1 <> 0 then
      begin
        reset(f);
        i1 := 0;
        d1 := 0;
      end;
      i2 := 0;
      d0 := d1;
      // process each point
      while (not EOF(f)) and (i2 < 359) do
      begin
        repeat
          readln(f, buf)
        until EOF(f) or ((trim(buf) <> '') and (buf[1] <> '#'));
        if (trim(buf) = '') or (buf[1] = '#') then
          break;
        i2 := round(StrToFloat(trim(words(buf, blank, 1, 1))));
        d2 := strtofloat(trim(words(buf, blank, 2, 1)));
        if i2 > 359 then
          i2 := 359;
        if i1 >= i2 then
          continue;
        if d2 > 90 then
          d2 := 90;
        if d2 < 0 then
          d2 := 0;
        for i := i1 to i2 do
        begin
          de := deg2rad * (d1 + (i - i1) * (d2 - d1) / (i2 - i1));
          cfgsc.horizonlist[i + 1] := de;
          cfgsc.HorizonMax := max(cfgsc.HorizonMax, de);
          cfgsc.HorizonMin := min(cfgsc.HorizonMin, de);
        end;
        i1 := i2;
        d1 := d2;
      end;

    finally
      cfgsc.horizonlistname := fname;
      closefile(f);
      // fill last point
      if i2 < 359 then
      begin
        for i := i1 to 359 do
        begin
          de := deg2rad * (d1 + (i - i1) * (d0 - d1) / (359 - i1));
          cfgsc.horizonlist[i + 1] := de;
          cfgsc.HorizonMax := max(cfgsc.HorizonMax, de);
          cfgsc.HorizonMin := min(cfgsc.HorizonMin, de);
        end;
      end;
      cfgsc.horizonlist[0] := cfgsc.horizonlist[1];
      cfgsc.horizonlist[361] := cfgsc.horizonlist[1];
    end;
  end;
  except
  end;
end;

end.
