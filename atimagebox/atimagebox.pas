{
ATImageBox for Lazarus
Copyright (C) Alexey Torgashin, uvviewsoft.com
License: MPL 2.0
}

unit ATImageBox;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Controls, Graphics,
  StdCtrls, ExtCtrls,
  LMessages,
  LCLType,
  Forms,
  Math;

const
  cViewerImageScales: array[1 .. 33] of Integer = (
    1, 2, 4, 7, 10, 15, 20, 25, 30,
    40, 50, 60, 70, 80, 90, 100,
    125, 150, 175, 200, 250, 300, 350, 400, 450, 500,
    600, 700, 800, 1000, 1200, 1400, 1600);


type
  TATScrollAltEvent = procedure(Sender: TObject; Inc: Boolean) of object;

type

  { TATImageBox }

  TATImageBox = class(TScrollBox)
  private
    FFocusable: Boolean;
    FImage: TImage;
    FImageWidth: Integer;
    FImageHeight: Integer;
    FImageFit,
    FImageFitOnlyBig,
    FImageFitWidth,
    FImageFitHeight,
    FImageCenter: Boolean;
    FImageScale: Integer;
    FImageKeepPosition: Boolean;
    FImageDrag: Boolean;
    FImageDragCursor: TCursor;
    FImageScaleCursor: TCursor;
    FImageDragging: Boolean;
    FImageDraggingPoint: TPoint;
    FImageMouseDown: Boolean;
    FKeyModifierZoom: TShiftStateEnum;
    FKeyModifierHorzScroll: TShiftStateEnum;
    FInitScrollbarSize: integer;
    FCheckers: boolean;
    FCheckersSize: integer;
    FCheckersColor1: TColor;
    FCheckersColor2: TColor;

    FOnScroll: TNotifyEvent;
    FOnScrollAlt: TATScrollAltEvent;
    FOnOptionsChange: TNotifyEvent;

    FOldLeft: integer;
    FOldTop: integer;
    FOldWidth: integer;
    FOldHeight: integer;
    FOldSelfW: integer;
    FOldSelfH: integer;

    procedure SetCheckers(AValue: boolean);
    procedure DoScroll;
    procedure DoScrollAlt(AInc: Boolean);
    procedure DoOptionsChange;
    procedure MouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure MouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure SetCheckersColor1(AValue: TColor);
    procedure SetCheckersColor2(AValue: TColor);
    procedure SetCheckersSize(AValue: integer);
    procedure UpdateImagePosition(AResetPosition: Boolean = False);
    procedure SetImageFit(AValue: Boolean);
    procedure SetImageFitOnlyBig(AValue: Boolean);
    procedure SetImageFitWidth(AValue: Boolean);
    procedure SetImageFitHeight(AValue: Boolean);
    procedure SetImageCenter(AValue: Boolean);
    procedure SetImageScale(AValue: Integer);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ImagePaintBackground(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
    function GetPicture: TPicture;
    procedure SetPicture(AValue: TPicture);

  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const FN: string);
    procedure LoadBitmap(ABitmap: TBitmap; ATransp: Boolean);
    procedure LoadPicture(APicture: TPicture);
    procedure Unload;
    procedure UpdateInfo;
    procedure IncreaseImageScale(AIncrement: Boolean);
    property Image: TImage read FImage;
    property ImageWidth: Integer read FImageWidth;
    property ImageHeight: Integer read FImageHeight;
    property ImageScale: Integer read FImageScale write SetImageScale;

  protected
    procedure WMHScroll(var Message: TLMHScroll); message LM_HScroll;
    procedure WMVScroll(var Message: TLMVScroll); message LM_VScroll;
    procedure WMGetDlgCode(var Message: TLMessage); message LM_GETDLGCODE;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Loaded; override;

  published
    property Picture: TPicture read GetPicture write SetPicture;
    property OptFocusable: Boolean read FFocusable write FFocusable default True;
    property OptFitToWindow: Boolean read FImageFit write SetImageFit default False;
    property OptFitOnlyBig: Boolean read FImageFitOnlyBig write SetImageFitOnlyBig default True;
    property OptFitWidth: Boolean read FImageFitWidth write SetImageFitWidth default False;
    property OptFitHeight: Boolean read FImageFitHeight write SetImageFitHeight default False;
    property OptCenter: Boolean read FImageCenter write SetImageCenter default True;
    property OptKeepPosition: Boolean read FImageKeepPosition write FImageKeepPosition default True;
    property OptDrag: Boolean read FImageDrag write FImageDrag default True;
    property OptCursorDrag: TCursor read FImageDragCursor write FImageDragCursor default crSizeAll;
    property OptCursorScale: TCursor read FImageScaleCursor write FImageScaleCursor default crSizeNS;
    property OptKeyModifierZoom: TShiftStateEnum read FKeyModifierZoom write FKeyModifierZoom default ssModifier;
    property OptKeyModifierHorzScroll: TShiftStateEnum read FKeyModifierHorzScroll write FKeyModifierHorzScroll default ssShift;
    property OptCheckers: boolean read FCheckers write SetCheckers default true;
    property OptChechersSize: integer read FCheckersSize write SetCheckersSize default 8;
    property OptCheckersColor1: TColor read FCheckersColor1 write SetCheckersColor1 default clWhite;
    property OptCheckersColor2: TColor read FCheckersColor2 write SetCheckersColor2 default clLtGray;

    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
    property OnScrollAlt: TATScrollAltEvent read FOnScrollAlt write FOnScrollAlt;
    property OnOptionsChange: TNotifyEvent read FOnOptionsChange write FOnOptionsChange;
  end;


