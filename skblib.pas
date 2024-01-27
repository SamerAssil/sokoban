unit skblib;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.StrUtils,
  System.Generics.Collections, System.Math, System.Types,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.Controls, Vcl.Graphics;

type
  TDirection = (dUp, dDown, dLeft, dRight);

  TPosition = record
    Col: integer;
    Row: integer;
    procedure Shift(aDir: TDirection);
  end;

  TStringListHelper = class Helper for TStringList
    function Width: integer;
    function Height: integer;
    procedure Fill(aWidth, aHeight: integer; aChar: Char);
    procedure MoveToStringList(aPos: TPosition; aTarget: TStringList);
    function IsGoal(aPos: TPosition): Boolean;
    function IsBox(aPos: TPosition): Boolean;
    function isPlayer(aPos: TPosition): Boolean;
    function AtPos(aPos: TPosition): Char;
    procedure ReplaceAtPos(aPos: TPosition; aNewChar: Char);
    function MoveChar(aPos: TPosition; aDirection: TDirection): TPosition;
    function Neighbor(aPos: TPosition; aDirection: TDirection;
      var NeighberPos: TPosition): Char;
  end;

  TGoals = TStringList;
  TMap = TStringList;

  TGame = class;

  TLevel = class
  private
    FMap: TMap;
    FGoals: TGoals;
    ThePlayer: TPosition;
    game: TGame;
  public
    constructor create(aGame: TGame);
    destructor Destroy; override;
    procedure LoadLevel(aNo: integer);
    procedure LoadAssets;
    function isBoxInPlace(aPosition: TPosition): Boolean;
    function MovePlayer(aDirection: TDirection): TPosition;
    property Map: TMap read FMap write FMap;
    property Goals: TGoals read FGoals write FGoals;
  end;

  TAsset = record
    symbol: Char;
    Rs_Name: String;
    Image: TPngImage;
  end;

  TGameState = (gsStart, gsFinish, gsRun);

  TOnCompletePro = procedure() of Object;

  TGame = class
  private
    FLevel: TLevel;
    FOutputImage: TImage;
    Assets: TArray<TAsset>;
  private
    FState: TGameState;
    FOnComplete: TOnCompletePro;
    FZoom: integer;
    function findAsset(aSymbol: Char): TAsset;
    procedure SetState(const Value: TGameState);
    procedure DrawAsset(aPos: TPosition; const [Ref] Asset: TAsset);
    procedure SetZoom(const Value: integer);
  public
    constructor create(aOutputImage: TImage; aOnComplete: TOnCompletePro = nil);
    destructor Destroy; override;
    procedure Draw;
    procedure ZoomOut;
    procedure ZoomIn;
    function CheckCompleted: Boolean;
    procedure Step(aDirection: TDirection);
    property Level: TLevel read FLevel write FLevel;
    property OutputImage: TImage read FOutputImage;
    property State: TGameState read FState write SetState;
    property OnComplete: TOnCompletePro read FOnComplete write FOnComplete;
    property Zoom: integer read FZoom write SetZoom default 30;
  end;

const
  ZOOM_STEP = 5;
  ZOOM_MAX = 100;
  ZOOM_MIN = 10;
  PLAYER = '@';
  GOAL = 'X';
  WALL = '#';
  BOX = 'O';
  EMPTY = '.';
  BOX_IN_PLACE = '+';

  SYMBOLS: array [0 .. 5] of Char = (PLAYER, EMPTY, WALL, GOAL, BOX,
    BOX_IN_PLACE);
  RS_NAMES: array [0 .. 5] of string = ('player_front', 'empty', 'wall', 'goal',
    'box', 'BoxInPlace');

function Position(aCol, aRow: integer): TPosition; inline;

{$ZEROBASEDSTRINGS ON}

implementation

{ TPosition }

procedure TPosition.Shift(aDir: TDirection);
begin
  case aDir of
    dUp:
      dec(Row);
    dDown:
      inc(Row);
    dLeft:
      dec(Col);
    dRight:
      inc(Col);
  end;
end;

{ TLevel }

function Position(aCol, aRow: integer): TPosition; inline;
begin
  Result.Col := aCol;
  Result.Row := aRow;
end;

constructor TLevel.create(aGame: TGame);
begin
  game := aGame;
