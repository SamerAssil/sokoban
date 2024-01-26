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
  end;

  TStringListHelper = class Helper for TStringList
    function Width: integer;
    function Height: integer;
    procedure Fill(aWidth, aHeight: integer; aChar: Char);
    procedure MoveToStringList(aPos: TPosition; aTarget: TStringList);
    function IsGoal(aPos: TPosition): Boolean;
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
    Player: TPosition;
    [weak]
    game: TGame;
  public
    constructor create(aGame: TGame);
    destructor Destroy; override;
    procedure LoadLevel(aNo: integer);
    procedure LoadAssets;
    function MovePlayer(aDirection: TDirection): TPosition;
    property Map: TMap read FMap write FMap;
    property Goals: TGoals read FGoals write FGoals;
  end;

  TAsset = record
    symbol: Char;
    Rs_Name: String;
    Image: TPngImage;
  end;

  TSymbolsAnd = TObjectDictionary<Char, String>;
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
    function findAsset(aSymbol: Char): TAsset;
    procedure SetState(const Value: TGameState);
  public
    constructor create(aOutputImage: TImage; aOnComplete: TOnCompletePro = nil);
    destructor Destroy; override;
    procedure Draw;
    function CheckCompleted: Boolean;
    procedure Step(aDirection: TDirection);
    property Level: TLevel read FLevel write FLevel;
    property OutputImage: TImage read FOutputImage;
    property State: TGameState read FState write SetState;
    property OnComplete: TOnCompletePro read FOnComplete write FOnComplete;
  end;

const
  BLOCK_SIZE = 64;
  Player = '@';
  PlayerU = 'U';
  GOAL = 'X';
  WALL = '#';
  BOX = 'O';
  EMPTY = '.';
  DEAD_END_POS: TPosition = (Col: - 1; Row: - 1);

  SYMBOLS: array [0 .. 4] of Char = (Player, EMPTY, WALL, GOAL, BOX);
  RS_NAMES: array [0 .. 4] of string = ('player_front', 'empty', 'wall',
    'goal', 'box');

function Position(aCol, aRow: integer): TPosition; inline;

{$ZEROBASEDSTRINGS ON}

implementation

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
end;

procedure TLevel.LoadAssets;
var
  png: TPngImage;
  asset: TAsset;
begin
  for var i: integer := low(SYMBOLS) to high(SYMBOLS) do
  begin
    png := TPngImage.create;
    png.LoadFromResourceName(HInstance, RS_NAMES[i]);
    asset.symbol := SYMBOLS[i];
    asset.Rs_Name := RS_NAMES[i];
    asset.Image := png;
    game.Assets := game.Assets + [asset];
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

  Map := TMap.create(TDuplicates.dupAccept, false, false);
  Map.LoadFromStream(rs);

  Goals := TGoals.create(TDuplicates.dupAccept, false, false);;
  Goals.Fill(Map.Width, Map.Height, EMPTY);

  for var Col: integer := 0 to Map.Width - 1 do
    for var Row: integer := 0 to Map.Height - 1 do
    begin
      if Map.isPlayer(Position(Col, Row)) then
        Player := Position(Col, Row);
      if Map.IsGoal(Position(Col, Row)) then
        Map.MoveToStringList(Position(Col, Row), Goals);
    end;

  LoadAssets;
  game.Draw;
  game.State := gsRun;
end;

function TLevel.MovePlayer(aDirection: TDirection): TPosition;
var
  p, nPos: TPosition;
begin
  case Map.Neighbor(Player, aDirection, nPos) of
    EMPTY:
      Player := Map.MoveChar(Player, aDirection);
    BOX:
      begin
        if Map.Neighbor(nPos, aDirection, p) = EMPTY then
        begin
          Map.MoveChar(nPos, aDirection);
          Player := Map.MoveChar(Player, aDirection);
        end;
      end;
  end;
  Result := Player;
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

function TStringListHelper.IsGoal(aPos: TPosition): Boolean;
begin
  Result := Self[aPos.Row].Chars[aPos.Col] = GOAL;
end;

function TStringListHelper.isPlayer(aPos: TPosition): Boolean;
begin
  Result := Self.AtPos(aPos) = Player;
end;

function TStringListHelper.MoveChar(aPos: TPosition; aDirection: TDirection)
  : TPosition;
var
  chr: Char;
  newPos: TPosition;
begin
  chr := Self.AtPos(aPos);
  case aDirection of
    dUp:
      newPos := Position(aPos.Col, aPos.Row - 1);
    dDown:
      newPos := Position(aPos.Col, aPos.Row + 1);
    dLeft:
      newPos := Position(aPos.Col - 1, aPos.Row);
    dRight:
      newPos := Position(aPos.Col + 1, aPos.Row);
  end;
  Self.ReplaceAtPos(newPos, chr);
  Self.ReplaceAtPos(Position(aPos.Col, aPos.Row), EMPTY);
  Result := newPos;
end;

procedure TStringListHelper.MoveToStringList(aPos: TPosition;
  aTarget: TStringList);
var
  chr: Char;
begin
  chr := Self.AtPos(Position(aPos.Col, aPos.Row));
  aTarget.ReplaceAtPos(aPos, chr);
  Self.ReplaceAtPos(aPos, EMPTY);
end;

function TStringListHelper.Neighbor(aPos: TPosition; aDirection: TDirection;
  var NeighberPos: TPosition): Char;
var
  pos: TPosition;
begin
  case aDirection of
    dUp:
      pos := Position(aPos.Col, aPos.Row - 1);
    dDown:
      pos := Position(aPos.Col, aPos.Row + 1);
    dLeft:
      pos := Position(aPos.Col - 1, aPos.Row);
    dRight:
      pos := Position(aPos.Col + 1, aPos.Row);
  end;
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
  FLevel := TLevel.create(Self);
  FOutputImage := aOutputImage;
  State := gsStart;
  OnComplete := aOnComplete
end;

destructor TGame.Destroy;
begin
  Level.Free;
end;

procedure TGame.Draw;
var
  asset, EmptyAsset: TAsset;
begin
  EmptyAsset := findAsset(EMPTY);

  for var Col: integer := 0 to Level.Map.Width - 1 do
    for var Row: integer := 0 to Level.Map.Height - 1 do
    begin
      OutputImage.Canvas.Draw(Col * BLOCK_SIZE, Row * BLOCK_SIZE,
        EmptyAsset.Image);

      asset := findAsset(Level.Goals.AtPos(Position(Col, Row)));
      OutputImage.Canvas.Draw(Col * BLOCK_SIZE, Row * BLOCK_SIZE, asset.Image);

      asset := findAsset(Level.Map.AtPos(Position(Col, Row)));
      if asset.symbol <> EMPTY then
        OutputImage.Canvas.Draw(Col * BLOCK_SIZE, Row * BLOCK_SIZE,
          asset.Image);
    end;
end;

function TGame.findAsset(aSymbol: Char): TAsset;
var
  asset: TAsset;
begin
  for asset in Assets do
    if aSymbol = asset.symbol then
    begin
      Result := asset;
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

procedure TGame.Step(aDirection: TDirection);
var
  p: TPosition;
begin
  p.Col := 10;
  Level.MovePlayer(aDirection);
  Draw;
  CheckCompleted;
end;

end.