implementation

const
  cImageLineSize = 50; //Line size: pixels to scroll by arrows and mouse sheel
  cImageGapSize = 20; //Gap size: PgUp/PgDn/Home/End scroll by control size minus gap size

procedure DoPaintCheckers(C: TCanvas;
  ASizeX, ASizeY: integer;
  ACellSize: integer;
  AColor1, AColor2: TColor);
var
  i, j: integer;
begin
  c.Brush.Color:= AColor1;
  c.FillRect(0, 0, ASizeX, ASizeY);

  for i:= 0 to ASizeX div ACellSize + 1 do
    for j:= 0 to ASizeY div ACellSize + 1 do
      if odd(i) xor odd(j) then
      begin
        c.Brush.Color:= AColor2;
        c.FillRect(i*ACellSize, j*ACellSize, (i+1)*ACellSize, (j+1)*ACellSize);
      end;
end;


{ TATImageBox }

constructor TATImageBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  //Init inherited properties
  AutoScroll:= False;
  DoubleBuffered:= True; //To remove flicker when new image is loaded
  HorzScrollBar.Tracking:= True;
  VertScrollBar.Tracking:= True;

  //Init fields
  FFocusable:= True;
  FImageFit:= False;
  FImageFitOnlyBig:= True;
  FImageFitWidth:= False;
  FImageFitHeight:= False;
  FImageCenter:= True;
  FImageWidth:= 0;
  FImageHeight:= 0;
  FImageScale:= 100;
  FImageKeepPosition:= True;
  FImageDrag:= True;
  FImageDragCursor:= crSizeAll;
  FImageScaleCursor:= crSizeNS;
  FImageDragging:= False;
  FImageDraggingPoint:= Point(0, 0);
  FImageMouseDown:= False;

  FKeyModifierZoom:= ssModifier;
  FKeyModifierHorzScroll:= ssShift;

  FCheckers:= true;
  FCheckersSize:= 8;
  FCheckersColor1:= clWhite;
  FCheckersColor2:= clLtGray;

  FImage:= TImage.Create(Self);
  with FImage do
  begin
    Parent:= Self;
    Align:= alNone;
    SetBounds(0, 0, 100, 100);
    AutoSize:= False;
    OnMouseDown:= @ImageMouseDown;
    OnMouseUp:= @ImageMouseUp;
    OnMouseMove:= @ImageMouseMove;
    OnPaintBackground:= @ImagePaintBackground;
  end;

  //Init event handlers
  OnMouseWheelUp:= @MouseWheelUp;
  OnMouseWheelDown:= @MouseWheelDown;

  with TScrollBar.Create(Self) do
  try
    Kind:= sbVertical;
    FInitScrollbarSize:= Width;
  finally
    Free
  end;