end;

destructor TLevel.Destroy;
begin
  Map.Free;
  Goals.Free;
end;

function TLevel.isBoxInPlace(aPosition: TPosition): Boolean;
begin
  Result := (Map.IsBox(aPosition)) and (Goals.IsGoal(aPosition));
end;

procedure TLevel.LoadAssets;
var
  png: TPngImage;
  Asset: TAsset;
begin
  for var i: integer := low(SYMBOLS) to high(SYMBOLS) do
  begin
    png := TPngImage.create;
    png.LoadFromResourceName(HInstance, RS_NAMES[i]);
    Asset.symbol := SYMBOLS[i];
    Asset.Rs_Name := RS_NAMES[i];
    Asset.Image := png;
    game.Assets := game.Assets + [Asset];
  end;
end;

procedure TLevel.LoadLevel(aNo: integer);
var
  rs: TResourceStream;
begin
  Map.Free;
  Goals.Free;
  game.OutputImage.Picture.Assign(nil);
  rs := TResourceStream.create(HInstance, 'lvl' + aNo.ToString, RT_RCDATA);
  try

    Map := TMap.create(TDuplicates.dupAccept, false, false);
    Map.LoadFromStream(rs);

    Goals := TGoals.create(TDuplicates.dupAccept, false, false);;
    Goals.Fill(Map.Width, Map.Height, EMPTY);

    for var Col: integer := 0 to Map.Width - 1 do
      for var Row: integer := 0 to Map.Height - 1 do
      begin
        case Map.AtPos(Position(Col, Row)) of
          PLAYER:
            ThePlayer := Position(Col, Row);
          GOAL:
            Map.MoveToStringList(Position(Col, Row), Goals);
        end;
      end;
    LoadAssets;
    game.Draw;
    game.State := gsRun;
  finally
    rs.Free;
  end;
end;

function TLevel.MovePlayer(aDirection: TDirection): TPosition;
var
  p, nPos: TPosition;
begin
  case Map.Neighbor(ThePlayer, aDirection, nPos) of
    EMPTY:
      ThePlayer := Map.MoveChar(ThePlayer, aDirection);
    BOX:
      begin
        if Map.Neighbor(nPos, aDirection, p) = EMPTY then
        begin
          Map.MoveChar(nPos, aDirection);
          ThePlayer := Map.MoveChar(ThePlayer, aDirection);
        end;
      end;
  end;
  Result := ThePlayer;
end;

{ TStringListHelper }

function TStringListHelper.AtPos(aPos: TPosition): Char;
begin
  Result := Self[aPos.Row].Chars[aPos.Col];
end;

procedure TStringListHelper.Fill(aWidth, aHeight: integer; aChar: Char);
var
  line: String;
begin
  Self.Clear;
  line := StringOfChar(aChar, aWidth);
  for var i: integer := 0 to aHeight do
    Self.Add(line);
end;

function TStringListHelper.Height: integer;
begin
  Result := Self.Count;
end;

function TStringListHelper.IsBox(aPos: TPosition): Boolean;
begin
  Result := Self.AtPos(aPos) = BOX;
end;

function TStringListHelper.IsGoal(aPos: TPosition): Boolean;
begin
  Result := Self.AtPos(aPos) = GOAL;
end;

function TStringListHelper.isPlayer(aPos: TPosition): Boolean;
begin
  Result := Self.AtPos(aPos) = PLAYER;
end;

function TStringListHelper.MoveChar(aPos: TPosition; aDirection: TDirection)
  : TPosition;
var
  chr: Char;
  newPos: TPosition;
begin
  chr := Self.AtPos(aPos);
  newPos := aPos;
  newPos.Shift(aDirection);
  Self.ReplaceAtPos(newPos, chr);
  Self.ReplaceAtPos(aPos, EMPTY);
  Result := newPos;
end;

procedure TStringListHelper.MoveToStringList(aPos: TPosition;
  aTarget: TStringList);
var
  chr: Char;
begin
  chr := Self.AtPos(aPos);
  aTarget.ReplaceAtPos(aPos, chr);
  Self.ReplaceAtPos(aPos, EMPTY);
end;

function TStringListHelper.Neighbor(aPos: TPosition; aDirection: TDirection;
  var NeighberPos: TPosition): Char;
