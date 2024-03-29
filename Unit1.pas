unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, skblib, Vcl.ExtCtrls,
  Vcl.AppEvnts, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Image1: TImage;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DialogKey(var Msg: TWMKey); message CM_DIALOGKEY;
  private
    procedure onGameComplete;
    procedure StartGame(aLevel: integer);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  game: TGame;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  StartGame(1);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  StartGame(2);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  StartGame(3);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  game.ZoomOut;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  game.ZoomIn;
end;

procedure TForm1.DialogKey(var Msg: TWMKey);
begin
  case Msg.CharCode of
    VK_DOWN, VK_UP, VK_RIGHT, VK_LEFT:
      begin
        onKeyDown(Self, Msg.CharCode, KeyDataToShiftState(Msg.KeyData));
        Msg.Result := 1;
      end;
  else
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  game.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := true;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_DOWN:
      game.Step(dDown);
    VK_UP:
      game.Step(dUP);
    VK_LEFT:
      game.Step(dLeft);
    VK_RIGHT:
      game.Step(dRight);
  end;
  Memo1.Lines := game.Level.map;
end;

procedure TForm1.onGameComplete;
begin
  ShowMessage('Nice');
end;

procedure TForm1.StartGame(aLevel: integer);
begin
  if assigned(game) then
    game.Free;
  game := TGame.Create(Image1, onGameComplete);
  game.Level.LoadLevel(aLevel);
  Memo1.Lines := game.Level.map;
end;



end.