end;

procedure TATImageBox.SetCheckers(AValue: boolean);
begin
  if FCheckers<>AValue then
  begin
    FCheckers:= AValue;
    if FCheckers then
      FImage.OnPaintBackground:= @ImagePaintBackground
    else
      FImage.OnPaintBackground:= nil;
    FImage.Invalidate;
  end;
end;

procedure TATImageBox.DoScroll;
begin
  if Assigned(FOnScroll) then
    FOnScroll(Self);
end;

procedure TATImageBox.DoScrollAlt(AInc: Boolean);
begin
  if Assigned(FOnScrollAlt) then
    FOnScrollAlt(Self, AInc);
end;

procedure TATImageBox.WMHScroll(var Message: TLMHScroll);
begin
  inherited;
  DoScroll;
end;

procedure TATImageBox.WMVScroll(var Message: TLMVScroll);
begin
  inherited;
  DoScroll;
end;

procedure TATImageBox.MouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if (Shift = []) then
  begin
    with VertScrollBar do
      Position:= Position - cImageLineSize;
    DoScroll;
  end
  else
  if (Shift = [FKeyModifierHorzScroll]) then
  begin
    with HorzScrollBar do
      Position:= Position - cImageLineSize;
    DoScroll;
  end
  else
  if (Shift = [FKeyModifierZoom]) or FImageMouseDown then
  begin
    IncreaseImageScale(True);
    FImageDragging:= False;
    if FImageMouseDown then
      Screen.Cursor:= FImageScaleCursor;
  end;

  Handled:= True;
end;

procedure TATImageBox.MouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if (Shift = []) then
  begin
    with VertScrollBar do
      Position:= Position + cImageLineSize;
    DoScroll;
  end
  else
  if (Shift = [FKeyModifierHorzScroll]) then
  begin
    with HorzScrollBar do
      Position:= Position + cImageLineSize;
    DoScroll;
  end
  else
  if (Shift = [FKeyModifierZoom]) or FImageMouseDown then
  begin
    IncreaseImageScale(False);
    FImageDragging:= False;
    if FImageMouseDown then
      Screen.Cursor:= FImageScaleCursor;
  end;

  Handled:= True;
end;

procedure TATImageBox.SetCheckersColor1(AValue: TColor);
begin
  if FCheckersColor1= AValue then Exit;
  FCheckersColor1:= AValue;
  FImage.Invalidate;
end;

procedure TATImageBox.SetCheckersColor2(AValue: TColor);
begin
  if FCheckersColor2= AValue then Exit;
  FCheckersColor2:= AValue;
  FImage.Invalidate;
end;

procedure TATImageBox.SetCheckersSize(AValue: integer);
begin
  if FCheckersSize=AValue then Exit;
  FCheckersSize:= AValue;
  FImage.Invalidate;
end;

procedure TATImageBox.WMGetDlgCode(var Message: TLMessage);
begin
  Message.Result:= DLGC_WANTARROWS;
end;

procedure TATImageBox.KeyDown(var Key: Word; Shift: TShiftState);

  function PageSize(AClientSize: Integer): Integer;
  begin
    Result:= Max(AClientSize - cImageGapSize, AClientSize div 3 * 2);
  end;