var
  pos: TPosition;
begin
  pos := aPos;
  pos.Shift(aDirection);
  NeighberPos := pos;
  Result := AtPos(pos);
end;

procedure TStringListHelper.ReplaceAtPos(aPos: TPosition; aNewChar: Char);
var
  line: String;
begin
  line := Self[aPos.Row];
  line[aPos.Col] := aNewChar;
  Self[aPos.Row] := line;
end;

function TStringListHelper.Width: integer;
begin
  Result := Self[0].Length;
end;

{ TGame }

constructor TGame.create(aOutputImage: TImage; aOnComplete: TOnCompletePro);
begin
  FZoom := (ZOOM_MAX - ZOOM_MIN) div 2;
  FLevel := TLevel.create(Self);
  FOutputImage := aOutputImage;
  State := gsStart;
  OnComplete := aOnComplete
end;

destructor TGame.Destroy;
begin
  Level.Free;
  for var i: integer := Low(Assets) to High(Assets) do
    Assets[i].Image.Free;
end;

procedure TGame.Draw;
var
  Asset, EmptyAsset, BoxInPlaceAsset: TAsset;
  pos: TPosition;
begin
  OutputImage.Canvas.Brush.Color := clWindow;
  OutputImage.Canvas.FillRect(OutputImage.ClientRect);
  EmptyAsset := findAsset(EMPTY);
  BoxInPlaceAsset := findAsset(BOX_IN_PLACE);

  for var Col: integer := 0 to Level.Map.Width - 1 do
    for var Row: integer := 0 to Level.Map.Height - 1 do
    begin
      pos := Position(Col, Row);
      DrawAsset(pos, EmptyAsset);
      // clear the boad
      Asset := findAsset(Level.Goals.AtPos(pos));
      DrawAsset(pos, Asset);

      Asset := findAsset(Level.Map.AtPos(pos));
      // drow map items
      if Asset.symbol <> EMPTY then
        DrawAsset(pos, Asset);
      // Drow Box in goals
      if Level.isBoxInPlace(pos) then
        DrawAsset(pos, BoxInPlaceAsset)
    end;
end;

procedure TGame.DrawAsset(aPos: TPosition; const [Ref] Asset: TAsset);
begin
  OutputImage.Canvas.StretchDraw(Rect(aPos.Col * Zoom, aPos.Row * Zoom,
    (aPos.Col * Zoom) + Zoom, (aPos.Row * Zoom) + Zoom), Asset.Image);
  // OutputImage.Canvas.Draw(aPos.Col * BLOCK_SIZE, aPos.Row * BLOCK_SIZE,
  // Asset.Image);
end;

function TGame.findAsset(aSymbol: Char): TAsset;
var
  Asset: TAsset;
begin
  for Asset in Assets do
    if aSymbol = Asset.symbol then
    begin
      Result := Asset;
      exit;
    end;
end;

function TGame.CheckCompleted: Boolean;
begin
  for var Col: integer := 0 to Level.Map.Width - 1 do
    for var Row: integer := 0 to Level.Map.Height - 1 do
    begin
      if (Level.Goals.AtPos(Position(Col, Row)) = GOAL) and
        (not(Level.Map.AtPos(Position(Col, Row)) = BOX)) then
      begin
        State := gsRun;
        Result := false;
        exit;
      end;
    end;
  Result := true;
  State := gsFinish;
end;

procedure TGame.SetState(const Value: TGameState);
begin
  if FState <> Value then
  begin
    FState := Value;
    if (assigned(OnComplete)) and (FState = gsFinish) then
      OnComplete();
  end;
end;

procedure TGame.SetZoom(const Value: integer);
begin
  FZoom := Value;
  if FZoom > ZOOM_MAX then
    FZoom := ZOOM_MAX;
  if FZoom < ZOOM_MIN then
    FZoom := ZOOM_MIN;
  Draw;
end;

procedure TGame.Step(aDirection: TDirection);
begin
  Level.MovePlayer(aDirection);
  Draw;
  CheckCompleted;
end;

procedure TGame.ZoomIn;
begin
  Zoom := Zoom + ZOOM_STEP;
end;

procedure TGame.ZoomOut;
begin
  Zoom := Zoom - ZOOM_STEP;
end;

end.