begin
  case Key of
    VK_LEFT:
    begin
      if Shift = [] then
      begin
        with HorzScrollBar do
          Position:= Position - cImageLineSize;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssCtrl] then
      begin
        with HorzScrollBar do
          Position:= 0;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssAlt] then
      begin
        DoScrollAlt(False);
        Key:= 0;
      end;
    end;

    VK_RIGHT:
    begin
      if Shift = [] then
      begin
        with HorzScrollBar do
          Position:= Position + cImageLineSize;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssCtrl] then
      begin
        with HorzScrollBar do
          Position:= Range;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssAlt] then
      begin
        DoScrollAlt(True);
        Key:= 0;
      end;
    end;

    VK_HOME:
      if Shift = [] then
      begin
        with HorzScrollBar do
          Position:= Position - PageSize(ClientWidth);
        DoScroll;
        Key:= 0;
      end;

    VK_END:
      if Shift = [] then
      begin
        with HorzScrollBar do
          Position:= Position + PageSize(ClientWidth);
        DoScroll;
        Key:= 0;
      end;

    VK_UP:
    begin
      if Shift = [] then
      begin
        with VertScrollBar do
          Position:= Position - cImageLineSize;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssCtrl] then
      begin
        with VertScrollBar do
          Position:= 0;
        DoScroll;
        Key:= 0;
      end;
    end;

    VK_DOWN:
    begin
      if Shift = [] then
      begin
        with VertScrollBar do
          Position:= Position + cImageLineSize;
        DoScroll;
        Key:= 0;
      end
      else
      if Shift = [ssCtrl] then
      begin
        with VertScrollBar do
          Position:= Range;
        DoScroll;
        Key:= 0;
      end;
    end;

    VK_PRIOR:
      if Shift = [] then
      begin
        with VertScrollBar do
          Position:= Position - PageSize(ClientHeight);
        DoScroll;
        Key:= 0;
      end;

    VK_NEXT:
      if Shift = [] then
      begin
        with VertScrollBar do
          Position:= Position + PageSize(ClientHeight);
        DoScroll;
        Key:= 0;
      end;
  end;
end;


procedure TATImageBox.UpdateImagePosition(AResetPosition: Boolean = False);
var
  bKeepPosition: Boolean;
  CliWidth, CliHeight,
  NewWidth, NewHeight, NewLeft, NewTop,
  ScrollMaxX, ScrollMaxY: Integer;
  NRatio, NImageRatio, CenterRatioX, CenterRatioY: Double;
  NScrollbarSize: integer;
begin
  bKeepPosition:= FImageKeepPosition and not AResetPosition;

  if FImageFit then
    NScrollbarSize:= 0
  else
    NScrollbarSize:= FInitScrollbarSize;

  VertScrollBar.Visible:= not FImageFit;
  HorzScrollBar.Visible:= not FImageFit;
  CliWidth:= Width-NScrollbarSize;
  CliHeight:= Height-NScrollbarSize;

  //Save center position, need to restore it later
  CenterRatioX:= 0;
  CenterRatioY:= 0;

  if FImage.Width > 0 then
  begin
    if FImage.Left >= 0 then
      CenterRatioX:= (CliWidth div 2 - FImage.Left) / FImage.Width
    else
      CenterRatioX:= (CliWidth div 2 + HorzScrollBar.Position) / FImage.Width;
  end;

  if FImage.Height > 0 then
  begin
    if FImage.Top >= 0 then
      CenterRatioY:= (CliHeight div 2 - FImage.Top) / FImage.Height
    else
      CenterRatioY:= (CliHeight div 2 + VertScrollBar.Position) / FImage.Height;
  end;

  //Set controls params
  if not bKeepPosition then
  begin
    HorzScrollBar.Position:= 0;
    VertScrollBar.Position:= 0;
  end;

  AutoScroll:= not FImageFit;

  FImage.AutoSize:= (not FImageFit) and (FImageScale = 100);
  FImage.Stretch:= not FImage.AutoSize;

  {
  //Note: commented, because we convert icon to bitmap in UpdateInfo.
  //Work around VCL draw bug for icons:
  if FImageIsIcon then
    begin
    FImage.AutoSize:= False;
    FImage.Stretch:= True;
    FImage.Width:= FImageWidth;
    FImage.Height:= FImageHeight;
    end;
    }

  //Fit and recalculate ImageScale
  if FImageFit then
  begin
    {
    //Note: code commented in as it causes wrong scaling sometimes.
    //If image is already fit, don't scale it:
    if (FImage.Width = CliWidth) and
      (FImage.Height = CliHeight) then
    begin
      NewWidth:= FImage.Width;
      NewHeight:= FImage.Height;
    end
    else
    }
    //Need to scale
    begin
      NewWidth:= FImageWidth;
      NewHeight:= FImageHeight;

      if FImageFitOnlyBig and
        (FImageWidth <= CliWidth) and (FImageHeight <= CliHeight) then
      begin
        FImageScale:= 100;
      end
      else
      begin
        if (CliWidth > 0) and (CliHeight > 0) and
          (FImageWidth > 0) and (FImageHeight > 0) then
        begin
          NRatio:= CliWidth / CliHeight;
          NImageRatio:= FImageWidth / FImageHeight;
          if ((NRatio >= NImageRatio) and (not FImageFitWidth)) or FImageFitHeight then
          begin
            //fit height
            if FImageFitOnlyBig and (CliHeight >= FImageHeight) then begin end
            else
            begin
              NewHeight:= CliHeight;
              NewWidth:= Trunc(NewHeight * NImageRatio);
              FImageScale:= CliHeight * 100 div FImageHeight;
            end;
          end
          else
          begin
            //fit width
            if FImageFitOnlyBig and (CliWidth >= FImageWidth) then begin end
            else
            begin
              NewWidth:= CliWidth;
              NewHeight:= Trunc(NewWidth / NImageRatio);
              FImageScale:= CliWidth * 100 div FImageWidth;
            end;
          end;
        end;
      end
    end
  end //if FImageFit
  else
  begin
    NewWidth:= Round(FImageWidth * FImageScale / 100);
    NewHeight:= Round(FImageHeight * FImageScale / 100);
  end;

  //Update image position
  NewLeft:= 0;
  NewTop:= 0;

  if FImageCenter then
  begin
    if CliWidth > NewWidth then
      NewLeft:= (CliWidth - NewWidth) div 2;
    if CliHeight > NewHeight then
      NewTop:= (CliHeight - NewHeight) div 2;
  end;

  if (FOldLeft<>NewLeft - HorzScrollBar.Position) or
    (FOldTop<>NewTop - VertScrollBar.Position) or
    (FOldWidth<>NewWidth) or
    (FOldHeight<>NewHeight) then
  begin
    FOldLeft:= NewLeft - HorzScrollBar.Position;
    FOldTop:= NewTop - VertScrollBar.Position;
    FOldWidth:= NewWidth;
    FOldHeight:= NewHeight;
    FImage.SetBounds(
      FOldLeft,
      FOldTop,
      FOldWidth,
      FOldHeight);
  end;

  //Restore saved center position
  if bKeepPosition then
  begin
    if NewLeft = 0 then
    begin
      ScrollMaxX:= Max(NewWidth - CliWidth, 0);
      HorzScrollBar.Position:=
        Min(ScrollMaxX, Trunc(CenterRatioX * NewWidth) - CliWidth div 2);
    end
    else
      HorzScrollBar.Position:= 0;

    if NewTop = 0 then
    begin
      ScrollMaxY:= Max(NewHeight - CliHeight, 0);
      VertScrollBar.Position:=
        Min(ScrollMaxY, Trunc(CenterRatioY * NewHeight) - CliHeight div 2);
    end
    else
      VertScrollBar.Position:= 0;
  end;

  //adjust range
  if HorzScrollbar.Visible then
    HorzScrollbar.Range:= NewWidth;
  if VertScrollBar.Visible then
    VertScrollbar.Range:= NewHeight;

  DoScroll;
end;

procedure TATImageBox.SetImageFit(AValue: Boolean);
begin
  if AValue <> FImageFit then
  begin
    FImageFit:= AValue;
    if not FImageFit then
      FImageScale:= 100;
    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.SetImageFitOnlyBig(AValue: Boolean);
begin
  if AValue <> FImageFitOnlyBig then
  begin
    FImageFitOnlyBig:= AValue;
    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.SetImageCenter(AValue: Boolean);
begin
  if AValue <> FImageCenter then
  begin
    FImageCenter:= AValue;
    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.UpdateInfo;
begin
  FImageWidth:= 0;
  FImageHeight:= 0;
  FImageScale:= 100;

  FImage.Visible:= true;

  if Assigned(FImage.Picture) and Assigned(FImage.Picture.Graphic) then
  begin
    FImageWidth:= FImage.Picture.Width;
    FImageHeight:= FImage.Picture.Height;

    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.Resize;
begin
  inherited;
  if Assigned(FImage) and
    ((FOldSelfW <> Self.Width) or (FOldSelfH <> Self.Height)) then
  begin
    FOldSelfW:= Self.Width;
    FOldSelfH:= Self.Height;
    UpdateImagePosition;
  end;
end;

procedure TATImageBox.SetImageScale(AValue: Integer);
begin
  if (AValue<=0) or (AValue>2000) then exit;
  if FImageScale <> AValue then
  begin
    FImageScale:= AValue;
    FImageFit:= False;
    HorzScrollBar.Position:= 0;
    VertScrollBar.Position:= 0;
    UpdateImagePosition;
    DoOptionsChange;
  end;
end;

procedure TATImageBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if FFocusable then
    SetFocus;
end;

procedure TATImageBox.Loaded;
begin
  inherited;
  UpdateInfo;
  UpdateImagePosition(true);
end;

procedure TATImageBox.ImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FFocusable then
    SetFocus;

  if (Button = mbLeft) then
  begin
    FImageMouseDown:= True;
    if FImageDrag then
    begin
      FImageDragging:= True;
      FImageDraggingPoint:= Point(X, Y);
      Screen.Cursor:= FImageDragCursor;
    end;
  end;
end;

procedure TATImageBox.ImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
  begin
    FImageMouseDown:= False;
    FImageDragging:= False;
    Screen.Cursor:= crDefault;
  end;
end;

procedure TATImageBox.ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FImageDrag and FImageDragging then
  begin
    HorzScrollBar.Position:= HorzScrollBar.Position + (FImageDraggingPoint.X - X);
    VertScrollBar.Position:= VertScrollBar.Position + (FImageDraggingPoint.Y - Y);
    DoScroll;
  end;
end;

procedure TATImageBox.IncreaseImageScale(AIncrement: Boolean);
var
  i: Integer;
begin
  if AIncrement then
  begin
    for i:= Low(cViewerImageScales) to High(cViewerImageScales) do
      if cViewerImageScales[i] > ImageScale then
      begin
        ImageScale:= cViewerImageScales[i];
        Break
      end;
  end
  else
  begin
    for i:= High(cViewerImageScales) downto Low(cViewerImageScales) do
      if cViewerImageScales[i] < ImageScale then
      begin
        ImageScale:= cViewerImageScales[i];
        Break
      end;
  end;
end;

procedure TATImageBox.DoOptionsChange;
begin
  if Assigned(FOnOptionsChange) then
    FOnOptionsChange(Self);
end;


procedure TATImageBox.SetImageFitWidth(AValue: Boolean);
begin
  if AValue <> FImageFitWidth then
  begin
    FImageFitWidth:= AValue;
    if AValue then
      FImageFitHeight:= False;
    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.SetImageFitHeight(AValue: Boolean);
begin
  if AValue <> FImageFitHeight then
  begin
    FImageFitHeight:= AValue;
    if AValue then
      FImageFitWidth:= False;
    UpdateImagePosition(True);
  end;
end;

procedure TATImageBox.Unload;
begin
  FImage.Picture:= nil;
  UpdateInfo;
end;

procedure TATImageBox.LoadBitmap(ABitmap: TBitmap; ATransp: Boolean);
begin
  Unload;
  FImage.Picture.Assign(ABitmap);
  FImage.Transparent:= ATransp;
  UpdateInfo;
end;

procedure TATImageBox.LoadPicture(APicture: TPicture);
begin
  Unload;
  FImage.Picture.Assign(APicture);
  UpdateInfo;
end;

procedure TATImageBox.LoadFromFile(const FN: string);
begin
  Unload;
  FImage.Picture.LoadFromFile(FN);
  UpdateInfo;
end;

function TATImageBox.GetPicture: TPicture;
begin
  Result:= FImage.Picture;
end;

procedure TATImageBox.SetPicture(AValue: TPicture);
begin
  LoadPicture(AValue);
  UpdateImagePosition(true);
end;

procedure TATImageBox.ImagePaintBackground(ASender: TObject; ACanvas: TCanvas; ARect: TRect);
begin
  DoPaintCheckers(
    ACanvas,
    ARect.Right-ARect.Left,
    ARect.Bottom-ARect.Top,
    FCheckersSize,
    FCheckersColor1,
    FCheckersColor2
    );
end;

end.
